Set-Location 'F:\agency\ai-representation\agents\worker-a'
$env:CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = '1'
Copy-Item 'F:\agency\ai-representation\config\worker-CLAUDE.md' 'F:\agency\ai-representation\agents\worker-a\CLAUDE.md' -Force
Write-Host 'Worker A ready.' -ForegroundColor Blue
Write-Host 'Project root: F:\agency\ai-representation' -ForegroundColor Gray
claude
