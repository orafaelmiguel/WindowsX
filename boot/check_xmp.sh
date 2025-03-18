#!/bin/bash

echo "Checking XMP status..."

XMP_STATUS=$(powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \
    "(Get-CimInstance -ClassName Win32_PhysicalMemory | Select-Object -ExpandProperty ConfiguredClockSpeed) -gt 0")

if [[ "$XMP_STATUS" == "True" ]]; then
    echo "XMP is enabled."
else
    echo "XMP is disabled!. Enable it in BIOS for better performance and run script again."
fi


