#!/bin/sh
# Boot Hook: Auto-backup saves every 7 days
# Creates a backup tarball of all RetroArch saves/states/configs

FLAG="/mnt/SDCARD/System/var/.last_backup"
NOW=$(date +%s)
LAST=$(cat "$FLAG" 2>/dev/null || echo 0)
INTERVAL=$((7 * 86400))  # 7 days

if [ $((NOW - LAST)) -ge $INTERVAL ]; then
    if [ -f /mnt/SDCARD/System/usr/trimui/scripts/save_backup.sh ]; then
        sh /mnt/SDCARD/System/usr/trimui/scripts/save_backup.sh backup >/dev/null 2>&1
        echo "$NOW" > "$FLAG"
    fi
fi
