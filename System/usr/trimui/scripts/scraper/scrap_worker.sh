#!/bin/sh
# CrossMix-OS Scraper Worker — processes one ROM.
# Usage: scrap_worker.sh <emu> <rom_path>
# Exit codes: 0=scraped or already done, 1=failed, 2=transient/retryable

set -u
EMU="$1"; ROM_PATH="$2"
. /mnt/SDCARD/System/usr/trimui/scripts/env.sh
. /mnt/SDCARD/System/usr/trimui/scripts/scraper/scraper_state.sh

# ── config ──
CFG=/mnt/SDCARD/System/etc/scraper.json
MediaType=$(jq -r '.Screenscraper_MediaType' "$CFG"); SelectedRegion=$(jq -r '.Screenscraper_Region' "$CFG")
userSS=$(jq -r '.screenscraper_username' "$CFG"); passSS=$(jq -r '.screenscraper_password' "$CFG")
u=$(echo -n KUZE433CLBLHSZCIOB2AU=== | base32 -d | base64 -d)
p=$(echo -n KZEFMTCTIRBHMWJQN55GKSCRGFKGOPJ5BI====== | base32 -d | base64 -d)
DB=/mnt/SDCARD/System/usr/trimui/scripts/scraper/regions.db
RegionOrder=$(sqlite3 "$DB" "SELECT ss_tree||';'||ss_fallback FROM regions WHERE ss_nomcourt='$SelectedRegion';")
IFS=';' read -r R1 R2 R3 R4 R5 R6 R7 R8 <<EOF
$RegionOrder
EOF

# ── system ID ──
get_ssid() { case $1 in
    ADVMAME|ARCADE|MAME|MAME2003PLUS|MAME2010|MBA) ssid="75";;  AMIGA) ssid="64";;
    AMIGACD|AMIGACDTV) ssid="134";;  ARDUBOY) ssid="263";;  ATARI2600) ssid="26";;
    ATARIST) ssid="42";;  ATARI5200) ssid="40";;  ATARI7800) ssid="41";;
    ATARI800) ssid="43";;  ATOMISWAVE) ssid="53";;  C64) ssid="66";;
    CHANNELF) ssid="80";;  COLECO|COLSGM) ssid="183";;  CPC) ssid="65";;
    CPET) ssid="240";;  CPLUS4) ssid="99";;  CPS1) ssid="6";;  CPS2) ssid="7";;
    CPS3) ssid="8";;  DAPHNE) ssid="49";;  DC) ssid="23";;  DOS) ssid="135";;
    EASYRPG) ssid="231";;  EBK) ssid="93";;  FBA2012|FBALPHA) ssid="75";;
    FC) ssid="3";;  FDS) ssid="106";;  GB) ssid="9";;  GBA) ssid="12";;
    GBC) ssid="10";;  GG) ssid="21";;  GW) ssid="52";;  INTELLIVISION) ssid="115";;
    JAGUAR) ssid="27";;  LOWRESNX) ssid="244";;  LUTRO) ssid="206";;
    LYNX) ssid="28";;  MD|MDMSU) ssid="1";;  MEGADUCK) ssid="90";;  MS) ssid="2";;
    MSX) ssid="113";;  MSX2) ssid="116";;  N64) ssid="14";;  N64DD) ssid="122";;
    NAOMI) ssid="56";;  NDS) ssid="15";;  NEOCD) ssid="70";;  NEOGEO) ssid="142";;
    NGP|NGC) ssid="25";;  ODYSSEY|VIDEOPAC) ssid="104";;  OPENBOR) ssid="214";;
    PALMOS) ssid="219";;  PANASONIC) ssid="29";;  PCE) ssid="31";;  PCECD) ssid="114";;
    PC88) ssid="221";;  PCFX) ssid="72";;  PC98) ssid="208";;  PICO) ssid="234";;
    POKEMINI) ssid="211";;  PORTS) ssid="137";;  PS) ssid="57";;  PSP) ssid="61";;
    PSPMINIS) ssid="172";;  SATURN) ssid="22";;  SATELLAVIEW) ssid="107";;
    SCUMMVM) ssid="123";;  SEGACD) ssid="20";;  SEGA32X|SFX) ssid="19";;
    SG1000) ssid="109";;  SFC|SFCMSU) ssid="4";;  SGB) ssid="127";;  SUFAMI) ssid="108";;
    THOMSON) ssid="141";;  TIC) ssid="222";;  UZEBOX) ssid="216";;  VB) ssid="11";;
    VECTREX) ssid="102";;  VIC20) ssid="73";;  WSC|WS) ssid="45";;  X68000) ssid="79";;
    X1) ssid="220";;  ZXEIGHTYONE) ssid="77";;  ZXS) ssid="76";;
    esac; }

# ── search API with retry ──
search_ss() {
    local retry=0 max=5
    while true; do
        result=$(curl -sS "$url")
        head=$(echo "$result" | head -n1)
        if echo "$head"|grep -q "maximum threads"; then
            [ $retry -ge $max ] && { echo "API busy, max retries"; return 2; }
            retry=$((retry+1)); echo "Retry $retry/$max..."; sleep $((5+retry))
        else break; fi
    done
    echo "$head"|grep -q "API closed" && { echo "API down"; return 1; }
    [ -z "$head" ] && { echo "Empty response"; return 1; }
    echo "$head"|grep -q "^Erreur" && { echo "No match"; return 1; }
    gameIDSS=$(echo "$result"|jq -r '.response.jeu.id')
    ! [ "$gameIDSS" -eq "$gameIDSS" ] 2>/dev/null && gameIDSS=$(echo "$result"|jq -r '.jeu.id')
    return 0
}

# ── main ──
romName=$(basename "$ROM_PATH"); romNameNoExt=${romName%.*}
scraper_state_init "$EMU"

# already scraped on disk?
[ -f "/mnt/SDCARD/Imgs/$EMU/$romNameNoExt.png" ] && { echo "already present"; exit 0; }

# already in resume state?
scraper_state_get_completed "$EMU" | grep -qFx "$romName" && { echo "skipped (resume)"; exit 0; }

# clean name for API
tw="$(echo "${romNameNoExt/".nkit"/}" | sed -E 's/(!|&|Disc|Rev|CD[0-9])//g; s| *[[(].*||; s/(\s|-|_)+$//; s|[_ ]|%20|g')"

get_ssid "$EMU"
rs=$(stat -c%s "$ROM_PATH"); [ "$rs" -eq 0 ] && rs=1048576

# search by name
url="https://www.screenscraper.fr/api2/jeuInfos.php?devid=${u%?}&devpassword=${p#??}&softname=crossmix&output=json&ssid=${userSS}&sspassword=${passSS}&sha1=&systemeid=${ssid}&romtype=rom&romnom=${tw}.zip&romtaille=${rs}"
search_ss; sr=$?

# fallback: search by SHA1
if [ $sr -ne 0 ] || ! [ "$gameIDSS" -eq "$gameIDSS" ] 2>/dev/null; then
    [ $rs -gt 419430400 ] && { echo "too big for checksum"; scraper_state_mark_failed "$EMU" "$romName" "too_big"; exit 1; }
    ck=$(sha1sum "$ROM_PATH"|awk '{print $1}')
    url="https://www.screenscraper.fr/api2/jeuInfos.php?devid=${u%?}&devpassword=${p#??}&softname=crossmix&output=json&ssid=${userSS}&sspassword=${passSS}&sha1=${ck}&systemeid=&romtype=rom&romnom=${tw}.zip&romtaille=${rs}"
    search_ss || { scraper_state_mark_failed "$EMU" "$romName" "no_match"; exit 1; }
fi
echo "gameID = $gameIDSS"

# find media
med=$(echo "$result"|jq '.response.jeu.medias')
MediaURL=$(echo "$med"|jq --arg t "$MediaType" --arg r1 "$R1" --arg r2 "$R2" --arg r3 "$R3" --arg r4 "$R4" --arg r5 "$R5" --arg r6 "$R6" --arg r7 "$R7" --arg r8 "$R8" 'map(select(.type==$t))|sort_by(if .region==$r1 then 0 elif .region==$r2 then 1 elif .region==$r3 then 2 elif .region==$r4 then 3 elif .region==$r5 then 4 elif .region==$r6 then 5 elif .region==$r7 then 6 elif .region==$r8 then 7 else 8 end)|.[0].url'|head -n1)

[ -z "$MediaURL" ] || [ "$MediaURL" = "null" ] && { echo "no media found"; scraper_state_mark_failed "$EMU" "$romName" "no_media"; exit 1; }

# download
MediaURL=$(echo "$MediaURL"|sed 's/"$/\&maxwidth=400\&maxheight=580"/;s/"//g')
out="/mnt/SDCARD/Imgs/$EMU/$romNameNoExt.png"; tmp="/tmp/${romNameNoExt}.tmpdl.$$"
mkdir -p "$(dirname "$out")" 2>/dev/null

wget "$MediaURL" -O "$tmp" >/dev/null 2>&1
if [ $? -eq 0 ]; then
    mv -f "$tmp" "$out"
    echo "downloaded: $romNameNoExt"
    [ -d /tmp/trimui_osd/ ] && printf '{"duration":2000,"x":920,"y":330,"message":"","font":"","icon":"%s","fontsize":24}\n' "$out" > /tmp/trimui_osd/osd_toast_msg
    [ -f "$out" ] && { scraper_state_mark_completed "$EMU" "$romName"; exit 0; }
fi
rm -f "$tmp"
scraper_state_mark_failed "$EMU" "$romName" "download_failed"
exit 1
