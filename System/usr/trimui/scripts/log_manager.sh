#!/bin/sh
# CrossMix-OS Log Manager
# View, clear, or export logs. Entry point for Apps menu.
# Usage: sh log_manager.sh [view|clear|export|stats]

set -u
LOGDIR="/mnt/SDCARD/System/var/logs"
LOG="$LOGDIR/crossmix.log"
ACTION="${1:-stats}"

case "$ACTION" in
  stats)
    echo "CrossMix-OS Log Manager"
    echo "======================="
    if [ -f "$LOG" ]; then
      SIZE=$(du -h "$LOG" | awk '{print $1}')
      LINES=$(wc -l < "$LOG")
      FIRST=$(head -1 "$LOG" | cut -c1-19)
      LAST=$(tail -1 "$LOG" | cut -c1-19)
      echo "Log file : $LOG"
      echo "Size     : $SIZE"
      echo "Lines    : $LINES"
      echo "First    : $FIRST"
      echo "Last     : $LAST"
      echo ""
      echo "Databases:"
      for db in /mnt/SDCARD/System/var/battery.db /mnt/SDCARD/System/var/game_stats.db; do
        [ -f "$db" ] && echo "  $(basename $db): $(du -h "$db" | awk '{print $1}')"
      done
    else
      echo "No logs yet."
    fi
    ;;

  view)
    TAIL="${2:-50}"
    echo "Last $TAIL lines of crossmix.log:"
    echo "================================"
    [ -f "$LOG" ] && tail -"$TAIL" "$LOG" || echo "(empty)"
    ;;

  clear)
    if [ -f "$LOG" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') [log_manager] logs cleared by user" > "$LOG"
      echo "Logs cleared. Old entries removed."
    fi
    ;;

  export)
    sh /mnt/SDCARD/System/usr/trimui/scripts/gather_logs.sh
    ;;

  *)
    echo "Usage: sh log_manager.sh [stats|view|clear|export]"
    echo "  stats  - show log and database sizes"
    echo "  view N - show last N lines (default 50)"
    echo "  clear  - clear crossmix.log"
    echo "  export - create debug tarball (gather_logs)"
    ;;
esac
