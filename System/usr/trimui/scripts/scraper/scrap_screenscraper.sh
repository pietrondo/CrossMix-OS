#!/bin/sh
#echo $0 $*    # for debugging

source /mnt/SDCARD/System/usr/trimui/scripts/common_functions.sh

enable_wifi
check_connection


if [ -z "$1" ]; then
    echo -e "\nusage : scrap_screenscraper.sh emu_folder_name [rom_name]\nexample : scrap_screenscraper.sh SFC\n"
    exit
fi

echo performance >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor


romcount=0
Scrap_Success=0
Scrap_Fail=0
Scrap_notrequired=0

CurrentSystem=$1
CurrentRom="$2"

Screenscraper_information() {
    # clear

    cat <<EOF
==========================================================================================

For better scraping performance set your ScreenScraper account in the file :
/mnt/SDCARD/System/etc/scraper.json
 
Number of downloads per day and speed increases with participation in the 
database or with donations.

All is detailed at : 
https://www.screenscraper.fr/faq.php

Quota counters are reset every day at midnight (French time - UTC+2)

==========================================================================================

EOF

    # read -n 1 -s -r -p "Press A to continue"
    # clear
}

# Function to search on screenscraper with retry logic
search_on_screenscraper() {
    local retry_count=0
    local max_retries=5

    while true; do
        # TODO : managing multithread for users who have it.
        api_result=$(curl -sS "$url")
        Head_api_result=$(echo "$api_result" | head -n 1)

        # Don't check art if max threads for leechers is used
        if echo "$Head_api_result" | grep -q "The maximum threads"; then
            if [ "$retry_count" -ge "$max_retries" ]; then
                echo "The Screenscraper API is too busy for non-users. Please try again later (or register)."
                echo "Press any key to finish"
                # read dummy
                break
            else
                let retry_count++
                echo "Retrying API call ($retry_count / $max_retries)..."
                echo "Registering a Screenscraper account can help !"
                sleep_duration=$((5 + retry_count))
                sleep "$sleep_duration"
            fi
        else
            break # we have a result, we exit
        fi
    done

    # Don't check art if screenscraper is closed
    if echo "$Head_api_result" | grep -q "API closed"; then
        echo -e "${RED}The Screenscraper API is currently down, please try again later.{NONE}"
        let Scrap_Fail++
        # read -n 1 -s -r -p "Press A to exit"
        return
    fi

    # Don't check art after a failed curl request
    if [ -z "$Head_api_result" ]; then
        echo -e "${RED}Request failed${NC}"
        echo "$(date '+%Y-%m-%d %Hh%M') : Request failed for ${romNameTrimmed}"
        let Scrap_Fail++
        return
    fi

    # Don't check art if screenscraper can't find a match
    if echo "$Head_api_result" | grep -q "^Erreur"; then
        echo -e "${RED}No match found${NC}"
        echo "$(date '+%Y-%m-%d %Hh%M') : Couldn't find a match for ${romNameTrimmed}"
        return
    fi

    gameIDSS=$(echo "$api_result" | jq -r '.response.jeu.id')
    if ! [ "$gameIDSS" -eq "$gameIDSS" ] 2>/dev/null; then
        gameIDSS=$(echo "$api_result" | jq -r '.jeu.id')
    fi
}


get_ssSystemID() {
  case $1 in
    ADVMAME)            ssSystemID="75";;    # Mame
    AMIGA)              ssSystemID="64";;    # Commodore Amiga
    AMIGACD)            ssSystemID="134";;   # Commodore Amiga CD
    AMIGACDTV)          ssSystemID="129";;   # Commodore Amiga CD
    ARCADE)             ssSystemID="75";;    # Mame
    ARDUBOY)            ssSystemID="263";;   # Arduboy
    ATARI2600)          ssSystemID="26";;    # Atari 2600
    ATARIST)            ssSystemID="42";;    # Atari ST
    ATOMISWAVE)         ssSystemID="53";;    # Atari ST
    COLECO)             ssSystemID="183";;   # Coleco
    COLSGM)             ssSystemID="183";;   # Coleco
    C64)                ssSystemID="66";;    # Commodore 64
    CPC)                ssSystemID="65";;    # Amstrad CPC
    CPET)               ssSystemID="240";;   # Commodore PET
    CPLUS4)             ssSystemID="99";;    # Commodore Plus 4
    CPS1)               ssSystemID="6";;     # Capcom Play System
    CPS2)               ssSystemID="7";;     # Capcom Play System 2
    CPS3)               ssSystemID="8";;     # Capcom Play System 3
    DAPHNE)             ssSystemID="49";;    # Daphne
    DC)                 ssSystemID="23";;    # dreamcast
    DOS)                ssSystemID="135";;   # DOS
    EASYRPG)            ssSystemID="231";;   # EasyRPG
    EBK)                ssSystemID="93";;    # EBK
    ATARI800)           ssSystemID="43";;    # Atari 800
    CHANNELF)           ssSystemID="80";;    # Fairchild Channel F
    FBA2012)            ssSystemID="75";;    # FBA2012
    FBALPHA)            ssSystemID="75";;    # FBAlpha
    FBNEO)              ssSystemID="";;      # FBNeo (Empty)
    FC)                 ssSystemID="3";;     # NES (Famicom)
    FDS)                ssSystemID="106";;   # Famicom Disk System
    ATARI5200)          ssSystemID="40";;    # Atari 5200
    GB)                 ssSystemID="9";;     # Game Boy
    GBA)                ssSystemID="12";;    # Game Boy Advance
    GBC)                ssSystemID="10";;    # Game Boy Color
    GG)                 ssSystemID="21";;    # Sega Game Gear
    GW)                 ssSystemID="52";;    # Nintendo Game & Watch
    INTELLIVISION)      ssSystemID="115";;   # Intellivision
    JAGUAR)             ssSystemID="27";;    # Atari Jaguar
    LOWRESNX)           ssSystemID="244";;   # LowRes NX
    LUTRO)              ssSystemID="206";;   # Lutro
    LYNX)               ssSystemID="28";;    # Atari Lynx
    MAME)               ssSystemID="75";;    # Mame 2000
    MAME2003PLUS)       ssSystemID="75";;    # Mame 2003
    MAME2010)           ssSystemID="75";;    # Mame 2003
    MBA)                ssSystemID="75";;    # MBA
    MD)                 ssSystemID="1";;     # Sega Genesis (Mega Drive)
    MDMSU)              ssSystemID="1";;     # Sega Genesis (Mega Drive) Hacks
    MEGADUCK)           ssSystemID="90";;    # Megaduck
    MS)                 ssSystemID="2";;     # Sega Master System
    MSX)                ssSystemID="113";;   # MSX
    MSX2)               ssSystemID="116";;   # MSX
    N64)                ssSystemID="14";;    # Nintendo 64
    N64DD)              ssSystemID="122";;   # Nintendo 64DD
    NAOMI)              ssSystemID="56";;    # Sega Naomi
    NDS)                ssSystemID="15";;    # NDS
    NEOCD)              ssSystemID="70";;    # Neo Geo CD
    NEOGEO)             ssSystemID="142";;   # Neo Geo AES
    NGP)                ssSystemID="25";;    # Neo Geo Pocket
    NGC)                ssSystemID="82";;    # Neo-geo Pocket Color
    ODYSSEY)            ssSystemID="104";;   # Videopac / Magnavox Odyssey 2
    OPENBOR)            ssSystemID="214";;   # OpenBOR
    PALMOS)             ssSystemID="219";;   # Palm
    PANASONIC)          ssSystemID="29";;    # 3DO
    PCE)                ssSystemID="31";;    # NEC TurboGrafx-16 / PC Engine
    PCECD)              ssSystemID="114";;   # NEC TurboGrafx-CD
    PC88)               ssSystemID="221";;   # NEC PC-8000 & PC-8800 series / NEC PC-8801
    PCFX)               ssSystemID="72";;    # NEC PC-FX
    PC98)               ssSystemID="208";;   # NEC PC-98 / NEC PC-9801
    PICO)               ssSystemID="234";;   # PICO
    POKEMINI)           ssSystemID="211";;   # PokeMini
    PORTS)              ssSystemID="137";;   # PC Win9X
    PS)                 ssSystemID="57";;    # Sony Playstation
    PSP)                ssSystemID="61";;    # Sony PSP
    PSPMINIS)           ssSystemID="172";;   # Sony PSP Minis
    SATURN)             ssSystemID="22";;    # Sony PSP Minis
    SATELLAVIEW)        ssSystemID="107";;   # Satellaview
    SCUMMVM)            ssSystemID="123";;   # ScummVM
    SEGACD)             ssSystemID="20";;    # Sega CD
    SG1000)             ssSystemID="109";;   # Sega SG-1000
    ATARI7800)          ssSystemID="41";;    # Atari 7800
    SFC)                ssSystemID="4";;     # Super Nintendo (SNES)
    SFCMSU)             ssSystemID="4";;     # Super Nintendo (SNES) hacks
    SGB)                ssSystemID="127";;   # Super Game Boy
    SFX)                ssSystemID="105";;   # NEC PC Engine SuperGrafx
    SUFAMI)             ssSystemID="108";;   # Sufami Turbo
    WS)                 ssSystemID="207";;   # Watara Supervision
    WSC)                ssSystemID="207";;   # Watara Supervision
    SEGA32X)            ssSystemID="19";;    # Sega 32X
    SFX)                ssSystemID="19";;    # Sega 32X
    THOMSON)            ssSystemID="141";;   # Thomson
    TIC)                ssSystemID="222";;   # TIC-80
    UZEBOX)             ssSystemID="216";;   # Uzebox
    VB)                 ssSystemID="11";;    # Virtual Boy
    VECTREX)            ssSystemID="102";;   # Vectrex
    VIC20)              ssSystemID="73";;    # Commodore VIC-20
    VIDEOPAC)           ssSystemID="104";;   # Videopac
    VMU)                ssSystemID="23";;    # Dreamcast VMU (useless)
    WS)                 ssSystemID="45";;    # Bandai WonderSwan & Color
    X68000)             ssSystemID="79";;    # Sharp X68000
    X1)                 ssSystemID="220";;   # Sharp X1
    ZXEIGHTYONE)        ssSystemID="77";;    # Sinclair ZX-81
    ZXS)                ssSystemID="76";;    # Sinclair ZX Spectrum
    *)                  echo "Unknown platform"
  esac
}



saveMetadata=false
# clear

           
echo -e "\n******************************************************************************************"
echo -e "************************************** SCREENSCRAPER *************************************"
echo -e "******************************************************************************************\n\n"

#We check for existing credentials

ScraperConfigFile=/mnt/SDCARD/System/etc/scraper.json
if [ -f "$ScraperConfigFile" ]; then

    config=$(cat $ScraperConfigFile)

    MediaType=$(echo "$config" | jq -r '.Screenscraper_MediaType')

    SelectedRegion=$(echo "$config" | jq -r '.Screenscraper_Region')
    echo "Scraping Target: $CurrentSystem"
    echo "Media Type: $MediaType"
    echo "Current Region: $SelectedRegion"
    userSS=$(echo "$config" | jq -r '.screenscraper_username')
    passSS=$(echo "$config" | jq -r '.screenscraper_password')
    ScrapeInBackground=$(echo "$config" | jq -r '.ScrapeInBackground')
    u=$(echo -n KUZE433CLBLHSZCIOB2AU=== | base32 -d | base64 -d)
    p=$(echo -n KZEFMTCTIRBHMWJQN55GKSCRGFKGOPJ5BI====== | base32 -d | base64 -d)

    # public MediaType="box-2D"

    # Regions order management
    regionsDB="/mnt/SDCARD/System/usr/trimui/scripts/scraper/regions.db"
    RegionOrder=$(sqlite3 $regionsDB "SELECT ss_tree || ';' || ss_fallback FROM regions WHERE ss_nomcourt = '$SelectedRegion';")
    # we split the RegionOrder in each region variable (do not indent)
    IFS=';' read -r Region1 Region2 Region3 Region4 Region5 Region6 Region7 Region8 <<EOF
$RegionOrder
EOF
echo "Region search order: $RegionOrder"


    if [ "$userSS" = "null" ] || [ "$passSS" = "null" ] || [ "$userSS" = "" ] || [ "$passSS" = "" ]; then
        userStored="false"
    else
        userStored="true"
    fi
fi


if [ "$userStored" = "true" ]; then
    echo "screenscraper username: $userSS"
    echo -e "screenscraper password: xxxx (hidden)\n"
else
    echo -e "screenscraper account not configured.\n"
fi


if pgrep "text_viewer" >/dev/null  || [ "$ScrapeInBackground" = "true" ]; then
	NONE=""
	NC=""
	RED=""
	GREEN=""
	YELLOW=""
	PURPLE=""
	CYAN=""
	WHITE=""
	BOLD=""
	UNDERLINE=""
	BLINK=""
fi


# TODO : improve or remove this part (now in options)
if [ "$userStored" = "false" ] && [ "$ScrapeInBackground" = "false" ]; then
	Screenscraper_information
	break
fi



####################################################################################################################################

# ── Delegate to multithreaded master ──
. /mnt/SDCARD/System/usr/trimui/scripts/env.sh
exec /mnt/SDCARD/System/usr/trimui/scripts/scraper/scrap_master.sh "$CurrentSystem" "$CurrentRom"
