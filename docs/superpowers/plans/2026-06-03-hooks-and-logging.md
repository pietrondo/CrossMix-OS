# Hooks System + Centralized Logging — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add centralized logging (`log_message`) and lifecycle hooks (`pre-launch.d/` / `post-launch.d/`) to CrossMix-OS, enabling extensible per-emulator behavior and easy debug log gathering.

**Architecture:** Two new functions in `common_functions.sh`, five hook scripts in `hooks/`, one `gather_logs.sh` script, and optional launcher integration. All scripts are POSIX `sh`, adding ~90 lines total.

**Tech Stack:** POSIX `sh`, existing `common_functions.sh` pattern, `printf`, `date`.

---

## File Map

| File | Action | Lines |
|------|--------|-------|
| `System/usr/trimui/scripts/common_functions.sh` | Modify (+run_hooks, +log_message, +constants) | +30 |
| `System/usr/trimui/hooks/pre-launch.d/10_cpu_performance.sh` | Create | 15 |
| `System/usr/trimui/hooks/pre-launch.d/20_log_start.sh` | Create | 8 |
| `System/usr/trimui/hooks/post-launch.d/10_cpu_restore.sh` | Create | 10 |
| `System/usr/trimui/hooks/post-launch.d/20_log_end.sh` | Create | 8 |
| `System/usr/trimui/hooks/post-launch.d/90_battery_log.sh` | Create | 12 |
| `System/usr/trimui/scripts/gather_logs.sh` | Create | 15 |
| `tests/hooks_logging.test.sh` | Create | Unit tests |

---

### Task 1: Add `run_hooks()` and `log_message()` to common_functions.sh

**Files:**
- Modify: `System/usr/trimui/scripts/common_functions.sh`

- [ ] **Step 1: Read the file to find insertion point**

Read `System/usr/trimui/scripts/common_functions.sh`, find the end of the file or after the `enable_wifi()` function (around line 340). Insert before the last line.

- [ ] **Step 2: Append the new functions**

Append after the existing content (before any trailing blank lines):

```sh

# ── CrossMix-OS Hooks & Logging ──
HOOKS_BASE="/mnt/SDCARD/System/usr/trimui/hooks"
LOGDIR="/mnt/SDCARD/System/var/logs"

run_hooks() {
    local stage="$1"  # pre-launch | post-launch
    local emu="$2"
    for d in "$HOOKS_BASE/$stage.d" "$HOOKS_BASE/$emu/$stage.d"; do
        [ -d "$d" ] && for f in "$d"/*.sh; do
            [ -x "$f" ] && . "$f"
        done
    done
}

log_message() {
    local tag="${1:-unknown}"; shift
    mkdir -p "$LOGDIR"
    printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$tag" "$*" >> "$LOGDIR/crossmix.log"
}
```

- [ ] **Step 3: Verify syntax**

Run: `bash -n System/usr/trimui/scripts/common_functions.sh`
Expected: no output

- [ ] **Step 4: Commit**

```sh
git add System/usr/trimui/scripts/common_functions.sh
git commit -m "feat(hooks): add run_hooks() and log_message() to common_functions"
```

---

### Task 2: Create hook scripts

**Files:**
- Create: `System/usr/trimui/hooks/pre-launch.d/10_cpu_performance.sh`
- Create: `System/usr/trimui/hooks/pre-launch.d/20_log_start.sh`
- Create: `System/usr/trimui/hooks/post-launch.d/10_cpu_restore.sh`
- Create: `System/usr/trimui/hooks/post-launch.d/20_log_end.sh`
- Create: `System/usr/trimui/hooks/post-launch.d/90_battery_log.sh`

- [ ] **Step 1: Create directories**

```sh
mkdir -p System/usr/trimui/hooks/pre-launch.d
mkdir -p System/usr/trimui/hooks/post-launch.d
```

- [ ] **Step 2: Write `pre-launch.d/10_cpu_performance.sh`**

```sh
#!/bin/sh
# Hook: Set CPU governor to performance before launching a game
echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null
log_message "cpu" "governor set to performance"
```

- [ ] **Step 3: Write `pre-launch.d/20_log_start.sh`**

```sh
#!/bin/sh
# Hook: Log game launch start
log_message "launch" "game starting on $2"
```

- [ ] **Step 4: Write `post-launch.d/10_cpu_restore.sh`**

```sh
#!/bin/sh
# Hook: Restore CPU governor to ondemand after game exits
echo ondemand > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null
log_message "cpu" "governor restored to ondemand"
```

- [ ] **Step 5: Write `post-launch.d/20_log_end.sh`**

```sh
#!/bin/sh
# Hook: Log game launch end
log_message "launch" "game ended on $2"
```

- [ ] **Step 6: Write `post-launch.d/90_battery_log.sh`**

```sh
#!/bin/sh
# Hook: Log battery level after game session
BAT=$(cat /sys/class/power_supply/axp20x-battery/capacity 2>/dev/null || echo "?")
log_message "battery" "level=${BAT}%"
```

- [ ] **Step 7: Make hooks executable and verify syntax**

```sh
chmod +x System/usr/trimui/hooks/pre-launch.d/*.sh
chmod +x System/usr/trimui/hooks/post-launch.d/*.sh
for f in System/usr/trimui/hooks/pre-launch.d/*.sh System/usr/trimui/hooks/post-launch.d/*.sh; do
    bash -n "$f" || echo "FAIL: $f"
done
# Expected: no "FAIL" output
```

- [ ] **Step 8: Commit**

```sh
git add System/usr/trimui/hooks/
git commit -m "feat(hooks): add CPU scaling and battery logging hook scripts"
```

---

### Task 3: Create gather_logs.sh

**Files:**
- Create: `System/usr/trimui/scripts/gather_logs.sh`

- [ ] **Step 1: Write `gather_logs.sh`**

```sh
#!/bin/sh
# CrossMix-OS Debug Log Gatherer
# Collects logs, system info, and packages into a tarball.
# Output: /mnt/SDCARD/crossmix_debug_<date>.tar.gz

set -u
OUT="/mnt/SDCARD/crossmix_debug_$(date +%Y%m%d_%H%M%S).tar.gz"
T=$(mktemp -d)

# Copy all CrossMix logs
if [ -d /mnt/SDCARD/System/var/logs ]; then
    cp -r /mnt/SDCARD/System/var/logs "$T/logs" 2>/dev/null
fi

# System info
dmesg > "$T/dmesg.txt" 2>/dev/null
cat /proc/cpuinfo > "$T/cpuinfo.txt" 2>/dev/null
free > "$T/meminfo.txt" 2>/dev/null
df -h > "$T/disk.txt" 2>/dev/null
uname -a > "$T/uname.txt" 2>/dev/null

tar -czf "$OUT" -C "$T" . 2>/dev/null
rm -rf "$T"

if [ -f "$OUT" ]; then
    echo "Debug bundle created: $OUT"
    echo "Copy this file to your PC and send to the developer."
else
    echo "ERROR: Failed to create debug bundle"
    exit 1
fi
```

- [ ] **Step 2: Verify syntax and make executable**

```sh
bash -n System/usr/trimui/scripts/gather_logs.sh && chmod +x System/usr/trimui/scripts/gather_logs.sh
# Expected: no output
```

- [ ] **Step 3: Commit**

```sh
git add System/usr/trimui/scripts/gather_logs.sh
git commit -m "feat(hooks): add gather_logs.sh debug bundle collector"
```

---

### Task 4: Write tests

**Files:**
- Create: `tests/hooks_logging.test.sh`

- [ ] **Step 1: Write test file**

```sh
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
    if echo "$1" | grep -q "$2"; then PASS=$((PASS+1)); echo "  PASS: $3"
    else FAIL=$((FAIL+1)); echo "  FAIL: $3 (missing '$2')"; fi
}

# Override paths for testing
TMP=$(mktemp -d)
export LOGDIR="$TMP/logs"
export HOOKS_BASE="$TMP/hooks"

# Source common_functions (will fail on env.sh dependency, that's OK for unit tests)
bash -n ./System/usr/trimui/scripts/common_functions.sh; assert_eq "$?" "0" "common_functions.sh valid syntax"

# Test log_message directly (bypassing source, test the function from common_functions)
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

# Create a test hook
cat > "$HOOKS_BASE/pre-launch.d/99_test.sh" << 'EOF'
#!/bin/sh
echo "hook_ran=true" >> /tmp/hook_test_result
EOF
chmod +x "$HOOKS_BASE/pre-launch.d/99_test.sh"

# run_hooks should execute it
run_hooks "pre-launch" "TESTEMU"
[ -f /tmp/hook_test_result ] && grep -q "hook_ran=true" /tmp/hook_test_result
assert_eq "$?" "0" "run_hooks executes pre-launch hook scripts"
rm -f /tmp/hook_test_result

# run_hooks with no hooks dir should not error
run_hooks "pre-launch" "NOEXIST"
assert_eq "$?" "0" "run_hooks with missing dir does not crash"

# run_hooks with unexecutable hook should skip it
cat > "$HOOKS_BASE/post-launch.d/99_notexec.sh" << 'EOF'
#!/bin/sh
echo "should not run" >> /tmp/hook_test_result
EOF
# NOT chmod +x — should be skipped
run_hooks "post-launch" "TESTEMU"
[ -f /tmp/hook_test_result ] && assert_eq "1" "0" "run_hooks skips non-executable hooks" || PASS=$((PASS+1)); echo "  PASS: run_hooks skips non-executable hooks"

rm -rf "$TMP"

echo "======================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "ALL TESTS PASSED" || echo "SOME TESTS FAILED"
exit $FAIL
```

- [ ] **Step 2: Run tests**

```sh
sh tests/hooks_logging.test.sh
# Expected: ALL TESTS PASSED (8 passed, 0 failed)
```

- [ ] **Step 3: Commit**

```sh
git add tests/hooks_logging.test.sh
git commit -m "test(hooks): add unit tests for log_message and run_hooks"
```

---

### Task 5: Syntax-validate all files and run full suite

- [ ] **Step 1: Validate all new scripts**

```sh
for f in \
    System/usr/trimui/scripts/common_functions.sh \
    System/usr/trimui/scripts/gather_logs.sh \
    System/usr/trimui/hooks/pre-launch.d/10_cpu_performance.sh \
    System/usr/trimui/hooks/pre-launch.d/20_log_start.sh \
    System/usr/trimui/hooks/post-launch.d/10_cpu_restore.sh \
    System/usr/trimui/hooks/post-launch.d/20_log_end.sh \
    System/usr/trimui/hooks/post-launch.d/90_battery_log.sh; do
    bash -n "$f" || echo "SYNTAX ERROR: $f"
done
echo "Syntax check complete"
# Expected: no SYNTAX ERROR lines
```

- [ ] **Step 2: Run test suite**

```sh
sh tests/hooks_logging.test.sh
# Expected: ALL TESTS PASSED
```

- [ ] **Step 3: Final commit**

```sh
git status
git commit -m "chore(hooks): final validation and syntax checks" --allow-empty
```

---

## Self-Review

1. **Spec coverage**: All requirements mapped:
   - `run_hooks()` → Task 1
   - `log_message()` → Task 1
   - Hook scripts (5) → Task 2
   - `gather_logs.sh` → Task 3
   - Tests → Task 4
   - Validation → Task 5

2. **Placeholder scan**: No TBD, TODO, or vague references. All code blocks complete. ✓

3. **Type consistency**: `HOOKS_BASE`, `LOGDIR`, `run_hooks`, `log_message` used consistently across all tasks. ✓
