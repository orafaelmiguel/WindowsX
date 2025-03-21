Write-Output "Checking Drivers..."
Write-Output "drivers.log" "Checking for driver updates..."

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

if (!(Get-Module -ListAvailable -Name PSWindowsUpdate)) {
  Write-Output "Installing PSWindowsUpdate module..."
  Install-Module -Name PSWindowsUpdate -Force -AllowClobber
}

Import-Module PSWindowsUpdate

Write-Output "Enabling Windows Update for drivers..."
# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

Write-Output "Listing available driver updates..."
Get-WindowsUpdate -MicrosoftUpdate -Category "Drivers"

Write-Output "Installing driver updates..."
Get-WindowsUpdate -MicrosoftUpdate -Category "Drivers" -AcceptAll -AutoReboot

Write-Output "Driver update process completed successfully."