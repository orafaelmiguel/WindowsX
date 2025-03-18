. .\logs\drivers.ps1 

Write-Output "Checking Drivers..."
Write-Log "drivers.log" "Checking for driver updates..."

if (!(Get-Module -ListAvailable -Name PSWindowsUpdate)) {
  Write-Log "drivers.log" "Installing PSWindowsUpdate module..."
  Install-Module -Name PSWindowsUpdate -Force -AllowClobber
}

Import-Module PSWindowsUpdate

Write-Log "drivers.log" "Enabling Windows Update for drivers..."
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

Write-Log "drivers.log" "Listing available driver updates..."
Get-WindowsUpdate -MicrosoftUpdate -Category "Drivers"

Write-Log "drivers.log" "Installing driver updates..."
Get-WindowsUpdate -MicrosoftUpdate -Category "Drivers" -AcceptAll -AutoReboot

Write-Log "drivers.log" "Driver update process completed successfully."