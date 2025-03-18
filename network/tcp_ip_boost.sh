#!/bin/sh

echo "Optimizing TCP/IP..."

powershell.exe -Command "netsh int tcp set global ecncapability=enabled"
powershell.exe -Command "netsh int tcp set global nonsackrttresiliency=disabled"
powershell.exe -Command "netsh int tcp set global autotuninglevel=highlyrestricted"
powershell.exe -Command "netsh int tcp set global rss=enabled"
powershell.exe -Command "netsh int tcp set global initialRto=3000"
powershell.exe -Command "netsh int tcp set supplemental custom congestionprovider=ctcp"
powershell.exe -Command "netsh int tcp set heuristics disabled"

echo "Restarting active network adapters to apply changes..."
powershell.exe -Command "& {Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Restart-NetAdapter -Confirm:$false}"

powershell.exe -Command "netsh int tcp show global"

echo "TCP/IP optimization complete!"
