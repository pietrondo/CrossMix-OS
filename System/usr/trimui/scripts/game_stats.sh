#!/bin/sh
# CrossMix-OS Game Time Statistics
# Shows total play time per emulator and overall.
# Usage: sh game_stats.sh [days]

set -u
DAYS="${1:-30}"
DB="/mnt/SDCARD/System/var/game_stats.db"
[ -f "$DB" ] || { echo "No game time data yet. Play some games first."; exit 1; }

echo "Game Time Statistics — last $DAYS days"
echo "========================================"
sqlite3 -header -column "$DB" "
SELECT
  emu as Emulator,
  COUNT(*) as Sessions,
  SUM(duration_sec)/60 as TotalMin,
  CAST(AVG(duration_sec)/60 AS INTEGER) as AvgMin
FROM sessions
WHERE ts >= date('now', '-${DAYS} days')
GROUP BY emu
ORDER BY TotalMin DESC;
" 2>/dev/null

echo ""
echo "---"
echo "Overall:"
sqlite3 "$DB" "SELECT 'Total: ' || SUM(duration_sec)/60 || ' min across ' || COUNT(*) || ' sessions' FROM sessions WHERE ts >= date('now', '-${DAYS} days');" 2>/dev/null
