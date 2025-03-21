Write-Output "Disabling hibernation..."

powercfg -h off

$HIBERNATION_STATUS = powercfg /query | Select-String "Hibernation"

if (-not $HIBERNATION_STATUS) {
    Write-Output "Hibernation successfully disabled."
} else {
    Write-Output "Failed to disable hibernation."
}
