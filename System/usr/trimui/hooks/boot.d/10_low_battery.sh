#!/bin/sh
# Boot Hook: Low battery warning
# Shows warning if battery is below threshold at boot

THRESHOLD=15
BAT=$(cat /sys/class/power_supply/axp20x-battery/capacity 2>/dev/null || echo 100)

if [ "$BAT" -le "$THRESHOLD" ] 2>/dev/null; then
    /mnt/SDCARD/System/bin/infoscreen.sh -m "Low battery: ${BAT}% - Charge soon!" -t 5 2>/dev/null
fi
