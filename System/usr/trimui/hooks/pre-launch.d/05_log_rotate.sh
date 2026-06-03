#!/bin/sh
# Hook: Truncate log if too large (runs at boot via pre-launch)
LOG="/mnt/SDCARD/System/var/logs/crossmix.log"
MAX_LINES=5000
[ -f "$LOG" ] || exit 0
LINES=$(wc -l < "$LOG" 2>/dev/null || echo 0)
if [ "$LINES" -gt "$MAX_LINES" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') [log_rotate] truncated (was $LINES lines)" > "$LOG"
fi
