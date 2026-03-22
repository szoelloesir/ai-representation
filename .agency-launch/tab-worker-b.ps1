Set-Location 'F:\agency\ai-representation'
$env:CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = '1'
Write-Host 'Worker B - autonomous mode' -ForegroundColor Blue
Write-Host 'Project root: F:\agency\ai-representation' -ForegroundColor Gray
Write-Host 'Waiting for tasks...' -ForegroundColor Gray
& 'F:\agency\ai-representation\worker-loop.ps1' -WorkerId 'b' -ProjectRoot 'F:\agency\ai-representation'
