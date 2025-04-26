Write-Output "Detecting storage drives..."
$ErrorActionPreference = "SilentlyContinue"

try {
    $drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
    
    if ($drives.Count -eq 0) {
        Write-Output "No drives detected, checking with alternate method..."
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
        Write-Output "DRIVE_DETECTED|C:"
    }
} catch {
    Write-Output "Error detecting drives: $_"
    Write-Output "DRIVE_DETECTED|C:"
}

Write-Output "Drive detection completed."
Write-Output "SCRIPT_COMPLETED" 