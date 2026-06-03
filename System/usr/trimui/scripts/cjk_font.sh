#!/bin/sh
# CrossMix-OS CJK Font Support
# Configures RetroArch to use a CJK-capable font for Asian game titles.
# DroidSansFallback is included in many distros and covers CJK.
# Usage: sh cjk_font.sh [install|remove]

set -u
RA_CFG="/mnt/SDCARD/RetroArch/retroarch.cfg"
FONT_DIR="/mnt/SDCARD/RetroArch/.retroarch/assets/pkg"
FONT_FILE="$FONT_DIR/DroidSansFallback.ttf"

ACTION="${1:-install}"

case "$ACTION" in
  install)
    mkdir -p "$FONT_DIR"

    # Check if font already exists
    if [ -f "$FONT_FILE" ]; then
        echo "CJK font already installed."
    else
        echo "Attempting to locate CJK font..."
        # Common locations for CJK fonts on Linux/Embedded
        for candidate in \
            /usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf \
            /usr/share/fonts/truetype/wqy/wqy-microhei.ttc \
            /usr/share/fonts/noto/NotoSansCJK-Regular.ttc \
            /usr/share/fonts/truetype/unifont/unifont.ttf; do
            if [ -f "$candidate" ]; then
                cp "$candidate" "$FONT_FILE"
                echo "Copied: $candidate → $FONT_FILE"
                break
            fi
        done
    fi

    if [ -f "$FONT_FILE" ]; then
        # Set RetroArch OSD message font
        sed -i 's|video_font_path = .*|video_font_path = "'"$FONT_FILE"'"|' "$RA_CFG"
        echo "CJK font enabled in RetroArch config."
        echo "Game titles in Chinese/Japanese/Korean will now display correctly."
    else
        echo "WARNING: No CJK font found on device."
        echo "Place a CJK .ttf font at: $FONT_FILE"
    fi
    ;;

  remove)
    sed -i 's|video_font_path = .*|video_font_path = ""|' "$RA_CFG"
    rm -f "$FONT_FILE"
    echo "CJK font disabled."
    ;;

  *)
    echo "Usage: sh cjk_font.sh [install|remove]"
    ;;
esac
