#!/bin/sh
# CrossMix-OS Core Stripper
# Strips debug symbols from RetroArch cores, reducing file size by 30-50%.
# Requires: aarch64-linux-strip (available on CrossMix device)
# Usage: sh core_strip.sh [--dry-run]

set -u
CORES_DIR="/mnt/SDCARD/RetroArch/.retroarch/cores"
DRY_RUN=false
[ "${1:-}" = "--dry-run" ] && DRY_RUN=true

strip_bin="/usr/bin/aarch64-linux-strip"
command -v "$strip_bin" >/dev/null 2>&1 || strip_bin="aarch64-linux-strip"
command -v "$strip_bin" >/dev/null 2>&1 || { echo "ERROR: aarch64-linux-strip not found."; exit 1; }

TOTAL_BEFORE=0
TOTAL_AFTER=0
COUNT=0

echo "Core Stripper — $(date)"
echo "========================="
echo ""

for core in "$CORES_DIR"/*.so; do
    [ -f "$core" ] || continue
    SIZE_BEFORE=$(stat -c%s "$core" 2>/dev/null || wc -c < "$core")
    SIZE_MB=$(awk "BEGIN {printf \"%.1f\", $SIZE_BEFORE/1048576}")

    if [ "$SIZE_MB" = "0.0" ]; then
        # Already stripped or very small
        continue
    fi

    if [ "$DRY_RUN" = "true" ]; then
        echo "  $(basename $core): ${SIZE_MB} MB"
    else
        printf "  Stripping %-40s %5.1f MB → " "$(basename $core)" "$SIZE_MB"
        "$strip_bin" "$core" 2>/dev/null
        SIZE_AFTER=$(stat -c%s "$core" 2>/dev/null || wc -c < "$core")
        SIZE_AFTER_MB=$(awk "BEGIN {printf \"%.1f\", $SIZE_AFTER/1048576}")
        printf "%5.1f MB (saved %d%%)\n" "$SIZE_AFTER_MB" \
            "$(awk "BEGIN {printf \"%.0f\", 100 - ($SIZE_AFTER/$SIZE_BEFORE)*100}")"
    fi

    TOTAL_BEFORE=$((TOTAL_BEFORE + SIZE_BEFORE))
    [ "$DRY_RUN" = "false" ] && TOTAL_AFTER=$((TOTAL_AFTER + SIZE_AFTER))
    COUNT=$((COUNT + 1))
done

echo ""
if [ "$DRY_RUN" = "true" ]; then
    TOTAL_MB=$(awk "BEGIN {printf \"%.0f\", $TOTAL_BEFORE/1048576}")
    echo "Would process $COUNT cores ($TOTAL_MB MB total)"
    echo "Run without --dry-run to strip."
else
    BEFORE_MB=$(awk "BEGIN {printf \"%.0f\", $TOTAL_BEFORE/1048576}")
    AFTER_MB=$(awk "BEGIN {printf \"%.0f\", $TOTAL_AFTER/1048576}")
    SAVED=$((TOTAL_BEFORE - TOTAL_AFTER))
    SAVED_MB=$(awk "BEGIN {printf \"%.0f\", $SAVED/1048576}")
    echo "Stripped $COUNT cores: ${BEFORE_MB} MB → ${AFTER_MB} MB (saved ${SAVED_MB} MB)"
fi
