#include <stdio.h>
#include <stdlib.h>
#include <windows.h>
#include <shellapi.h>

#define LOG_DIR "logs"
#define LOG_FILE "./logs/intel_optimization.log"

int isRunningAsAdmin() {
    BOOL isAdmin = FALSE;
    HANDLE hToken = NULL;
    
    if (OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &hToken)) {
        TOKEN_ELEVATION elevation;
        DWORD size;
        
        if (GetTokenInformation(hToken, TokenElevation, &elevation, sizeof(elevation), &size)) {
            isAdmin = elevation.TokenIsElevated;
        }
        CloseHandle(hToken);
    }
    
    return isAdmin;
}

void runAsAdmin() {
    char exePath[MAX_PATH];
    GetModuleFileName(NULL, exePath, MAX_PATH);

    SHELLEXECUTEINFO sei = { sizeof(SHELLEXECUTEINFO) };
    sei.lpVerb = "runas";  // Pede execução como administrador
    sei.lpFile = exePath;
    sei.hwnd = NULL;
    sei.nShow = SW_NORMAL;
    sei.fMask = SEE_MASK_NOCLOSEPROCESS;

    if (!ShellExecuteEx(&sei)) {
        printf("Failed to request administrator privileges.\n");
        exit(1);
    }

    exit(0);
}

void createLogDir() {
    CreateDirectory(LOG_DIR, NULL);
}

void logMessage(const char *message) {
    FILE *logFile = fopen(LOG_FILE, "a");
    if (logFile) {
        fprintf(logFile, "[%s] %s\n", __TIMESTAMP__, message);
        fclose(logFile);
    }
}

void runPowerShellScript(const char *script) {
    char command[512];
    sprintf(command, "\"C:\\Program Files\\Git\\bin\\bash.exe\" -c 'powershell -ExecutionPolicy Bypass -File .\\intel\\bin\\%s'", script);
    int result = system(command);

    if (result == 0) {
        logMessage("Executed successfully:");
        logMessage(script);
    } else {
        logMessage("ERROR executing:");
        logMessage(script);
    }
}

int main() {
    if (!isRunningAsAdmin()) {
        printf("Requesting administrator privileges...\n");
        runAsAdmin();
    }

    printf("Starting Intel CPU Optimization...\n");
    createLogDir();
    logMessage("=== Starting Intel CPU Optimization Process ===");

    runPowerShellScript("acpi_adjust.ps1");
    runPowerShellScript("cpu_virtual_memory.ps1");
    runPowerShellScript("disable_oscillations_clock.ps1");
    runPowerShellScript("intel_get_xtu.ps1");

    logMessage("=== Intel CPU Optimization Process Completed ===");
    printf("Intel optimization completed! Check logs in 'logs/' folder.\n");

    system("pause");
    return 0;
}
