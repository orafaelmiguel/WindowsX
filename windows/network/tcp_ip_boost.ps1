write-Host ""
Write-Host "--------------------------------------------" -ForegroundColor Yellow
Write-Host "Optimizing TCP/IP..." -ForegroundColor Yellow
Write-Host "--------------------------------------------" -ForegroundColor Yellow
write-Host ""
write-Host ""
write-Host ""
Start-Sleep -Seconds 6

netsh int tcp set global ecncapability=enabled 
Start-Sleep -Seconds 2
netsh int tcp set global nonsackrttresiliency=disabled 
Start-Sleep -Seconds 2
netsh int tcp set global autotuninglevel=highlyrestricted 
Start-Sleep -Seconds 2
netsh int tcp set global rss=enabled 
Start-Sleep -Seconds 2
netsh int tcp set global initialRto=3000 
Start-Sleep -Seconds 2
netsh int tcp set supplemental custom congestionprovider=ctcp
Start-Sleep -Seconds 2
netsh int tcp set heuristics disabled 
write-Host ""

Write-Host "--------------------------------------------" -ForegroundColor Yellow
Write-Host "Restarting active network adapters to apply changes..."
Write-Host "--------------------------------------------" -ForegroundColor Yellow
Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Restart-NetAdapter -Confirm:$False
write-Host ""
write-Host ""
write-Host ""
Start-Sleep -Seconds 2

netsh int tcp show global 

write-Host ""
write-Host ""
write-Host ""

Start-Sleep -Seconds 4

Write-Host "********************************************" -ForegroundColor Green
Write-Host "TCP/IP optimization complete!" -ForegroundColor Green
Write-Host "********************************************" -ForegroundColor Green
write-Host ""
write-Host ""

write-Host "Made by Ocean :3" -ForegroundColor Red

Write-Host "------------------------------------------------------------------------------------------------------------------" -ForegroundColor Magenta
