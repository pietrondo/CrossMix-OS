#!/bin/sh
# Hook: Log battery level after game session
BAT=$(cat /sys/class/power_supply/axp20x-battery/capacity 2>/dev/null || echo "?")
log_message "battery" "${HOOK_EMU:-?} end level=${BAT}%"
