# §7 D-E5 — Build-a-Dua double-tap (live sim)

**Run date:** 2026-04-26
**Sim:** iPhone 17 (UDID `E1152EC8-6A80-4966-92D9-7D7425A81CD2`)
**Account:** `shareqa@sakinaqa.test` (uid `7fd655f4-33bd-4ed9-8974-2be27504df5d`)
**Tools:** `mcp__ios-simulator__*`, `mcp__supabase__execute_sql`, plistlib (SP inspection)

## Why this run

D-E5 (Duplicate-tap on Build) was filed as **BLOCKED** on the 2026-04-26 content-history run (`docs/qa/runs/2026-04-26-content-history.md:31`) because the Try-Again clear bug made the prerequisite setup unreachable. That blocker is now closed (`docs/qa/findings/2026-04-26-build-dua-tryagain-no-clear.md`), so this run finally exercises the rapid-double-tap on both submit paths live.

## Code coverage already in place

- `lib/features/duas/providers/duas_provider.dart:420` — `if (state.buildLoading) return;` early-return on `submitBuild`.
- `lib/features/duas/providers/duas_provider.dart:431` — same guard on `submitBuildWithToken`.
- `test/features/duas/submit_build_reentry_guard_test.dart` — 3 unit tests, all PASS:
  - `submitBuild early-returns when buildLoading is true`
  - `two synchronous submitBuild calls in the same microtask only run the AI once`
  - `submitBuildWithToken early-returns when buildLoading is true`

## Live cases

### D-E5a — Free-build path, rapid double-tap

| Step | Observed |
|---|---|
| Pre: `daily_usage_built_dua_2026-04-26` SP counter | 2 (server null; 2 free builds already used today by prior tests) |
| Type "Help me strengthen my prayer and grow closer to Allah" | OK |
| Two consecutive `ui_tap (200, 693)` (Build My Dua) | Both registered |
| Loader at 72% during build | ✓ |
| Result reaches "Opening Praise" section | ✓ (build succeeded once) |
| Post: SP counter | **3** (delta = +1, not +2) |
| Post: `user_built_duas` rows | 3 (unchanged — no Save tap, by design) |

**Verdict:** PASS. Two taps → exactly one AI call → counter +1.

### D-E5b — Token-spend path, rapid double-tap

| Step | Observed |
|---|---|
| Pre: SP counter | 3 (limit hit) |
| Pre: `user_tokens.balance` | **235** |
| Type "Help me find peace and trust in Allah's plan" → Build | Token gate sheet fires ("Daily limit reached / 3 free Build a Dua sessions today / Spend 50 tokens") |
| Two consecutive `ui_tap (200, 656)` on "Spend 50 tokens to continue" | Both registered |
| Loader during build | ✓ |
| Result reaches "Opening Praise" section | ✓ (build succeeded once) |
| Post: `user_tokens.balance` | **185** (delta = -50, not -100) |

**Verdict:** PASS. Two taps → exactly one AI call → exactly one 50-token spend.

## Screenshots

- `/tmp/sakina-qa/de5/02-duas-tab.png` — Build a Dua landing
- `/tmp/sakina-qa/de5/03-loading.png` — 72% loader after first double-tap
- `/tmp/sakina-qa/de5/06-after-build.png` — successful result (free path)
- `/tmp/sakina-qa/de5/07-token-gate.png` — token gate sheet (D-E5b)
- `/tmp/sakina-qa/de5/08-token-spend-result.png` — successful result (token-spend path)

## Notes for next runner

- `user_daily_usage` rows on the server were `null` for this user throughout — local SP counter is authoritative for the free-build gate. The Supabase upsert in `daily_usage_service.dart:_upsertToday` either failed silently or hasn't synced; investigated only insofar as it didn't affect the guard verification. Worth a separate look but **not** a D-E5 regression.
- App boot sometimes rehydrates SP from a server-side source even when `user_daily_usage` has no row. Could not pinpoint the source in this run; reset via plistlib + cold-launch is unreliable. For a clean baseline, prefer to confirm via `xcrun simctl get_app_container ... data` + plutil dump immediately before the test.
- Always verify the signed-in uid via the SP key suffix before reading DB — this run started against the wrong uid (`qa20260426`) until the plist dump revealed the real signed-in user (`shareqa`).

## Status

D-E5 — closed. Code: guard at `duas_provider.dart:420`/`:431`. Unit tests: 3/3 PASS. Live sim: free-build PASS + token-spend PASS.
