# setup-project.ps1
# Sets up a new agency project in the CURRENT directory.
# Run this once per project. Safe to re-run - skips what already exists.
#
# Prerequisites: install-global.ps1 must have been run first.
#
# Usage:
#   cd F:\my-project
#   \path\to\agency\project\setup-project.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$GLOBAL_ROOT = Join-Path $env:USERPROFILE ".agency"

# ---- Guard: ensure global install exists ----
if (-not (Test-Path "$GLOBAL_ROOT\venv\Scripts\openviking-server.exe")) {
    Write-Host ""
    Write-Host "Global install not found. Run install-global.ps1 first." -ForegroundColor Red
    Write-Host "Expected: $GLOBAL_ROOT\venv\Scripts\openviking-server.exe" -ForegroundColor Yellow
    exit 1
}

$PROJECT_ROOT = Get-Location
$env:AGENCY_GLOBAL  = $GLOBAL_ROOT
$env:AGENCY_PROJECT = $PROJECT_ROOT

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Agency - Project Setup" -ForegroundColor Cyan
Write-Host "  Project root: $PROJECT_ROOT" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$scripts = @(
    "$PSScriptRoot\scripts\p01-prompt.ps1",
    "$PSScriptRoot\scripts\p02-folders.ps1",
    "$PSScriptRoot\scripts\p03-env.ps1",
    "$PSScriptRoot\scripts\p04-claude-md.ps1",
    "$PSScriptRoot\scripts\p05-verify.ps1"
)

foreach ($script in $scripts) {
    Write-Host ""
    Write-Host "--- $([System.IO.Path]::GetFileName($script)) ---" -ForegroundColor Yellow
    & $script
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        Write-Host "FAILED. Fix the error above and re-run." -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  Project setup complete." -ForegroundColor Green
Write-Host "  To start your workspace:" -ForegroundColor Green
Write-Host "    .\launch.ps1" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
