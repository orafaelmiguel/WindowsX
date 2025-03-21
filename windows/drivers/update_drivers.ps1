Write-Host "********************************************" -ForegroundColor Cyan
Write-Host "Checking Drivers..." -ForegroundColor Cyan
Write-Host "********************************************" -ForegroundColor Cyan
Write-Host ""
Write-Host ""
Write-Host ""

Write-Host "********************************************" -ForegroundColor Cyan
Write-Host "drivers.log" "Checking for driver updates..." -ForegroundColor Cyan
Write-Host "********************************************" -ForegroundColor Cyan
Write-Host ""
Write-Host ""
Write-Host ""


Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

if (!(Get-Module -ListAvailable -Name PSWindowsUpdate)) {
  Write-Host "--------------------------------------------" -ForegroundColor Yellow
  Write-Host "Installing PSWindowsUpdate module..." -ForegroundColor Yellow
  Write-Host "--------------------------------------------" -ForegroundColor Yellow
  Write-Host ""
  Write-Host ""
  Write-Host ""
  Install-Module -Name PSWindowsUpdate -Force -AllowClobber
}

Import-Module PSWindowsUpdate

Write-Host "--------------------------------------------" -ForegroundColor Yellow
Write-Host "Enabling Windows Update for drivers..." -ForegroundColor Yellow
Write-Host "--------------------------------------------" -ForegroundColor Yellow
Write-Host ""
Write-Host ""
Write-Host ""
# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

Write-Host "--------------------------------------------" -ForegroundColor Yellow
Write-Host "Listing available driver updates..." -ForegroundColor Yellow
Write-Host "--------------------------------------------" -ForegroundColor Yellow
Get-WindowsUpdate -MicrosoftUpdate -Category "Drivers"
Write-Host ""
Write-Host ""
Write-Host ""

Write-Host "--------------------------------------------" -ForegroundColor Yellow
Write-Host "Installing driver updates..." -ForegroundColor Yellow
Write-Host "--------------------------------------------" -ForegroundColor Yellow
Write-Host ""
Write-Host ""
Write-Host ""
Get-WindowsUpdate -MicrosoftUpdate -Category "Drivers" -AcceptAll -AutoReboot

Write-Host "********************************************" -ForegroundColor Green
Write-Host "Driver update process completed successfully." -ForegroundColor Green
Write-Host "********************************************" -ForegroundColor Green
Write-Host ""