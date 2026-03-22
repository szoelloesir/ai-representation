Set-Location 'F:\agency\ai-representation'
$env:VIRTUAL_ENV = 'C:\Users\rszol\.agency\venv'
$env:PATH = 'C:\Users\rszol\.agency\venv\Scripts;' + $env:PATH
@(
    'C:\Users\rszol\.agency\openviking-data\.openviking.pid',
    'C:\Users\rszol\.agency\openviking-data\vectordb\context\store\LOCK'
) | ForEach-Object {
    if (Test-Path $_) { Remove-Item $_ -Force; Write-Host "  Removed: $_" -ForegroundColor Gray }
}
Write-Host 'Lock files cleared.' -ForegroundColor Gray
Write-Host 'OpenViking server starting...' -ForegroundColor Cyan
if ('False' -eq 'True') {
    $seedJob = Start-Process 'C:\Users\rszol\.agency\venv\Scripts\openviking-server.exe' -PassThru
    Write-Host 'Seeding user context...' -ForegroundColor Gray
    Start-Sleep -Seconds 5
    ov add-resource 'C:\Users\rszol\.agency\config\user-context.md' --target viking://user/preferences/ --wait
    '' | Set-Content 'C:\Users\rszol\.agency\openviking-data\.user-context-seeded'
    Write-Host 'User context seeded.' -ForegroundColor Green
    Stop-Process -Id $seedJob.Id -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
}
Write-Host 'OpenViking running on port 1933. Do not close this tab.' -ForegroundColor Yellow
& 'C:\Users\rszol\.agency\venv\Scripts\openviking-server.exe'
