$adminCheck = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $adminCheck.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host ""
    Write-Host "[ERROR] Please run this script as Admin!" -ForegroundColor Red
    exit 1
}

Write-Host "********************************************" -ForegroundColor Cyan
Write-Host "[INFO] Starting Network Optimization..." -ForegroundColor Cyan
Write-Host "********************************************" -ForegroundColor Cyan
Write-Host ""
Write-Host ""
Write-Host ""

Write-Host "--------------------------------------------" -ForegroundColor Yellow
Write-Host "[INFO] Disabling NetBIOS over TCP/IP..." -ForegroundColor Yellow
Write-Host "--------------------------------------------" -ForegroundColor Yellow
Write-Host ""

$networkAdapter = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true } | Select-Object -First 1

if ($networkAdapter) {
    $networkAdapter.SetTcpipNetbios(2) | Out-Null
    Write-Host "NetBIOS disabled on interface: $($networkAdapter.Description)" -ForegroundColor Green
} else {
    Write-Host "No network adapter with IP enabled found." -ForegroundColor Red
}
Write-Host ""
Write-Host ""
Write-Host ""

Write-Host "--------------------------------------------" -ForegroundColor Yellow
Write-Host "[INFO] Disabling LLMNR..." -ForegroundColor Yellow
Write-Host "--------------------------------------------" -ForegroundColor Yellow
Write-Host ""

$LLMNRPath = "HKLM:\Software\Policies\Microsoft\Windows NT\DNSClient"
if (!(Test-Path $LLMNRPath)) { 
    New-Item -Path $LLMNRPath -Force | Out-Null 
}
Set-ItemProperty -Path $LLMNRPath -Name "EnableMulticast" -Value 0
Write-Host "LLMNR successfully disabled." -ForegroundColor Green
Write-Host ""
Write-Host ""
Write-Host ""

Write-Host "--------------------------------------------" -ForegroundColor Yellow
Write-Host "[INFO] Disabling SMBv1..." -ForegroundColor Yellow
Write-Host "--------------------------------------------" -ForegroundColor Yellow
Write-Host ""

Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
Disable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol" -NoRestart
Write-Host "SMBv1 successfully disabled." -ForegroundColor Green
Write-Host ""
Write-Host ""
Write-Host ""

$disableIPv6 = $true  
if ($disableIPv6) {
    Write-Host "--------------------------------------------"-ForegroundColor Yellow
    Write-Host "[INFO] Disabling IPv6..." -ForegroundColor Yellow
    Write-Host "--------------------------------------------" -ForegroundColor Yellow
    Write-Host ""

    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 0xFF -PropertyType DWord -Force
    Write-Host "IPv6 successfully disabled." -ForegroundColor Green
}
Write-Host ""
Write-Host ""
Write-Host ""

Write-Host "********************************************" -ForegroundColor Cyan
Write-Host "[INFO] Network Optimization Complete!" -ForegroundColor Cyan
Write-Host "********************************************" -ForegroundColor Cyan
Write-Host ""
