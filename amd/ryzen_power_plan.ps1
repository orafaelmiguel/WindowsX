$adminCheck = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $adminCheck.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Run as a Admnistrator!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "********************************************" -ForegroundColor Cyan
Write-Host "`Applying AMD Ryzen Balanced..." -ForegroundColor Cyan
Write-Host "********************************************" -ForegroundColor Cyan
Write-Host ""
Write-Host ""
Write-Host ""


$powerPlans = powercfg /L

if ($powerPlans -match "00000000-0000-0000-0000-000000000000") {
    Write-Host "--------------------------------------------" -ForegroundColor Green
    Write-Host "AMD Ryzen Balanced is already installed." -ForegroundColor Green
    Write-Host "--------------------------------------------" -ForegroundColor Green
} else {
    Write-Host "--------------------------------------------" -ForegroundColor Yellow
    Write-Host "AMD Ryzen Balanced plan not found, applying Windows plan..." -ForegroundColor Yellow
    Write-Host "--------------------------------------------" -ForegroundColor Yellow
    powercfg /S SCHEME_BALANCED
}

# amd code
powercfg /S 381b4222-f694-41f0-9685-ff5bb260df2e

Write-Host "********************************************" -ForegroundColor Green
Write-Host "[INFO] O plano de energia foi aplicado com sucesso." -ForegroundColor Green
Write-Host "********************************************" -ForegroundColor Green
Write-Host ""

Write-Host "------------------------------------------------------------------------------------------------------------------" -ForegroundColor Magenta
