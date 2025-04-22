# Large Files Scanner Script
# This script scans the system for large files that might be taking up unnecessary space

Write-Output "Starting large files scan..."
Write-Output "This may take a few minutes, please wait..."

# Define minimum file size to consider (100 MB)
$minSizeMB = 100
$minSizeBytes = $minSizeMB * 1MB

# Define paths to scan
$pathsToScan = @(
    "$env:USERPROFILE\Downloads",
    "$env:USERPROFILE\Documents",
    "$env:USERPROFILE\Pictures",
    "$env:USERPROFILE\Videos",
    "$env:USERPROFILE\Desktop"
)

# Function to format file sizes
function Format-FileSize {
    param ([long]$Size)
    
    if ($Size -ge 1TB) { return "{0:N2} TB" -f ($Size / 1TB) }
    if ($Size -ge 1GB) { return "{0:N2} GB" -f ($Size / 1GB) }
    if ($Size -ge 1MB) { return "{0:N2} MB" -f ($Size / 1MB) }
    if ($Size -ge 1KB) { return "{0:N2} KB" -f ($Size / 1KB) }
    
    return "$Size bytes"
}

# Array to hold results
$largeFiles = @()

foreach ($path in $pathsToScan) {
    Write-Output "Scanning $path for large files..."
    
    if (Test-Path $path) {
        try {
            $files = Get-ChildItem -Path $path -File -Recurse -ErrorAction SilentlyContinue | 
                     Where-Object { $_.Length -gt $minSizeBytes } |
                     Sort-Object -Property Length -Descending
            
            if ($files.Count -gt 0) {
                $largeFiles += $files
                Write-Output "Found $($files.Count) large files in $path"
            } else {
                Write-Output "No large files found in $path"
            }
        } catch {
            Write-Output "Error scanning $path : $_"
        }
    } else {
        Write-Output "Path $path does not exist or is not accessible"
    }
}

# Display results
Write-Output "`nLarge files scan completed."
Write-Output "Found a total of $($largeFiles.Count) files larger than $minSizeMB MB."

if ($largeFiles.Count -gt 0) {
    Write-Output "`nTop 20 largest files:"
    $largeFiles | Select-Object -First 20 | ForEach-Object {
        $formattedSize = Format-FileSize -Size $_.Length
        Write-Output "$formattedSize : $($_.FullName)"
    }
    
    # Calculate total size of large files
    $totalSize = ($largeFiles | Measure-Object -Property Length -Sum).Sum
    $formattedTotalSize = Format-FileSize -Size $totalSize
    
    Write-Output "`nTotal space used by all large files: $formattedTotalSize"
    Write-Output "You may want to review these files and delete any that are no longer needed."
} else {
    Write-Output "No large files found on your system."
}

Write-Output "SCRIPT_COMPLETED" 