#!/bin/sh
# CrossMix-OS Battery Statistics
# Reads SQLite history and displays battery trends.
# Usage: sh battery_stats.sh [days]

set -u
DAYS="${1:-7}"
DB="/mnt/SDCARD/System/var/battery.db"
[ -f "$DB" ] || { echo "No battery data yet. Play a few games first."; exit 1; }

echo "Battery History — last $DAYS days"
echo "================================"
echo ""

sqlite3 -header -column "$DB" "
SELECT
  date(ts) as Date,
  COUNT(*) as Sessions,
  MIN(level) as Min,
  MAX(level) as Max,
  CAST(AVG(level) AS INTEGER) as Avg
FROM history
WHERE ts >= date('now', '-${DAYS} days')
GROUP BY date(ts)
ORDER BY date(ts) DESC
LIMIT $DAYS;
" 2>/dev/null

echo ""
echo "---"
echo "Last 10 entries:"
sqlite3 -header -column "$DB" "
SELECT ts, level, emu, event
FROM history
ORDER BY ts DESC
LIMIT 10;
" 2>/dev/null

# Estimate time remaining based on discharge rate
LAST_TWO=$(sqlite3 "$DB" "SELECT level FROM history ORDER BY ts DESC LIMIT 2;" 2>/dev/null)
if [ "$(echo "$LAST_TWO" | wc -l)" = "2" ]; then
    RATE=$(echo "$LAST_TWO" | awk 'NR==1{a=$1} NR==2{b=$1} END{printf "%.1f", (a-b)}')
    CURRENT=$BAT
    echo ""
    echo "Discharge rate: ${RATE}% per session"
    echo "Estimated sessions remaining: ~$(awk "BEGIN {print int($CURRENT/$RATE)}")"
fi
