Set-Location 'F:\agency\ai-representation'
$env:CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = '1'
Copy-Item 'F:\agency\ai-representation\config\worker-CLAUDE.md' 'F:\agency\ai-representation\CLAUDE.md' -Force
Write-Host 'Worker ready.' -ForegroundColor Blue
claude
