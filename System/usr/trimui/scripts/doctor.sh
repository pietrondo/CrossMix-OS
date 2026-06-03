#!/bin/sh
# CrossMix-OS Doctor — System Health Check
# Validates installation integrity, configs, permissions, and logs.
# Usage: sh doctor.sh [--verbose]

set -u
VERBOSE=false; [ "${1:-}" = "--verbose" ] && VERBOSE=true
PASS=0; FAIL=0; WARN=0
SD="/mnt/SDCARD"

check() {
    local desc="$1"; shift
    if "$@" >/dev/null 2>&1; then
        PASS=$((PASS+1))
        $VERBOSE && echo "  ✅ $desc" || true
    else
        FAIL=$((FAIL+1))
        echo "  ❌ $desc"
    fi
}

warn() {
    local desc="$1"; shift
    if "$@" >/dev/null 2>&1; then
        $VERBOSE && echo "  ✅ $desc" || true
    else
        WARN=$((WARN+1))
        echo "  ⚠️  $desc"
    fi
}

echo "CrossMix-OS Doctor"
echo "=================="
echo ""

# ── Critical files ──
echo "--- Critical Files ---"
check "crossmix-version.txt exists" test -f "$SD/System/usr/trimui/crossmix-version.txt"
check "env.sh exists" test -f "$SD/System/usr/trimui/scripts/env.sh"
check "common_functions.sh exists" test -f "$SD/System/usr/trimui/scripts/common_functions.sh"
check "retroarch.cfg exists" test -f "$SD/RetroArch/retroarch.cfg"
check "crossmix.json valid" jq . "$SD/System/etc/crossmix.json" 2>/dev/null

# ── JSON configs ──
echo ""
echo "--- Config Files ---"
check "scraper.json valid JSON" jq . "$SD/System/etc/scraper.json" 2>/dev/null
warn  "achievements.json present" test -f "$SD/System/etc/achievements.json"

# ── Hooks ──
echo ""
echo "--- Hooks System ---"
HOOKS_OK=0; HOOKS_MISSING=0
for d in boot.d pre-launch.d post-launch.d; do
    HOOKDIR="$SD/System/usr/trimui/hooks/$d"
    if [ -d "$HOOKDIR" ]; then
        COUNT=$(ls "$HOOKDIR"/*.sh 2>/dev/null | wc -l)
        EXEC=$(find "$HOOKDIR" -name "*.sh" -executable 2>/dev/null | wc -l)
        if [ "$COUNT" -gt 0 ]; then
            if [ "$EXEC" -eq "$COUNT" ]; then
                HOOKS_OK=$((HOOKS_OK + 1))
                echo "  ✅ $d: $COUNT hooks (all executable)"
            else
                WARN=$((WARN + 1))
                echo "  ⚠️  $d: $COUNT hooks, $EXEC executable ($((COUNT - EXEC)) need chmod)"
            fi
        else
            WARN=$((WARN + 1))
            echo "  ⚠️  $d: empty (no hooks)"
        fi
    else
        HOOKS_MISSING=$((HOOKS_MISSING + 1))
        echo "  ❌ $d: directory missing"
    fi
done

# ── RetroArch ──
echo ""
echo "--- RetroArch ---"
check "ra64.trimui exists" test -f "$SD/RetroArch/ra64.trimui"
check "ra64.trimui executable" test -x "$SD/RetroArch/ra64.trimui"
CORES_COUNT=$(ls "$SD/RetroArch/.retroarch/cores/"*.so 2>/dev/null | wc -l)
echo "  ℹ️  $CORES_COUNT cores installed"
CORES_SIZE=$(du -sh "$SD/RetroArch/.retroarch/cores/" 2>/dev/null | awk '{print $1}')
echo "  ℹ️  Cores total size: $CORES_SIZE"

# ── Disk ──
echo ""
echo "--- Storage ---"
DISK_USED=$(df -h "$SD" | tail -1 | awk '{print $3}')
DISK_FREE=$(df -h "$SD" | tail -1 | awk '{print $4}')
DISK_PCT=$(df -h "$SD" | tail -1 | awk '{print $5}' | tr -d '%')
echo "  ℹ️  SD: $DISK_USED used, $DISK_FREE free ($DISK_PCT%)"
if [ "$DISK_PCT" -gt 90 ]; then
    WARN=$((WARN + 1))
    echo "  ⚠️  SD card is >90% full. Consider core_dedup.sh"
fi

# ── Logs DB ──
echo ""
echo "--- Logs & Data ---"
check "log directory exists" test -d "$SD/System/var/logs"
if [ -f "$SD/System/var/logs/crossmix.log" ]; then
    LOG_LINES=$(wc -l < "$SD/System/var/logs/crossmix.log")
    echo "  ℹ️  crossmix.log: $LOG_LINES entries"
    [ "$LOG_LINES" -gt 5000 ] && echo "  ⚠️  Log is large. Use log_manager.sh clear"
fi
warn  "battery.db exists" test -f "$SD/System/var/battery.db"
warn  "game_stats.db exists" test -f "$SD/System/var/game_stats.db"

# ── Summary ──
echo ""
echo "========================"
echo "Results: $PASS passed, $WARN warnings, $FAIL failed"
echo "========================"

if [ $FAIL -gt 0 ]; then
    echo "Run 'sh gather_logs.sh' to collect debug info."
    exit 1
elif [ $WARN -gt 0 ]; then
    echo "System is mostly healthy. Fix warnings for optimal experience."
else
    echo "All checks passed. System is healthy."
fi
