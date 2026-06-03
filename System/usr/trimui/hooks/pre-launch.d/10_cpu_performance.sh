#!/bin/sh
# Hook: Set CPU governor to performance before launching a game
echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null
log_message "cpu" "governor set to performance"
