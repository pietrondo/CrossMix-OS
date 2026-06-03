#!/bin/sh
# CrossMix-OS Unit Tests
# Run on device: sh tests/run_tests.sh

set -u
PASS=0; FAIL=0

assert_eq() {
    if [ "$1" = "$2" ]; then
        PASS=$((PASS + 1)); echo "  PASS: $3"
    else
        FAIL=$((FAIL + 1)); echo "  FAIL: $3 (expected '$2', got '$1')"
    fi
}

assert_gt() {
    if [ "$1" -gt "$2" ]; then
        PASS=$((PASS + 1)); echo "  PASS: $3"
    else
        FAIL=$((FAIL + 1)); echo "  FAIL: $3 ($1 not > $2)"
    fi
}

# Test verify_sha1
echo "=== verify_sha1 tests ==="
. /mnt/SDCARD/System/usr/trimui/scripts/update_common.sh 2>/dev/null || true

TMP=$(mktemp -d)
echo "test content" > "$TMP/test.txt"
expected=$(sha1sum "$TMP/test.txt" | awk '{print $1}')

verify_sha1 "$TMP/test.txt" "$expected"
assert_eq "$?" "0" "verify_sha1 with correct hash returns 0"

verify_sha1 "$TMP/test.txt" "deadbeef"
assert_eq "$?" "1" "verify_sha1 with wrong hash returns 1"

verify_sha1 "/nonexistent" "deadbeef"
assert_eq "$?" "1" "verify_sha1 with missing file returns 1"

# Test ReadableSizeValue
echo "=== ReadableSizeValue tests ==="
assert_eq "$(ReadableSizeValue 500)" "500 Bytes" "500 bytes"
assert_eq "$(ReadableSizeValue 2048)" "2 KB" "2048 bytes = 2 KB"

# Test get_version
echo "=== get_version tests ==="
v1=$(get_version "1.2.3" 2>/dev/null)
v2=$(get_version "1.3.0" 2>/dev/null)
[ -n "$v1" ] && [ -n "$v2" ] && assert_gt "$v2" "$v1" "1.3.0 > 1.2.3"

# Test crossmix-version.txt exists
echo "=== System checks ==="
[ -f /mnt/SDCARD/System/usr/trimui/crossmix-version.txt ]
assert_eq "$?" "0" "crossmix-version.txt exists"

[ -f /mnt/SDCARD/System/usr/trimui/scripts/env.sh ]
assert_eq "$?" "0" "env.sh exists"

echo ""
echo "=== scraper_state tests ==="
if [ -f ./tests/scraper_state.test.sh ]; then
    sh ./tests/scraper_state.test.sh
fi
echo ""
echo "=== hooks + logging tests ==="
if [ -f ./tests/hooks_logging.test.sh ]; then
    sh ./tests/hooks_logging.test.sh
fi
echo ""
echo "=== scraper integration tests ==="
if [ -f ./tests/scraper_integration.sh ]; then
    sh ./tests/scraper_integration.sh
fi

echo ""
echo "=== script syntax checks ==="
for script in \
    System/usr/trimui/scripts/gather_logs.sh \
    System/usr/trimui/scripts/log_manager.sh \
    System/usr/trimui/scripts/battery_stats.sh \
    System/usr/trimui/scripts/game_stats.sh \
    System/usr/trimui/scripts/display_probe.sh \
    System/usr/trimui/hooks/pre-launch.d/*.sh \
    System/usr/trimui/hooks/post-launch.d/*.sh; do
    if [ -f "$script" ]; then
        bash -n "$script" 2>/dev/null && echo "  OK: $script" || echo "  SYNTAX ERROR: $script"
    fi
done

rm -rf "$TMP"

echo ""
echo "======================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "ALL TESTS PASSED" || echo "SOME TESTS FAILED"
