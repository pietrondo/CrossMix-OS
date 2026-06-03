#!/bin/sh
# CrossMix-OS Scraper Master — orchestrates parallel scraping via xargs -P.
# Usage: scrap_master.sh <emu> [rom_name]

set -u
EMU="$1"; SINGLE="${2:-}"
. /mnt/SDCARD/System/usr/trimui/scripts/env.sh
. /mnt/SDCARD/System/usr/trimui/scripts/scraper/scraper_state.sh

# ── workers count ──
CFG=/mnt/SDCARD/System/etc/scraper.json
userSS=$(jq -r '.screenscraper_username' "$CFG")
w=$(jq -r '.scraper_workers // "auto"' "$CFG"); RESUME=$(jq -r '.scraper_resume // true' "$CFG")
if [ "$w" = "auto" ] || [ "$w" = "null" ]; then
    [ -n "$userSS" ] && [ "$userSS" != "null" ] && [ "$userSS" != "" ] && w=4 || w=1
fi
[ "$w" -lt 1 ] && w=1; [ "$w" -gt 8 ] && w=8

# ── lock ──
scraper_state_lock "$EMU" || { echo "ERROR: scraper already running for $EMU"; exit 1; }
cleanup() { scraper_state_unlock "$EMU"; rm -f /tmp/stay_awake; }
trap cleanup EXIT INT TERM
echo 1 >/tmp/stay_awake

# ── ROM list ──
ExtList=$(jq -r '.extlist' "/mnt/SDCARD/Emus/$EMU/config.json")
F=""; if [ -z "$ExtList" ]||[ "$ExtList" = "null" ]; then F="! -name '*.db' ! -name '.gitkeep' ! -name '*.launch'"
else
    el=$(echo "$ExtList"|tr '|' ' '); fi=1
    for e in $el; do [ $fi -eq 1 ] && F="-iname '*.$e'"&&fi=0||F="$F -o -iname '*.$e'"; done
    F="! -name '*.db' ! -name '.gitkeep' ! -name '*.launch' -a ( $F )"
fi
RF=""; [ -n "$SINGLE" ] && SINGLE_ESC="*$(echo "$SINGLE"|sed "s/'/\\\\'/g; s/\[/\\\[/g; s/\]/\\\]/g")*" && RF="-name '*$SINGLE_ESC*'"

IFS='
'; set -f
ALL=$(eval "find /mnt/SDCARD/Roms/$EMU -maxdepth 2 -type f ! -name '.*' ! -name '*.xml' ! -name '*.miyoocmd' ! -name '*.cfg' ! -name '*.db' ! -name '*.png' ! -name '*.state' ! -name '*.srm' ! -path '*/Imgs/*' ! -path '*/.game_config/*' $F $RF" 2>/dev/null)

# ── resume filter ──
scraper_state_init "$EMU"
MISSING=""; SKIPPED=0; [ "$RESUME" = "true" ] || RESUME=false
if [ "$RESUME" = "true" ]; then
    for p in $ALL; do
        n=$(basename "$p")
        if scraper_state_get_completed "$EMU" | grep -qFx "$n"; then SKIPPED=$((SKIPPED+1))
        else MISSING="$MISSING
$p"; fi
    done
else MISSING="$ALL"; fi
MISSING=$(echo "$MISSING"|sed '/^$/d')
TOTAL=$(echo "$MISSING"|wc -l); echo "Workers:$w Resume:$RESUME ROMs:$TOTAL Skipped:$SKIPPED"

# ── dispatch ──
[ "$TOTAL" -gt 0 ] && echo "$MISSING" | xargs -P "$w" -L 1 -I {} \
    sh /mnt/SDCARD/System/usr/trimui/scripts/scraper/scrap_worker.sh "$EMU" "{}"

# ── summary ──
S=0; F=0
[ -f "$SCRAPER_STATE_DIR/$EMU/state.json" ] && {
    S=$(jq '.completed|length' "$SCRAPER_STATE_DIR/$EMU/state.json"); F=$(jq '.failed|length' "$SCRAPER_STATE_DIR/$EMU/state.json")
}
echo "=========================="
echo "Successfully scraped: $S"; echo "Already present: $SKIPPED"
echo "Failed or not found: $F"; echo "=========================="
sync; sleep 1
