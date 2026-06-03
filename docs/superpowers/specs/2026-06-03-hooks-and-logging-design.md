# Hooks System + Centralized Logging — Design Spec

**Status:** Approved  
**Date:** 2026-06-03  
**Target version:** v1.7.1

## Context

CrossMix-OS has no centralized logging and no extensibility hooks. When something breaks, debugging requires SSH + manual `dmesg` inspection by the user, and logs are scattered across `/tmp/` or stdout (lost). Additionally, new features (RetroAchievements, CPU scaling, battery monitor) need a standard way to hook into emulator lifecycle events.

## Goals

1. **Centralized logging** — all CrossMix scripts write to a single log file with timestamps and tags. Users can run `gather_logs.sh` to collect a tarball for debugging.
2. **Hooks system** — `pre-launch.d/` and `post-launch.d/` script directories, both global and per-emulator, executed around emulator launch.
3. **Minimal invasiveness** — no changes to existing launcher scripts beyond adding `source common_functions.sh` (which many already do).
4. **Future-proof** — enables RetroAchievements, CPU scaling, battery logging, game time tracking as independent hook scripts.

## Non-goals

- Log rotation (keep it simple: truncate on boot)
- Structured logging (JSON) — plain text with `[timestamp] [tag] message` is sufficient
- Remote log upload
- Per-app log files (single `crossmix.log` is simpler to gather)
- Modifying RetroArch internal logging (RA has its own)

## Architecture

```
common_functions.sh  ← +log_message(), +run_hooks()
        │
        ▼
  Emu launcher (e.g., Emus/SFC/launch.sh)
        │
        ├─► run_hooks "pre-launch" "SFC"
        │     ├─► hooks/pre-launch.d/*.sh    (globali)
        │     └─► hooks/SFC/pre-launch.d/*.sh  (per-emu)
        │
        ├─► RetroArch (invariato)
        │
        └─► run_hooks "post-launch" "SFC"
              ├─► hooks/post-launch.d/*.sh
              └─► hooks/SFC/post-launch.d/*.sh
```

## Components

### 1. `common_functions.sh` (modified)

Add two functions:

```sh
# Run hooks for lifecycle stage
run_hooks() {
    local stage="$1"  # pre-launch | post-launch
    local emu="$2"
    for d in "$HOOKS_BASE/$stage.d" "$HOOKS_BASE/$emu/$stage.d"; do
        [ -d "$d" ] && for f in "$d"/*.sh; do
            [ -x "$f" ] && . "$f"
        done
    done
}

# Centralized logging
log_message() {
    local tag="${1:-unknown}"; shift
    mkdir -p "$LOGDIR"
    printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$tag" "$*" >> "$LOGDIR/crossmix.log"
}
```

Constants: `HOOKS_BASE="/mnt/SDCARD/System/usr/trimui/hooks"`, `LOGDIR="/mnt/SDCARD/System/var/logs"`.

### 2. Hook scripts (new)

| File | When | What |
|------|------|------|
| `hooks/pre-launch.d/10_cpu_performance.sh` | Pre-launch global | Set CPU governor to performance |
| `hooks/pre-launch.d/20_log_start.sh` | Pre-launch global | Log emulator start |
| `hooks/post-launch.d/10_cpu_restore.sh` | Post-launch global | Restore CPU governor to ondemand |
| `hooks/post-launch.d/20_log_end.sh` | Post-launch global | Log emulator end |
| `hooks/post-launch.d/90_battery_log.sh` | Post-launch global | Log battery level |

### 3. `gather_logs.sh` (new)

```
Path: System/usr/trimui/scripts/gather_logs.sh
Collects: /mnt/SDCARD/System/var/logs/ + dmesg + cpuinfo + meminfo + disk usage
Output: /mnt/SDCARD/crossmix_debug_YYYYMMDD_HHMMSS.tar.gz
```

### 4. Launcher integration

In each `Emus/*/launch.sh`, add after `source common_functions.sh`:

```sh
run_hooks "pre-launch" "$EMU_TAG"
# ... existing launch logic ...
run_hooks "post-launch" "$EMU_TAG"
```

Only launchers that already source `common_functions.sh` get this automatically via the hook call in the common launch script pattern.

## Data Flow

### Normal emulator launch
1. User selects game → `Emus/SFC/launch.sh` starts
2. `run_hooks "pre-launch" "SFC"` → CPU governor set to performance, start logged
3. RetroArch runs the game
4. `run_hooks "post-launch" "SFC"` → CPU restored, end logged, battery logged
5. All events in `/mnt/SDCARD/System/var/logs/crossmix.log`

### Debug gathering
1. User opens Apps → Gather Logs
2. `gather_logs.sh` runs, collects everything into a tarball
3. Tarball appears at SD root: `/mnt/SDCARD/crossmix_debug_...tar.gz`
4. User copies to PC, sends to developer

## Testing

### Unit
- `log_message "TEST" "hello"` → verify line appears in crossmix.log with correct timestamp format
- `run_hooks "pre-launch" "FAKE"` with empty dir → no errors
- `run_hooks "pre-launch" "FAKE"` with one hook script → hook executed, `$? = 0`

### Integration
- Launch a game, verify 4 log entries appear (start, cpu set, cpu restore, end)
- Run `gather_logs.sh`, verify tarball contains dmesg + cpuinfo + meminfo + disk.txt + crossmix.log
- Simulate missing hook dir → no crash

### Manual
- Real device: launch 3 different emulators, gather logs, inspect tarball
- Real device: add a custom hook in `hooks/post-launch.d/99_test.sh`, verify it runs

## File Map

| File | Action |
|------|--------|
| `System/usr/trimui/scripts/common_functions.sh` | Modify (+run_hooks, +log_message, +constants) |
| `System/usr/trimui/hooks/pre-launch.d/10_cpu_performance.sh` | Create |
| `System/usr/trimui/hooks/pre-launch.d/20_log_start.sh` | Create |
| `System/usr/trimui/hooks/post-launch.d/10_cpu_restore.sh` | Create |
| `System/usr/trimui/hooks/post-launch.d/20_log_end.sh` | Create |
| `System/usr/trimui/hooks/post-launch.d/90_battery_log.sh` | Create |
| `System/usr/trimui/scripts/gather_logs.sh` | Create |
| `tests/hooks.test.sh` | Create |
| `tests/gather_logs.test.sh` | Create |

## Rollout

- Phase 1 (this spec): hooks infrastructure + logging + gather_logs + CPU scaling hook + battery hook
- Phase 2 (RetroAchievements spec): `hooks/pre-launch.d/30_retroachievements.sh`
- Phase 3 (Battery monitor spec): `hooks/post-launch.d/90_battery_log.sh` extended with SQLite history
- Phase 4 (Game time tracker): `hooks/pre-launch.d/25_game_timer_start.sh` + `hooks/post-launch.d/25_game_timer_stop.sh`
