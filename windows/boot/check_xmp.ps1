Write-Output "Checking XMP status..."

$XMP_STATUS = Get-CimInstance -ClassName Win32_PhysicalMemory | Select-Object -ExpandProperty ConfiguredClockSpeed

if ($XMP_STATUS -gt 0) {
    Write-Output "XMP is enabled."
} else {
    Write-Output "XMP is disabled! Enable it in BIOS for better performance and run script again."
}
