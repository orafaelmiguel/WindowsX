Write-Output "Disabling services on boot..."

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
    Write-Host "Disabling $service ..."
    Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
    Set-Service -Name $service -StartupType Disabled
}

Write-Host "All unnecessary services have been disabled!"
