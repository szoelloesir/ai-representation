# scripts/p04-claude-md.ps1
# Generates project-specific CLAUDE.md files by substituting
# project meta into the global templates.
# Also generates a project-level providers.json that starts as a copy
# of the global one (override by editing it).

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$PROJECT = $env:AGENCY_PROJECT
$GLOBAL  = $env:AGENCY_GLOBAL
$META    = Get-Content $env:AGENCY_PROJECT_META -Raw | ConvertFrom-Json

$name        = $META.name
$slug        = $META.slug
$description = $META.description
$roles       = $META.activeRoles

# Format active roles as a bullet list for injection into CLAUDE.md
$roleList = ($roles | ForEach-Object { "- $_" }) -join "`n"

function Expand-Template {
    param($templatePath, $destPath, $label)

    if (Test-Path $destPath) {
        Write-Host "  Exists (skipped): $label" -ForegroundColor Gray
        return
    }

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

    [System.IO.File]::WriteAllText($destPath, $content, [System.Text.Encoding]::UTF8)
    Write-Host "  [OK]  Created: $label" -ForegroundColor Green
}

$templateDir = Join-Path $GLOBAL "config"
$configDir   = Join-Path $PROJECT "config"
New-Item -ItemType Directory -Force -Path $configDir | Out-Null

Write-Host "  Generating CLAUDE.md files for project: $name ($slug)"

Expand-Template `
    "$templateDir\orchestrator-CLAUDE.md.template" `
    "$configDir\orchestrator-CLAUDE.md" `
    "config\orchestrator-CLAUDE.md"

Expand-Template `
    "$templateDir\worker-CLAUDE.md.template" `
    "$configDir\worker-CLAUDE.md" `
    "config\worker-CLAUDE.md"

# ---- Project providers.json ----
# Starts as a copy of the global one - edit to override per-project routing.
$projectProviders = "$configDir\providers.json"
if (Test-Path $projectProviders) {
    Write-Host "  Exists (skipped): config\providers.json (project)" -ForegroundColor Gray
} else {
    Copy-Item "$templateDir\providers.json" $projectProviders
    # Stamp it so it's clear this is a project-level override
    $p = Get-Content $projectProviders -Raw | ConvertFrom-Json
    $p | Add-Member -NotePropertyName "_project" -NotePropertyValue $slug -Force
    $p | Add-Member -NotePropertyName "_overrides_global" -NotePropertyValue $true -Force
    $p | ConvertTo-Json -Depth 10 | Set-Content $projectProviders -Encoding UTF8
    Write-Host "  [OK]  Created: config\providers.json (project override - edit to customise)" -ForegroundColor Green
}

Write-Host "  CLAUDE.md files ready." -ForegroundColor Green
Write-Host "  Review them in: $configDir" -ForegroundColor Gray
