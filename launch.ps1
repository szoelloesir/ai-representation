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
$watcherSrc = Join-Path $PROJECT "watcher.ps1"
if (-not (Test-Path $watcherSrc)) {
    Write-Host "ERROR: watcher.ps1 not found in project root." -ForegroundColor Red
    exit 1
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
if ($ovRunning) {
    Write-Host "OpenViking already running on port $ovPort." -ForegroundColor Gray
}

# ---- Seed user context (once) ----
$userContextSrc   = Join-Path $GLOBAL "config\user-context.md"
$userContextStamp = Join-Path $GLOBAL "openviking-data\.user-context-seeded"
$seedContext      = (Test-Path $userContextSrc) -and -not (Test-Path $userContextStamp)
$seedStr          = $seedContext.ToString()

# ---- Create per-agent working directories ----
# Each agent gets its own subdirectory so their CLAUDE.md files never collide
$orchDir    = Join-Path $PROJECT "agents\orchestrator"
$workerADir = Join-Path $PROJECT "agents\worker-a"
$workerBDir = Join-Path $PROJECT "agents\worker-b"

New-Item -ItemType Directory -Force -Path $orchDir    | Out-Null
New-Item -ItemType Directory -Force -Path $workerADir | Out-Null
New-Item -ItemType Directory -Force -Path $workerBDir | Out-Null

Copy-Item "$PROJECT\config\orchestrator-CLAUDE.md" "$orchDir\CLAUDE.md"    -Force
Copy-Item "$PROJECT\config\worker-CLAUDE.md"       "$workerADir\CLAUDE.md" -Force
Copy-Item "$PROJECT\config\worker-CLAUDE.md"       "$workerBDir\CLAUDE.md" -Force

# ---- Write per-tab scripts ----
$tempDir = Join-Path $PROJECT ".agency-launch"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

# Server tab
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

# Watcher tab
$watcherScript = Join-Path $tempDir "tab-watcher.ps1"
Set-Content $watcherScript -Encoding UTF8 -Value @"
Set-Location '$PROJECT'
Write-Host 'Starting agency watcher...' -ForegroundColor Yellow
& '$watcherSrc' '$PROJECT'
"@

# Orchestrator tab
$orchScript = Join-Path $tempDir "tab-orchestrator.ps1"
Set-Content $orchScript -Encoding UTF8 -Value @"
Set-Location '$orchDir'
`$env:CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = '1'
Copy-Item '$PROJECT\config\orchestrator-CLAUDE.md' '$orchDir\CLAUDE.md' -Force
Write-Host 'Orchestrator - $($projectMeta.name)' -ForegroundColor Green
Write-Host 'Project root: $PROJECT' -ForegroundColor Gray
Write-Host 'URI: viking://resources/$slug/' -ForegroundColor Gray
Write-Host 'You are the ORCHESTRATOR. Talk to the user. Route tasks to workers.' -ForegroundColor Cyan
claude
"@

# Worker A tab
$workerAScript = Join-Path $tempDir "tab-worker-a.ps1"
Set-Content $workerAScript -Encoding UTF8 -Value @"
Set-Location '$workerADir'
`$env:CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = '1'
Copy-Item '$PROJECT\config\worker-CLAUDE.md' '$workerADir\CLAUDE.md' -Force
Write-Host 'Worker A ready.' -ForegroundColor Blue
Write-Host 'Project root: $PROJECT' -ForegroundColor Gray
claude
"@

# Worker B tab
$workerBScript = Join-Path $tempDir "tab-worker-b.ps1"
Set-Content $workerBScript -Encoding UTF8 -Value @"
Set-Location '$workerBDir'
`$env:CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = '1'
Copy-Item '$PROJECT\config\worker-CLAUDE.md' '$workerBDir\CLAUDE.md' -Force
Write-Host 'Worker B ready.' -ForegroundColor Blue
Write-Host 'Project root: $PROJECT' -ForegroundColor Gray
claude
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
Write-Host "  Tab 2  Watcher       - monitors task/result files" -ForegroundColor Gray
Write-Host "  Tab 3  Orchestrator  - THIS is your interface" -ForegroundColor Green
Write-Host "  Tab 4  Worker A      - do not interact directly" -ForegroundColor Gray
Write-Host "  Tab 5  Worker B      - do not interact directly" -ForegroundColor Gray
Write-Host ""
Write-Host "  Project URI: viking://resources/$slug/" -ForegroundColor Cyan
