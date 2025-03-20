Write-Output "Stabilizing CPU clocks..."

# disable c-state (can generate higher temperatures)
$regKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Power"
Set-ItemProperty -Path $regKey -Name "CsEnabled" -Value 0
Write-Output "Disabled CPU C-states to avoid frequency scaling oscillations."

powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100
powercfg -setactive SCHEME_CURRENT
Write-Output "Disabled idle state frequency scaling to maintain stable CPU frequency."
$cpuInfo = Get-WmiObject -Class Win32_Processor
$cpuInfo | ForEach-Object { Write-Output "Current CPU frequency: $($_.CurrentClockSpeed) MHz" }

Write-Output "CPU frequency scaling has been adjusted to avoid clock oscillations."
