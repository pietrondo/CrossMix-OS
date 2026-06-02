#!/bin/sh
# CrossMix-Pit Edition - Core Downloader
# Downloads RetroArch cores from christianhaitian/retroarch-cores (aarch64)
# Run on the device to update all cores to latest versions.
#
# Usage: sh download_cores.sh [core1] [core2] ...
#   No args: update all installed cores
#   With args: update only specified cores

set -u
CORES_URL="https://raw.githubusercontent.com/christianhaitian/retroarch-cores/master/aarch64"
DEST="/mnt/SDCARD/RetroArch/.retroarch/cores"
SKIP_SIZE_MB=20

download_core() {
    local name="$1"
    local so_file="${name}.so"
    local zip_url="${CORES_URL}/${so_file}.zip"
    local tmp_zip="/tmp/${so_file}.zip"

    # Check if core exists upstream
    if ! /mnt/SDCARD/System/bin/wget -q --spider "$zip_url" 2>/dev/null; then
        echo "SKIP: $name (not found upstream)"
        return 2
    fi

    echo -n "Downloading $name... "
    if ! /mnt/SDCARD/System/bin/wget -q -O "$tmp_zip" "$zip_url"; then
        echo "FAILED (download error)"
        return 1
    fi

    # Extract
    /mnt/SDCARD/System/bin/7zz x -aoa "$tmp_zip" -o"$DEST" >/dev/null 2>&1
    rm -f "$tmp_zip"

    local sz=$(stat -c%s "$DEST/$so_file" 2>/dev/null || echo 0)
    local sz_mb=$((sz / 1048576))

    if [ "$sz_mb" -gt "$SKIP_SIZE_MB" ]; then
        echo "OK ($sz_mb MB - large, kept as .so)"
    else
        echo "OK ($sz_mb MB)"
    fi
    return 0
}

# Main
if [ $# -gt 0 ]; then
    for core in "$@"; do
        download_core "$core"
    done
else
    updated=0
    skipped=0
    failed=0
    echo "Scanning installed cores..."
    for so in "$DEST"/*.so; do
        [ -f "$so" ] || continue
        name=$(basename "$so" .so)
        download_core "$name"
        case $? in
            0) updated=$((updated + 1)) ;;
            1) failed=$((failed + 1)) ;;
            2) skipped=$((skipped + 1)) ;;
        esac
    done
    echo ""
    echo "Done: $updated updated, $skipped skipped, $failed failed"
fi
