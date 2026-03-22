# scripts/p02-folders.ps1
# Creates the project-level folder structure.
# Nothing global lives here - only what is specific to this project.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ROOT = $env:AGENCY_PROJECT

$folders = @(
    "$ROOT\context",
    "$ROOT\context\tasks",       # orchestrator writes task assignments here
    "$ROOT\context\handoffs",    # workers write results here
    "$ROOT\context\decisions",   # significant decisions (also pushed to OpenViking)
    "$ROOT\logs"
)

Write-Host "  Creating project folders..."

foreach ($folder in $folders) {
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Force -Path $folder | Out-Null
        Write-Host "  Created:  $folder" -ForegroundColor Green
    } else {
        Write-Host "  Exists:   $folder" -ForegroundColor Gray
    }
}

# .gitignore - keep secrets and runtime noise out of version control
$gitignore = "$ROOT\.gitignore"
if (-not (Test-Path $gitignore)) {
    @"
# Agency runtime files
.env
.agency-project.json
context/tasks/
context/handoffs/
logs/
"@ | Set-Content $gitignore -Encoding UTF8
    Write-Host "  Created:  .gitignore" -ForegroundColor Green
} else {
    Write-Host "  Exists:   .gitignore" -ForegroundColor Gray
}

Write-Host "  Project folders ready." -ForegroundColor Green
