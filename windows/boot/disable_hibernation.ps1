write-Host ""
Write-Host "--------------------------------------------" -ForegroundColor Yellow
Write-Host "Disabling hibernation..." -ForegroundColor Yellow
Write-Host "--------------------------------------------" -ForegroundColor Yellow
Write-Host ""
Write-Host ""
Write-Host ""
Start-Sleep -Seconds 6

powercfg -h off

$HIBERNATION_STATUS = powercfg /query | Select-String "Hibernation"

if (-not $HIBERNATION_STATUS) {
    Write-Host "********************************************" -ForegroundColor Green
    Write-Host "Hibernation successfully disabled." -ForegroundColor Green
    Write-Host "********************************************" -ForegroundColor Green
} else {
    Write-Output "Failed to disable hibernation." -ForegroundColor Red
}
Write-Host ""

Write-Host "------------------------------------------------------------------------------------------------------------------" -ForegroundColor Magenta

