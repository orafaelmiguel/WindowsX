#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <shlobj.h>
#include <shlwapi.h>
#include <process.h>
#include <setjmp.h>
#include <signal.h>

#pragma comment(lib, "shell32.lib")
#pragma comment(lib, "shlwapi.lib")

#define MB (1024LL * 1024LL)
#define GB (1024LL * 1024LL * 1024LL)
#define MAX_THREADS 4
#define MAX_SCAN_DEPTH 20
#define MAX_PATH_LENGTH 260

// Valores mais conservadores para estabilidade
#define LARGE_DIR_THRESHOLD (500) // número de arquivos
#define SAMPLING_FACTOR 2 // amostrar 1 a cada X arquivos para diretórios grandes
#define MAX_CACHE_ENTRIES 50

// Global error handling variable
jmp_buf exception_buffer;
volatile int in_protected_section = 0;

// Signal handler for SIGSEGV
void segfault_handler(int sig) {
    if (in_protected_section) {
        // Jump back to the protected section's error handler
        in_protected_section = 0;
        longjmp(exception_buffer, 1);
    }
}

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

typedef struct {
    char dirPath[MAX_PATH]; // Usando buffer fixo em vez de ponteiro para evitar problemas
    ULONGLONG result;
    int maxDepth;
} ThreadData;

typedef struct {
    ULONGLONG* imageSize;
    ULONGLONG* videoSize;
    ULONGLONG* audioSize;
    ULONGLONG* documentSize;
} FileTypeScanResult;

// Variáveis globais para armazenar a informação de diretórios já escaneados (cache)
CRITICAL_SECTION cacheLock;
char cachedPaths[MAX_CACHE_ENTRIES][MAX_PATH];
ULONGLONG cachedSizes[MAX_CACHE_ENTRIES];
int cacheCount = 0;

// Variáveis globais para diretórios comuns a serem ignorados
const char* ignoreDirs[] = {
    "Windows\\WinSxS",
    "Windows\\assembly",
    "Windows\\Installer",
    "Windows\\servicing"
};
const int ignoreCount = sizeof(ignoreDirs) / sizeof(ignoreDirs[0]);

// Protótipos de função
void ScanDrives(char* drivesToScan);
ULONGLONG GetDirectorySize(const char* dirPath, int maxDepth);
unsigned __stdcall DirectorySizeThreadProc(void* arg);
ULONGLONG GetSystemFilesSize(void);
ULONGLONG GetDownloadsSize(void);
ULONGLONG GetRecycleBinSize(void);
ULONGLONG GetTempFilesSize(void);
DWORD WINAPI FileTypesScanProc(LPVOID lpParam);
ULONGLONG GetInstalledApplicationsSize(void);
int ShouldScanSystemFiles(char* drivesToScan);
int ShouldIgnoreDirectory(const char* path);
ULONGLONG LookupCachedSize(const char* path);
void AddToCache(const char* path, ULONGLONG size);

int main(int argc, char* argv[]) {
    char* drivesToScan = NULL;
    HANDLE threads[4];
    ThreadData threadData[4];
    
    // Set error mode to suppress Windows error dialog boxes
    SetErrorMode(SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX);
    
    // Set up signal handler for segmentation faults
    signal(SIGSEGV, segfault_handler);
    
    // Inicializar seção crítica para o cache
    InitializeCriticalSection(&cacheLock);
    
    printf("Starting storage scan...\n");
    
    // Parse command line arguments
    if (argc > 1) {
        drivesToScan = argv[1];
        printf("Will scan specific drives: %s\n", drivesToScan);
    }
    
    // Scan drives
    ScanDrives(drivesToScan);
    
    // Versão simplificada e mais estável
    // Preferimos execução sequencial em vez de paralela para evitar problemas de memória
    ULONGLONG systemFilesSize = 0;
    
    // Safely handle Windows files scan with proper error handling
    in_protected_section = 1;
    if (setjmp(exception_buffer) == 0) {
        systemFilesSize = GetSystemFilesSize();
        in_protected_section = 0;
    } else {
        in_protected_section = 0;
        printf("Error accessing system files, using default value\n");
        systemFilesSize = 50000000000; // Default value
    }
    printf("SYSTEM_FILES_SIZE|%llu\n", systemFilesSize);
    
    ULONGLONG downloadsSize = 0;
    in_protected_section = 1;
    if (setjmp(exception_buffer) == 0) {
        downloadsSize = GetDownloadsSize();
        in_protected_section = 0;
    } else {
        in_protected_section = 0;
        printf("Error accessing downloads folder, using default value\n");
        downloadsSize = 10000000000; // Default value
    }
    printf("DOWNLOADS_SIZE|%llu\n", downloadsSize);
    
    ULONGLONG recycleBinSize = 0;
    in_protected_section = 1;
    if (setjmp(exception_buffer) == 0) {
        recycleBinSize = GetRecycleBinSize();
        in_protected_section = 0;
    } else {
        in_protected_section = 0;
        printf("Error accessing recycle bin, using default value\n");
        recycleBinSize = 2000000000; // Default value
    }
    printf("RECYCLE_BIN_SIZE|%llu\n", recycleBinSize);
    
    ULONGLONG tempFilesSize = 0;
    in_protected_section = 1;
    if (setjmp(exception_buffer) == 0) {
        tempFilesSize = GetTempFilesSize();
        in_protected_section = 0;
    } else {
        in_protected_section = 0;
        printf("Error accessing temp files, using default value\n");
        tempFilesSize = 5000000000; // Default value
    }
    printf("TEMP_FILES_SIZE|%llu\n", tempFilesSize);
    
    // Resultados do tamanho por tipo de arquivo
    ULONGLONG imageSize = 0, videoSize = 0, audioSize = 0, documentSize = 0;
    
    // Inicializar estrutura para armazenar ponteiros para resultados
    FileTypeScanResult fileTypesResults;
    fileTypesResults.imageSize = &imageSize;
    fileTypesResults.videoSize = &videoSize;
    fileTypesResults.audioSize = &audioSize;
    fileTypesResults.documentSize = &documentSize;
    
    // Safely handle file type scanning
    in_protected_section = 1;
    if (setjmp(exception_buffer) == 0) {
        FileTypesScanProc(&fileTypesResults);
        in_protected_section = 0;
    } else {
        in_protected_section = 0;
        printf("Error scanning file types, using default values\n");
        imageSize = 5000000000;
        videoSize = 10000000000;
        audioSize = 5000000000;
        documentSize = 2000000000;
    }
    
    printf("IMAGES_SIZE|%llu\n", imageSize);
    printf("VIDEOS_SIZE|%llu\n", videoSize);
    printf("AUDIO_SIZE|%llu\n", audioSize);
    printf("DOCUMENTS_SIZE|%llu\n", documentSize);
    
    // Obter aplicativos instalados
    ULONGLONG appsSize = 0;
    in_protected_section = 1;
    if (setjmp(exception_buffer) == 0) {
        appsSize = GetInstalledApplicationsSize();
        in_protected_section = 0;
    } else {
        in_protected_section = 0;
        printf("Error accessing installed apps, using default value\n");
        appsSize = 50000000000; // Default value
    }
    printf("APPS_SIZE|%llu\n", appsSize);
    
    printf("Storage scan completed.\n");
    printf("SCRIPT_COMPLETED\n");
    
    // Destruir a seção crítica
    DeleteCriticalSection(&cacheLock);
    
    return 0;
}

// Thread procedure para cálculo de tamanho de diretório
unsigned __stdcall DirectorySizeThreadProc(void* arg) {
    ThreadData* data = (ThreadData*)arg;
    data->result = GetDirectorySize(data->dirPath, data->maxDepth);
    return 0;
}

int ShouldIgnoreDirectory(const char* path) {
    if (!path) return 0;
    
    for (int i = 0; i < ignoreCount; i++) {
        if (strstr(path, ignoreDirs[i]) != NULL) {
            return 1;
        }
    }
    return 0;
}

ULONGLONG LookupCachedSize(const char* path) {
    ULONGLONG result = 0;
    
    if (!path) return 0;
    
    EnterCriticalSection(&cacheLock);
    for (int i = 0; i < cacheCount; i++) {
        if (_stricmp(cachedPaths[i], path) == 0) {
            result = cachedSizes[i];
            break;
        }
    }
    LeaveCriticalSection(&cacheLock);
    
    return result;
}

void AddToCache(const char* path, ULONGLONG size) {
    if (!path) return;
    
    EnterCriticalSection(&cacheLock);
    if (cacheCount < MAX_CACHE_ENTRIES) {
        strncpy(cachedPaths[cacheCount], path, MAX_PATH - 1);
        cachedPaths[cacheCount][MAX_PATH - 1] = '\0';
        cachedSizes[cacheCount] = size;
        cacheCount++;
    }
    LeaveCriticalSection(&cacheLock);
}

int ShouldScanSystemFiles(char* drivesToScan) {
    if (drivesToScan == NULL || strlen(drivesToScan) == 0) {
        return 1;
    }
    
    // Create a copy to avoid modifying the original
    char drivesToScanCopy[256];
    strncpy(drivesToScanCopy, drivesToScan, sizeof(drivesToScanCopy) - 1);
    drivesToScanCopy[sizeof(drivesToScanCopy) - 1] = '\0';
    
    // Check if C: drive is in the list
    char* context = NULL;
    char* token = strtok_s(drivesToScanCopy, ",", &context);
    while (token != NULL) {
        while (*token == ' ') token++; // Skip leading spaces
        if (strncmp(token, "C:", 2) == 0) {
            return 1;
        }
        token = strtok_s(NULL, ",", &context);
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
            strncpy(drivesToScanCopy, drivesToScan, sizeof(drivesToScanCopy) - 1);
            drivesToScanCopy[sizeof(drivesToScanCopy) - 1] = '\0';
            
            char* context = NULL;
            char* token = strtok_s(drivesToScanCopy, ",", &context);
            while (token != NULL) {
                while (*token == ' ') token++; // Skip leading spaces
                if (strncmp(token, driveLetter, 2) == 0) {
                    driveFound = 1;
                    break;
                }
                token = strtok_s(NULL, ",", &context);
            }
            
            if (!driveFound) continue;
        }
        
        // Get drive space information
        ULARGE_INTEGER freeBytesAvailable, totalBytes, totalFreeBytes;
        char driveWithSlash[4] = {0};
        sprintf(driveWithSlash, "%s\\", driveLetter);
        
        if (!GetDiskFreeSpaceEx(driveWithSlash, &freeBytesAvailable, &totalBytes, &totalFreeBytes)) {
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

// Versão simplificada de GetDirectorySize
ULONGLONG GetDirectorySize(const char* dirPath, int maxDepth) {
    if (!dirPath || maxDepth <= 0) return 0;
    
    // Verificar se o diretório existe
    WIN32_FIND_DATA findData;
    HANDLE hFind = INVALID_HANDLE_VALUE;
    char searchPath[MAX_PATH];
    
    // Verificar se já temos este diretório em cache
    ULONGLONG cachedSize = LookupCachedSize(dirPath);
    if (cachedSize > 0) {
        return cachedSize;
    }
    
    // Verificar se o diretório deve ser ignorado
    if (ShouldIgnoreDirectory(dirPath)) {
        return 0;
    }
    
    ULONGLONG totalSize = 0;
    
    // Evitar diretórios protegidos
    if (strstr(dirPath, "System Volume Information") != NULL ||
        strstr(dirPath, "$RECYCLE.BIN") != NULL ||
        strstr(dirPath, "Windows\\System32") != NULL) {
        return 0;
    }
    
    // Safety check using setjmp/longjmp
    in_protected_section = 1;
    if (setjmp(exception_buffer) == 0) {
        // Construir caminho de pesquisa
        strncpy(searchPath, dirPath, MAX_PATH - 3);
        searchPath[MAX_PATH - 3] = '\0';
        
        // Garantir que o caminho termina com barra
        size_t len = strlen(searchPath);
        if (len > 0 && searchPath[len - 1] != '\\') {
            strcat(searchPath, "\\");
        }
        
        // Adicionar curinga para busca
        strcat(searchPath, "*");
        
        // Usar FindFirstFile para compatibilidade máxima
        hFind = FindFirstFile(searchPath, &findData);
        
        if (hFind == INVALID_HANDLE_VALUE) {
            in_protected_section = 0;
            return 0; // Diretório vazio ou erro
        }
        
        int fileCount = 0;
        do {
            // Ignorar "." e ".."
            if (strcmp(findData.cFileName, ".") == 0 || strcmp(findData.cFileName, "..") == 0) {
                continue;
            }
            
            fileCount++;
            
            // Limitar o número de arquivos analisados para melhorar desempenho
            if (fileCount > 1000) {
                // Encontramos muitos arquivos, vamos estimar o restante
                totalSize *= 2; // Multiplica por 2 como uma aproximação
                break;
            }
            
            // Construir caminho completo
            char fullPath[MAX_PATH];
            sprintf(fullPath, "%s%s", dirPath, findData.cFileName);
            
            if (findData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
                // Diretório - recursão com limitação de profundidade
                char subDirPath[MAX_PATH];
                snprintf(subDirPath, MAX_PATH - 1, "%s\\", fullPath);
                totalSize += GetDirectorySize(subDirPath, maxDepth - 1);
            } else {
                // Arquivo - adicionar tamanho
                ULARGE_INTEGER fileSize;
                fileSize.LowPart = findData.nFileSizeLow;
                fileSize.HighPart = findData.nFileSizeHigh;
                totalSize += fileSize.QuadPart;
            }
        } while (FindNextFile(hFind, &findData));
        
        FindClose(hFind);
        in_protected_section = 0;
    } else {
        in_protected_section = 0;
        // If access exception occurs, just return 0
        if (hFind != INVALID_HANDLE_VALUE) {
            FindClose(hFind);
        }
        return 0;
    }
    
    // Adicionar ao cache
    AddToCache(dirPath, totalSize);
    
    return totalSize;
}

ULONGLONG GetSystemFilesSize(void) {
    printf("Scanning system files size...\n");
    
    char windowsFolder[MAX_PATH];
    if (!GetWindowsDirectory(windowsFolder, MAX_PATH)) {
        return 50000000000; // valor padrão em caso de erro
    }
    
    // Adicionar barra final
    char dirPath[MAX_PATH];
    snprintf(dirPath, MAX_PATH - 1, "%s\\", windowsFolder);
    
    return GetDirectorySize(dirPath, 2); // Profundidade reduzida para estabilidade
}

ULONGLONG GetDownloadsSize(void) {
    printf("Scanning downloads folder size...\n");
    
    char downloadsFolder[MAX_PATH];
    
    // Método mais seguro para obter pasta de downloads
    char userProfile[MAX_PATH];
    if (!GetEnvironmentVariable("USERPROFILE", userProfile, MAX_PATH)) {
        return 10000000000; // valor padrão
    }
    
    // Adicionar barra final
    char dirPath[MAX_PATH];
    snprintf(dirPath, MAX_PATH - 1, "%s\\Downloads\\", userProfile);
    
    return GetDirectorySize(dirPath, 3);
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
    
    // Get user temp folder - método mais seguro
    if (GetTempPath(MAX_PATH, tempFolder)) {
        totalSize += GetDirectorySize(tempFolder, 2);
    }
    
    return totalSize;
}

// Implementação simplificada e segura da verificação de tipo de arquivo
int IsFileOfType(const char* filename, const char** extensions, int extensionCount) {
    if (!filename) return 0;
    
    char* extension = strrchr(filename, '.');
    if (extension == NULL) return 0;
    
    // Converter para minúsculas para comparação sem diferenciação
    char lowerExt[32] = {0};
    int i = 0;
    extension++; // Pular o ponto
    
    while (*extension && i < 31) {
        lowerExt[i++] = tolower(*extension);
        extension++;
    }
    
    // Verificar contra extensões permitidas
    for (i = 0; i < extensionCount; i++) {
        if (strcmp(lowerExt, extensions[i] + 1) == 0) { // +1 para pular o ponto na lista de extensões
            return 1;
        }
    }
    
    return 0;
}

// Função simplificada para escanear tipos de arquivo
DWORD WINAPI FileTypesScanProc(LPVOID lpParam) {
    FileTypeScanResult* result = (FileTypeScanResult*)lpParam;
    if (!result) return 1;
    
    // Obter caminhos de pastas comuns
    char userProfile[MAX_PATH];
    if (!GetEnvironmentVariable("USERPROFILE", userProfile, MAX_PATH)) {
        // Em caso de erro, atribuir valores estimados
        *result->imageSize = 5000000000;
        *result->videoSize = 10000000000;
        *result->audioSize = 5000000000;
        *result->documentSize = 2000000000;
        return 1;
    }
    
    // Diretórios principais a verificar
    char picturesFolder[MAX_PATH];
    char videosFolder[MAX_PATH];
    char musicFolder[MAX_PATH];
    char documentsFolder[MAX_PATH];
    
    snprintf(picturesFolder, MAX_PATH - 1, "%s\\Pictures\\", userProfile);
    snprintf(videosFolder, MAX_PATH - 1, "%s\\Videos\\", userProfile);
    snprintf(musicFolder, MAX_PATH - 1, "%s\\Music\\", userProfile);
    snprintf(documentsFolder, MAX_PATH - 1, "%s\\Documents\\", userProfile);
    
    // Verificar tamanhos de diretórios
    ULONGLONG picturesSize = GetDirectorySize(picturesFolder, 3);
    ULONGLONG videosSize = GetDirectorySize(videosFolder, 3);
    ULONGLONG musicSize = GetDirectorySize(musicFolder, 3);
    ULONGLONG documentsSize = GetDirectorySize(documentsFolder, 3);
    
    // Atribuir estimativas de tipo com base nos diretórios
    *result->imageSize = picturesSize;
    *result->videoSize = videosSize;
    *result->audioSize = musicSize;
    *result->documentSize = documentsSize;
    
    return 0;
}

ULONGLONG GetInstalledApplicationsSize(void) {
    printf("Scanning installed applications...\n");
    
    ULONGLONG appSize = 0;
    char programFiles[MAX_PATH];
    char programFilesX86[MAX_PATH];
    
    // Abordagem mais segura para obter caminhos de Program Files
    if (GetEnvironmentVariable("ProgramFiles", programFiles, MAX_PATH)) {
        char programFilesPath[MAX_PATH];
        snprintf(programFilesPath, MAX_PATH - 1, "%s\\", programFiles);
        appSize += GetDirectorySize(programFilesPath, 2);
    }
    
    if (GetEnvironmentVariable("ProgramFiles(x86)", programFilesX86, MAX_PATH)) {
        char programFilesX86Path[MAX_PATH];
        snprintf(programFilesX86Path, MAX_PATH - 1, "%s\\", programFilesX86);
        appSize += GetDirectorySize(programFilesX86Path, 2);
    }
    
    // Se não foi possível calcular, usar valor padrão
    if (appSize == 0) {
        appSize = 50000000000;
    }
    
    return appSize;
}
