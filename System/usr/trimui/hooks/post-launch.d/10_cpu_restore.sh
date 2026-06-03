#!/bin/sh
# Hook: Restore CPU governor to ondemand after game exits
echo ondemand > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null
log_message "cpu" "governor restored to ondemand"
