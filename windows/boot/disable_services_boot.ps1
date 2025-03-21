write-Host ""
Write-Host "--------------------------------------------" -ForegroundColor Yellow
Write-Host "Disabling services on boot..." -ForegroundColor Yellow
Write-Host "--------------------------------------------" -ForegroundColor Yellow
Write-Host ""
Write-Host ""
Write-Host ""
Start-Sleep -Seconds 6

$adminCheck = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $adminCheck.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: Please run this script as Administrator."
    exit 1
}

# disabled services
$services = @(
    'DiagTrack', 
    'dmwappushservice',
    'SysMain', # if u use hdd, dont run
    'WSearch',
    'XblGameSave',
    'XboxNetApiSvc',
    'TabletInputService',
    'stisvc',  # if u use webcam, dont run
    'RetailDemo',
    'MapsBroker',
    'lfsvc'  # geoloc
)

foreach ($service in $services) {
    Write-Host "Disabling $service ..." -ForegroundColor Cyan
    Stop-Service -Name $service -Force -ErrorAction SilentlyContinue 
    Set-Service -Name $service -StartupType Disabled
}
Write-Host ""
Write-Host ""
Write-Host ""
Start-Sleep -Seconds 6

Write-Host "********************************************" -ForegroundColor Green
Write-Host "All unnecessary services have been disabled!" -ForegroundColor Green
Write-Host "********************************************" -ForegroundColor Green
Write-Host ""

Write-Host "------------------------------------------------------------------------------------------------------------------" -ForegroundColor Magenta

