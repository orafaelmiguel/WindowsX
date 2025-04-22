# List Drives Script
# This script detects and lists all available drives on the system

Write-Output "Detecting storage drives..."
$ErrorActionPreference = "SilentlyContinue"

# Get all fixed drives (local disk drives, excluding network drives, CD-ROMs, etc.)
try {
    $drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
    
    if ($drives.Count -eq 0) {
        Write-Output "No drives detected, checking with alternate method..."
        # Alternate method
        $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null }
    }
    
    foreach ($drive in $drives) {
        $driveLetter = $drive.DeviceID
        if ($driveLetter -notmatch ':$') {
            $driveLetter = "$($driveLetter):"
        }
        Write-Output "DRIVE_DETECTED|$driveLetter"
    }
    
    if ($drives.Count -eq 0) {
        # If no drives detected, at least return C:
        Write-Output "DRIVE_DETECTED|C:"
    }
} catch {
    Write-Output "Error detecting drives: $_"
    # Ensure we at least return the system drive
    Write-Output "DRIVE_DETECTED|C:"
}

Write-Output "Drive detection completed."
Write-Output "SCRIPT_COMPLETED" 