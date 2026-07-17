# Duʿā Times — Scheduled Notifications (Phase 2) — Implementation Plan

**Status:** Draft (in `/plan-eng-review`; architecture reversed to HYBRID mid-review)
**Date:** 2026-07-16
**Depends on:** shipped Duʿā Times engine (`lib/services/dua_window_engine.dart`); existing OneSignal cron `supabase/functions/send-scheduled-notifications/index.ts`; spec `docs/superpowers/specs/2026-07-15-dua-acceptance-times-widget-design.md`

> **Decision reversal (2026-07-16, during eng-review):** an all-local design was reviewed, then reversed to **HYBRID** at the user's direction — the reliability of precise-window delivery (dormant users, travel, DST) outweighed the on-device-location invariant for the precise windows. Calendar windows stay local; precise windows move to server-push. The server-side surface introduced here has NOT yet been through a full architecture review — see the review report.

## 1. Goal

Remind the user at the right local time that a duʿā-acceptance window is open, driving re-entry into **Build-a-Duʿā**. Hybrid delivery so the flagship precise windows (last-third-of-night, Friday hour, iftar) fire **even when the app is closed / the user has traveled**.

## 2. Architecture decision: HYBRID

| Window class | Delivery | Why |
|---|---|---|
| **Calendar** (ʿArafah, White Days, Ramadan, Laylat al-Qadr, ʿAshura, Eid, Dhul-Ḥijjah) | **LOCAL** (`flutter_local_notifications`) | Date-only, no location, schedulable 30–60d out. Local keeps them private + free, no dormancy problem. |
| **Precise** (last-third-of-night, Friday hour, iftar) | **SERVER-PUSH** (OneSignal via a Supabase cron) | Fire time depends on the user's coarse location + prayer math. Server fires regardless of app-open → solves dormancy, travel, and DST that the all-local model could not. |

**What this reuses (big win):** the app already runs `send-scheduled-notifications` (Supabase cron → OneSignal) gated on `push_enabled` + `push_enabled_last_verified_at`, plus the `user_notification_preferences` table and per-category opt-in model. The precise-window path **extends this existing cron**, it doesn't build a new push stack. Net-new server work is the **per-user prayer-time computation**, not the delivery pipe.

### 2.1 Free-tier / quota verification (explicit — the user's headline question)

| Path | Quota? | Verdict |
|---|---|---|
| **Calendar → local** | None (iOS schedules on-device) | ✅ free, unlimited |
| **Precise → OneSignal server-push** | OneSignal free tier = **unlimited mobile push** (web-push + Journeys are the only capped things; neither used) | ✅ no send cap to surpass |
| **Supabase cron + prayer-calc** | Runs on the existing scheduler; extra compute is per-user prayer times once/day | ✅ within current plan; monitor invocation time as users grow |

**Answer:** even with server-push, **mobile push is unlimited on OneSignal's free tier**, so there is no send quota to exceed. The only cost dimension that scales with users is Supabase cron compute (one prayer-time calc per opted-in user per day) — cheap, and bounded by the existing cron's cadence. No monetary free-tier ceiling is at risk.

## 3. Data sources

- **Calendar windows:** seeded `dua_windows` table (18 rows, ~1yr: 2026-07-27 → 2027-06-18) + bundled asset. Read on-device via the engine; scheduled locally.
- **Precise windows:** computed **server-side** from the user's stored **coarse lat/lon + IANA tz** (synced from `LocationService` + `flutter_timezone`, same values the on-device engine already resolves). The server runs the prayer-time math (a Deno prayer-times computation — port/lib equivalent to `adhan_dart`) per opted-in user per day and enqueues OneSignal sends at each window's local instant.

## 4. Architecture

```
CALENDAR (local)                              PRECISE (server-enqueue of client-computed instants)
Duʿā card / foreground                         Flutter: on opt-in / location or tz change
  │ engine.buildSchedule (calendar only)        │ engine computes a 30-45d horizon of
  ▼                                             │ precise-window {type, fireUtc} instants
DuaNotificationScheduler.reschedule()          ▼ sync the list (version-stamped) →
  │ filter + reserved dua id band              dua_precise_notifications (RLS, user-private)
  │ targeted cancel + zonedSchedule             │
  ▼                                            Supabase cron (extends send-scheduled-notifications):
flutter_local_notifications (on-device)         │ SELECT instants due in the next tick  ← indexed, no per-user math
                                                │ enqueue OneSignal push (fatigue + quiet-hours honored)
                                                ▼
                                              OneSignal → device (fires app-closed)
```

- **Local side (new):** `lib/services/dua_notification_scheduler.dart` — calendar-only. Keeps all the review hardening below.
- **Single prayer engine (Server Issue 1):** the on-device `DuaWindowEngine` is the ONLY prayer-time source. There is NO server-side prayer math — eliminating the drift risk of two engines. The client computes a **30–45 day** horizon of precise-window instants (cheap on-device; the current engine horizon is 7d and must be extended for the sync path) and syncs the list.
- **Server side (new):** a `dua_precise_notifications` table (`user_id, window_type, fire_utc, sync_version`) — **RLS-guarded, user-private, never public**. The cron **extends `send-scheduled-notifications`**: a simple indexed `WHERE fire_utc BETWEEN now() AND now()+tick` query enqueues due pushes (no per-user compute, no N+1). Alternative to evaluate: hand OneSignal `send_after` scheduled sends directly instead of a polling cron (D3).
- **Client sync (targeted replace):** on opt-in / significant-location-change / tz-change, the client replaces its rows atomically by `sync_version` (server-side analogue of the local id-band targeted cancel — never a blind delete-all).
- **Privacy win:** the client syncs **derived timestamps, not raw lat/lon**. The server never stores the user's coordinates — a materially smaller privacy footprint than the coords-on-server design (see §5).

### Review hardening (still applies to the LOCAL calendar path)
- **Delegate coexistence (Issue 1, BLOCKING):** OneSignal 5.x and `flutter_local_notifications` both want the `UNUserNotificationCenter` delegate. Phase 0 device spike: pin ownership; assert a local calendar-notification tap routes to `/duas` AND OneSignal open-tracking still fires. (Precise windows are OneSignal-native, so their taps already route through OneSignal.)
- **Reserved dua id band + targeted cancel (Issue 2):** local calendar ids live in a reserved band; cancel only that band, never `cancelAll`. Survey OneSignal's own local-notification id usage first (Risk 7).
- **Throttle + skip-if-unchanged (Issue 3):** local reschedule at most once/N min; skip OS churn when the computed set is byte-identical (hash & compare, mirroring `WidgetDataService`).
- **Authorization level (Risk 5):** check OneSignal auth is `authorized`, not merely `provisional` (provisional = silent delivery, no buzz).

## 5. Privacy (improved by Server Issue 1)

With client-computes-instants, **raw location never leaves the device** — the client syncs derived `fire_utc` timestamps, not lat/lon. So the on-device-location invariant is largely preserved:
- **No `Location` data-type disclosure is required** (no coordinates are transmitted or stored).
- The synced timestamps are user-private schedule data → RLS-guarded; declared under App Privacy as App-Functionality data (schedule/usage), NOT Location. No ATT (not tracking).
- **Caveat to verify with legal/App-Review framing:** prayer-time timestamps *correlate* to approximate longitude/latitude, so a determined observer could infer coarse region. This is far weaker than transmitting coordinates, but the opt-in copy should still be honest ("to remind you at the right local times, Sakina's servers hold your upcoming reminder times; your location never leaves your phone").
- Calendar-only users never sync anything.

## 6. Opt-in & preferences

- One category `notify_dua_windows` in `user_notification_preferences`. Opt-in gates BOTH the local calendar schedule AND the server precise-window enqueue (and the coarse-coords sync).
- Default: opt-in ON after first Duʿā Times engagement; global mute respected (verify the global-mute construct exists in `notification_service.dart` before depending on it — outside-voice #5).
- **Fatigue policy (D1):** night-third precise push defaults to Friday / White Days / Laylat nights, not nightly; full-nightly optional.

## 7. Phased implementation

**Phase 0 — deps + delegate spike (local side)** — add `flutter_local_notifications` + `timezone`; init at boot; **BLOCKING delegate coexistence spike** (Issue 1) + auth-level check (Risk 5).
**Phase 1 — local calendar scheduler** — `DuaNotificationScheduler` (calendar-only): reserved id band, targeted cancel, throttle + skip-if-unchanged, deterministic ids, degrade silently.
**Phase 2 — server enqueue path** — new RLS-guarded `dua_precise_notifications` table (`user_id, window_type, fire_utc, sync_version`); extend `send-scheduled-notifications` with a due-instants query that enqueues OneSignal pushes (NO server prayer math). Respect fatigue policy (client already filtered) + quiet-hours dedup so it never double-buzzes the existing daily/streak cron (outside-voice #9). Extend the client engine horizon to 30–45d for the precise-sync path only.
**Phase 3 — client sync + opt-in + copy** — sync coarse coords + tz on opt-in / location change; `notify_dua_windows` toggle; per-window copy + i18n (no Arabic/English mixing).
**Phase 4 — tests** — LOCAL: cap/id-band/targeted-cancel-survives-foreign-id/tz/opt-out/degrade/permission-denied (unit, fake plugin). SERVER: pgTAP/Deno tests for the prayer-calc correctness (known lat/lon/date fixtures), the enqueue timing, RLS on the coords columns, and the quiet-hours dedup. Device/E2E: local calendar tap → `/duas`; a precise push fires app-closed at the right local instant.

## 8. Open decisions (recommendations — confirm)
- **D1 — night-third cadence:** default Friday / White Days / Laylat, not nightly (fatigue).
- **D2 — precise fire point:** at window open (server enqueues at the exact local instant).
- **D3 — enqueue mechanism:** a polling cron (`WHERE fire_utc BETWEEN now() AND now()+tick`) vs handing OneSignal `send_after` scheduled sends directly at sync time. Rec: start with the polling cron (reuses the existing scheduler, easy to cancel/replace on re-sync); evaluate `send_after` if cron latency matters.
- **D4 — sync horizon + triggers:** how many days of precise instants to sync (rec: 30–45d) and when to re-sync (rec: opt-in, significant-location-change, tz-change, and a periodic refresh on app open). Longer horizon = more dormancy coverage at ~no cost.

## 9. Risks
1. **Sync-horizon dormancy** — precise pushes only exist for the synced 30–45d horizon; a user dormant longer goes dark until reopen. Far better than all-local; longer horizon costs ~nothing. LOW–MED. (No server prayer-calc drift risk anymore — single engine.)
2. **Sync-replace correctness** — re-syncing must atomically replace the user's rows by `sync_version` (never blind delete-all mid-cron, or a push could be dropped/duplicated). Pin with a test. MED.
3. **RLS on `dua_precise_notifications`** — `fire_utc` rows are user-private; must be RLS-guarded (NOT public). HIGH if missed.
4. **Delegate coexistence (local side)** — Issue 1 spike gates Phase 1. MED.
5. **Double-buzz vs existing cron** — precise pushes + daily/streak cron need shared quiet-hours/dedup. MED.
6. **Privacy framing** — timestamps correlate to coarse region; opt-in copy must be honest even though raw coordinates never leave the device. LOW–MED.
7. **Stale/duplicate pushes on OneSignal** — if using `send_after` (D3), re-sync must cancel previously-scheduled OneSignal messages; the polling-cron path avoids this. Scoped by D3.

## 10. NOT in scope
- Rain window, Live Activities (separate Phase 2 plans).
- Full server-push for calendar windows (kept local — no location needed, privacy-preserving).
- Re-engagement/lapsed-user campaigns beyond the window reminders.

## 11. What already exists (reused, not rebuilt)
- `send-scheduled-notifications` cron + OneSignal delivery + `push_enabled` freshness gate → extended, not replaced.
- `user_notification_preferences` + per-category opt-in model → one new category + coords/tz columns.
- `DuaWindowEngine` (calendar windows) → local scheduler consumes it directly.
- `flutter_timezone`, `LocationService.getCoarseLocation` → coords/tz sync source.
- `WidgetDataService` byte-identical perf guard → pattern for the local skip-if-unchanged.

## 12. Effort
- Local calendar path: ~2–3 days.
- Client engine 30–45d horizon + instant sync (targeted-replace): ~1–2 days.
- Server enqueue path (RLS table + due-instants query in the cron + tests): ~2–3 days *(down from ~4–6 — no server prayer engine after Server Issue 1)*.
- Opt-in + copy + privacy framing: ~1–2 days.
- **Total ~6–10 dev-days** (the single-engine design shaved the server surface vs the coords-on-server variant).

## Implementation Tasks
Synthesized from this review. P1 blocks ship; P2 same-branch.

- [ ] **T1 (P1, human: ~2-3d / CC: ~30min)** — server-enqueue — Extend `send-scheduled-notifications` with a due-instants query that enqueues OneSignal pushes (NO server prayer math)
  - Surfaced by: Server Issue 1 (single prayer engine — client computes instants, server enqueues)
  - Files: `supabase/functions/send-scheduled-notifications/index.ts`
  - Verify: Deno test — rows with `fire_utc` in the tick window enqueue exactly once; quiet-hours honored
- [ ] **T2 (P1, human: ~0.5d / CC: ~10min)** — db-rls — RLS-guarded `dua_precise_notifications` table (`user_id, window_type, fire_utc, sync_version`)
  - Surfaced by: Risk 3 (fire_utc rows are user-private, must NOT be public-readable)
  - Files: `supabase/migrations`
  - Verify: pgTAP — anon/other-user cannot read another user's rows
- [ ] **T2b (P1, human: ~1-2d / CC: ~20min)** — client-sync — Extend engine to a 30–45d precise horizon + atomic sync-by-`sync_version` (targeted replace)
  - Surfaced by: Server Issue 1 + Risk 2 (sync-replace correctness)
  - Files: `lib/services/dua_window_engine.dart`, `lib/services/` (sync seam)
  - Verify: `flutter test` — re-sync replaces prior rows, no drop/dup; horizon length
- [ ] **T3 (P1, human: ~0.5d / CC: ~20min)** — ios-notif — Phase 0 delegate coexistence spike + auth-level check
  - Surfaced by: Issue 1 + Risk 5
  - Files: `ios/Runner`
  - Verify: device — local tap routes `/duas`, OneSignal opens still count, auth is `authorized` not `provisional`
- [ ] **T4 (P2, human: ~2-3d / CC: ~30min)** — local-scheduler — `DuaNotificationScheduler` (calendar-only): reserved id band, targeted cancel, throttle + skip-if-unchanged
  - Surfaced by: Issues 2, 3
  - Files: `lib/services/dua_notification_scheduler.dart`
  - Verify: `flutter test` — foreign id survives, cap, tz, opt-out clears band
- [ ] **T5 (P2, human: ~1d / CC: ~20min)** — server-tests — prayer-calc correctness vs client fixtures, enqueue timing, quiet-hours dedup, RLS
  - Surfaced by: Test review + outside-voice #9
  - Files: `supabase/tests`
  - Verify: pgTAP + Deno test green in CI

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 2 | ISSUES_OPEN | Pass 1 (local): 3 issues folded + reversal all-local → HYBRID. Pass 2 (server): Server Issue 1 → single prayer engine (client computes instants, server enqueues) — killed the drift risk + shrank privacy footprint & server scope |
| Outside Voice | `/plan-eng-review` (Claude subagent; codex broken on host) | Independent 2nd opinion | 1 | ISSUES_FOUND | 10 findings; 6 folded as hardening, #10 triggered the hybrid reversal |
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | — | — |

**Completion summary:** Pass 1 (local) — Step 0 scope accepted · Arch 1 + reversal · Code Quality 1 · Test 3 unit + 1 device gap · Perf 1 · outside voice 10 findings (6 folded). Pass 2 (server) — Server Issue 1 resolved: NO server prayer math; on-device engine is the single source of truth; client syncs derived `fire_utc` instants (RLS table), server is a dumb due-instants enqueuer. Critical gaps: down to 0 blocking (was 2 — server prayer-calc drift eliminated; coords-on-server eliminated). Parallelization: Lane A local scheduler (`lib/services/`), Lane B server enqueue (`supabase/`), Lane C client sync (`lib/services/`) — A+B parallel, C integrates.

**CROSS-MODEL:** review + outside voice agreed on local-path hardening; diverged on core architecture (#10) — user reversed to hybrid; Pass 2 then simplified the hybrid to a single-engine design.

**VERDICT:** ENG reviewed across BOTH the local calendar path and the hybrid server surface; all architecture findings folded, no blocking critical gaps remain. Ship-cleared to implement once the 4 product/mechanism decisions (D1–D4) are confirmed. Recommended: a quick `/plan-design-review` on the opt-in + privacy-framing copy before build.

**UNRESOLVED DECISIONS:**
- D1 night-third cadence (default Fri/White/Laylat vs nightly) — not confirmed
- D2 precise fire point — not confirmed
- D3 enqueue mechanism (polling cron vs OneSignal `send_after`) — not confirmed
- D4 sync horizon length + re-sync triggers — not confirmed
