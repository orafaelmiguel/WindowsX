#!/bin/sh

echo "Optimizing TCP/IP..."

powershell.exe -Command "netsh int tcp set global ecncapability=enabled"
powershell.exe -Command "netsh int tcp set global nonsackrttresiliency=disabled"
powershell.exe -Command "netsh int tcp set global autotuninglevel=highlyrestricted"

# RSS ??????????????? plz work
powershell.exe -Command "netsh int tcp set global rss=enabled"
powershell.exe -Command "netsh int tcp set global initialRto=3000"
powershell.exe -Command "netsh int tcp set supplemental custom congestionprovider=ctcp"
powershell.exe -Command "netsh int tcp set heuristics disabled"

echo "Restarting network adapter to apply changes..."
powershell.exe -Command "Restart-NetAdapter -Name '*' -Confirm:$false"

echo "TCP/IP optimization complete!"
