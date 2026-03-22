# scripts/p03-env.ps1
# Creates a project-level .env file.
# Skips if already exists - never overwrites keys you have already filled in.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ENV_FILE = Join-Path $env:AGENCY_PROJECT ".env"

if (Test-Path $ENV_FILE) {
    Write-Host "  .env already exists - skipping." -ForegroundColor Gray

    # Warn if still has placeholders
    $content = Get-Content $ENV_FILE -Raw
    if ($content -match "your-.*-key-here") {
        Write-Host "  [WARN] .env still contains placeholder values. Fill them in before launching." -ForegroundColor Yellow
    }
    return
}

@"
# Project API Keys
# Fill in your actual keys. This file is git-ignored - never commit it.

ANTHROPIC_API_KEY=your-anthropic-api-key-here

# Required for OpenViking embeddings (text-embedding-3-large)
# TODO(future-models): replace with a local embedding model to remove this dependency
#   See ov.conf: change provider to litellm + ollama/nomic-embed-text
OPENAI_API_KEY=your-openai-api-key-here

# TODO(future-models): add keys as you onboard new providers
# GEMINI_API_KEY=
# OPENROUTER_API_KEY=
"@ | Set-Content $ENV_FILE -Encoding UTF8

Write-Host "  [OK]  .env created" -ForegroundColor Green
Write-Host "  ACTION: Open .env and fill in your API keys before running launch.ps1" -ForegroundColor Yellow
