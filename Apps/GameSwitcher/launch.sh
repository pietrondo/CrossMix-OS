#!/bin/sh
# CrossMix-OS Game Switcher — Quick-switch between recent games
# Uses getkey.sh for D-pad navigation through recentlist.json

set -u
. /mnt/SDCARD/System/usr/trimui/scripts/env.sh

RECENT="/mnt/SDCARD/Roms/recentlist.json"
GETKEY="/mnt/SDCARD/System/usr/trimui/scripts/getkey.sh"
[ -f "$RECENT" ] || { infoscreen.sh -m "No recent games." -t 2; exit 0; }

TOTAL=$(jq '. | length' "$RECENT" 2>/dev/null || echo 0)
[ "$TOTAL" -eq 0 ] && { infoscreen.sh -m "No recent games." -t 2; exit 0; }
MAX=$((TOTAL < 10 ? TOTAL : 10))

# Build menu array
IDX=0
while [ $IDX -lt $MAX ]; do
    LABEL=$(jq -r ".[$IDX].label" "$RECENT")
    printf "  %s\n" "$LABEL"
    IDX=$((IDX + 1))
done | /mnt/SDCARD/System/bin/text_viewer -t "Game Switcher - D-pad to select, A=switch, B=cancel" -f 15 &
TV_PID=$!
sleep 1

# Navigate with D-pad
SEL=0
while true; do
    # Highlight current selection
    kill -USR1 "$TV_PID" 2>/dev/null  # attempt to scroll, may not work
    BUTTON=$("$GETKEY" "UP DOWN A B" 2>/dev/null)
    case "$BUTTON" in
        UP)    SEL=$((SEL > 0 ? SEL - 1 : MAX - 1));;
        DOWN)  SEL=$((SEL < MAX - 1 ? SEL + 1 : 0));;
        A)
            kill "$TV_PID" 2>/dev/null
            GAME_PATH=$(jq -r ".[$SEL].rompath" "$RECENT")
            GAME_LAUNCHER=$(jq -r ".[$SEL].launch" "$RECENT")
            GAME_LABEL=$(jq -r ".[$SEL].label" "$RECENT")
            [ "$GAME_PATH" = "null" ] && { infoscreen.sh -m "Invalid selection." -t 2; exit 1; }
            infoscreen.sh -m "Switching to $GAME_LABEL..." -t 1
            exec sh /mnt/SDCARD/Apps/GameSwitcher/switch.sh "$GAME_PATH" "$GAME_LAUNCHER"
            ;;
        B)
            kill "$TV_PID" 2>/dev/null
            exit 0
            ;;
    esac
done
