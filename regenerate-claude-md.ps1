# regenerate-claude-md.ps1
# Regenerates config\orchestrator-CLAUDE.md and config\worker-CLAUDE.md
# from the updated global templates.
# Run from your project root.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$PROJECT     = $PSScriptRoot
$GLOBAL      = Join-Path $env:USERPROFILE ".agency"
$TEMPLATE_DIR = Join-Path $GLOBAL "config"
$META        = Join-Path $PROJECT ".agency-project.json"

if (-not (Test-Path $META)) {
    Write-Host "ERROR: .agency-project.json not found. Run from project root." -ForegroundColor Red
    exit 1
}

$projectMeta = Get-Content $META -Raw | ConvertFrom-Json
$name        = $projectMeta.name
$slug        = $projectMeta.slug
$description = $projectMeta.description
$roles       = $projectMeta.activeRoles
$roleList    = ($roles | ForEach-Object { "- $_" }) -join "`n"

function Expand-Template {
    param($templatePath, $destPath, $label)

    if (-not (Test-Path $templatePath)) {
        Write-Host "  [FAIL] Template not found: $templatePath" -ForegroundColor Red
        exit 1
    }

    $content = Get-Content $templatePath -Raw -Encoding UTF8
    $content = $content `
        -replace "\{\{PROJECT_NAME\}\}",        $name `
        -replace "\{\{PROJECT_SLUG\}\}",        $slug `
        -replace "\{\{PROJECT_DESCRIPTION\}\}", $description `
        -replace "\{\{ACTIVE_ROLES\}\}",        $roleList

    $content | Set-Content -Path $destPath -Encoding UTF8
    Write-Host "  [OK] $label" -ForegroundColor Green
}

Write-Host "Regenerating CLAUDE.md files for: $name ($slug)" -ForegroundColor Cyan
Write-Host ""

$configDir = Join-Path $PROJECT "config"
New-Item -ItemType Directory -Force -Path $configDir | Out-Null

Expand-Template `
    (Join-Path $TEMPLATE_DIR "orchestrator-CLAUDE.md.template") `
    (Join-Path $configDir "orchestrator-CLAUDE.md") `
    "config\orchestrator-CLAUDE.md"

Expand-Template `
    (Join-Path $TEMPLATE_DIR "worker-CLAUDE.md.template") `
    (Join-Path $configDir "worker-CLAUDE.md") `
    "config\worker-CLAUDE.md"

# Also copy fresh into the agent subdirectories if they exist
foreach ($pair in @(
    @{ src = "orchestrator-CLAUDE.md"; dest = "agents\orchestrator\CLAUDE.md" },
    @{ src = "worker-CLAUDE.md";       dest = "agents\worker-a\CLAUDE.md" },
    @{ src = "worker-CLAUDE.md";       dest = "agents\worker-b\CLAUDE.md" }
)) {
    $destPath = Join-Path $PROJECT $pair.dest
    if (Test-Path (Split-Path $destPath)) {
        Copy-Item (Join-Path $configDir $pair.src) $destPath -Force
        Write-Host "  [OK] $($pair.dest)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Done. Relaunch to apply." -ForegroundColor Green
