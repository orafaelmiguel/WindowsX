#!bin/bash 

echo "Disabling hibernation... "

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "powercfg -h off"

HIBERNATION_STATUS=$(powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "powercfg /query | Select-String 'Hibernation'")

if [[ -z "$HIBERNATION_STATUS" ]]; then
	echo "Hibernation successfully disabled."
else
	echo "Faile to disable hibernation."
fi
