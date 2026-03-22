# scripts/p05-verify.ps1
# Verifies the project setup is complete.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$PROJECT = $env:AGENCY_PROJECT
$GLOBAL  = $env:AGENCY_GLOBAL
$issues  = @()

function Check {
    param($cond, $label, $fix)
    if ($cond) {
        Write-Host "  [OK]   $label" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] $label" -ForegroundColor Red
        Write-Host "         Fix: $fix" -ForegroundColor Yellow
        $script:issues += $label
    }
}

Write-Host "Verifying project setup..."

Check (Test-Path "$PROJECT\.agency-project.json")           "Project meta file"               "Re-run p01-prompt.ps1"
Check (Test-Path "$PROJECT\.env")                           ".env exists"                     "Re-run p03-env.ps1"
Check (Test-Path "$PROJECT\context\tasks")                  "context/tasks folder"            "Re-run p02-folders.ps1"
Check (Test-Path "$PROJECT\context\handoffs")               "context/handoffs folder"         "Re-run p02-folders.ps1"
Check (Test-Path "$PROJECT\context\decisions")              "context/decisions folder"        "Re-run p02-folders.ps1"
Check (Test-Path "$PROJECT\config\orchestrator-CLAUDE.md")  "Orchestrator CLAUDE.md"          "Re-run p04-claude-md.ps1"
Check (Test-Path "$PROJECT\config\worker-CLAUDE.md")        "Worker CLAUDE.md"                "Re-run p04-claude-md.ps1"
Check (Test-Path "$PROJECT\config\providers.json")          "Project providers.json"          "Re-run p04-claude-md.ps1"
Check (Test-Path "$PROJECT\.gitignore")                     ".gitignore"                      "Re-run p02-folders.ps1"

# Global dependencies still reachable
Check (Test-Path "$GLOBAL\venv\Scripts\openviking-server.exe") "Global OpenViking binary"     "Re-run install-global.ps1"
Check (Test-Path "$GLOBAL\config\user-context.md")             "Global user-context.md"       "Re-run install-global.ps1"

# Warn about unfilled .env
$envContent = Get-Content "$PROJECT\.env" -ErrorAction SilentlyContinue -Raw
if ($envContent -match "your-.*-key-here") {
    Write-Host "  [WARN] .env has unfilled placeholder keys - fill before launching" -ForegroundColor Yellow
}

# Warn about unfilled user-context
$ucContent = Get-Content "$GLOBAL\config\user-context.md" -ErrorAction SilentlyContinue -Raw
if ($ucContent -match "e\.g\.") {
    Write-Host "  [WARN] user-context.md still has example placeholders - fill it in" -ForegroundColor Yellow
    Write-Host "         Path: $GLOBAL\config\user-context.md" -ForegroundColor Gray
}

Write-Host ""
if ($issues.Count -eq 0) {
    $meta = Get-Content "$PROJECT\.agency-project.json" -Raw | ConvertFrom-Json
    Write-Host "Project '$($meta.name)' is ready." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Fill in .env API keys" -ForegroundColor White
    Write-Host "  2. Fill in $GLOBAL\config\user-context.md (once, shared)" -ForegroundColor White
    Write-Host "  3. Run .\launch.ps1" -ForegroundColor White
} else {
    Write-Host "$($issues.Count) issue(s). Fix and re-run affected scripts." -ForegroundColor Red
    exit 1
}
