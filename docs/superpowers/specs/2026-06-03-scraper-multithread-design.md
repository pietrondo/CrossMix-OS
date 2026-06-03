# Scraper Multithread + Retry — Design Spec

**Status**: Approved
**Date**: 2026-06-03
**Author**: CrossMix-OS maintainer
**Target version**: v1.7.1 (or v1.8.0 if breaking)

## Context

CrossMix-OS includes a scraper for the ScreenScraper.fr service, used to download boxart and metadata for ROMs across ~30 emulated systems. The current implementation (`System/usr/trimui/scripts/scraper/scrap_screenscraper.sh`, 551 lines) processes ROMs **sequentially**: for each ROM it issues 2–3 HTTP calls (search by name, search by SHA1, download image).

For a typical TrimUI Smart Pro user with 1000+ ROMs, a full scrape takes **30–90 minutes** of single-threaded work, and the bottleneck is mostly HTTP latency, not CPU. The ScreenScraper service explicitly allows parallel scraping for authenticated users (donors, contributors), but the current code does not exploit this.

The code already has a TODO at line 57: `# TODO : managing multithread for users who have it.` This spec implements it.

## Goals

1. **Reduce full-library scrape time** by ~4× for users with ScreenScraper accounts (and proportionally less for free users, capped at 1 worker).
2. **Make scraping resumable** after interruption (user cancel, power loss, WiFi drop, OOM).
3. **Improve robustness** against transient HTTP errors (5xx, 429, timeouts) with structured retry.
4. **Preserve all existing behavior** for users who do not configure parallel scraping (default = 1 worker for anonymous, 4 for authenticated).
5. **Stay within the existing constraints** of POSIX `sh`, low-end device (A133, 1GB RAM), slow SD I/O, and the `text_viewer` UI.

## Non-goals

- Cloud save sync (out of scope, separate spec).
- Theme store or community content delivery (out of scope).
- Switch to a different scraping backend (ScreenScraper is the only target).
- Add new scraping metadata fields (use existing schema).
- Rewrite the existing `scrap_screenscraper.sh` from scratch (incremental refactor only).
- Support scraping while a game is running (only the dedicated Scraper app).

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│ scrap_screenscraper.sh  (entry point, modified)         │
│   └─► scrap_master.sh  (NEW, orchestrator)              │
│         ├─► Read state file (resume support)           │
│         ├─► Compute missing ROMs                       │
│         ├─► Launch xargs -P $WORKERS                   │
│         │     └─► scrap_worker.sh  (NEW, per ROM)      │
│         │           ├─► search_on_screenscraper()      │
│         │           ├─► download art                   │
│         │           └─► update state atomically        │
│         └─► Aggregate results, display summary          │
└─────────────────────────────────────────────────────────┘
```

**Split rationale**: keeping a thin master, a small worker, and a state helper makes the code testable and the master readable. The existing `scrap_screenscraper.sh` becomes a thin shim that handles WiFi setup, the banner, and argument parsing, then delegates to the master.

## Components

### `scrap_screenscraper.sh` (modified, ~30 lines removed, ~10 added)

Existing entry point. Changes:
- Keep `enable_wifi` + `check_connection` (lines 6–7)
- Keep `Screenscraper_information` banner
- Keep argument parsing
- **Remove**: lines 230–530 (the per-ROM scraping logic)
- **Add**: `exec scrap_master.sh "$@"` (or explicit call for testability)

### `scrap_master.sh` (new, ~120 lines)

Responsibilities:
- Read `scraper.json` config
- Acquire per-emu-folder lock (`System/var/scraper_state/<emu>.lock`)
- Enumerate ROMs in `/mnt/SDCARD/Roms/<emu>/`
- Filter out already-scraped ROMs (image present + valid + not `.notag`)
- Load state file, filter out completed ROMs (if `scraper_resume: true`)
- Build ROM list, pipe to `xargs -P $WORKERS -I {} scrap_worker.sh "$EMU" "{}"`
- Trap SIGTERM/SIGINT: forward to xargs, write final state
- Aggregate per-worker exit codes via xargs output
- Display final summary: success, failed, skipped (resume), duration

### `scrap_worker.sh` (new, ~180 lines)

Responsibilities (extracted from existing `scrap_screenscraper.sh` lines 230–530):
- Take 2 args: `emu_folder`, `rom_path`
- Look up ScreenScraper system ID (from `regions.db` / system mapping)
- Call `search_on_screenscraper()` (existing logic, line 52)
- If match found, download art to `<rom>.png`
- Write atomic state update (`completed[]` or `failed[]`)
- Exit 0 on success, 1 on permanent fail, 2 on transient (worker pool will skip)

The worker is **stateless** (apart from reading the state file). It can be killed and restarted without corruption.

### `scraper_state.sh` (new helper, ~60 lines)

Reusable shell functions for:
- `state_init <emu>` — create `System/var/scraper_state/<emu>.json` if missing
- `state_mark_completed <emu> <rom>` — append to `completed[]` (atomic write)
- `state_mark_failed <emu> <rom>` — append to `failed[]`
- `state_load <emu>` — emit JSON to stdout
- `state_lock_acquire <emu>` / `state_lock_release <emu>` — `mkdir`-based atomic lock

### `scraper_state.json` (new, per emu folder)

Path: `/mnt/SDCARD/System/var/scraper_state/<emu>.json`

Schema:
```json
{
  "emu": "SFC",
  "started_at": "2026-06-03T10:23:00Z",
  "last_update": "2026-06-03T10:45:12Z",
  "completed": ["rom1.sfc", "rom2.zip"],
  "failed": [{"rom": "broken.sfc", "reason": "no_match", "ts": "..."}]
}
```

Rotation: never auto-rotated. Manual deletion by user via Apps panel (future enhancement).

### `scraper.lock` (new, per emu folder)

Path: `/mnt/SDCARD/System/var/scraper_state/<emu>.lock`

Acquired via `mkdir` (atomic on POSIX). If it fails, second run exits with a clear error. Stale lock (older than 24h) auto-removed on next acquire attempt.

## Configuration

Extend `System/etc/scraper.json` (or `scraper.json.example` template) with:

```json
{
  "screenscraper_username": "",
  "screenscraper_password": "",
  "Screenscraper_MediaType": "box-2D",
  "Screenscraper_Region": "wor",
  "scraper_workers": null,        // null = auto (1 anon, 4 auth)
  "scraper_resume": true,
  "scraper_timeout_sec": 30,
  "scraper_max_retries": 3
}
```

| Key | Default | Range | Notes |
|-----|---------|-------|-------|
| `scraper_workers` | `null` (auto) | 1–8 | Clamped. `null` → 1 if username empty, else 4. |
| `scraper_resume` | `true` | bool | If false, state file is ignored. |
| `scraper_timeout_sec` | 30 | 5–120 | Per-HTTP-call timeout. |
| `scraper_max_retries` | 3 | 1–10 | Per-ROM retries on transient errors. |

## Data Flow

### Happy path (anonymous user, fresh scrape)

1. User taps **Apps → Scraper → SFC**.
2. `scrap_screenscraper.sh SFC` → `enable_wifi` + `check_connection` → `scrap_master.sh SFC`.
3. Master reads config: `username=""` → `WORKERS=1`.
4. Master enumerates 250 ROMs in `/mnt/SDCARD/Roms/SFC/`.
5. State file absent → `missing = all 250`.
6. `xargs -P 1 -I {} scrap_worker.sh SFC {}` runs sequentially (same as today).
7. Each worker: search → match → download → mark `completed`.
8. Master shows: `Scraped 248/250 (2 failed). Duration 41m.`

### Happy path (authenticated user, fresh scrape)

1–5. Same as above, but `WORKERS=4`.
6. `xargs -P 4 -I {} scrap_worker.sh SFC {}` runs 4 ROMs in parallel.
7. Workers write to state file under per-emu `flock` (or atomic rename per-key) to avoid corruption.
8. Master shows: `Scraped 250/250. Duration 11m.` (4× faster)

### Resume path (interrupted run)

1. User starts `scrap_screenscraper.sh SFC` (250 ROMs, 4 workers).
2. After 5 min: 90 ROMs completed, user presses B → `text_viewer` sends SIGTERM to `xargs`.
3. Master traps SIGTERM, sends SIGTERM to children, waits up to 5s, writes state file, exits.
4. State file shows 90 completed.
5. User re-runs: master reads state, filters out 90 completed, runs remaining 160.
6. State file shows 250 completed, 0 failed.

### Error path (server rate limit)

1. Worker #3 receives `"The maximum threads"` response.
2. Existing `search_on_screenscraper()` retry logic (lines 53–78): waits 6s, retries up to 5×.
3. If still rate-limited after 5 retries: worker exits 2, marks ROM as `failed: rate_limit`.
4. Master continues with other workers.
5. Summary: `248/250 (2 failed: rate_limit)`.

## Error Handling

| Error | Where handled | Strategy |
|-------|---------------|----------|
| `max threads` response | worker `search_on_screenscraper()` | Existing: wait `5+N`s, retry up to 5× |
| `API closed` response | worker | Mark `failed`, exit 1, master continues |
| HTTP 5xx / curl timeout | worker | Retry 3× with backoff (1s, 2s, 4s) |
| HTTP 429 with `Retry-After` | worker | Honor `Retry-After`, then retry |
| Network drop mid-download | worker | `.part` temp file, atomic rename on success, cleanup on fail |
| Worker crash (OOM, segfault) | master | Worker timeout 120s, mark `failed: crashed`, continue |
| 2 concurrent runs same emu | master | `mkdir` lock fails, second run exits with clear message |
| User cancel (B button) | master | SIGTERM propagated, state saved, clean exit |
| Stale lock (process killed) | master | Lock older than 24h auto-removed |
| State file corrupt | master | Backup `.json.bak`, recreate empty, log warning |

### State file atomicity

Workers serialize writes via `flock` on a per-emu lock file (`System/var/scraper_state/<emu>.write.lock`) when appending to `completed[]` / `failed[]`. Read uses the same lock. The JSON file is rewritten as a whole on each update (small enough; OK on TrimUI).

## Testing

### Unit tests (bats)

`tests/scraper.bats`:

- `state_init` creates file with correct schema
- `state_mark_completed` is idempotent
- `state_lock_acquire` fails when already held
- `state_lock_acquire` removes stale lock > 24h
- workers count auto-detection: empty username → 1, with username → 4
- workers count clamping: 0 → 1, 100 → 8
- resume: completed ROMs are skipped on next run

### Integration tests (bash + mock server)

`tests/scraper_integration.sh`:

- Spin up local mock server (Python `http.server` with hardcoded responses)
- Run `scrap_master.sh` with `WORKERS=4` on a 10-ROM fixture
- Verify all 10 ROMs end up with valid `box-2D` images
- Verify state file contains all 10 in `completed[]`
- Verify wall time is < 0.5× sequential time (i.e., parallel works)

### Manual test plan (on real device)

- Account user: scrape `GBA` folder (~120 ROMs), expect <15 min vs ~50 min today
- Anonymous user: scrape `SFC` folder, expect same time as today (workers=1)
- Cancel: start scrape, press B after 2 min, restart, verify resume
- Concurrent run: open 2 SSH sessions, run scraper on same emu, second should fail with clear message
- Power loss: yank SD mid-scrape, reinsert, re-run, verify resume picks up correctly

### CI (GitHub Actions, future)

- Run `shellcheck` on all 3 new scripts
- Run `bats tests/scraper.bats`
- Run integration test in Linux container

## Migration & Rollout

### Backward compatibility

- Existing `scrap_screenscraper.sh SFC rom_name` (per-ROM mode) still works: master detects single ROM arg and runs worker directly.
- Existing `scraper.json` files without new keys: defaults apply.
- No DB migration needed (state files are new, opt-in via `scraper_resume: true`).
- Wiki page `Scraper.md` (if exists) updated with new options.

### Rollout

1. **Phase 1** (this spec): all 3 new scripts + tests + example config. Default `WORKERS=1` for anonymous, `=4` for auth. No behavior change for non-account users.
2. **Phase 2** (later): add UI to `text_viewer` showing per-worker progress (e.g., 4 progress bars). Optional, gated behind a flag.
3. **Phase 3** (later): add "Scraper" tab in `Apps` panel showing per-system completion status.

## Open Questions

None at design time. All decisions in the design discussion above are approved.

## References

- Existing scraper: `System/usr/trimui/scripts/scraper/scrap_screenscraper.sh` (line 57 TODO)
- ScreenScraper API docs: https://www.screenscraper.fr/api2.php
- ScreenScraper rate limits / threads: https://www.screenscraper.fr/faq.php
- CrossMix-OS roadmap: `docs/superpowers/specs/` (this and future specs)
