#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <shlobj.h>
#include <shlwapi.h>

#pragma comment(lib, "shell32.lib")
#pragma comment(lib, "shlwapi.lib")

#define MB (1024LL * 1024LL)
#define GB (1024LL * 1024LL * 1024LL)

typedef struct {
    ULONGLONG totalSpace;
    ULONGLONG freeSpace;
    ULONGLONG usedSpace;
    double usedPercentage;
} DriveInfo;

typedef struct {
    ULONGLONG systemFilesSize;
    ULONGLONG downloadsSize;
    ULONGLONG recycleBinSize;
    ULONGLONG tempFilesSize;
    ULONGLONG appsSize;
    ULONGLONG imagesSize;
    ULONGLONG videosSize;
    ULONGLONG audioSize;
    ULONGLONG documentsSize;
} StorageInfo;

// Function declarations
void ScanDrives(char* drivesToScan);
ULONGLONG GetDirectorySize(const char* dirPath);
ULONGLONG GetSystemFilesSize(void);
ULONGLONG GetDownloadsSize(void);
ULONGLONG GetRecycleBinSize(void);
ULONGLONG GetTempFilesSize(void);
void GetFilesByType(ULONGLONG* imageSize, ULONGLONG* videoSize, ULONGLONG* audioSize, ULONGLONG* documentSize);
ULONGLONG GetInstalledApplicationsSize(void);
int ShouldScanSystemFiles(char* drivesToScan);

int main(int argc, char* argv[]) {
    char* drivesToScan = NULL;
    
    printf("Starting storage scan...\n");
    
    // Parse command line arguments
    if (argc > 1) {
        drivesToScan = argv[1];
        printf("Will scan specific drives: %s\n", drivesToScan);
    }
    
    // Scan drives
    ScanDrives(drivesToScan);
    
    // Get other storage information
    ULONGLONG systemFilesSize = GetSystemFilesSize();
    printf("SYSTEM_FILES_SIZE|%llu\n", systemFilesSize);
    
    ULONGLONG downloadsSize = GetDownloadsSize();
    printf("DOWNLOADS_SIZE|%llu\n", downloadsSize);
    
    ULONGLONG recycleBinSize = GetRecycleBinSize();
    printf("RECYCLE_BIN_SIZE|%llu\n", recycleBinSize);
    
    ULONGLONG tempFilesSize = GetTempFilesSize();
    printf("TEMP_FILES_SIZE|%llu\n", tempFilesSize);
    
    ULONGLONG imageSize = 0, videoSize = 0, audioSize = 0, documentSize = 0;
    GetFilesByType(&imageSize, &videoSize, &audioSize, &documentSize);
    printf("IMAGES_SIZE|%llu\n", imageSize);
    printf("VIDEOS_SIZE|%llu\n", videoSize);
    printf("AUDIO_SIZE|%llu\n", audioSize);
    printf("DOCUMENTS_SIZE|%llu\n", documentSize);
    
    ULONGLONG appsSize = GetInstalledApplicationsSize();
    printf("APPS_SIZE|%llu\n", appsSize);
    
    printf("Storage scan completed.\n");
    printf("SCRIPT_COMPLETED\n");
    
    return 0;
}

int ShouldScanSystemFiles(char* drivesToScan) {
    if (drivesToScan == NULL || strlen(drivesToScan) == 0) {
        return 1;
    }
    
    // Check if C: drive is in the list
    char* token = strtok(drivesToScan, ",");
    while (token != NULL) {
        while (*token == ' ') token++; // Skip leading spaces
        if (strncmp(token, "C:", 2) == 0) {
            return 1;
        }
        token = strtok(NULL, ",");
    }
    
    return 0;
}

void ScanDrives(char* drivesToScan) {
    char drives[256];
    DriveInfo driveInfos[26]; // Maximum 26 drives (A-Z)
    int driveCount = 0;
    
    DWORD drivesMask = GetLogicalDrives();
    
    if (drivesMask == 0) {
        printf("Error getting drives: %lu\n", GetLastError());
        printf("DRIVE_INFO|C:|1000000000000|500000000000|500000000000|50.00\n");
        return;
    }
    
    // Get drive information
    for (int i = 0; i < 26; i++) {
        if (!(drivesMask & (1 << i))) continue;
        
        char driveLetter[4];
        sprintf(driveLetter, "%c:", 'A' + i);
        
        UINT driveType = GetDriveType(driveLetter);
        if (driveType != DRIVE_FIXED) continue; // Only interested in fixed drives
        
        // Check if drive is in requested list
        if (drivesToScan != NULL && strlen(drivesToScan) > 0) {
            int driveFound = 0;
            char drivesToScanCopy[256];
            strcpy(drivesToScanCopy, drivesToScan);
            
            char* token = strtok(drivesToScanCopy, ",");
            while (token != NULL) {
                while (*token == ' ') token++; // Skip leading spaces
                if (strncmp(token, driveLetter, 2) == 0) {
                    driveFound = 1;
                    break;
                }
                token = strtok(NULL, ",");
            }
            
            if (!driveFound) continue;
        }
        
        // Get drive space information
        ULARGE_INTEGER freeBytesAvailable, totalBytes, totalFreeBytes;
        
        if (!GetDiskFreeSpaceEx(driveLetter, &freeBytesAvailable, &totalBytes, &totalFreeBytes)) {
            printf("Error getting drive space for %s: %lu\n", driveLetter, GetLastError());
            continue;
        }
        
        DriveInfo info;
        info.totalSpace = totalBytes.QuadPart;
        info.freeSpace = freeBytesAvailable.QuadPart;
        info.usedSpace = info.totalSpace - info.freeSpace;
        info.usedPercentage = ((double)info.usedSpace / info.totalSpace) * 100;
        
        // Store drive information
        driveInfos[driveCount++] = info;
        
        printf("DRIVE_INFO|%s|%llu|%llu|%llu|%.2f\n", 
               driveLetter, 
               info.totalSpace, 
               info.freeSpace, 
               info.usedSpace, 
               info.usedPercentage);
    }
    
    if (driveCount == 0) {
        printf("No matching drives found!\n");
        printf("DRIVE_INFO|C:|1000000000000|500000000000|500000000000|50.00\n");
        return;
    }
}

ULONGLONG GetDirectorySize(const char* dirPath) {
    WIN32_FIND_DATA findData;
    HANDLE hFind = INVALID_HANDLE_VALUE;
    ULONGLONG totalSize = 0;
    char searchPath[MAX_PATH];
    
    // Ensure the path has a trailing backslash
    strcpy(searchPath, dirPath);
    if (searchPath[strlen(searchPath) - 1] != '\\') {
        strcat(searchPath, "\\");
    }
    
    // Create search pattern
    char findPattern[MAX_PATH];
    strcpy(findPattern, searchPath);
    strcat(findPattern, "*");
    
    // Find first file
    hFind = FindFirstFile(findPattern, &findData);
    
    if (hFind == INVALID_HANDLE_VALUE) {
        return 0; // Error or empty directory
    }
    
    do {
        // Skip "." and ".." directories
        if (strcmp(findData.cFileName, ".") == 0 || strcmp(findData.cFileName, "..") == 0) {
            continue;
        }
        
        // Construct full path to the found item
        char fullPath[MAX_PATH];
        strcpy(fullPath, searchPath);
        strcat(fullPath, findData.cFileName);
        
        if (findData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
            // Recursively calculate size of subdirectory
            totalSize += GetDirectorySize(fullPath);
        } else {
            // Add file size
            ULARGE_INTEGER fileSize;
            fileSize.LowPart = findData.nFileSizeLow;
            fileSize.HighPart = findData.nFileSizeHigh;
            totalSize += fileSize.QuadPart;
        }
    } while (FindNextFile(hFind, &findData));
    
    FindClose(hFind);
    
    return totalSize;
}

ULONGLONG GetSystemFilesSize(void) {
    printf("Scanning system files size...\n");
    
    char windowsFolder[MAX_PATH];
    GetWindowsDirectory(windowsFolder, MAX_PATH);
    
    return GetDirectorySize(windowsFolder);
}

ULONGLONG GetDownloadsSize(void) {
    printf("Scanning downloads folder size...\n");
    
    char downloadsFolder[MAX_PATH];
    SHGetFolderPath(NULL, CSIDL_PERSONAL, NULL, 0, downloadsFolder);
    PathAppend(downloadsFolder, "Downloads");
    
    return GetDirectorySize(downloadsFolder);
}

ULONGLONG GetRecycleBinSize(void) {
    printf("Scanning recycle bin size...\n");
    
    ULONGLONG recycleBinSize = 0;
    SHQUERYRBINFO rbInfo;
    
    rbInfo.cbSize = sizeof(SHQUERYRBINFO);
    
    if (SHQueryRecycleBin(NULL, &rbInfo) == S_OK) {
        recycleBinSize = rbInfo.i64Size;
    } else {
        printf("Error getting recycle bin size: %lu\n", GetLastError());
        recycleBinSize = 2000000000; // Default value
    }
    
    return recycleBinSize;
}

ULONGLONG GetTempFilesSize(void) {
    printf("Scanning temporary files size...\n");
    
    ULONGLONG totalSize = 0;
    char tempFolder[MAX_PATH];
    char winTempFolder[MAX_PATH];
    char softwareDistFolder[MAX_PATH];
    
    // Get user temp folder
    GetTempPath(MAX_PATH, tempFolder);
    totalSize += GetDirectorySize(tempFolder);
    
    // Get Windows temp folder
    GetWindowsDirectory(winTempFolder, MAX_PATH);
    strcat(winTempFolder, "\\Temp");
    totalSize += GetDirectorySize(winTempFolder);
    
    // Get Software Distribution Download folder
    GetWindowsDirectory(softwareDistFolder, MAX_PATH);
    strcat(softwareDistFolder, "\\SoftwareDistribution\\Download");
    totalSize += GetDirectorySize(softwareDistFolder);
    
    return totalSize;
}

int IsFileOfType(const char* filename, const char** extensions, int extensionCount) {
    char* extension = strrchr(filename, '.');
    if (extension == NULL) return 0;
    
    // Convert to lowercase
    char lowerExt[32] = {0};
    int i = 0;
    extension++; // Skip the period
    while (*extension && i < 31) {
        lowerExt[i++] = tolower(*extension);
        extension++;
    }
    
    // Check against allowed extensions
    for (i = 0; i < extensionCount; i++) {
        if (strcmp(lowerExt, extensions[i] + 1) == 0) { // +1 to skip the period in the extensions list
            return 1;
        }
    }
    
    return 0;
}

void GetFilesByType(ULONGLONG* imageSize, ULONGLONG* videoSize, ULONGLONG* audioSize, ULONGLONG* documentSize) {
    printf("Scanning files by type...\n");
    
    const char* imageExtensions[] = {".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".webp"};
    const char* videoExtensions[] = {".mp4", ".avi", ".mkv", ".mov", ".wmv", ".flv", ".webm", ".m4v", ".3gp", ".mpg", ".mpeg"};
    const char* audioExtensions[] = {".mp3", ".wav", ".ogg", ".flac", ".aac", ".wma", ".m4a", ".opus"};
    const char* documentExtensions[] = {".pdf", ".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx", ".txt", ".rtf", ".csv", ".odt", ".ods", ".odp"};
    
    int imageExtCount = sizeof(imageExtensions) / sizeof(imageExtensions[0]);
    int videoExtCount = sizeof(videoExtensions) / sizeof(videoExtensions[0]);
    int audioExtCount = sizeof(audioExtensions) / sizeof(audioExtensions[0]);
    int documentExtCount = sizeof(documentExtensions) / sizeof(documentExtensions[0]);
    
    // Folders to scan
    char folders[6][MAX_PATH];
    char userProfile[MAX_PATH];
    
    // Get user profile path
    if (!GetEnvironmentVariable("USERPROFILE", userProfile, MAX_PATH)) {
        printf("Error getting user profile: %lu\n", GetLastError());
        return;
    }
    
    // Initialize folders to scan
    sprintf(folders[0], "%s\\Desktop", userProfile);
    sprintf(folders[1], "%s\\Documents", userProfile);
    sprintf(folders[2], "%s\\Pictures", userProfile);
    sprintf(folders[3], "%s\\Videos", userProfile);
    sprintf(folders[4], "%s\\Music", userProfile);
    sprintf(folders[5], "%s\\Downloads", userProfile);
    
    *imageSize = 0;
    *videoSize = 0;
    *audioSize = 0;
    *documentSize = 0;
    
    // Scan each folder
    for (int folderIndex = 0; folderIndex < 6; folderIndex++) {
        WIN32_FIND_DATA findData;
        HANDLE hFind = INVALID_HANDLE_VALUE;
        char searchPath[MAX_PATH];
        
        // Create search pattern
        strcpy(searchPath, folders[folderIndex]);
        strcat(searchPath, "\\*");
        
        // Find first file
        hFind = FindFirstFile(searchPath, &findData);
        
        if (hFind == INVALID_HANDLE_VALUE) {
            continue; // Error or empty directory
        }
        
        do {
            // Skip "." and ".." directories
            if (strcmp(findData.cFileName, ".") == 0 || strcmp(findData.cFileName, "..") == 0) {
                continue;
            }
            
            // Construct full path to the found item
            char fullPath[MAX_PATH];
            sprintf(fullPath, "%s\\%s", folders[folderIndex], findData.cFileName);
            
            if (findData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
                // This is a subdirectory, we could scan it recursively if needed
                continue;
            } else {
                // Check file type and add to corresponding size
                ULARGE_INTEGER fileSize;
                fileSize.LowPart = findData.nFileSizeLow;
                fileSize.HighPart = findData.nFileSizeHigh;
                
                if (IsFileOfType(findData.cFileName, imageExtensions, imageExtCount)) {
                    *imageSize += fileSize.QuadPart;
                } else if (IsFileOfType(findData.cFileName, videoExtensions, videoExtCount)) {
                    *videoSize += fileSize.QuadPart;
                } else if (IsFileOfType(findData.cFileName, audioExtensions, audioExtCount)) {
                    *audioSize += fileSize.QuadPart;
                } else if (IsFileOfType(findData.cFileName, documentExtensions, documentExtCount)) {
                    *documentSize += fileSize.QuadPart;
                }
            }
        } while (FindNextFile(hFind, &findData));
        
        FindClose(hFind);
    }
}

ULONGLONG GetInstalledApplicationsSize(void) {
    printf("Scanning installed applications...\n");
    
    ULONGLONG appSize = 0;
    char programFiles[MAX_PATH];
    char programFilesX86[MAX_PATH];
    
    // Get program files paths
    if (!GetEnvironmentVariable("ProgramFiles", programFiles, MAX_PATH) ||
        !GetEnvironmentVariable("ProgramFiles(x86)", programFilesX86, MAX_PATH)) {
        printf("Error getting program files paths: %lu\n", GetLastError());
        return 50000000000; // Default value
    }
    
    // Common game directories
    const char* gameDirs[] = {
        "C:\\Program Files (x86)\\Steam\\steamapps\\common",
        "C:\\Program Files\\Steam\\steamapps\\common",
        "C:\\Program Files\\Epic Games",
        "C:\\Program Files (x86)\\Origin Games",
        "C:\\Program Files\\EA Games",
        "C:\\Program Files (x86)\\Ubisoft"
    };
    
    // Add Program Files sizes
    appSize += GetDirectorySize(programFiles);
    appSize += GetDirectorySize(programFilesX86);
    
    // Add game directories sizes
    for (int i = 0; i < sizeof(gameDirs) / sizeof(gameDirs[0]); i++) {
        ULONGLONG size = GetDirectorySize(gameDirs[i]);
        if (size > 1 * GB) {
            printf("Found %.2f GB for %s\n", (double)size / GB, gameDirs[i]);
        }
        appSize += size;
    }
    
    return appSize;
}
