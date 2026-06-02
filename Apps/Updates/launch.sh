#!/bin/sh
set -u
. /mnt/SDCARD/System/usr/trimui/scripts/env.sh

APP_DIR="/mnt/SDCARD/Apps/Updates"
UPDATES_DIR="/mnt/SDCARD/System/updates"

# Scan for update zip on SD card
find_update_zip() {
    # Check root first, then System/updates/
    local found
    found=$(find /mnt/SDCARD -maxdepth 1 -name "CrossMix-OS_v*.zip" -print -quit)
    if [ -z "$found" ]; then
        found=$(find /mnt/SDCARD/System/updates -maxdepth 1 -name "CrossMix-OS_v*.zip" -print -quit 2>/dev/null)
    fi
    echo "$found"
}

# Extract version from zip filename
extract_version() {
    echo "$1" | awk -F'_v|\.zip' '{print $2}'
}

# Check if this version is newer than installed
is_newer_version() {
    local update_ver="$1"
    local current_ver
    current_ver=$(cat /mnt/SDCARD/System/usr/trimui/crossmix-version.txt 2>/dev/null || echo "0")
    if [ "$(echo "$update_ver" | tr -d '.')" -gt "$(echo "$current_ver" | tr -d '.')" ]; then
        return 0
    fi
    return 1
}

# Perform the update using existing crossmix_update.sh from the zip
do_update() {
    local zip_file="$1"
    local version="$2"

    /mnt/SDCARD/System/bin/7zz e "$zip_file" "System/usr/trimui/scripts/crossmix_update.sh" -o/tmp -y
    if [ ! -f "/tmp/crossmix_update.sh" ]; then
        infoscreen.sh -m "Failed to extract update script from zip." -k "A" -fs 30
        return 1
    fi

    chmod a+x "/tmp/crossmix_update.sh"

    # Kill preload to prevent conflicts, then run update
    pkill -9 preload.sh 2>/dev/null
    pkill -9 runtrimui.sh 2>/dev/null

    /mnt/SDCARD/System/bin/text_viewer -s /tmp/crossmix_update.sh
}

#################### MAIN ####################

ZIP_FILE=$(find_update_zip)

if [ -n "$ZIP_FILE" ]; then
    VERSION=$(extract_version "$ZIP_FILE")
    CURRENT=$(cat /mnt/SDCARD/System/usr/trimui/crossmix-version.txt 2>/dev/null || echo "unknown")

    if is_newer_version "$VERSION"; then
        button=$(infoscreen.sh -m "CrossMix-OS v$VERSION found on SD card.\n\nCurrent: v$CURRENT\nNew: v$VERSION\n\nPress A to install, B to cancel." -k "A B" -fs 28)
        if [ "$button" = "A" ]; then
            do_update "$ZIP_FILE" "$VERSION"
        fi
    else
        infoscreen.sh -m "CrossMix-OS v$VERSION found, but it is not newer than current v$CURRENT.\n\nNothing to update." -k "A" -fs 28
    fi
else
    # No zip on SD - offer OTA or instructions
    button=$(infoscreen.sh -m "No CrossMix update file found on SD card.\n\nDownload CrossMix-OS_v*.zip from GitHub\nand copy to the root of your SD card.\n\nOr use OTA update (requires WiFi).\n\nPress A to run OTA update, B to exit." -k "A B" -fs 24)

    if [ "$button" = "A" ]; then
        /mnt/SDCARD/Apps/Terminal/launch.sh -e "/mnt/SDCARD/System/usr/trimui/scripts/ota_update.sh"
    fi
fi

# Restart MainUI if it was killed
if ! pgrep runtrimui.sh >/dev/null 2>&1; then
    /usr/trimui/bin/runtrimui.sh &
fi
