#!/bin/sh
# Boot Hook: Run first-time setup once after install/update
# Checks version against last setup run, re-runs on update

FLAG="/mnt/SDCARD/System/var/.setup_done"
CUR_VER=$(cat /mnt/SDCARD/System/usr/trimui/crossmix-version.txt 2>/dev/null || echo "0")
LAST_VER=$(cat "$FLAG" 2>/dev/null || echo "0")

if [ "$CUR_VER" != "$LAST_VER" ]; then
    echo "Running first-time setup for $CUR_VER..."
    sh /mnt/SDCARD/System/usr/trimui/scripts/setup.sh 2>/dev/null
    echo "$CUR_VER" > "$FLAG"
fi
