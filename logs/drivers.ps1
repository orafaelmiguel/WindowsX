$LogDir = "logs"
if (!(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir | Out-Null
}

function Write-Log {
    param (
        [string]$LogFile,
        [string]$Message
    )
    $Timestamp = Get-Date -Format "dd-MM-yyyy HH:mm:ss"
    "$Timestamp $Message" | Out-File -Append -FilePath "$LogDir\$LogFile"
}