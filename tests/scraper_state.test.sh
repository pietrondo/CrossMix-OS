#!/bin/sh
# Unit tests for scraper_state.sh
# Run: sh tests/scraper_state.test.sh

set -u
PASS=0; FAIL=0
assert_eq() {
    if [ "$1" = "$2" ]; then PASS=$((PASS+1)); echo "  PASS: $3"
    else FAIL=$((FAIL+1)); echo "  FAIL: $3 (expected '$2', got '$1')"; fi
}
assert_gt() {
    if [ "$1" -gt "$2" ]; then PASS=$((PASS+1)); echo "  PASS: $3"
    else FAIL=$((FAIL+1)); echo "  FAIL: $3 ($1 not > $2)"; fi
}

# Override state dir for testing (avoid writing to real /mnt/SDCARD)
SCRAPER_STATE_DIR=$(mktemp -d)
export SCRAPER_STATE_DIR

# Fake stat for lock age (always return 0 for test predictability)
stat() {
    if [ "$1" = "-c" ] && [ "$2" = "%Y" ]; then echo "0"; else command stat "$@"; fi
}
export -f stat

. ./System/usr/trimui/scripts/scraper/scraper_state.sh 2>/dev/null || true

echo "=== scraper_state_init tests ==="
scraper_state_init "TEST"
[ -f "$SCRAPER_STATE_DIR/TEST/state.json" ]; assert_eq "$?" "0" "state_init creates state.json"

echo "=== scraper_state_mark_completed tests ==="
scraper_state_mark_completed "TEST" "rom1.zip"
scraper_state_get_completed "TEST" | grep -q "rom1.zip"; assert_eq "$?" "0" "mark_completed adds rom"

# Idempotent: second mark is a no-op
scraper_state_mark_completed "TEST" "rom1.zip"
count=$(scraper_state_get_completed "TEST" | wc -l)
assert_eq "$count" "1" "mark_completed is idempotent"

echo "=== scraper_state_mark_failed tests ==="
scraper_state_mark_failed "TEST" "bad.rom" "no_match"
jq -e '.failed[] | select(.rom == "bad.rom" and .reason == "no_match")' \
    "$SCRAPER_STATE_DIR/TEST/state.json" >/dev/null 2>&1
assert_eq "$?" "0" "mark_failed records rom and reason"

echo "=== scraper_state_lock tests ==="
scraper_state_lock "TEST"; assert_eq "$?" "0" "first lock succeeds"
scraper_state_lock "TEST"; assert_eq "$?" "1" "second lock fails (already held)"
scraper_state_unlock "TEST"
scraper_state_lock "TEST"; assert_eq "$?" "0" "lock succeeds after unlock"

echo "=== scraper_state_clear tests ==="
scraper_state_clear "TEST"
[ -f "$SCRAPER_STATE_DIR/TEST/state.json" ]; assert_eq "$?" "1" "clear removes state.json"

rm -rf "$SCRAPER_STATE_DIR"

echo "======================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "ALL TESTS PASSED" || echo "SOME TESTS FAILED"
exit $FAIL
