# Duplicate Files Finder Script
# This script finds duplicate files to help free up disk space

Write-Output "Starting duplicate files scan..."
Write-Output "This process may take a while depending on the number of files to scan."

# Define paths to scan
$pathsToScan = @(
    "$env:USERPROFILE\Downloads",
    "$env:USERPROFILE\Documents",
    "$env:USERPROFILE\Pictures",
    "$env:USERPROFILE\Videos",
    "$env:USERPROFILE\Desktop"
)

# Minimum file size to consider (skip very small files to speed up the process)
$minSizeKB = 10  # 10 KB
$minSizeBytes = $minSizeKB * 1KB

# Function to format file sizes
function Format-FileSize {
    param ([long]$Size)
    
    if ($Size -ge 1TB) { return "{0:N2} TB" -f ($Size / 1TB) }
    if ($Size -ge 1GB) { return "{0:N2} GB" -f ($Size / 1GB) }
    if ($Size -ge 1MB) { return "{0:N2} MB" -f ($Size / 1MB) }
    if ($Size -ge 1KB) { return "{0:N2} KB" -f ($Size / 1KB) }
    
    return "$Size bytes"
}

# Get files from specified paths
Write-Output "Collecting file information..."
$allFiles = @()

foreach ($path in $pathsToScan) {
    Write-Output "Scanning $path..."
    
    if (Test-Path $path) {
        try {
            $files = Get-ChildItem -Path $path -File -Recurse -ErrorAction SilentlyContinue | 
                     Where-Object { $_.Length -ge $minSizeBytes }
            
            $allFiles += $files
            Write-Output "Found $($files.Count) files in $path"
        } catch {
            Write-Output "Error scanning $path : $_"
        }
    } else {
        Write-Output "Path $path does not exist or is not accessible"
    }
}

Write-Output "Total files to analyze: $($allFiles.Count)"

# Group files by size to reduce comparison scope
Write-Output "Grouping files by size..."
$filesBySize = $allFiles | Group-Object -Property Length

# Find potential duplicates (files with the same size)
$potentialDuplicates = $filesBySize | Where-Object { $_.Count -gt 1 }
Write-Output "Found $($potentialDuplicates.Count) groups of files with identical sizes."

# Compare file hashes to find actual duplicates
Write-Output "Comparing file contents to find actual duplicates..."
$duplicateGroups = @()

foreach ($sizeGroup in $potentialDuplicates) {
    Write-Output "Analyzing $($sizeGroup.Count) files of size $([math]::Round($sizeGroup.Name / 1MB, 2)) MB..."
    
    # Calculate hashes for each file in the group
    $filesWithHash = $sizeGroup.Group | ForEach-Object {
        try {
            $hash = Get-FileHash -Path $_.FullName -Algorithm MD5 -ErrorAction SilentlyContinue
            if ($hash) {
                [PSCustomObject]@{
                    Path = $_.FullName
                    Size = $_.Length
                    Hash = $hash.Hash
                    Name = $_.Name
                    LastWriteTime = $_.LastWriteTime
                }
            }
        } catch {
            Write-Output "Error calculating hash for $($_.FullName): $_"
            $null
        }
    } | Where-Object { $_ -ne $null }
    
    # Group files by hash
    $hashGroups = $filesWithHash | Group-Object -Property Hash
    
    # Add duplicate groups (more than one file with the same hash)
    $duplicateGroups += $hashGroups | Where-Object { $_.Count -gt 1 }
}

# Display results
$totalDuplicateGroups = $duplicateGroups.Count
$totalDuplicateFiles = ($duplicateGroups | Measure-Object -Property Count -Sum).Sum - $totalDuplicateGroups
$totalWastedSpace = ($duplicateGroups | ForEach-Object { ($_.Group[0].Size) * ($_.Count - 1) } | Measure-Object -Sum).Sum

Write-Output "`nDuplicate files scan completed."
Write-Output "Found $totalDuplicateGroups groups of duplicate files."
Write-Output "Total duplicate files: $totalDuplicateFiles"
Write-Output "Total wasted space: $(Format-FileSize -Size $totalWastedSpace)"

if ($totalDuplicateGroups -gt 0) {
    Write-Output "`nTop duplicate groups by size:"
    
    $duplicateGroups | 
        Sort-Object -Property { $_.Group[0].Size * ($_.Count - 1) } -Descending | 
        Select-Object -First 10 | 
        ForEach-Object {
            $groupSize = Format-FileSize -Size $_.Group[0].Size
            $wastedSpace = Format-FileSize -Size ($_.Group[0].Size * ($_.Count - 1))
            
            Write-Output "`nDuplicate group: $($_.Count) files, each $groupSize (Wasted space: $wastedSpace)"
            $_.Group | ForEach-Object {
                Write-Output "  - $($_.Path) (Last modified: $($_.LastWriteTime))"
            }
        }
    
    Write-Output "`nConsider reviewing these duplicate files and removing unnecessary copies."
} else {
    Write-Output "No duplicate files found."
}

Write-Output "SCRIPT_COMPLETED" 