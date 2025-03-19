Write-Host "Optimizing TCP/IP..."

netsh int tcp set global ecncapability=enabled
netsh int tcp set global nonsackrttresiliency=disabled
netsh int tcp set global autotuninglevel=highlyrestricted
netsh int tcp set global rss=enabled
netsh int tcp set global initialRto=3000
netsh int tcp set supplemental custom congestionprovider=ctcp
netsh int tcp set heuristics disabled

Write-Host "Restarting active network adapters to apply changes..."
# I swear to god if this doesn't work this time...
Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Restart-NetAdapter -Confirm:$False

netsh int tcp show global

Write-Host "TCP/IP optimization complete!"