# Windows Cache Cleaner Script
# This script cleans various Windows caches to improve performance and free up space

Write-Output "Starting Windows cache cleanup..."

# Calculate initial disk space
$initialSpace = (Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'" | Select-Object -ExpandProperty FreeSpace)
$initialSpaceGB = [math]::Round($initialSpace / 1GB, 2)
Write-Output "Initial free space: $initialSpaceGB GB"

# Clean DNS Cache
Write-Output "Flushing DNS Cache..."
try {
    Clear-DnsClientCache
    Write-Output "DNS cache flushed successfully."
} catch {
    Write-Output "Error flushing DNS cache: $_"
}

# Clean Windows Store Cache
Write-Output "Cleaning Windows Store Cache..."
try {
    Stop-Service -Name InstallService -Force -ErrorAction SilentlyContinue
    $wsresetProcess = Start-Process -FilePath "wsreset.exe" -WindowStyle Hidden -PassThru
    Start-Sleep -Seconds 5
    if (-not $wsresetProcess.HasExited) {
        Stop-Process -Id $wsresetProcess.Id -Force
    }
    Start-Service -Name InstallService -ErrorAction SilentlyContinue
    Write-Output "Windows Store cache cleaned successfully."
} catch {
    Write-Output "Error cleaning Windows Store cache: $_"
}

# Clean Windows Font Cache
Write-Output "Cleaning Windows Font Cache..."
try {
    Stop-Service -Name "FontCache" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\ServiceProfiles\LocalService\AppData\Local\FontCache\*" -Force -Recurse -ErrorAction SilentlyContinue
    Start-Service -Name "FontCache" -ErrorAction SilentlyContinue
    Write-Output "Font cache cleaned successfully."
} catch {
    Write-Output "Error cleaning font cache: $_"
}

# Clean Windows Thumbnail Cache
Write-Output "Cleaning Windows Thumbnail Cache..."
try {
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -ErrorAction SilentlyContinue
    Write-Output "Thumbnail cache cleaned successfully."
} catch {
    Write-Output "Error cleaning thumbnail cache: $_"
}

# Clean Internet Explorer Cache
Write-Output "Cleaning Internet Explorer Cache..."
try {
    RunDll32.exe InetCpl.cpl, ClearMyTracksByProcess 8
    Write-Output "Internet Explorer cache cleaned successfully."
} catch {
    Write-Output "Error cleaning Internet Explorer cache: $_"
}

# Clean System Restore Points (keeping the most recent one)
Write-Output "Cleaning old System Restore Points..."
try {
    $restorePoints = Get-ComputerRestorePoint
    if ($restorePoints.Count -gt 1) {
        $restorePoints | Sort-Object -Property CreationTime -Descending | Select-Object -Skip 1 | ForEach-Object {
            Remove-ComputerRestorePoint -SequenceNumber $_.SequenceNumber
        }
        Write-Output "Old system restore points cleaned successfully."
    } else {
        Write-Output "Less than 2 restore points found. No cleaning needed."
    }
} catch {
    Write-Output "Error cleaning system restore points: $_"
}

# Clean Windows Error Reporting Files
Write-Output "Cleaning Windows Error Reporting Files..."
try {
    Remove-Item -Path "C:\ProgramData\Microsoft\Windows\WER\ReportArchive\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\ProgramData\Microsoft\Windows\WER\ReportQueue\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Output "Windows Error Reporting files cleaned successfully."
} catch {
    Write-Output "Error cleaning Windows Error Reporting files: $_"
}

# Calculate space freed
$finalSpace = (Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'" | Select-Object -ExpandProperty FreeSpace)
$finalSpaceGB = [math]::Round($finalSpace / 1GB, 2)
$freedSpace = [math]::Round(($finalSpace - $initialSpace) / 1MB, 2)

Write-Output "Windows cache cleanup completed."
Write-Output "Final free space: $finalSpaceGB GB"
Write-Output "Total space freed: $freedSpace MB"

Write-Output "SCRIPT_COMPLETED" 