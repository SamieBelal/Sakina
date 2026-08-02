# Daily-Loop UTC Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align `daily_loop_provider.dart` and its downstream consumers (quest week/month boundaries) to UTC, matching the `daily_rewards_service` / `streak_service` / `claim_daily_reward` RPC clock that the launch-gate fix (PR #8) already standardised. Eliminate the 51% local-vs-UTC date disagreement currently visible in production `user_checkin_history` data.

**Architecture:** Mirror the exact `debugLaunchGateClock` / `debugRewardsClock` seam pattern from PR #8:
1. Add `@visibleForTesting debugDailyLoopClock = () => DateTime.now().toUtc()` to `daily_loop_provider.dart` and route the three time-keyed callsites (`_todayKey`, the two `CheckInRecord.date` writes) through it.
2. Add `@visibleForTesting debugQuestBoundariesClock = () => DateTime.now().toUtc()` to `quests_provider.dart` so `_weekStart()` / `_monthStart()` align with the now-UTC `CheckInRecord.date` they're compared against. Without this, the quest counters would silently break for users west of UTC.
3. Pin both seams with regression tests that mock the clock to a local-vs-UTC midnight boundary and assert SharedPrefs key shape, checkin write, and quest counting all agree.

The greeting-hour and dua-rotation `DateTime.now()` callsites stay LOCAL — they're perceptual (what hour-of-day the user *feels* it is), not data keys.

**Tech Stack:** Flutter 3.41.6 / Dart 3.11.4, Riverpod (StateNotifier), SharedPreferences, `flutter_test` with `FakeSupabaseSyncService`.

---

## Background — why this matters

Pulled from production `user_checkin_history` on 2026-05-12: **91 of 177 paired rows (51%) had `checked_in_at` disagreeing with the same user's `user_activity_log.active_date` by exactly one day** over a 60-day window. The client writes a local-date-string (`'2026-05-12'`) into a `timestamptz` column, which Postgres parses as midnight UTC. 100% of recent rows in `user_checkin_history` have `00:00:00` UTC time component — proving the precision is "day" not "moment", and the day boundary is local.

Symptoms in the field:
- Users crossing local midnight while still in the same UTC day see "fresh muhasabah available" because the local SharedPrefs key changed (`daily_loop_<local-date>`) while the server still considers them already-checked-in for that UTC day.
- `user_checkin_history.checked_in_at` doesn't reflect when the user actually did the thing — it reflects what the client thought the local date was, cast to midnight UTC.
- Journal display, history-based AI context, and dedup all read this corrupted timestamp.

The fix landed for the launch-gate in PR #8 (`debugLaunchGateClock` / `debugRewardsClock`). This plan extends the same seam pattern to the remaining local-time callsites in the daily loop.

---

## File Structure

**Modify:**
- `lib/features/daily/providers/daily_loop_provider.dart` — add `debugDailyLoopClock` seam; replace three `DateTime.now()` callsites (lines 254, 445, 610).
- `lib/features/quests/providers/quests_provider.dart` — add `debugQuestBoundariesClock` seam; replace `_weekStart()` / `_monthStart()` `DateTime.now()` callsites (lines 555, 562).

**Create:**
- `test/features/daily/daily_loop_utc_test.dart` — pins UTC behaviour of `_todayKey` and `CheckInRecord.date` writes at a local-vs-UTC midnight boundary.
- `test/features/quests/quests_provider_utc_boundaries_test.dart` — pins that `_weekStart()` / `_monthStart()` are UTC and agree with `CheckInRecord.date` counts.

**Do NOT modify:**
- `lib/services/checkin_history_service.dart` — already pipes `CheckInRecord.date` through to `checked_in_at` faithfully; the fix is upstream at the write callsite.
- `lib/features/journal/screens/journal_screen.dart` — uses `DateTime.parse(r.date)` which now gets UTC-derived input automatically.
- The greeting-hour callsites at `daily_loop_provider.dart:277, 328, 333` — perceptual time-of-day, not date keys.
- Existing rows in `user_checkin_history` — leave them; the 91 disagreeing rows will age out, and re-writing them server-side is high-risk for low value (historical analytics only).

---

## Task 1: Add `debugDailyLoopClock` seam + route `_todayKey` through it

**Files:**
- Modify: `lib/features/daily/providers/daily_loop_provider.dart` (add import, add seam, change `_todayKey`)
- Create: `test/features/daily/daily_loop_utc_test.dart`

- [ ] **Step 1: Write the failing test** — `test/features/daily/daily_loop_utc_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-A');
    SupabaseSyncService.debugSetInstance(fakeSync);
    debugDailyLoopClock = () => DateTime.utc(2026, 5, 13, 4, 30);
  });

  tearDown(() {
    SupabaseSyncService.debugReset();
    debugDailyLoopClock = () => DateTime.now().toUtc();
  });

  test(
    'daily-loop SharedPrefs key uses UTC date even when local time is the previous day',
    () async {
      // Simulates 11:30 PM EST on 2026-05-12 (= 04:30 UTC on 2026-05-13).
      // The local date is 2026-05-12 but the UTC date is 2026-05-13.
      // After the fix, the key must use UTC.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Trigger one persist by reading the notifier (its constructor calls _initialize
      // which eventually persists). For the key-shape assertion we don't need a full
      // lifecycle — just call the notifier's persist path indirectly.
      // Simpler: read the notifier so it's constructed, then directly verify the
      // key the persist would use by checking SharedPrefs keys after a manual
      // persist trigger via skipAll() which calls _persistTodayState() internally.
      final notifier = container.read(dailyLoopProvider.notifier);
      await notifier.skipAll();

      final prefs = await SharedPreferences.getInstance();
      final scopedKey =
          SupabaseSyncService.instance.scopedKey('daily_loop_2026-05-13');
      expect(
        prefs.getString(scopedKey),
        isNotNull,
        reason: 'SharedPrefs key must be keyed by UTC date 2026-05-13, not local 2026-05-12',
      );

      final localKey =
          SupabaseSyncService.instance.scopedKey('daily_loop_2026-05-12');
      expect(
        prefs.getString(localKey),
        isNull,
        reason: 'Stale local-date key must NOT be written',
      );
    },
  );
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/daily/daily_loop_utc_test.dart`
Expected: FAIL — `debugDailyLoopClock` is undefined (compile error), or once the seam exists, the local-key check finds the key written under `daily_loop_2026-05-12` instead.

- [ ] **Step 3: Add the seam + route `_todayKey` through it** — `lib/features/daily/providers/daily_loop_provider.dart`

Find the existing imports at the top of the file. Verify `package:flutter/foundation.dart` is imported. If not, add this import alongside the other imports:

```dart
import 'package:flutter/foundation.dart';
```

(`flutter/foundation.dart` exposes both `debugPrint` and `@visibleForTesting` — the file already uses `debugPrint` at line 464, 561, 581, 583, 623, so the import is almost certainly already there. If `grep -n "package:flutter/foundation" lib/features/daily/providers/daily_loop_provider.dart` returns nothing, add it.)

Then find the existing `_todayKey` getter at line 253-258, which looks like:

```dart
  String get _todayKey {
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return supabaseSyncService.scopedKey('daily_loop_$date');
  }
```

Replace it AND insert the top-level seam directly above the `DailyLoopNotifier` class declaration. Specifically:

(a) Find the line `class DailyLoopNotifier extends StateNotifier<DailyLoopState> {` (around line 204). Directly above it, insert:

```dart
/// Test seam — replace in tests via `debugDailyLoopClock = ...` to drive
/// the daily-loop date math at deterministic UTC instants. Production
/// callers always read `DateTime.now().toUtc()`. Mirrors `debugLaunchGateClock`
/// (`launch_gate_state.dart`) and `debugRewardsClock` (`daily_rewards_service.dart`)
/// so all three modules agree on the day boundary. Without this seam the
/// daily-loop SharedPrefs key was keyed by local date while the server-side
/// `claim_daily_reward` RPC keyed by UTC, causing a "fresh muhasabah"
/// flicker for users crossing local midnight on the same UTC day. See PR #8
/// for the matching launch-gate fix and `TODO.md` for the prior context.
@visibleForTesting
DateTime Function() debugDailyLoopClock = () => DateTime.now().toUtc();
```

(b) Replace the `_todayKey` getter body to read the seam:

```dart
  String get _todayKey {
    final now = debugDailyLoopClock();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return supabaseSyncService.scopedKey('daily_loop_$date');
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/daily/daily_loop_utc_test.dart`
Expected: PASS — the SharedPrefs key is now `daily_loop_2026-05-13` (UTC), no local-keyed entry exists.

- [ ] **Step 5: Run the pre-existing daily-loop test for regression**

Run: `flutter test test/features/daily/daily_loop_scoped_key_test.dart test/features/daily/daily_loop_reset_today_test.dart`
Expected: PASS — both pre-existing tests still pass. They use the key infrastructure but don't assert any specific date string.

- [ ] **Step 6: Commit**

```bash
git add lib/features/daily/providers/daily_loop_provider.dart test/features/daily/daily_loop_utc_test.dart
git commit -m "fix(daily-loop): key SharedPrefs cache by UTC date to match server clock

Mirrors the debugLaunchGateClock / debugRewardsClock seam pattern
shipped in PR #8. _todayKey was keying daily_loop_<local-date> while
the server-side claim_daily_reward RPC and streak service use UTC,
causing 51% of paired user_checkin_history vs user_activity_log
rows to disagree by one day in production. Pinned by
daily_loop_utc_test."
```

---

## Task 2: Route the two `CheckInRecord.date` writes through the same seam

**Files:**
- Modify: `lib/features/daily/providers/daily_loop_provider.dart:445, 610`
- Modify: `test/features/daily/daily_loop_utc_test.dart` (add second test case)

**Decision from `/plan-eng-review`:** Task 2's original widget-test (which wrapped `discoverName()` in try/catch and asserted on the cached history JSON) was removed as fragile. Both write callsites use the SAME `debugDailyLoopClock` seam that Task 1's `_todayKey` test already pins, so the date writes are transitively covered. Skip writing a new test in this task; jump straight to the source edit.

- [ ] **Step 1: Route the two `CheckInRecord.date` writes** — `lib/features/daily/providers/daily_loop_provider.dart`

Find the first write site at lines 444-447 (inside `discoverName`, after the card is engaged):

```dart
      // Save to history
      try {
        final today = DateTime.now();
        final dateStr =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
```

Replace `final today = DateTime.now();` with:

```dart
        final today = debugDailyLoopClock();
```

Find the second write site at lines 609-612 (inside `answerCheckin`, after the AI returns):

```dart
      // Save check-in to history
      try {
        final today = DateTime.now();
        final dateStr =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
```

Replace `final today = DateTime.now();` with:

```dart
        final today = debugDailyLoopClock();
```

(Two identical one-line edits.)

- [ ] **Step 2: Run Task 1's test to verify it still passes**

Run: `flutter test test/features/daily/daily_loop_utc_test.dart`
Expected: PASS — Task 1's test still passes (the new writes don't break the existing assertion).

- [ ] **Step 3: Run the broader daily-feature suite for regression**

Run: `flutter test test/features/daily/`
Expected: PASS — all pre-existing tests + Task 1's new test pass.

- [ ] **Step 4: Commit**

```bash
git add lib/features/daily/providers/daily_loop_provider.dart test/features/daily/daily_loop_utc_test.dart
git commit -m "fix(daily-loop): route CheckInRecord.date writes through debugDailyLoopClock

Both write sites (discoverName at L445 + answerCheckin at L610) wrote
CheckInRecord.date from DateTime.now() (local) which then propagated
into user_checkin_history.checked_in_at as 'local-date midnight UTC'.
Now uses debugDailyLoopClock() so the persisted date agrees with the
SharedPrefs key from Task 1 and the server-side UTC clock."
```

---

## Task 3: Align quest week/month boundaries with the now-UTC `CheckInRecord.date`

**Why this is mandatory, not optional:** `quests_provider.dart:1711, 1766` count reflections + muhasabahs per week/month by parsing `r.date` and comparing against `_weekStart()` / `_monthStart()`. After Tasks 1+2, `r.date` is UTC. If `_weekStart()` stays local (i.e. midnight Monday in the user's local timezone), then for users west of UTC the week boundary will fire AFTER UTC's week rollover, double-counting Sunday-night-local reflections into the wrong week. The fix only works end-to-end if the boundaries match the data.

**Files:**
- Modify: `lib/features/quests/providers/quests_provider.dart:554-564`
- Create: `test/features/quests/quests_provider_utc_boundaries_test.dart`

- [ ] **Step 1: Write the failing test** — `test/features/quests/quests_provider_utc_boundaries_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    debugQuestBoundariesClock = () => DateTime.now().toUtc();
  });

  test('weekStart returns the UTC Monday midnight, not local Monday', () {
    // 11:30 PM EST on Sunday 2026-05-10 = 04:30 UTC on Monday 2026-05-11.
    // Local week would still be the previous week; UTC week starts at
    // 2026-05-11 00:00 UTC (Monday).
    debugQuestBoundariesClock = () => DateTime.utc(2026, 5, 11, 4, 30);
    final weekStart = debugQuestWeekStart();
    expect(weekStart, DateTime.utc(2026, 5, 11));
    expect(weekStart.isUtc, isTrue);
  });

  test('monthStart returns the 1st of the UTC month', () {
    debugQuestBoundariesClock = () => DateTime.utc(2026, 5, 13, 4, 30);
    final monthStart = debugQuestMonthStart();
    expect(monthStart, DateTime.utc(2026, 5, 1));
    expect(monthStart.isUtc, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/quests/quests_provider_utc_boundaries_test.dart`
Expected: FAIL — `debugQuestBoundariesClock`, `debugQuestWeekStart`, `debugQuestMonthStart` are all undefined (compile error).

- [ ] **Step 3: Add the seam + UTC boundaries + test seams** — `lib/features/quests/providers/quests_provider.dart`

Verify `package:flutter/foundation.dart` is imported at the top of the file. If not, add it (the file uses `debugPrint` elsewhere so it's likely already imported).

Find lines 553-564:

```dart
/// Midnight at the start of this week's Monday (local time).
DateTime _weekStart() {
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  return DateTime(monday.year, monday.month, monday.day);
}

/// Midnight at the start of the 1st of this month (local time).
DateTime _monthStart() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
}
```

Replace with:

```dart
/// Test seam — replace in tests via `debugQuestBoundariesClock = ...` to drive
/// quest week/month rollover at deterministic UTC instants. Production callers
/// always read `DateTime.now().toUtc()`. Quest counters compare against
/// `CheckInRecord.date` and `SavedReflection.date`, both of which are now
/// UTC-derived (see `debugDailyLoopClock` in `daily_loop_provider.dart`),
/// so the boundaries must also be UTC or users west of UTC double-count
/// Sunday-night-local reflections into the wrong week.
@visibleForTesting
DateTime Function() debugQuestBoundariesClock = () => DateTime.now().toUtc();

/// Midnight at the start of this UTC week's Monday.
DateTime _weekStart() {
  final now = debugQuestBoundariesClock();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  return DateTime.utc(monday.year, monday.month, monday.day);
}

/// Midnight at the start of the 1st of this UTC month.
DateTime _monthStart() {
  final now = debugQuestBoundariesClock();
  return DateTime.utc(now.year, now.month, 1);
}

/// Test seam — exposes `_weekStart()` for the regression test without
/// making the production helper public.
@visibleForTesting
DateTime debugQuestWeekStart() => _weekStart();

/// Test seam — exposes `_monthStart()` for the regression test without
/// making the production helper public.
@visibleForTesting
DateTime debugQuestMonthStart() => _monthStart();
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/quests/quests_provider_utc_boundaries_test.dart`
Expected: PASS — both tests pass, both `weekStart` and `monthStart` are UTC.

- [ ] **Step 5: Run the broader quests test suite for regression**

Run: `flutter test test/features/quests/`
Expected: PASS — any pre-existing quest tests still pass. If any pre-existing test asserts a specific local-time date, the test must be updated to UTC — but no quest tests are expected to make such assertions because quest counters compare relative dates, not absolute ones.

- [ ] **Step 6: Commit**

```bash
git add lib/features/quests/providers/quests_provider.dart test/features/quests/quests_provider_utc_boundaries_test.dart
git commit -m "fix(quests): align _weekStart / _monthStart with now-UTC CheckInRecord.date

Tasks 1+2 made daily_loop_provider write CheckInRecord.date as a UTC
date string. quests_provider counts these per week/month using
_weekStart()/_monthStart() which were local-Monday/local-1st. For
users west of UTC this would double-count Sunday-night-local
reflections into the wrong UTC week. Both boundaries now use the
debugQuestBoundariesClock seam (UTC by default). Pinned by
quests_provider_utc_boundaries_test."
```

---

## Task 4: Full-suite verification + manual sanity check

**Files:**
- (No code changes — verification only)

- [ ] **Step 1: Run the full Flutter test suite**

Run: `flutter test`
Expected: All tests pass. Pay particular attention to:
- `test/features/daily/` (25+ pre-existing + 2 new)
- `test/features/quests/` (pre-existing + 2 new)
- `test/services/launch_gate_*` (3 pre-existing + 5 new from PR #8 — these should be unaffected by this PR)

If any test fails, classify (Test Failure Ownership Triage from `/ship`):
- **In-branch failure** (related to anything you touched) → STOP, fix, re-test.
- **Pre-existing failure** (untouched code) → note it in the PR body and proceed.

- [ ] **Step 2: Run `flutter analyze` for new warnings/errors**

Run: `flutter analyze`
Expected: No new errors or warnings beyond the ~54 pre-existing infos noted in `CLAUDE.md` / `MEMORY.md`.

- [ ] **Step 3: Manual sanity check on iOS simulator (optional but recommended)**

This isn't a strict regression-test — it's an end-to-end sanity check that the daily-loop UX still works after the clock change.

```bash
xcrun simctl boot "iPhone 17" 2>/dev/null || true
flutter run --dart-define-from-file=env.json -d "$(xcrun simctl list devices booted -j | python3 -c 'import json,sys; d=json.load(sys.stdin); print([v[0]["udid"] for v in d["devices"].values() if v][0])')"
```

On the simulator:
1. Sign in as a test user.
2. Tap "Begin Muḥāsabah" on the home screen.
3. Complete the discover-name flow (any choice).
4. Force-close the app.
5. Cold-launch again. Expected: the daily loop screen shows "Muḥāsabah Done" state (already-completed today), not a fresh start.

If the home tile flickers between "fresh" and "done" states across cold launches, the clock is still drifting somewhere. Stop and investigate. If it's stable, ship.

- [ ] **Step 4: No commit (verification-only task)**

Move on to the GSTACK Review Report below.

---

## NOT in scope

- **Backfilling existing `user_checkin_history` rows** with corrected UTC dates. The 91 disagreeing rows from the 60-day production sample will age out; rewriting them is high-risk for low value (historical analytics only).
- **Greeting-hour and dua-rotation `DateTime.now()` callsites** at `daily_loop_provider.dart:277, 328, 333`. These are perceptual ("it's morning, say morning") not date keys, and switching them to UTC would surprise users in non-UTC timezones (an EDT user opening the app at 7am local would see "End the day with remembrance"). Leave local.
- **Server-side migration** to add a separate `date` column to `user_checkin_history` distinct from `checked_in_at`. The schema as-is (single timestamptz storing date-only at midnight UTC) is fine once the client writes UTC dates correctly.
- **TODO #4 (unknown-name fallback telemetry)** — separate plan / separate PR. This plan is scoped to issue #5 only.

---

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | CLEAR (PLAN) | 1 issue (Task 2 fragile test) resolved — testWidgets removed, source edit kept; transitive coverage via Task 1 seam test |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | — | — |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

**UNRESOLVED:** 0
**VERDICT:** ENG CLEARED — ready to implement
