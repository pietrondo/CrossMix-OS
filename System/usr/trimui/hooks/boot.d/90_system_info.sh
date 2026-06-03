#!/bin/sh
# Boot Hook: Log system info at startup
# Records firmware version, free space, core count at boot

. /mnt/SDCARD/System/usr/trimui/scripts/common_functions.sh 2>/dev/null || true

VER=$(cat /mnt/SDCARD/System/usr/trimui/crossmix-version.txt 2>/dev/null || echo "?")
DISK=$(df -h /mnt/SDCARD | tail -1 | awk '{print $4}')
CORES=$(ls /mnt/SDCARD/RetroArch/.retroarch/cores/*.so 2>/dev/null | wc -l)

log_message "boot" "CrossMix $VER | disk free=$DISK | cores=$CORES"
