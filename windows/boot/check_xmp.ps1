Write-Host "********************************************" -ForegroundColor Cyan
Write-Host "Checking XMP status..." -ForegroundColor Cyan
Write-Host "********************************************" -ForegroundColor Cyan
Write-Host ""
Write-Host ""
Write-Host ""

Start-Sleep -Seconds 6

$XMP_STATUS = Get-CimInstance -ClassName Win32_PhysicalMemory | Select-Object -ExpandProperty ConfiguredClockSpeed

if ($XMP_STATUS -gt 0) {
    Write-Host "--------------------------------------------" -ForegroundColor Green
    Write-Host "XMP is enabled." -ForegroundColor Green
    Write-Host "--------------------------------------------" -ForegroundColor Green
    Write-Host ""
    Write-Host ""
    Write-Host ""
} else {
    Write-Host "--------------------------------------------" -ForegroundColor Yellow
    Write-Host "XMP is disabled! Enable it in BIOS for better performance and run script again." -ForegroundColor Yellow
    Write-Host "--------------------------------------------" -ForegroundColor Yellow
    Write-Host ""
    Write-Host ""
    Write-Host ""
}

Write-Host "------------------------------------------------------------------------------------------------------------------" -ForegroundColor Magenta
