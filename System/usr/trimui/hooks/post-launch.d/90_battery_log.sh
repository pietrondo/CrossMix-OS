#!/bin/sh
# Hook: Log battery level after game session
# Stores in both crossmix.log and SQLite history for trend analysis

BAT=$(cat /sys/class/power_supply/axp20x-battery/capacity 2>/dev/null || echo "?")
EMU="${HOOK_EMU:-?}"
log_message "battery" "${EMU} end level=${BAT}%"

# SQLite history for trend analysis
DB="/mnt/SDCARD/System/var/battery.db"
mkdir -p "$(dirname "$DB")"
sqlite3 "$DB" "CREATE TABLE IF NOT EXISTS history(ts TEXT, level INTEGER, emu TEXT, event TEXT);" 2>/dev/null
sqlite3 "$DB" "INSERT INTO history VALUES('$(date +%Y-%m-%dT%H:%M:%S)',$BAT,'$EMU','game_end');" 2>/dev/null
