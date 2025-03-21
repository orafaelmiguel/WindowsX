#include <stdio.h>
#include <stdlib.h>
#include <windows.h>
#include <shellapi.h>

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
    sei.lpVerb = "runas";  //adm plz
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

int isGitInstalled() {
    return (system("git --version > nul 2>&1") == 0);
}

void runShellScript(const char *script) {
    char command[512];
    sprintf(command, "\"C:\\Program Files\\Git\\bin\\bash.exe\" -c './%s'", script);
    int result = system(command);
}

void runPowerShellScript(const char *script) {
    char command[512];
    sprintf(command, "powershell -ExecutionPolicy Bypass -File \"./%s\"", script);
    int result = system(command);
}


int main() {
    if (!isRunningAsAdmin()) {
        printf("Requesting administrator privileges...\n");
        runAsAdmin();
    }

    printf("Starting Windows 10 Gaming Optimizer... :3n");

    if (!isGitInstalled()) {
        printf("ERROR: Git is not installed. Please install Git first.\n");
        return 1;
    }

    printf("Git found! Running optimizations...\n");

    runPowerShellScript(".././windows/network/protocols.ps1");
    runPowerShellScript(".././windows/boot/check_xmp.ps1");
    runPowerShellScript(".././windows/boot/disable_hibernation.ps1");
    runPowerShellScript(".././windows/boot/enable_all_cpu_cores.ps1");
    runPowerShellScript(".././windows/boot/disable_services_boot.ps1");
    
    runPowerShellScript(".././windows/drivers/update_drivers.ps1");

    // dont forget, run for last because internet disconnect
    runPowerShellScript(".././windows/network/tcp_ip_boost.ps1");

    system("pause");
    return 0;
}