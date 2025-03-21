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
    sei.lpVerb = "runas"; //adm plz 
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

void runPowerShellScript(const char *script) {
    char command[512];
    sprintf(command, "powershell -ExecutionPolicy Bypass -File \"./%s\"", script);
    int result = system(command);

    if (result == 0) {
        printf("Executed successfully: %s\n", script);
    } else {
        printf("ERROR executing: %s\n", script);
    }
}

int main() {
    if (!isRunningAsAdmin()) {
        printf("Requesting administrator privileges...\n");
        runAsAdmin();
    }

    printf("Starting Intel CPU Optimization...\n");

    runPowerShellScript(".././intel/acpi_adjust.ps1");
    runPowerShellScript(".././intel/cpu_virtual_memory.ps1");
    runPowerShellScript(".././intel/disable_oscillations_clock.ps1");

    printf("Intel optimization completed! Check logs in 'logs/' folder.\n");

    system("pause");
    return 0;
}