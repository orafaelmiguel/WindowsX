Write-Output "Installing Intel XTU..."

$XTU_Url = "https://downloadmirror.intel.com/849395/XTUSetup_7.14.2.14.exe"
$XTU_Path = "$env:TEMP\XTUSetup_7.14.2.14.exe"

Invoke-WebRequest -Uri $XTU_Url -OutFile $XTU_Path

Start-Process -FilePath $XTU_Path -ArgumentList "/quiet /norestart" -Wait

Start-Sleep -Seconds 10

$XTU_Executable = "C:\Program Files (x86)\Intel\Intel(R) Extreme Tuning Utility\Client\XTUUI.exe"

if (Test-Path $XTU_Executable) {
    Write-Output "Launching Intel XTU..."
    Start-Process -FilePath $XTU_Executable
} else {
    Write-Output "Intel XTU installation failed or not found!"
}
