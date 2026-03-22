# worker-loop.ps1
# Autonomous worker loop - polls for trigger files and runs claude --print.
# Restarts itself on error rather than dying.
#
# Usage: worker-loop.ps1 -WorkerId "a" -ProjectRoot "F:\agency\my-project"
#
# TODO(future-models): replace the claude --print block with a different
# API call based on providers.json. File protocol stays identical.

param(
    [Parameter(Mandatory)][string]$WorkerId,
    [Parameter(Mandatory)][string]$ProjectRoot
)

# Do NOT use Stop for the outer loop - log and continue on errors
$ErrorActionPreference = "Continue"

$TASKS    = Join-Path $ProjectRoot "context\tasks"
$HANDOFFS = Join-Path $ProjectRoot "context\handoffs"
$INTERVAL = 5

$triggerFile = Join-Path $TASKS    "worker-$WorkerId-trigger.txt"
$taskFile    = Join-Path $TASKS    "worker-$WorkerId-current.json"
$doneFile    = Join-Path $TASKS    "worker-$WorkerId-done.txt"
$resultFile  = Join-Path $HANDOFFS "worker-$WorkerId-result.md"

function Write-Log {
    param($msg, $color = "Gray")
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $msg" -ForegroundColor $color
}

Write-Host ""
Write-Host "Worker $WorkerId loop started" -ForegroundColor Blue
Write-Host "Polling every $INTERVAL seconds" -ForegroundColor Gray
Write-Host "Trigger : $triggerFile" -ForegroundColor Gray
Write-Host "Task    : $taskFile" -ForegroundColor Gray
Write-Host "Result  : $resultFile" -ForegroundColor Gray
Write-Host ""

while ($true) {
    try {
        if (Test-Path $triggerFile) {
            Write-Log "Trigger detected" "Cyan"

            # ---- Validate task file exists before doing anything ----
            if (-not (Test-Path $taskFile)) {
                Write-Log "WARNING: trigger exists but task file missing - removing stale trigger" "Yellow"
                Remove-Item $triggerFile -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds $INTERVAL
                continue
            }

            # ---- Read task ----
            $taskJson = Get-Content $taskFile -Raw -ErrorAction Stop
            $task     = $taskJson | ConvertFrom-Json
            $role     = if ($task.role)    { $task.role }    else { "engineering-senior-developer" }
            $taskMsg  = if ($task.task)    { $task.task }    else { "No task description provided" }
            $ctxUri   = if ($task.context_uri) { $task.context_uri } else { "viking://resources/" }

            Write-Log "Role : $role" "Gray"
            Write-Log "Task : $taskMsg" "Gray"

            # ---- Build prompt ----
            $prompt = @"
You are acting as the role defined in: ~/.claude/agents/$role.md
Read that file first to understand your persona and responsibilities.

Also read the user preferences at:
  viking://user/preferences/

Your task:
$taskMsg

Context URI for this project:
  $ctxUri

Query OpenViking before starting:
  ov find "$taskMsg" --uri $ctxUri

Complete the task fully. Write your complete result to this exact file:
  $resultFile

When your result is written, signal completion by writing the word DONE to:
  $doneFile

Do not stop until both files are written.
"@

            # ---- Run claude non-interactively ----
            # Write prompt and system prompt to temp files to avoid PowerShell
            # argument length limits when passing long strings to external processes.
            # Pipe prompt file into claude -p via Get-Content - this is reliable on Windows.
            Write-Log "Running claude -p ..." "Yellow"
            $promptFile  = Join-Path $ProjectRoot ".agency-launch\worker-$WorkerId-prompt.txt"
            $sysPromptFile = Join-Path $ProjectRoot ".agency-launch\worker-$WorkerId-sysprompt.txt"
            try {
                # Write prompt to file
                $prompt | Set-Content $promptFile -Encoding UTF8

                # Write system prompt to file
                "You are acting as the role defined in: ~/.claude/agents/$role.md - read that file first to understand your persona and responsibilities. Also read user preferences from viking://user/preferences/ before starting work." | Set-Content $sysPromptFile -Encoding UTF8

                # Pipe prompt file into claude -p
                $result = Get-Content $promptFile -Raw | claude -p --system-prompt-file $sysPromptFile --no-session-persistence 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Write-Log "claude exited with code $LASTEXITCODE" "Red"
                    "ERROR: claude exited with code $LASTEXITCODE`n`n$result" | Set-Content $resultFile -Encoding UTF8
                } else {
                    $result | Set-Content $resultFile -Encoding UTF8
                    Write-Log "Result written to $resultFile" "Green"
                }
            } catch {
                $errMsg = $_.Exception.Message
                Write-Log "ERROR running claude: $errMsg" "Red"
                "ERROR: $errMsg" | Set-Content $resultFile -Encoding UTF8
            } finally {
                Remove-Item $promptFile    -Force -ErrorAction SilentlyContinue
                Remove-Item $sysPromptFile -Force -ErrorAction SilentlyContinue
            }

            # ---- Signal done regardless of success/failure ----
            "DONE" | Set-Content $doneFile -Encoding UTF8
            Remove-Item $triggerFile -Force -ErrorAction SilentlyContinue
            Write-Log "Done signalled. Waiting for next task..." "Green"
        }
    } catch {
        # Outer catch - log and keep the loop alive
        Write-Log "LOOP ERROR: $($_.Exception.Message)" "Red"
        Write-Log "Continuing after error..." "Yellow"
    }

    Start-Sleep -Seconds $INTERVAL
}
