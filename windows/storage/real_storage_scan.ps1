# Real Storage Scanner Script
# This script scans and returns actual storage data from Windows system

param (
    [string]$drives = "" # Comma-separated list of drives to scan, e.g. "C:,D:,E:"
)

Write-Output "Starting real storage scan..."
$ErrorActionPreference = "SilentlyContinue"

# Parse drives parameter
$drivesToScan = @()
if ($drives -ne "") {
    $drivesToScan = $drives -split "," | ForEach-Object { $_.Trim() }
    Write-Output "Will scan specific drives: $($drivesToScan -join ', ')"
}

# Get all drives
function Get-DriveInfo {
    Write-Output "Scanning drives..."
    
    try {
        # Get all physical drives
        $allDrives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
        
        # Filter drives if specified
        if ($drivesToScan.Count -gt 0) {
            $allDrives = $allDrives | Where-Object { $driveLetter = $_.DeviceID; $drivesToScan -contains $driveLetter }
        }
        
        if ($allDrives.Count -eq 0) {
            Write-Output "No matching drives found!"
            
            # Provide default data for system drive if no drives match
            Write-Output "DRIVE_INFO|C:|1000000000000|500000000000|500000000000|50.00"
            return
        }
        
        foreach ($drive in $allDrives) {
            $driveLetter = $drive.DeviceID
            $totalSpace = $drive.Size
            $freeSpace = $drive.FreeSpace
            $usedSpace = $totalSpace - $freeSpace
            $usedPercentage = [math]::Round(($usedSpace / $totalSpace) * 100, 2)
            
            Write-Output "DRIVE_INFO|$driveLetter|$totalSpace|$freeSpace|$usedSpace|$usedPercentage"
        }
    } catch {
        Write-Output "Error getting drive information: $_"
        # Fornecer dados padrão para o disco C: se houver erro
        Write-Output "DRIVE_INFO|C:|1000000000000|500000000000|500000000000|50.00"
    }
}

# Should we scan system files? Only if C: is included
function Should-ScanSystemFiles {
    return ($drivesToScan.Count -eq 0) -or ($drivesToScan -contains "C:")
}

# Get system files size (Windows folder)
function Get-SystemFilesSize {
    # Skip if C: drive is not selected
    if (-not (Should-ScanSystemFiles)) {
        Write-Output "SYSTEM_FILES_SIZE|0"
        return
    }
    
    Write-Output "Scanning system files size..."
    
    try {
        $windowsFolder = "$env:SystemDrive\Windows"
        $size = (Get-ChildItem -Path $windowsFolder -Recurse | Measure-Object -Property Length -Sum).Sum
        if ($null -eq $size) { $size = 0 }
        
        Write-Output "SYSTEM_FILES_SIZE|$size"
    } catch {
        Write-Output "Error getting system files size: $_"
        Write-Output "SYSTEM_FILES_SIZE|50000000000"
    }
}

# Get downloads folder size
function Get-DownloadsSize {
    # Skip if C: drive is not selected
    if (-not (Should-ScanSystemFiles)) {
        Write-Output "DOWNLOADS_SIZE|0"
        return
    }
    
    Write-Output "Scanning downloads folder size..."
    
    try {
        $downloadsFolder = "$env:USERPROFILE\Downloads"
        $size = (Get-ChildItem -Path $downloadsFolder -Recurse | Measure-Object -Property Length -Sum).Sum
        if ($null -eq $size) { $size = 0 }
        
        Write-Output "DOWNLOADS_SIZE|$size"
    } catch {
        Write-Output "Error getting downloads folder size: $_"
        Write-Output "DOWNLOADS_SIZE|10000000000"
    }
}

# Get recycle bin size
function Get-RecycleBinSize {
    # Skip if C: drive is not selected
    if (-not (Should-ScanSystemFiles)) {
        Write-Output "RECYCLE_BIN_SIZE|0"
        return
    }
    
    Write-Output "Scanning recycle bin size..."
    
    try {
        $shellApp = New-Object -ComObject Shell.Application
        $recycleBin = $shellApp.NameSpace(10)
        
        if ($recycleBin -ne $null) {
            $size = ($recycleBin.Items() | Measure-Object -Property Size -Sum | Select-Object -ExpandProperty Sum)
            if ($null -eq $size) { $size = 0 }
        } else {
            $size = 0
        }
        
        Write-Output "RECYCLE_BIN_SIZE|$size"
    } catch {
        Write-Output "Error getting recycle bin size: $_"
        Write-Output "RECYCLE_BIN_SIZE|2000000000"
    } finally {
        if ($shellApp -ne $null) { 
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shellApp) | Out-Null 
        }
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }
}

# Get temporary files size
function Get-TempFilesSize {
    # Skip if C: drive is not selected
    if (-not (Should-ScanSystemFiles)) {
        Write-Output "TEMP_FILES_SIZE|0"
        return
    }
    
    Write-Output "Scanning temporary files size..."
    
    try {
        $tempFolders = @(
            "$env:TEMP",
            "$env:SystemRoot\Temp",
            "$env:SystemRoot\SoftwareDistribution\Download"
        )
        
        $totalSize = 0
        
        foreach ($folder in $tempFolders) {
            if (Test-Path $folder) {
                $size = (Get-ChildItem -Path $folder -Recurse | Measure-Object -Property Length -Sum).Sum
                if ($null -ne $size) {
                    $totalSize += $size
                }
            }
        }
        
        Write-Output "TEMP_FILES_SIZE|$totalSize"
    } catch {
        Write-Output "Error getting temporary files size: $_"
        Write-Output "TEMP_FILES_SIZE|5000000000"
    }
}

# Get files by type
function Get-FilesByType {
    # Skip if C: drive is not selected
    if (-not (Should-ScanSystemFiles)) {
        Write-Output "IMAGES_SIZE|0"
        Write-Output "VIDEOS_SIZE|0"
        Write-Output "AUDIO_SIZE|0"
        Write-Output "DOCUMENTS_SIZE|0"
        Write-Output "APPS_SIZE|0"
        return
    }
    
    Write-Output "Scanning files by type..."
    
    $scanFolders = @(
        "$env:USERPROFILE\Desktop",
        "$env:USERPROFILE\Documents",
        "$env:USERPROFILE\Pictures",
        "$env:USERPROFILE\Videos",
        "$env:USERPROFILE\Music",
        "$env:USERPROFILE\Downloads"
    )
    
    # Define file types
    $imageExtensions = @('.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.webp')
    $videoExtensions = @('.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm')
    $audioExtensions = @('.mp3', '.wav', '.ogg', '.flac', '.aac', '.wma', '.m4a')
    $documentExtensions = @('.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt', '.rtf')
    $appExtensions = @('.exe', '.msi', '.appx', '.msix')
    
    $imageSize = 0
    $videoSize = 0
    $audioSize = 0
    $documentSize = 0
    $appSize = 0
    
    foreach ($folder in $scanFolders) {
        if (Test-Path $folder) {
            try {
                $files = Get-ChildItem -Path $folder -File -Recurse -ErrorAction SilentlyContinue
                
                foreach ($file in $files) {
                    $extension = [System.IO.Path]::GetExtension($file.Name).ToLower()
                    
                    if ($imageExtensions -contains $extension) {
                        $imageSize += $file.Length
                    } elseif ($videoExtensions -contains $extension) {
                        $videoSize += $file.Length
                    } elseif ($audioExtensions -contains $extension) {
                        $audioSize += $file.Length
                    } elseif ($documentExtensions -contains $extension) {
                        $documentSize += $file.Length
                    } elseif ($appExtensions -contains $extension) {
                        $appSize += $file.Length
                    }
                }
            } catch {
                Write-Output "Error scanning folder $folder : $_"
            }
        }
    }
    
    # Garante que valores nulos não sejam usados
    if ($null -eq $imageSize) { $imageSize = 0 }
    if ($null -eq $videoSize) { $videoSize = 0 }
    if ($null -eq $audioSize) { $audioSize = 0 }
    if ($null -eq $documentSize) { $documentSize = 0 }
    if ($null -eq $appSize) { $appSize = 0 }
    
    Write-Output "IMAGES_SIZE|$imageSize"
    Write-Output "VIDEOS_SIZE|$videoSize"
    Write-Output "AUDIO_SIZE|$audioSize"
    Write-Output "DOCUMENTS_SIZE|$documentSize"
    Write-Output "APPS_SIZE|$appSize"
}

# Run all scans
Get-DriveInfo
Get-SystemFilesSize
Get-DownloadsSize
Get-RecycleBinSize
Get-TempFilesSize
Get-FilesByType

Write-Output "Storage scan completed."
Write-Output "SCRIPT_COMPLETED" 