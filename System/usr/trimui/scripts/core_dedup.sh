#!/bin/sh
# CrossMix-OS Core Deduplication Tool
# Identifies redundant RetroArch cores and offers safe removal.
# Usage: sh core_dedup.sh [--list|--suggest]

set -u
CORES="/mnt/SDCARD/RetroArch/.retroarch/cores"
ACTION="${1:---list}"

# Redundancy groups: preferred core first, alternatives after
# Format: "group_name|keep_core|remove1,remove2,..."
DUPLICATES="
MAME|mame_libretro.so|mame219_libretro.so,mame2016_libretro.so,mame2015_libretro.so,mame2010_libretro.so,mame2003_plus_libretro.so,mame2003_libretro.so
MESS|mess_libretro.so|mess2015_libretro.so
FBNeo|fbneo_libretro.so|fbalpha_libretro.so,fbalpha2012_libretro.so
Flycast|flycast_libretro.so|flycast_rumble_libretro.so
"

case "$ACTION" in
  --list)
    echo "=== Core Deduplication Analysis ==="
    echo ""
    TOTAL=0
    SAVED=0
    echo "$DUPLICATES" | while IFS='|' read -r group keep remove; do
        [ -z "$group" ] && continue
        echo "Group: $group"
        KEEP_SIZE=$(stat -c%s "$CORES/$keep" 2>/dev/null || echo 0)
        KEEP_MB=$(awk "BEGIN {printf \"%.0f\", $KEEP_SIZE/1048576}")
        echo "  Keep:    $keep (${KEEP_MB} MB)"

        OLD_IFS="$IFS"; IFS=','
        for rm_core in $remove; do
            RM_SIZE=$(stat -c%s "$CORES/$rm_core" 2>/dev/null || echo 0)
            if [ "$RM_SIZE" -gt 0 ]; then
                RM_MB=$(awk "BEGIN {printf \"%.0f\", $RM_SIZE/1048576}")
                echo "  Remove:  $rm_core (${RM_MB} MB)"
            fi
        done
        IFS="$OLD_IFS"
        echo ""
    done
    ;;

  --suggest)
    echo "Suggested cleanup (sd card space saved):"
    echo "========================================="
    SAVED_TOTAL=0
    echo "$DUPLICATES" | while IFS='|' read -r group keep remove; do
        [ -z "$group" ] && continue
        OLD_IFS="$IFS"; IFS=','
        for rm_core in $remove; do
            SIZE=$(stat -c%s "$CORES/$rm_core" 2>/dev/null || echo 0)
            if [ "$SIZE" -gt 0 ]; then
                MB=$(awk "BEGIN {printf \"%.0f\", $SIZE/1048576}")
                echo "  rm cores/$rm_core  # $MB MB"
            fi
        done
        IFS="$OLD_IFS"
    done
    echo ""
    echo "To apply: run the rm commands above, then restart RetroArch."
    ;;

  *)
    echo "Usage: sh core_dedup.sh [--list|--suggest]"
    echo "  --list     Show full analysis with sizes"
    echo "  --suggest  Show commands to free space"
    ;;
esac
