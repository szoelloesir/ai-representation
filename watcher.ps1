# watcher.ps1
# Central file watcher for the agency workspace.
# Monitors context/tasks/ for new assignments and completions.
# Runs in its own tab - do not close.
#
# Protocol:
#   Orchestrator writes  -> context/tasks/worker-a-current.json
#   Watcher detects      -> writes context/tasks/worker-a-trigger.txt
#   Worker polls         -> reads trigger, does work
#   Worker writes        -> context/handoffs/worker-a-result.md
#                       -> context/tasks/worker-a-done.txt
#   Watcher detects      -> writes context/tasks/orchestrator-trigger.txt
#   Orchestrator polls   -> reads trigger, reads result, reports to user
#
# Adding a new agent/LLM in future:
#   1. Add its name to $AGENTS below
#   2. The watcher handles it automatically - no other changes needed
#   TODO(future-models): each agent entry maps to a provider type.
#   When non-Claude agents are added, the trigger file can include
#   provider-specific metadata the agent runtime reads on pickup.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$PROJECT   = $args[0]
$TASKS     = Join-Path $PROJECT "context\tasks"
$HANDOFFS  = Join-Path $PROJECT "context\handoffs"
$INTERVAL  = 5  # seconds

# List of worker agent names - add new agents here as the pool grows
# TODO(future-models): extend this list when Gemini/Cursor workers are added
$AGENTS = @("worker-a", "worker-b")

function Write-Event {
    param($agent, $status, $detail = "")
    $ts = Get-Date -Format "HH:mm:ss"
    $msg = "[$ts] $agent - $status"
    if ($detail) { $msg += " ($detail)" }
    switch -Wildcard ($status) {
        "TASK ASSIGNED"   { Write-Host $msg -ForegroundColor Cyan }
        "TASK COMPLETED"  { Write-Host $msg -ForegroundColor Green }
        "RESULT READY"    { Write-Host $msg -ForegroundColor Green }
        "TRIGGER WRITTEN" { Write-Host $msg -ForegroundColor Gray }
        "ERROR*"          { Write-Host $msg -ForegroundColor Red }
        default           { Write-Host $msg -ForegroundColor Gray }
    }
}

function Write-Trigger {
    param($path, $content)
    $content | Set-Content -Path $path -Encoding UTF8
}

Write-Host ""
Write-Host "Agency Watcher started" -ForegroundColor Yellow
Write-Host "Project: $PROJECT" -ForegroundColor Gray
Write-Host "Polling every $INTERVAL seconds" -ForegroundColor Gray
Write-Host "Watching agents: $($AGENTS -join ', ')" -ForegroundColor Gray
Write-Host "Press Ctrl+C to stop." -ForegroundColor Gray
Write-Host ""
Write-Host "Waiting for activity..." -ForegroundColor Gray
Write-Host ""

# Track what we've already triggered to avoid duplicate notifications
$triggered = @{}

while ($true) {
    foreach ($agent in $AGENTS) {

        # ---- Detect new task assigned to worker ----
        $taskFile    = Join-Path $TASKS "$agent-current.json"
        $triggerFile = Join-Path $TASKS "$agent-trigger.txt"
        $doneFile    = Join-Path $TASKS "$agent-done.txt"
        $triggerKey  = "task-$agent"

        if ((Test-Path $taskFile) -and -not (Test-Path $triggerFile) -and -not (Test-Path $doneFile)) {
            if (-not $triggered[$triggerKey]) {
                try {
                    $task = Get-Content $taskFile -Raw | ConvertFrom-Json
                    $role = if ($task.role) { $task.role } else { "unknown role" }
                    Write-Event $agent "TASK ASSIGNED" $role

                    # Write trigger file for the worker to pick up
                    Write-Trigger $triggerFile "TASK_READY`n$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`nRead context/tasks/$agent-current.json and complete the task."
                    Write-Event $agent "TRIGGER WRITTEN" "$agent-trigger.txt"

                    $triggered[$triggerKey] = $true
                } catch {
                    Write-Event $agent "ERROR reading task file" $_.Exception.Message
                }
            }
        }

        # ---- Detect worker completed task ----
        $resultFile      = Join-Path $HANDOFFS "$agent-result.md"
        $orchTriggerFile = Join-Path $TASKS "orchestrator-trigger-$agent.txt"
        $doneKey         = "done-$agent"

        if ((Test-Path $doneFile) -and (Test-Path $resultFile)) {
            if (-not $triggered[$doneKey]) {
                Write-Event $agent "TASK COMPLETED"

                # Write trigger for orchestrator
                Write-Trigger $orchTriggerFile "RESULT_READY`n$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n$agent has completed its task. Read context/handoffs/$agent-result.md and synthesize."
                Write-Event "orchestrator" "RESULT READY" "from $agent"

                # Clean up task files so the slot is free for the next task
                Remove-Item $taskFile    -Force -ErrorAction SilentlyContinue
                Remove-Item $triggerFile -Force -ErrorAction SilentlyContinue
                Remove-Item $doneFile    -Force -ErrorAction SilentlyContinue

                # Reset tracking so this agent can receive new tasks
                $triggered.Remove($triggerKey)
                $triggered[$doneKey] = $true
            }
        }

        # ---- Reset done tracking once orchestrator acknowledges ----
        # Orchestrator deletes its trigger file after reading
        if (-not (Test-Path $orchTriggerFile) -and $triggered[$doneKey]) {
            $triggered.Remove($doneKey)
        }
    }

    Start-Sleep -Seconds $INTERVAL
}
