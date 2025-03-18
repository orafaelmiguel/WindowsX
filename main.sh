#!/bin/bash

echo "Starting Windows 10 Optimizer..."

BOOT_DIR="./boot"

SCRIPTS=(
	"check_xmp.sh"
	"disable_hibernation.sh"
	"enable_all_cpu_cores.sh"
)

SUCCESS_SCRIPTS=()
FAILED_SCRIPTS=()

for script in "${SCRIPTS[@]}"; do
    SCRIPT_PATH="$BOOT_DIR/$script"

    if [[ -f "$SCRIPT_PATH" ]]; then
        echo "Running $script..."
        bash "$SCRIPT_PATH"

        if [[ $? -eq 0 ]]; then
            SUCCESS_SCRIPTS+=("$script")
            echo "Finished $script"
        else
            FAILED_SCRIPTS+=("$script")
            echo "Error running $script"
        fi
    else
        FAILED_SCRIPTS+=("$script")
        echo "Script $script not found. Skipping..."
    fi
    echo "---------------------------------"
done

echo "Optimization process completed."
echo "---------------------------------"
echo "Successfully executed scripts:"
for script in "${SUCCESS_SCRIPTS[@]}"; do
    echo "   - $script"
done

echo ""
echo "Failed scripts:"
if [[ ${#FAILED_SCRIPTS[@]} -eq 0 ]]; then
    echo "   None! All scripts ran successfully."
else
    for script in "${FAILED_SCRIPTS[@]}"; do
        echo "   - $script"
    done
fi
