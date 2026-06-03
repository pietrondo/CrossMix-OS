#!/bin/sh
# CrossMix-OS First Boot & Post-Install Setup
# Runs on first boot after fresh install or update.
# Handles permissions, defaults, and optional optimizations.
# Usage: sh setup.sh [--full]

set -u
. /mnt/SDCARD/System/usr/trimui/scripts/env.sh

FULL=false; [ "${1:-}" = "--full" ] && FULL=true

echo "========================================"
echo "  CrossMix-OS Setup"
echo "  $(cat /mnt/SDCARD/System/usr/trimui/crossmix-version.txt 2>/dev/null || echo '?')"
echo "========================================"
echo ""

# 1. Fix hook permissions (critical for hooks system)
echo "[1/6] Fixing hook permissions..."
HOOKS="/mnt/SDCARD/System/usr/trimui/hooks"
for d in boot.d pre-launch.d post-launch.d; do
    [ -d "$HOOKS/$d" ] && chmod +x "$HOOKS/$d"/*.sh 2>/dev/null
done
echo "  Done."

# 2. Create log directory
echo "[2/6] Initializing log system..."
mkdir -p /mnt/SDCARD/System/var/logs /mnt/SDCARD/System/var/scraper_state
echo "  Done."

# 3. Set recommended RetroArch defaults (one-time)
echo "[3/6] Optimizing RetroArch audio..."
RA_CFG=/mnt/SDCARD/RetroArch/retroarch.cfg
if [ -f "$RA_CFG" ]; then
    sed -i 's/audio_resampler = .*/audio_resampler = "sinc"/' "$RA_CFG"
    sed -i 's/audio_resampler_quality = .*/audio_resampler_quality = "3"/' "$RA_CFG"
    sed -i 's/video_frame_delay = .*/video_frame_delay = "2"/' "$RA_CFG"
    echo "  Audio: sinc resampler, quality 3, frame_delay 2"
fi

# 4. Offer to download cheat database (if WiFi available)
echo "[4/6] Checking WiFi..."
IP=$(ip route get 1 2>/dev/null | awk '/src/ {print $NF; exit}')
if [ -n "$IP" ]; then
    echo "  WiFi online."
    if [ "$FULL" = "true" ]; then
        echo "  Downloading cheat database..."
        sh /mnt/SDCARD/System/usr/trimui/scripts/cheats_update.sh update 2>/dev/null
    else
        echo "  Run 'sh cheats_update.sh update' later for cheat DB."
    fi
else
    echo "  WiFi offline. Connect to download cheats."
fi

# 5. Strip core symbols (optional, saves 30-50% space)
echo "[5/7] Core optimization..."
if [ "$FULL" = "true" ]; then
    CORES_COUNT=$(ls /mnt/SDCARD/RetroArch/.retroarch/cores/*.so 2>/dev/null | wc -l)
    echo "  $CORES_COUNT cores detected."
    echo "  Optimizing with aarch64-linux-strip..."
    sh /mnt/SDCARD/System/usr/trimui/scripts/core_strip.sh 2>/dev/null || echo "  Skipped (strip tool unavailable)"
else
    echo "  Run 'sh core_strip.sh' later to strip debug symbols."
fi

# 6. Probe display capabilities (for future display controls)
echo "[6/7] Probing display..."
sh /mnt/SDCARD/System/usr/trimui/scripts/display_probe.sh > /mnt/SDCARD/System/var/display_probe.txt 2>/dev/null
echo "  Results saved to System/var/display_probe.txt"

# 7. Log initial system state
echo "[7/7] Logging system state..."
VER=$(cat /mnt/SDCARD/System/usr/trimui/crossmix-version.txt 2>/dev/null || echo "?")
DISK=$(df -h /mnt/SDCARD | tail -1 | awk '{print $4" free of "$2}')
RAM=$(free -m | awk '/Mem:/ {print $2"MB"}')
. /mnt/SDCARD/System/usr/trimui/scripts/common_functions.sh 2>/dev/null || true
log_message "setup" "first boot complete | version=$VER | disk=$DISK | ram=$RAM"

echo ""
echo "========================================"
echo "  Setup complete."
echo "  $(df -h /mnt/SDCARD | tail -1 | awk '{print "SD: "$4" free"}')"
echo "========================================"
