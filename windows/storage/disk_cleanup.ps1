Write-Output "Starting disk cleanup process..."
Write-Output "Scanning system for temporary files..."

$tempFolders = @(
    "C:\Windows\Temp\*",
    "$env:TEMP\*"
)

# Calculate initial disk space
$initialSpace = (Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'" | Select-Object -ExpandProperty FreeSpace)
$initialSpaceGB = [math]::Round($initialSpace / 1GB, 2)
Write-Output "Initial free space: $initialSpaceGB GB"

Write-Output "Cleaning Windows temporary files..."
try {
    Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Output "Windows temporary files cleaned successfully."
} catch {
    Write-Output "Error cleaning Windows temporary files: $_"
}

Write-Output "Cleaning user temporary files..."
try {
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Output "User temporary files cleaned successfully."
} catch {
    Write-Output "Error cleaning user temporary files: $_"
}

Write-Output "Cleaning Windows Update cache..."
try {
    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service -Name wuauserv -ErrorAction SilentlyContinue
    Write-Output "Windows Update cache cleaned successfully."
} catch {
    Write-Output "Error cleaning Windows Update cache: $_"
}

Write-Output "Cleaning prefetch files..."
try {
    Remove-Item -Path "C:\Windows\Prefetch\*" -Force -ErrorAction SilentlyContinue
    Write-Output "Prefetch files cleaned successfully."
} catch {
    Write-Output "Error cleaning prefetch files: $_"
}

$finalSpace = (Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'" | Select-Object -ExpandProperty FreeSpace)
$finalSpaceGB = [math]::Round($finalSpace / 1GB, 2)
$freedSpace = [math]::Round(($finalSpace - $initialSpace) / 1MB, 2)

Write-Output "Disk cleanup completed."
Write-Output "Final free space: $finalSpaceGB GB"
Write-Output "Total space freed: $freedSpace MB"

Write-Output "SCRIPT_COMPLETED" 