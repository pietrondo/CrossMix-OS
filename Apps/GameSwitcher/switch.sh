#!/bin/sh
# CrossMix-OS Game Switcher — Core switch logic
# Saves current state, kills RetroArch, launches target game immediately.
# Usage: sh switch.sh <rom_path> <launcher_path>

set -u
TARGET_ROM="$1"
TARGET_LAUNCHER="$2"

# 1. Log the switch
. /mnt/SDCARD/System/usr/trimui/scripts/common_functions.sh 2>/dev/null || true
log_message "switcher" "switch to $(basename "$TARGET_ROM")"

# 2. Cleanly exit current RetroArch (UDP QUIT → savestate_auto_save triggers)
RA_PID=$(pgrep -f ra64.trimui 2>/dev/null)
if [ -n "$RA_PID" ]; then
    echo -n "QUIT" | netcat -u -w1 127.0.0.1 55355 2>/dev/null
    for i in 1 2 3 4 5; do
        sleep 1
        kill -0 "$RA_PID" 2>/dev/null || break
    done
    kill -0 "$RA_PID" 2>/dev/null && kill "$RA_PID" 2>/dev/null
    sleep 1
fi

# 3. Also write cmd_to_run.sh for resume-at-boot compatibility
mkdir -p /mnt/SDCARD/trimui/app
cat > /tmp/cmd_to_run.sh << EOF
#!/bin/sh
cd /mnt/SDCARD
"$TARGET_LAUNCHER" "$TARGET_ROM" &
EOF
chmod +x /tmp/cmd_to_run.sh 2>/dev/null
cp -f /tmp/cmd_to_run.sh /mnt/SDCARD/trimui/app/cmd_to_run.sh 2>/dev/null

# 4. Launch the target game directly (immediate switch)
cd /mnt/SDCARD
exec "$TARGET_LAUNCHER" "$TARGET_ROM"
