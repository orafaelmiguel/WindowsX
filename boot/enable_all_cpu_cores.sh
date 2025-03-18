#!/bin/bash

echo "Enabling all CPU cores at boot..."

CPU_CORES=$(powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \
    "(Get-CimInstance -ClassName Win32_Processor).NumberOfLogicalProcessors")

echo "Detected $CPU_CORES CPU cores."

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \
    "reg add 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager' /v NumProcs /t REG_DWORD /d $CPU_CORES"

CHECK_CORES=$(powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \
    "(Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager' -Name NumProcs).NumProcs")

if [[ "$CHECK_CORES" -eq "$CPU_CORES" ]]; then
    echo "All CPU cores enabled successfully."
else
    echo "Failed to enable all CPU cores."
fi
