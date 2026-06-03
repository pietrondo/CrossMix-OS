#!/bin/sh
# CrossMix-OS Toolbox — Unified dashboard for system tools
# Touch + button friendly. Uses selector for menu navigation.
# A=select, B=back/exit

export PATH="/mnt/SDCARD/System/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"
SCRIPTS="/mnt/SDCARD/System/usr/trimui/scripts"
. "$SCRIPTS/env.sh"

# Helper: show message then return to menu
show_ok() {
    infoscreen.sh -m "$1" -t 3 2>/dev/null
}

# Helper: show output of a command
show_output() {
    local title="$1"; shift
    "$@" > /tmp/toolbox_output.txt 2>&1
    text_viewer -f 20 -t "$title (B=back)" < /tmp/toolbox_output.txt
    rm -f /tmp/toolbox_output.txt
}

while true; do
    # Build menu with dynamic stats
    DISK=$(df -h /mnt/SDCARD | tail -1 | awk '{print $4}')
    BAT=$(cat /sys/class/power_supply/axp20x-battery/capacity 2>/dev/null || echo "?")
    LOG_LINES=$(wc -l < /mnt/SDCARD/System/var/logs/crossmix.log 2>/dev/null || echo 0)
    VER=$(cat /mnt/SDCARD/System/usr/trimui/crossmix-version.txt 2>/dev/null || echo "?")

    CHOICE=$(selector -fs 120 -t "Toolbox — CrossMix $VER | SD: ${DISK} free | Bat: ${BAT}%" \
        -c \
        "System Health Check" \
        "Export Debug Bundle" \
        "View Logs (last 100 lines)" \
        "Clear All Logs" \
        "Backup Saves & States" \
        "Update Cheat Database" \
        "Core Dedup Analysis" \
        "About Toolbox")

    # B pressed = exit
    [ $? -ne 0 ] && exit 0

    SEL="${CHOICE#*: }"

    case "$SEL" in
        "System Health Check")
            show_output "System Health" sh "$SCRIPTS/doctor.sh"
            ;;

        "Export Debug Bundle")
            sh "$SCRIPTS/gather_logs.sh" > /tmp/toolbox_gather.txt 2>&1
            RESULT=$(tail -1 /tmp/toolbox_gather.txt)
            show_ok "$RESULT"
            rm -f /tmp/toolbox_gather.txt
            ;;

        "View Logs (last 100 lines)")
            if [ -f /mnt/SDCARD/System/var/logs/crossmix.log ]; then
                tail -100 /mnt/SDCARD/System/var/logs/crossmix.log > /tmp/toolbox_log.txt
                text_viewer -f 18 -t "Recent Logs (B=back)" < /tmp/toolbox_log.txt
                rm -f /tmp/toolbox_log.txt
            else
                show_ok "No logs yet."
            fi
            ;;

        "Clear All Logs")
            if [ -f /mnt/SDCARD/System/var/logs/crossmix.log ]; then
                LINES=$(wc -l < /mnt/SDCARD/System/var/logs/crossmix.log)
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] [toolbox] logs cleared ($LINES entries)" > /mnt/SDCARD/System/var/logs/crossmix.log
                show_ok "Cleared $LINES log entries."
            else
                show_ok "No logs to clear."
            fi
            ;;

        "Backup Saves & States")
            if [ -f "$SCRIPTS/save_backup.sh" ]; then
                sh "$SCRIPTS/save_backup.sh" backup > /tmp/toolbox_backup.txt 2>&1
                show_ok "$(tail -1 /tmp/toolbox_backup.txt)"
                rm -f /tmp/toolbox_backup.txt
            else
                show_ok "Backup script not found."
            fi
            ;;

        "Update Cheat Database")
            show_output "Cheats Update" sh "$SCRIPTS/cheats_update.sh" update
            ;;

        "Core Dedup Analysis")
            show_output "Core Dedup" sh "$SCRIPTS/core_dedup.sh" --suggest
            ;;

        "About Toolbox")
            VER=$(cat /mnt/SDCARD/System/usr/trimui/crossmix-version.txt 2>/dev/null || echo "?")
            HOOKS=$(find /mnt/SDCARD/System/usr/trimui/hooks -name "*.sh" 2>/dev/null | wc -l)
            CORES=$(ls /mnt/SDCARD/RetroArch/.retroarch/cores/*.so 2>/dev/null | wc -l)
            infoscreen.sh -m "CrossMix $VER | $HOOKS hooks | $CORES cores | Toolbox v1.0" -t 5 2>/dev/null
            ;;

        *)
            # Empty / cancel
            ;;
    esac
done
