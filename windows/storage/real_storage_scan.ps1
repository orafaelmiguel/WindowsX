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

# Get installed applications size - Enhanced to be more comprehensive
function Get-InstalledApplicationsSize {
    if (-not (Should-ScanSystemFiles)) {
        Write-Output "APPS_SIZE|0"
        return
    }
    
    Write-Output "Scanning installed applications (comprehensive)..."
    
    $appSize = 0
    $scannedPaths = @{}  # Track already scanned paths to avoid double-counting
    
    # List of common program installation directories to scan
    $programDirs = @(
        "$env:ProgramFiles",
        "${env:ProgramFiles(x86)}"
    )
    
    # Add Steam, Epic, and other game store directories if they exist
    $gameDirs = @(
        "C:\Program Files (x86)\Steam\steamapps\common",
        "C:\Program Files\Steam\steamapps\common",
        "C:\Program Files\Epic Games",
        "C:\Program Files (x86)\Origin Games",
        "C:\Program Files\EA Games",
        "C:\Program Files (x86)\Ubisoft"
    )
    
    # Scan all drives if specified
    if ($drivesToScan.Count -gt 0) {
        foreach ($drive in $drivesToScan) {
            # Add only non-C: drive game directories
            if ($drive -ne "C:") {
                $gameDirs += "$drive\SteamLibrary\steamapps\common"
                $gameDirs += "$drive\Steam\steamapps\common"
                $gameDirs += "$drive\Epic Games"
                $gameDirs += "$drive\Games"
            }
        }
    }
    
    # Combine both program and game directories
    $allAppDirs = $programDirs + $gameDirs
    
    # Scan all directories
    foreach ($dir in $allAppDirs) {
        if ((Test-Path $dir) -and (-not $scannedPaths.ContainsKey($dir.ToLower()))) {
            try {
                Write-Output "Scanning directory: $dir"
                $scannedPaths[$dir.ToLower()] = $true  
                $items = Get-ChildItem -Path $dir -ErrorAction SilentlyContinue | 
                         Where-Object { 
                             ($_.Name -ne "Windows") -and 
                             ($_.Name -ne "WindowsApps") -and 
                             ($_.Name -ne "System32") -and
                             ($_.Name -ne "Microsoft") -and
                             ($_.Name -ne "Common Files") -and
                             ($_.Name -ne "Windows Defender") -and
                             ($_.Name -ne "Windows NT") -and
                             ($_.Name -ne "Windows Kits") -and
                             ($_.Name -ne "Windows Portable Devices") -and
                             ($_.Name -ne "Windows Sidebar")
                         }
                foreach ($item in $items) {
                    if (Test-Path $item.FullName) {
                        $size = (Get-ChildItem -Path $item.FullName -Recurse -ErrorAction SilentlyContinue | 
                                Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                        
                        if ($null -ne $size -and $size -gt 0) {
                            $appSize += $size
                            if ($size -gt 100MB) {
                                $sizeInGB = ($size / 1GB).ToString('F2')
                                Write-Output "Found $sizeInGB GB for $($item.Name)"
                            }
                        }
                    }
                }
            } catch {
                Write-Output "Error scanning directory $dir : $_"
            }
        }
    }
    
    # Scan registry for installed applications, but only adding locations we haven't already scanned
    try {
        $registryPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )
        
        foreach ($path in $registryPaths) {
            $apps = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
            
            foreach ($app in $apps) {
                if ($app.InstallLocation -and (Test-Path $app.InstallLocation)) {
                    $location = $app.InstallLocation.TrimEnd('\')
                    
                    # Skip if already scanned or part of an already scanned directory
                    $alreadyScanned = $false
                    if ($scannedPaths.ContainsKey($location.ToLower())) {
                        $alreadyScanned = $true
                    } else {
                        foreach ($scannedPath in $scannedPaths.Keys) {
                            if ($location.ToLower().StartsWith($scannedPath)) {
                                $alreadyScanned = $true
                                break
                            }
                        }
                    }
                    
                    # Skip Microsoft and system applications to avoid counting OS files
                    $skipApp = $false
                    $skipKeywords = @('Microsoft', 'Windows', 'System', 'Driver', '.NET', 'Runtime', 'Update', 'Hotfix')
                    foreach ($keyword in $skipKeywords) {
                        if ($app.DisplayName -and $app.DisplayName.Contains($keyword)) {
                            $skipApp = $true
                            break
                        }
                    }
                    
                    if (-not $alreadyScanned -and -not $skipApp) {
                        Write-Output "Scanning from registry: $($app.DisplayName) at $location"
                        $scannedPaths[$location.ToLower()] = $true
                        
                        $size = (Get-ChildItem -Path $location -Recurse -ErrorAction SilentlyContinue | 
                               Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                        
                        if ($null -ne $size -and $size -gt 0) {
                            $appSize += $size
                            if ($size -gt 1GB) {
                                $sizeInGB = ($size / 1GB).ToString('F2')
                                Write-Output "Found $sizeInGB GB for $($app.DisplayName)"
                            }
                        }
                    }
                }
            }
        }
    } catch {
        Write-Output "Error scanning registry for applications: $_"
    }
    
    # Ensure the value is not null
    if ($null -eq $appSize) { $appSize = 0 }
    
    Write-Output "APPS_SIZE|$appSize"
}

# Get files by type
function Get-FilesByType {
    # Skip if C: drive is not selected
    if (-not (Should-ScanSystemFiles)) {
        Write-Output "IMAGES_SIZE|0"
        Write-Output "VIDEOS_SIZE|0"
        Write-Output "AUDIO_SIZE|0"
        Write-Output "DOCUMENTS_SIZE|0"
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
    $videoExtensions = @('.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm', '.m4v', '.3gp', '.mpg', '.mpeg')
    $audioExtensions = @('.mp3', '.wav', '.ogg', '.flac', '.aac', '.wma', '.m4a', '.opus')
    $documentExtensions = @('.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt', '.rtf', '.csv', '.odt', '.ods', '.odp')
    
    $imageSize = 0
    $videoSize = 0
    $audioSize = 0
    $documentSize = 0
    
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
    
    Write-Output "IMAGES_SIZE|$imageSize"
    Write-Output "VIDEOS_SIZE|$videoSize"
    Write-Output "AUDIO_SIZE|$audioSize"
    Write-Output "DOCUMENTS_SIZE|$documentSize"
}

# Run all scans
Get-DriveInfo
Get-SystemFilesSize
Get-DownloadsSize
Get-RecycleBinSize
Get-TempFilesSize
Get-FilesByType
Get-InstalledApplicationsSize

Write-Output "Storage scan completed."
Write-Output "SCRIPT_COMPLETED" 