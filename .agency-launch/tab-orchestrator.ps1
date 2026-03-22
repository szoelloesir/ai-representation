Set-Location 'F:\agency\ai-representation'
$env:CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = '1'
Copy-Item 'F:\agency\ai-representation\config\orchestrator-CLAUDE.md' 'F:\agency\ai-representation\CLAUDE.md' -Force
Write-Host 'Orchestrator - ai-representation' -ForegroundColor Green
Write-Host 'Project root: F:\agency\ai-representation' -ForegroundColor Gray
Write-Host 'URI: viking://resources/ai-representation/' -ForegroundColor Gray
Write-Host 'Task files: F:\agency\ai-representation\context\tasks\' -ForegroundColor Gray
Write-Host ''
Write-Host 'YOU ARE THE ORCHESTRATOR. Talk to the user here.' -ForegroundColor Cyan
claude
