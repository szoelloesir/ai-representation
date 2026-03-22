Set-Location 'F:\agency\ai-representation\agents\orchestrator'
$env:CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = '1'
Copy-Item 'F:\agency\ai-representation\config\orchestrator-CLAUDE.md' 'F:\agency\ai-representation\agents\orchestrator\CLAUDE.md' -Force
Write-Host 'Orchestrator - ai-representation' -ForegroundColor Green
Write-Host 'Project root: F:\agency\ai-representation' -ForegroundColor Gray
Write-Host 'URI: viking://resources/ai-representation/' -ForegroundColor Gray
Write-Host 'You are the ORCHESTRATOR. Talk to the user. Route tasks to workers.' -ForegroundColor Cyan
claude
