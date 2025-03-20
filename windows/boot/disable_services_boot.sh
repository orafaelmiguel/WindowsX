#!/bin/bash

echo "Disabling services on boot..."

if grep -qi microsoft /proc/version; then
    echo "unning inside WSL..."
    POWERSHELL_CMD="powershell.exe"
elif [[ "$MSYSTEM" == "MINGW64" || "$MSYSTEM" == "MINGW32" ]]; then
    echo "unning inside Git Bash..."
    POWERSHELL_CMD="powershell"
else
    echo "This script must be run inside WSL or Git Bash."
    exit 1
fi

$POWERSHELL_CMD -NoProfile -ExecutionPolicy Bypass -Command "
    \$adminCheck = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    if (!\$adminCheck.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host 'ERROR: Please run Git Bash as Administrator.'
        exit 1
    }

    # services disabled
    \$services = @(
        'DiagTrack',
        'dmwappushservice',
        'SysMain', # if u use HDD, dont run this script
        'WSearch',
        'XblGameSave',
        'XboxNetApiSvc',
        'TabletInputService',
        'stisvc',  # if u use webcam, dont run this too
        'RetailDemo',
        'MapsBroker',
        'lfsvc'  # geoloc
    )

    foreach (\$service in \$services) {
        Write-Host 'Disabling' \$service '...'
        Stop-Service -Name \$service -Force -ErrorAction SilentlyContinue
        Set-Service -Name \$service -StartupType Disabled
    }

    Write-Host 'All unnecessary services have been disabled!'
" || echo "Failed to disable services. Run Git Bash as Administrator!"
