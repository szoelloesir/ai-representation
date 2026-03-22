# watcher.ps1
# Central file watcher for the agency workspace.
# Monitors context/tasks/ for new assignments and completions.
# Runs in its own tab - do not close.
#
# Protocol:
#   Orchestrator writes  -> context/tasks/worker-a-current.json
#   Watcher detects      -> writes context/tasks/worker-a-trigger.txt
#   Worker loop polls    -> reads trigger, runs claude --print, writes result
#   Worker writes        -> context/handoffs/worker-a-result.md
#                       -> context/tasks/worker-a-done.txt
#   Watcher detects      -> writes context/tasks/orchestrator-trigger-worker-a.txt
#   Orchestrator polls   -> reads trigger, reads result, reports to user
#
# TODO(future-models): add new agent names to $AGENTS below.
# The rest of the watcher handles them automatically.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$PROJECT  = $args[0]
$TASKS    = Join-Path $PROJECT "context\tasks"
$HANDOFFS = Join-Path $PROJECT "context\handoffs"
$INTERVAL = 5

$AGENTS = @("worker-a", "worker-b")

function Write-Event {
    param($agent, $status, $detail = "")
    $ts  = Get-Date -Format "HH:mm:ss"
    $msg = "[$ts] $agent - $status"
    if ($detail) { $msg += " ($detail)" }
    switch -Wildcard ($status) {
        "TASK ASSIGNED"    { Write-Host $msg -ForegroundColor Cyan }
        "TASK COMPLETED"   { Write-Host $msg -ForegroundColor Green }
        "RESULT READY*"    { Write-Host $msg -ForegroundColor Green }
        "TRIGGER WRITTEN"  { Write-Host $msg -ForegroundColor Gray }
        "RESUME*"          { Write-Host $msg -ForegroundColor Yellow }
        "ERROR*"           { Write-Host $msg -ForegroundColor Red }
        default            { Write-Host $msg -ForegroundColor Gray }
    }
}

function Write-Trigger {
    param($path, $content)
    $content | Set-Content -Path $path -Encoding UTF8
}

function Process-Agent {
    param($agent)

    $taskFile    = Join-Path $TASKS    "$agent-current.json"
    $triggerFile = Join-Path $TASKS    "$agent-trigger.txt"
    $doneFile    = Join-Path $TASKS    "$agent-done.txt"
    $resultFile  = Join-Path $HANDOFFS "$agent-result.md"
    $orchTrigger = Join-Path $TASKS    "orchestrator-trigger-$agent.txt"
    $taskKey     = "task-$agent"
    $doneKey     = "done-$agent"

    # ---- Detect task assigned but not yet triggered ----
    if ((Test-Path $taskFile) -and -not (Test-Path $triggerFile) -and -not (Test-Path $doneFile)) {
        if (-not $script:triggered[$taskKey]) {
            try {
                $task = Get-Content $taskFile -Raw | ConvertFrom-Json
                $role = if ($task.role) { $task.role } else { "unknown role" }
                Write-Event $agent "TASK ASSIGNED" $role
                Write-Trigger $triggerFile "TASK_READY`n$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`nRead context/tasks/$agent-current.json and complete the task."
                Write-Event $agent "TRIGGER WRITTEN" "$agent-trigger.txt"
                $script:triggered[$taskKey] = $true
            } catch {
                Write-Event $agent "ERROR reading task" $_.Exception.Message
            }
        }
    }

    # ---- Detect worker completed ----
    if ((Test-Path $doneFile) -and (Test-Path $resultFile)) {
        if (-not $script:triggered[$doneKey]) {
            Write-Event $agent "TASK COMPLETED"
            Write-Trigger $orchTrigger "RESULT_READY`n$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n$agent completed task. Read context/handoffs/$agent-result.md and synthesize."
            Write-Event "orchestrator" "RESULT READY" "from $agent"
            Remove-Item $taskFile    -Force -ErrorAction SilentlyContinue
            Remove-Item $triggerFile -Force -ErrorAction SilentlyContinue
            Remove-Item $doneFile    -Force -ErrorAction SilentlyContinue
            $script:triggered.Remove($taskKey)
            $script:triggered[$doneKey] = $true
        }
    }

    # ---- Reset done tracking once orchestrator acknowledges (deletes its trigger) ----
    if (-not (Test-Path $orchTrigger) -and $script:triggered[$doneKey]) {
        $script:triggered.Remove($doneKey)
    }
}

# ----------------------------------------------------------------
# Startup scan - resume any state left over from previous session
# ----------------------------------------------------------------
Write-Host ""
Write-Host "Agency Watcher started" -ForegroundColor Yellow
Write-Host "Project : $PROJECT" -ForegroundColor Gray
Write-Host "Interval: every $INTERVAL seconds" -ForegroundColor Gray
Write-Host "Agents  : $($AGENTS -join ', ')" -ForegroundColor Gray
Write-Host "Press Ctrl+C to stop." -ForegroundColor Gray
Write-Host ""
Write-Host "Scanning for pre-existing state..." -ForegroundColor Yellow

$script:triggered = @{}
$foundOnStartup   = $false

foreach ($agent in $AGENTS) {
    $taskFile    = Join-Path $TASKS    "$agent-current.json"
    $triggerFile = Join-Path $TASKS    "$agent-trigger.txt"
    $doneFile    = Join-Path $TASKS    "$agent-done.txt"
    $resultFile  = Join-Path $HANDOFFS "$agent-result.md"
    $orchTrigger = Join-Path $TASKS    "orchestrator-trigger-$agent.txt"

    # Case 1: task exists, no trigger yet, not done -> re-trigger
    if ((Test-Path $taskFile) -and -not (Test-Path $triggerFile) -and -not (Test-Path $doneFile)) {
        try {
            $task = Get-Content $taskFile -Raw | ConvertFrom-Json
            $role = if ($task.role) { $task.role } else { "unknown role" }
            Write-Event $agent "RESUME: unstarted task" $role
            Write-Trigger $triggerFile "TASK_READY`n$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`nRESUMED - Read context/tasks/$agent-current.json and complete the task."
            Write-Event $agent "TRIGGER WRITTEN" "resumed"
            $script:triggered["task-$agent"] = $true
            $foundOnStartup = $true
        } catch {
            Write-Event $agent "ERROR reading existing task" $_.Exception.Message
        }
    }

    # Case 2: task exists, trigger exists, not done -> worker will pick up on next poll
    if ((Test-Path $taskFile) -and (Test-Path $triggerFile) -and -not (Test-Path $doneFile)) {
        Write-Event $agent "RESUME: task in progress" "worker will pick up on next poll"
        $script:triggered["task-$agent"] = $true
        $foundOnStartup = $true
    }

    # Case 3: done + result exist, orchestrator not yet notified -> re-notify
    if ((Test-Path $doneFile) -and (Test-Path $resultFile) -and -not (Test-Path $orchTrigger)) {
        Write-Event $agent "RESUME: result not delivered to orchestrator" ""
        Write-Trigger $orchTrigger "RESULT_READY`n$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`nRESUMED - $agent completed. Read context/handoffs/$agent-result.md and synthesize."
        Write-Event "orchestrator" "RESULT READY" "from $agent (resumed)"
        Remove-Item $taskFile    -Force -ErrorAction SilentlyContinue
        Remove-Item $triggerFile -Force -ErrorAction SilentlyContinue
        Remove-Item $doneFile    -Force -ErrorAction SilentlyContinue
        $script:triggered["done-$agent"] = $true
        $foundOnStartup = $true
    }
}

if (-not $foundOnStartup) {
    Write-Host "No pending state found - clean slate." -ForegroundColor Gray
}
Write-Host ""
Write-Host "Watching for activity..." -ForegroundColor Gray
Write-Host ""

# ----------------------------------------------------------------
# Main loop
# ----------------------------------------------------------------
while ($true) {
    foreach ($agent in $AGENTS) {
        Process-Agent $agent
    }
    Start-Sleep -Seconds $INTERVAL
}
