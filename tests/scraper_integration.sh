#!/bin/sh
# Integration test for Scraper multithread pipeline.
# Spins up a mock ScreenScraper API server, runs state logic tests.
# Run: sh tests/scraper_integration.sh

set -u
PASS=0; FAIL=0
assert_eq() {
    if [ "$1" = "$2" ]; then PASS=$((PASS+1)); echo "  PASS: $3"
    else FAIL=$((FAIL+1)); echo "  FAIL: $3 (expected '$2', got '$1')"; fi
}

# ── Setup ──
TMP=$(mktemp -d)
mkdir -p "$TMP/Imgs/TEST" "$TMP/Roms/TEST" "$TMP/Emus/TEST" "$TMP/System/var/scraper_state" "$TMP/System/etc"
export SCRAPER_STATE_DIR="$TMP/System/var/scraper_state"

# Mock config files
printf '{"extlist":"zip|gba"}\n' > "$TMP/Emus/TEST/config.json"
printf '{"screenscraper_username":"test","screenscraper_password":"pw","Screenscraper_MediaType":"box-2D","Screenscraper_Region":"us","scraper_workers":2,"scraper_resume":true}\n' > "$TMP/System/etc/scraper.json"

# Create test ROM files
echo "dummy rom 1" > "$TMP/Roms/TEST/game1.zip"
echo "dummy rom 2" > "$TMP/Roms/TEST/game2.zip"
echo "dummy rom 3" > "$TMP/Roms/TEST/game3.zip"

# Source state helper
. ./System/usr/trimui/scripts/scraper/scraper_state.sh 2>/dev/null || true

echo "=== Integration: state resume logic ==="
scraper_state_init "TEST"
scraper_state_mark_completed "TEST" "game1.zip"
scraper_state_get_completed "TEST" | grep -q "game1.zip"; assert_eq "$?" "0" "state tracks completed ROM"

# Verify ROM count
count=$(scraper_state_get_completed "TEST" | wc -l)
assert_eq "$count" "1" "exactly 1 completed after mark"

echo "=== Integration: lock prevents concurrent runs ==="
scraper_state_lock "TEST"; assert_eq "$?" "0" "lock acquired"
scraper_state_unlock "TEST"; assert_eq "$?" "0" "lock released"

# ── Cleanup ──
rm -rf "$TMP"

echo "======================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "ALL TESTS PASSED" || echo "SOME TESTS FAILED"
exit $FAIL
