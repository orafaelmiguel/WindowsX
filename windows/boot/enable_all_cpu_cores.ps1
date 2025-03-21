Write-Output "Enabling all CPU cores at boot..."

$CPU_CORES = (Get-CimInstance -ClassName Win32_Processor).NumberOfLogicalProcessors

Write-Output "Detected $CPU_CORES CPU cores."

$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager"
$registryName = "NumProcs"

Set-ItemProperty -Path $registryPath -Name $registryName -Value $CPU_CORES -Type DWord

$CHECK_CORES = (Get-ItemProperty -Path $registryPath -Name $registryName).NumProcs

if ($CHECK_CORES -eq $CPU_CORES) {
    Write-Output "All CPU cores enabled successfully."
} else {
    Write-Output "Failed to enable all CPU cores."
}
