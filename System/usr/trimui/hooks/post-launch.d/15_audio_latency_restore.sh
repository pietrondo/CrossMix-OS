#!/bin/sh
# Hook: Restore original RetroArch audio/latency after game
RA_CFG=/mnt/SDCARD/RetroArch/retroarch.cfg
BACKUP="/tmp/ra_cfg_audio_backup_$$"

[ -f "$BACKUP" ] || exit 0

while IFS= read -r line; do
    key=$(echo "$line" | awk '{print $1}')
    sed -i "s|^${key} = .*|${line}|" "$RA_CFG"
done < "$BACKUP"
rm -f "$BACKUP"
