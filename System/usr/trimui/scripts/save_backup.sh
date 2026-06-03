#!/bin/sh
# CrossMix-OS Save Backup & Restore
# Backs up all RetroArch saves, states, and configs.
# Usage: sh save_backup.sh [backup|restore|list]

set -u
BACKUP_DIR="/mnt/SDCARD/System/var/backups"
SAVES="/mnt/SDCARD/RetroArch/.retroarch/saves"
STATES="/mnt/SDCARD/RetroArch/.retroarch/states"
CONFIGS="/mnt/SDCARD/RetroArch/.retroarch/config"
CHEATS="/mnt/SDCARD/RetroArch/.retroarch/cheats"
ACTION="${1:-list}"

case "$ACTION" in
  backup)
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    DEST="$BACKUP_DIR/saves_$TIMESTAMP"
    mkdir -p "$DEST"

    echo "Backing up RetroArch data..."
    echo "=============================="

    SAVE_COUNT=0; STATE_COUNT=0; CFG_COUNT=0; CHEAT_COUNT=0

    if [ -d "$SAVES" ]; then
        cp -r "$SAVES" "$DEST/saves" 2>/dev/null
        SAVE_COUNT=$(find "$DEST/saves" -type f | wc -l)
    fi

    if [ -d "$STATES" ]; then
        cp -r "$STATES" "$DEST/states" 2>/dev/null
        STATE_COUNT=$(find "$DEST/states" -type f | wc -l)
    fi

    if [ -d "$CONFIGS" ]; then
        cp -r "$CONFIGS" "$DEST/config" 2>/dev/null
        CFG_COUNT=$(find "$DEST/config" -type f | wc -l)
    fi

    if [ -d "$CHEATS" ]; then
        cp -r "$CHEATS" "$DEST/cheats" 2>/dev/null
        CHEAT_COUNT=$(find "$DEST/cheats" -type f | wc -l)
    fi

    # Create tarball for easy transfer
    TARBALL="$BACKUP_DIR/saves_$TIMESTAMP.tar.gz"
    tar -czf "$TARBALL" -C "$DEST" . 2>/dev/null
    rm -rf "$DEST"

    SIZE=$(du -h "$TARBALL" | awk '{print $1}')
    echo ""
    echo "Backup complete: saves_$TIMESTAMP.tar.gz ($SIZE)"
    echo "  $SAVE_COUNT saves, $STATE_COUNT states, $CFG_COUNT configs, $CHEAT_COUNT cheat files"
    echo "  Location: $TARBALL"
    echo "  Copy to PC for safekeeping."

    # Log
    . /mnt/SDCARD/System/usr/trimui/scripts/common_functions.sh 2>/dev/null || true
    log_message "backup" "created saves_$TIMESTAMP.tar.gz ($SIZE, $((SAVE_COUNT + STATE_COUNT)) files)"
    ;;

  restore)
    # Find latest backup
    LATEST=$(ls -t "$BACKUP_DIR"/saves_*.tar.gz 2>/dev/null | head -1)
    if [ -z "$LATEST" ]; then
        echo "No backups found in $BACKUP_DIR"
        echo "Run 'sh save_backup.sh backup' first."
        exit 1
    fi

    echo "Restoring from: $(basename "$LATEST")"
    echo "=============================="
    TMP=$(mktemp -d)
    tar -xzf "$LATEST" -C "$TMP" 2>/dev/null

    [ -d "$TMP/saves" ] && cp -r "$TMP/saves"/* "$SAVES/" 2>/dev/null && echo "  Saves restored."
    [ -d "$TMP/states" ] && cp -r "$TMP/states"/* "$STATES/" 2>/dev/null && echo "  States restored."
    [ -d "$TMP/config" ] && cp -r "$TMP/config"/* "$CONFIGS/" 2>/dev/null && echo "  Configs restored."
    [ -d "$TMP/cheats" ] && cp -r "$TMP/cheats"/* "$CHEATS/" 2>/dev/null && echo "  Cheats restored."

    rm -rf "$TMP"
    echo "Restore complete."
    ;;

  list)
    echo "Save Backups:"
    echo "============="
    if [ -d "$BACKUP_DIR" ]; then
        for f in "$BACKUP_DIR"/saves_*.tar.gz; do
            [ -f "$f" ] || continue
            SIZE=$(du -h "$f" | awk '{print $1}')
            NAME=$(basename "$f" .tar.gz)
            echo "  $NAME ($SIZE)"
        done
    else
        echo "  (no backups yet)"
    fi
    ;;

  *)
    echo "Usage: sh save_backup.sh [backup|restore|list]"
    echo "  backup  - Create backup tarball of all saves/states/configs"
    echo "  restore - Restore from latest backup"
    echo "  list    - Show existing backups"
    ;;
esac
