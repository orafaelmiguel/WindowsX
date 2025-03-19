$regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\intelppm\Parameters"

# disable energy CPU control
Set-ItemProperty -Path $regPath -Name "EnableACPI" -Value 0

$regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\intelppm"

Set-ItemProperty -Path $regPath -Name "Start" -Value 0 
Set-ItemProperty -Path $regPath -Name "DisableACPI" -Value 1 

$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power"

Set-ItemProperty -Path $regPath -Name "ActivePowerScheme" -Value "{8c5e7b9c-1f7e-47a6-9d1e-470c51b9ef96}" 

# {8c5e7b9c-1f7e-47a6-9d1e-470c51b9ef96} dont forget this shit
# CPU high performance key