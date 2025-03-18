#!/bin/bash

echo "Starting Windows 10 Optimizer..."

BOOT_DIR="./boot"

SCRIPTS=(
	"boot/check_xmp.sh"
	"boot/disable_hibernation.sh"
	"boot/enable_all_cpu_cores.sh"
	"boot/disable_services_boot.sh"
	"network/tcp_ip_boost.sh"
)

SUCCESS=()
FAILED=()

for script in "${SCRIPTS[@]}"; do
  echo "Running $script..."
  if sh "$script"; then
    SUCCESS+=("$script")
  else
    FAILED+=("$script")
  fi
done

echo "----------------------------------------"
echo "Optimization Summary:"
echo "✅ Successful Scripts:"
for script in "${SUCCESS[@]}"; do
  echo "  - $script"
done

if [ ${#FAILED[@]} -ne 0 ]; then
  echo "❌ Failed Scripts:"
  for script in "${FAILED[@]}"; do
    echo "  - $script"
  done
fi

echo "Windows 10 Optimization Completed!"

