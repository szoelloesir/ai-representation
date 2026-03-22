# scripts/p01-prompt.ps1
# Interactively collects project details and writes them to a temp file
# that subsequent scripts read via $env:AGENCY_PROJECT_META.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$META_FILE = Join-Path $env:AGENCY_PROJECT ".agency-project.json"

# If meta already exists, load and confirm - don't re-ask everything
if (Test-Path $META_FILE) {
    $existing = Get-Content $META_FILE -Raw | ConvertFrom-Json
    Write-Host "  Project already configured: $($existing.name)" -ForegroundColor Gray
    Write-Host "  Re-running setup will skip existing files." -ForegroundColor Gray
    $env:AGENCY_PROJECT_META = $META_FILE
    return
}

Write-Host "  Let's configure this project."
Write-Host ""

# ---- Project name ----
do {
    $name = Read-Host "  Project name (e.g. my-app)"
    $name = $name.Trim()
} while ($name -eq "")

# Derive a slug: lowercase, spaces to hyphens, strip non-alphanumeric except hyphens
$slug = $name.ToLower() -replace "\s+", "-" -replace "[^a-z0-9\-]", ""

Write-Host ""
Write-Host "  Project slug (used for OpenViking URI): $slug" -ForegroundColor Gray
Write-Host "  viking://resources/$slug/" -ForegroundColor Gray
Write-Host ""

# ---- Description (single line, injected into CLAUDE.md) ----
$description = Read-Host "  One-line project description (press Enter to skip)"
$description = $description.Trim()
if ($description -eq "") { $description = "No description provided." }

# ---- Default active roles (lightweight set, no asking) ----
# These 5 cover the vast majority of early-stage project work.
# TODO(future-models): expand this list as more providers come online.
$defaultRoles = @(
    "engineering-software-architect",
    "engineering-frontend-developer",
    "engineering-backend-architect",
    "engineering-senior-developer",
    "testing-reality-checker"
)

Write-Host ""
Write-Host "  Default active roles:" -ForegroundColor Cyan
$defaultRoles | ForEach-Object { Write-Host "    - $_" -ForegroundColor Gray }
Write-Host "  (Edit .agency-project.json to change these later)" -ForegroundColor Gray

# ---- Write meta file ----
$meta = [ordered]@{
    name        = $name
    slug        = $slug
    description = $description
    activeRoles = $defaultRoles
    createdAt   = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}

$meta | ConvertTo-Json -Depth 5 | Set-Content $META_FILE -Encoding UTF8

$env:AGENCY_PROJECT_META = $META_FILE

Write-Host ""
Write-Host "  [OK]  Project meta saved to .agency-project.json" -ForegroundColor Green
