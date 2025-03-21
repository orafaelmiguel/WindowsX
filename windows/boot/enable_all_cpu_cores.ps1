write-Host ""
Write-Host "--------------------------------------------" -ForegroundColor Yellow
Write-Host "Enabling all CPU cores at boot..." -ForegroundColor Yellow
Write-Host "--------------------------------------------" -ForegroundColor Yellow
Write-Host ""
Write-Host ""
Write-Host ""
Start-Sleep -Seconds 6


$CPU_CORES = (Get-CimInstance -ClassName Win32_Processor).NumberOfLogicalProcessors

Write-Host "--------------------------------------------" -ForegroundColor Cyan
Write-Host "Detected $CPU_CORES CPU cores." -ForegroundColor Cyan
Write-Host "--------------------------------------------" -ForegroundColor Cyan
Write-Host ""
Write-Host ""
Write-Host ""
Start-Sleep -Seconds 6

$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager"
$registryName = "NumProcs"

Set-ItemProperty -Path $registryPath -Name $registryName -Value $CPU_CORES -Type DWord

$CHECK_CORES = (Get-ItemProperty -Path $registryPath -Name $registryName).NumProcs

if ($CHECK_CORES -eq $CPU_CORES) {
    Write-Host "********************************************" -ForegroundColor Green
    Write-Host "All CPU cores enabled successfully." -ForegroundColor Green
    Write-Host "********************************************" -ForegroundColor Green
} else {
    Write-Host "Failed to enable all CPU cores." -ForegroundColor Red
}
Write-Host ""

Write-Host "------------------------------------------------------------------------------------------------------------------" -ForegroundColor Magenta

