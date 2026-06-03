#!/bin/sh
# Hook: Record game session duration
EMU="${HOOK_EMU:-?}"
TIMER="/tmp/game_timer_start_$$"
[ -f "$TIMER" ] || exit 0

START=$(cat "$TIMER")
NOW=$(date +%s)
ELAPSED=$((NOW - START))
MIN=$((ELAPSED / 60))
SEC=$((ELAPSED % 60))
rm -f "$TIMER"

log_message "game_time" "${EMU} session ${MIN}m${SEC}s"

# Store in SQLite for analysis
DB="/mnt/SDCARD/System/var/game_stats.db"
mkdir -p "$(dirname "$DB")"
sqlite3 "$DB" "CREATE TABLE IF NOT EXISTS sessions(ts TEXT, emu TEXT, duration_sec INTEGER);" 2>/dev/null
sqlite3 "$DB" "INSERT INTO sessions VALUES('$(date +%Y-%m-%dT%H:%M:%S)','$EMU',$ELAPSED);" 2>/dev/null
