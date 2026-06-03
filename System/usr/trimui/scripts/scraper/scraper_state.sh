#!/bin/sh
# CrossMix-OS Scraper State Helper
# Manages per-emulator state files for scraper resume support.
# State files: System/var/scraper_state/<emu>/state.json
# Lock files:  System/var/scraper_state/<emu>/scraper.lock (run lock)
#              System/var/scraper_state/<emu>/state.write.lock (write serialization)

set -u

SCRAPER_STATE_DIR="${SCRAPER_STATE_DIR:-/mnt/SDCARD/System/var/scraper_state}"

scraper_state_init() {
    local emu="$1"; mkdir -p "$SCRAPER_STATE_DIR/$emu" 2>/dev/null
    local sf="$SCRAPER_STATE_DIR/$emu/state.json"
    [ -f "$sf" ] && return 0
    printf '{\n  "emu":"%s",\n  "started_at":"%s",\n  "last_update":"",\n  "completed":[],\n  "failed":[]\n}\n' \
        "$emu" "$(date "+%Y-%m-%d %H:%M:%S")" > "$sf"
}

scraper_state_get_completed() {
    local emu="$1"; local sf="$SCRAPER_STATE_DIR/$emu/state.json"
    [ -f "$sf" ] || { printf '[]\n'; return; }
    jq -r '.completed[]' "$sf" 2>/dev/null
}

scraper_state_mark_completed() {
    local emu="$1"; local rom="$2"
    local sf="$SCRAPER_STATE_DIR/$emu/state.json"
    local lock="$SCRAPER_STATE_DIR/$emu/state.write.lock"
    mkdir "$lock" 2>/dev/null || return 1
    local tmp="$SCRAPER_STATE_DIR/$emu/state.json.tmp.$$"
    jq --arg rom "$rom" --arg ts "$(date "+%Y-%m-%d %H:%M:%S")" \
       '.completed += [$rom] | .last_update = $ts' "$sf" > "$tmp" && mv -f "$tmp" "$sf"
    rmdir "$lock" 2>/dev/null; return 0
}

scraper_state_mark_failed() {
    local emu="$1"; local rom="$2"; local reason="${3:-unknown}"
    local sf="$SCRAPER_STATE_DIR/$emu/state.json"
    local lock="$SCRAPER_STATE_DIR/$emu/state.write.lock"
    mkdir "$lock" 2>/dev/null || return 1
    local tmp="$SCRAPER_STATE_DIR/$emu/state.json.tmp.$$"
    jq --arg rom "$rom" --arg reason "$reason" --arg ts "$(date "+%Y-%m-%d %H:%M:%S")" \
       '.failed += [{"rom":$rom,"reason":$reason,"ts":$ts}] | .last_update = $ts' \
       "$sf" > "$tmp" && mv -f "$tmp" "$sf"
    rmdir "$lock" 2>/dev/null; return 0
}

scraper_state_lock() {
    local emu="$1"; local lock="$SCRAPER_STATE_DIR/$emu/scraper.lock"
    if mkdir "$lock" 2>/dev/null; then echo $$ > "$lock/pid"; return 0; fi
    # stale lock check (>24h)
    if [ -f "$lock/pid" ]; then
        local age=$(($(date +%s) - $(stat -c %Y "$lock/pid" 2>/dev/null || printf 0)))
        if [ "$age" -gt 86400 ]; then
            rm -rf "$lock" 2>/dev/null
            if mkdir "$lock" 2>/dev/null; then echo $$ > "$lock/pid"; return 0; fi
        fi
    fi
    return 1
}

scraper_state_unlock() { rm -rf "$SCRAPER_STATE_DIR/$1/scraper.lock" 2>/dev/null; }

scraper_state_clear() { rm -f "$SCRAPER_STATE_DIR/$1/state.json"; }
