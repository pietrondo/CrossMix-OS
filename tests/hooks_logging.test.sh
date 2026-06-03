#!/bin/sh
# Unit tests for hooks system and centralized logging
# Run: sh tests/hooks_logging.test.sh

set -u
PASS=0; FAIL=0
assert_eq() {
    if [ "$1" = "$2" ]; then PASS=$((PASS+1)); echo "  PASS: $3"
    else FAIL=$((FAIL+1)); echo "  FAIL: $3 (expected '$2', got '$1')"; fi
}
assert_contains() {
    if echo "$1" | grep -Fq "$2"; then PASS=$((PASS+1)); echo "  PASS: $3"
    else FAIL=$((FAIL+1)); echo "  FAIL: $3 (missing '$2')"; fi
}

# Override paths for testing
TMP=$(mktemp -d)
export LOGDIR="$TMP/logs"
export HOOKS_BASE="$TMP/hooks"

# Test that common_functions has valid syntax
echo "=== syntax checks ==="
bash -n ./System/usr/trimui/scripts/common_functions.sh 2>/dev/null; assert_eq "$?" "0" "common_functions.sh syntax valid"
bash -n ./System/usr/trimui/scripts/gather_logs.sh 2>/dev/null; assert_eq "$?" "0" "gather_logs.sh syntax valid"

# Source common_functions (may fail on env.sh paths, that's ok for unit tests)
. ./System/usr/trimui/scripts/common_functions.sh 2>/dev/null || true

echo "=== log_message tests ==="
log_message "TEST" "hello world"
[ -f "$LOGDIR/crossmix.log" ]; assert_eq "$?" "0" "log_message creates crossmix.log"
content=$(cat "$LOGDIR/crossmix.log")
assert_contains "$content" "[TEST] hello world" "log_message writes tag and message"
assert_contains "$content" "$(date '+%Y-%m-%d')" "log_message includes timestamp"

log_message "TEST2" "second message"
lines=$(wc -l < "$LOGDIR/crossmix.log")
assert_eq "$lines" "2" "log_message appends (2 lines)"

echo "=== run_hooks tests ==="
mkdir -p "$HOOKS_BASE/pre-launch.d"
mkdir -p "$HOOKS_BASE/post-launch.d"

cat > "$HOOKS_BASE/pre-launch.d/99_test.sh" << 'SCRIPTEOF'
#!/bin/sh
echo "hook_ran=true" >> /tmp/hook_test_result
SCRIPTEOF
chmod +x "$HOOKS_BASE/pre-launch.d/99_test.sh"

run_hooks "pre-launch" "TESTEMU"
[ -f /tmp/hook_test_result ] && grep -Fq "hook_ran=true" /tmp/hook_test_result
assert_eq "$?" "0" "run_hooks executes pre-launch hook scripts"
rm -f /tmp/hook_test_result /tmp/hook_test_result2
rm -f "$HOOKS_BASE/pre-launch.d/99_test.sh"

# run_hooks with no hooks dir should not crash
run_hooks "pre-launch" "NOEXIST"
assert_eq "$?" "0" "run_hooks with missing dir does not crash"

# unexecutable hooks should be skipped
# hooks with non-.sh extension should be skipped (portable alternative to -x check)
cat > "$HOOKS_BASE/post-launch.d/99_notexec.disabled" << 'SCRIPTEOF'
#!/bin/sh
echo "should not run" >> /tmp/hook_test_result2
SCRIPTEOF
# NOT a .sh file — should be skipped by the *.sh glob
run_hooks "post-launch" "TESTEMU"
if [ -f /tmp/hook_test_result2 ]; then
    echo "  FAIL: run_hooks skips non-.sh files"
    FAIL=$((FAIL+1))
else
    PASS=$((PASS+1)); echo "  PASS: run_hooks skips non-.sh files"
fi

rm -rf "$TMP"

echo "======================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "ALL TESTS PASSED" || echo "SOME TESTS FAILED"
exit $FAIL
