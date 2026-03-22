# launch.ps1
# Starts the full agency workspace for this project.
# Run from the project root every session.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$PROJECT = $PSScriptRoot
$GLOBAL  = Join-Path $env:USERPROFILE ".agency"
$SERVER  = Join-Path $GLOBAL "venv\Scripts\openviking-server.exe"
$META    = Join-Path $PROJECT ".agency-project.json"

# ---- Detect PowerShell executable ----
$PS_EXE = if (Get-Command "pwsh" -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
Write-Host "Using shell: $PS_EXE" -ForegroundColor Gray

# ---- Guard checks ----
if (-not (Test-Path $SERVER)) {
    Write-Host "ERROR: OpenViking not installed. Run install-global.ps1 first." -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $META)) {
    Write-Host "ERROR: Project not set up. Run setup-project.ps1 first." -ForegroundColor Red
    exit 1
}
foreach ($required in @("watcher.ps1", "worker-loop.ps1")) {
    if (-not (Test-Path (Join-Path $PROJECT $required))) {
        Write-Host "ERROR: $required not found in project root." -ForegroundColor Red
        exit 1
    }
}

$projectMeta = Get-Content $META -Raw | ConvertFrom-Json
$slug        = $projectMeta.slug

# ---- Load .env (skip ANTHROPIC_API_KEY - Claude Code uses claude.ai subscription) ----
$envFile = Join-Path $PROJECT ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match "^\s*([^#][^=]+)=(.+)$") {
            $key = $matches[1].Trim()
            $val = $matches[2].Trim()
            if ($key -eq "ANTHROPIC_API_KEY") {
                Write-Host "  Skipping ANTHROPIC_API_KEY (Claude Code uses claude.ai subscription)" -ForegroundColor Gray
            } else {
                [System.Environment]::SetEnvironmentVariable($key, $val, "Process")
            }
        }
    }
    Write-Host "Keys loaded from .env" -ForegroundColor Gray
} else {
    Write-Host "WARNING: .env not found" -ForegroundColor Yellow
}

$env:CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"

# ---- Check if OpenViking already running ----
$ovPort    = 1933
$ovRunning = $false
try {
    $conn = New-Object System.Net.Sockets.TcpClient
    $conn.Connect("127.0.0.1", $ovPort)
    $conn.Close()
    $ovRunning = $true
} catch {}
if ($ovRunning) { Write-Host "OpenViking already running on port $ovPort." -ForegroundColor Gray }

# ---- Seed user context (once) ----
$userContextSrc   = Join-Path $GLOBAL "config\user-context.md"
$userContextStamp = Join-Path $GLOBAL "openviking-data\.user-context-seeded"
$seedContext      = (Test-Path $userContextSrc) -and -not (Test-Path $userContextStamp)
$seedStr          = $seedContext.ToString()

# ---- All agents run from PROJECT ROOT ----
# No subdirectories - Claude Code would create its own context/ tree inside them.
# CLAUDE.md collision is avoided by writing role-specific CLAUDE.md to project root
# just before launching each tab, using separate temp scripts launched sequentially.
# Workers use --system-prompt flag so they don't need CLAUDE.md at all.

$tempDir = Join-Path $PROJECT ".agency-launch"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

# Ensure context dirs exist at project root
New-Item -ItemType Directory -Force -Path (Join-Path $PROJECT "context\tasks")     | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $PROJECT "context\handoffs")  | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $PROJECT "context\decisions") | Out-Null

# ---- Server tab ----
$serverScript = Join-Path $tempDir "tab-server.ps1"
Set-Content $serverScript -Encoding UTF8 -Value @"
Set-Location '$PROJECT'
`$env:VIRTUAL_ENV = '$GLOBAL\venv'
`$env:PATH = '$GLOBAL\venv\Scripts;' + `$env:PATH
@(
    '$GLOBAL\openviking-data\.openviking.pid',
    '$GLOBAL\openviking-data\vectordb\context\store\LOCK'
) | ForEach-Object {
    if (Test-Path `$_) { Remove-Item `$_ -Force; Write-Host "  Removed: `$_" -ForegroundColor Gray }
}
Write-Host 'Lock files cleared.' -ForegroundColor Gray
Write-Host 'OpenViking server starting...' -ForegroundColor Cyan
if ('$seedStr' -eq 'True') {
    `$seedJob = Start-Process '$SERVER' -PassThru
    Write-Host 'Seeding user context...' -ForegroundColor Gray
    Start-Sleep -Seconds 5
    ov add-resource '$userContextSrc' --target viking://user/preferences/ --wait
    '' | Set-Content '$userContextStamp'
    Write-Host 'User context seeded.' -ForegroundColor Green
    Stop-Process -Id `$seedJob.Id -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
}
Write-Host 'OpenViking running on port 1933. Do not close this tab.' -ForegroundColor Yellow
& '$SERVER'
"@

# ---- Watcher tab ----
$watcherScript = Join-Path $tempDir "tab-watcher.ps1"
Set-Content $watcherScript -Encoding UTF8 -Value @"
Set-Location '$PROJECT'
Write-Host 'Starting agency watcher...' -ForegroundColor Yellow
& '$PROJECT\watcher.ps1' '$PROJECT'
"@

# ---- Orchestrator tab ----
# Runs from project root, uses config\orchestrator-CLAUDE.md as CLAUDE.md
$orchScript = Join-Path $tempDir "tab-orchestrator.ps1"
Set-Content $orchScript -Encoding UTF8 -Value @"
Set-Location '$PROJECT'
`$env:CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = '1'
Copy-Item '$PROJECT\config\orchestrator-CLAUDE.md' '$PROJECT\CLAUDE.md' -Force
Write-Host 'Orchestrator - $($projectMeta.name)' -ForegroundColor Green
Write-Host 'Project root: $PROJECT' -ForegroundColor Gray
Write-Host 'URI: viking://resources/$slug/' -ForegroundColor Gray
Write-Host 'Task files: $PROJECT\context\tasks\' -ForegroundColor Gray
Write-Host ''
Write-Host 'YOU ARE THE ORCHESTRATOR. Talk to the user here.' -ForegroundColor Cyan
claude
"@

# ---- Worker A tab ----
# Runs from project root via worker-loop - no CLAUDE.md needed, role injected per task
$workerAScript = Join-Path $tempDir "tab-worker-a.ps1"
Set-Content $workerAScript -Encoding UTF8 -Value @"
Set-Location '$PROJECT'
`$env:CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = '1'
Write-Host 'Worker A - autonomous mode' -ForegroundColor Blue
Write-Host 'Project root: $PROJECT' -ForegroundColor Gray
Write-Host 'Waiting for tasks...' -ForegroundColor Gray
& '$PROJECT\worker-loop.ps1' -WorkerId 'a' -ProjectRoot '$PROJECT'
"@

# ---- Worker B tab ----
$workerBScript = Join-Path $tempDir "tab-worker-b.ps1"
Set-Content $workerBScript -Encoding UTF8 -Value @"
Set-Location '$PROJECT'
`$env:CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = '1'
Write-Host 'Worker B - autonomous mode' -ForegroundColor Blue
Write-Host 'Project root: $PROJECT' -ForegroundColor Gray
Write-Host 'Waiting for tasks...' -ForegroundColor Gray
& '$PROJECT\worker-loop.ps1' -WorkerId 'b' -ProjectRoot '$PROJECT'
"@

# ---- Write .cmd launcher ----
$wtCmd = Join-Path $tempDir "launch-wt.cmd"
Set-Content $wtCmd -Encoding ASCII -Value "@echo off"
Add-Content $wtCmd -Encoding ASCII -Value "wt new-tab --title `"OV Server`" $PS_EXE -NoExit -File `"$serverScript`" ; new-tab --title `"Watcher`" $PS_EXE -NoExit -File `"$watcherScript`" ; new-tab --title `"Orchestrator`" $PS_EXE -NoExit -File `"$orchScript`" ; new-tab --title `"Worker A`" $PS_EXE -NoExit -File `"$workerAScript`" ; new-tab --title `"Worker B`" $PS_EXE -NoExit -File `"$workerBScript`""

Write-Host "Opening workspace for: $($projectMeta.name)" -ForegroundColor Cyan
cmd /c "`"$wtCmd`""

Write-Host ""
Write-Host "Workspace launched." -ForegroundColor Green
Write-Host ""
Write-Host "  Tab 1  OV Server     - leave running" -ForegroundColor Gray
Write-Host "  Tab 2  Watcher       - shows task/result activity" -ForegroundColor Gray
Write-Host "  Tab 3  Orchestrator  - YOUR interface, talk here" -ForegroundColor Green
Write-Host "  Tab 4  Worker A      - autonomous, do not interact" -ForegroundColor Gray
Write-Host "  Tab 5  Worker B      - autonomous, do not interact" -ForegroundColor Gray
Write-Host ""
Write-Host "  All agents work from: $PROJECT" -ForegroundColor Cyan
Write-Host "  Task files:  $PROJECT\context\tasks\" -ForegroundColor Cyan
