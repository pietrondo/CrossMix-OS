#!/bin/sh
# CrossMix-OS Cheats Manager
# Downloads and manages RetroArch cheat database.
# Usage: sh cheats_update.sh [update|list|enable]

set -u
CHEAT_DIR="/mnt/SDCARD/RetroArch/.retroarch/cheats"
CHEAT_ZIP="https://buildbot.libretro.com/assets/frontend/cheats.zip"
CHEAT_CACHE="/tmp/cheats.zip"
ACTION="${1:-update}"

case "$ACTION" in
  update)
    echo "Downloading cheat database..."
    echo "This may take a minute (cheats.zip is ~30MB)."
    echo ""

    . /mnt/SDCARD/System/usr/trimui/scripts/common_functions.sh 2>/dev/null || true
    enable_wifi
    check_connection

    mkdir -p "$CHEAT_DIR"
    rm -rf "$CHEAT_DIR"/*
    wget -q --show-progress "$CHEAT_ZIP" -O "$CHEAT_CACHE"

    if [ $? -eq 0 ] && [ -f "$CHEAT_CACHE" ]; then
        echo "Extracting..."
        unzip -qo "$CHEAT_CACHE" -d "$CHEAT_DIR"
        rm -f "$CHEAT_CACHE"
        COUNT=$(find "$CHEAT_DIR" -name "*.cht" | wc -l)
        echo ""
        echo "Done. $COUNT cheat files installed."
        echo "Cheats will be available in RetroArch Quick Menu during gameplay."
    else
        echo "ERROR: Download failed. Check WiFi connection."
        rm -f "$CHEAT_CACHE"
        exit 1
    fi
    ;;

  list)
    if [ -d "$CHEAT_DIR" ]; then
        echo "Cheat files by platform:"
        echo "======================="
        for d in "$CHEAT_DIR"/*/; do
            [ -d "$d" ] || continue
            COUNT=$(find "$d" -name "*.cht" | wc -l)
            echo "  $(basename $d): $COUNT cheats"
        done
    else
        echo "Cheats not installed. Run: sh cheats_update.sh update"
    fi
    ;;

  *)
    echo "Usage: sh cheats_update.sh [update|list]"
    echo "  update - download and install cheat database"
    echo "  list   - show installed cheat files by platform"
    ;;
esac
