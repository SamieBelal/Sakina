# PR #26 Deferred Follow-Ups Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans or an equivalent task-by-task workflow to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship one PR that closes the two actionable follow-ups from `flutter/TODOS.md`: add PR CI for Flutter and Supabase SQL tests, and fix the remaining AI-bypass reservation cleanup gap in `DailyLoopNotifier.discoverNameWithBypass`. As part of the dispose-hoist work, extract the now-3-site bypass-flow lifecycle into a `BypassFlowMixin` (the code's own pre-stated extraction threshold).

**Architecture:** Two focused workstreams:
1. CI adds a repo-root GitHub Actions workflow plus a small SQL-test runner script. The runner self-seeds an `auth.users` row so tests don't depend on existing branch DB data.
2. Extract `BypassFlowMixin` from the duplicated state in `ReflectNotifier` and `DuasNotifier`, then make `DailyLoopNotifier.discoverNameWithBypass` adopt it. Refactor Reflect + Duas to consume the mixin so we don't ship 3 copies of the same lifecycle.

**Tech Stack:** Flutter 3.41.6 / Dart 3.11.4, Riverpod `StateNotifier`, `subosito/flutter-action@v2` pinned to channel `stable` and version `3.41.6`, GitHub Actions, Supabase Preview Branches (per-PR branch DB via the GitHub integration), `psql` from `postgresql-client`, existing project SQL tests under `flutter/supabase/tests/*.sql`.

**Out of scope:** Do not remove the 1-arg `reserve_ai_bypass(text)` compatibility shim in this PR. That item remains blocked until 60+ days of adoption telemetry from PR #26 deployment shows old IPAs have drained.

---

## What Already Exists

- `flutter test` is already the canonical Dart test command in `flutter/CLAUDE.md`.
- `flutter/supabase/tests/*.sql` already contains SQL regression tests for AI bypass, freemium guards, notification eligibility, and IAP upsell dismissal. `ai_bypass_rpc_test.sql:78` already self-seeds an `auth.users` row inline; the convention exists and Task 1.2 extends it to the other test files.
- `ReflectNotifier` and `DuasNotifier` already implement the desired bypass lifecycle: track the active reservation id, track the in-flight reserve future, cancel active reservations on dispose, and chain a cancel if dispose happens before reserve resolves. **Pre-stated extraction rule (verbatim from `reflect_provider.dart:323-324`): "If a 4th gated feature is added, extract a BypassFlowMixin — three sites is the YAGNI threshold."** This plan adds the 3rd site, hitting that threshold exactly. Task 2.0 extracts the mixin before adding the 3rd consumer.
- `DailyLoopNotifier.discoverNameWithBypass` (`lib/features/daily/providers/daily_loop_provider.dart:495-516`) already reserves, runs `discoverName`, then commits or cancels. The gaps: (a) the reservation id lives only in a local variable, so `dispose()` cannot see it; (b) no `mounted` check after the awaits; (c) no rapid-tap re-entry guard; (d) no `_inflightReserveFuture` tracking so dispose-before-reserve leaks.
- `DailyLoopNotifier.discoverNameWithFirstBypass` (lines 523-532) shares the same `checkinLoading` guard but has no rapid-tap protection. Plan extends the new re-entry flag to gate it too.

## NOT in Scope

- Drop `reserve_ai_bypass(text)` shim — blocked by 60+ days of app-version adoption telemetry.
- Replace SQL tests with Supabase CLI-native `supabase test db` format — not required for this PR because current tests are plain SQL files and already runnable with `psql`.
- Add local Docker/Supabase dev setup — useful later, but the TODO explicitly calls for branch DB coverage in PR CI.
- Add UI or product changes to the bypass sheet — this is lifecycle cleanup and CI only.
- True-concurrent (multi-connection) SQL race tests for `reserve_ai_bypass` — verified via in-transaction isolation harness in PR #26 already; `pg_background`/`dblink` parallel-connection coverage is a separate ask.

## Data Flow

### CI Pipeline

```text
pull_request
  |
  +--> flutter-tests
  |      checkout
  |      setup Flutter 3.41.6
  |      cd flutter
  |      flutter pub get
  |      flutter test
  |
  +--> sql-tests
         checkout
         wait for Supabase Preview Branch
         fetch branch DATABASE_URL
         install psql
         ensure pgtap extension exists
         cd flutter
         scripts/run_sql_tests.sh
           |
           +--> psql -v ON_ERROR_STOP=1 -f supabase/tests/*.sql
```

### BypassFlowMixin lifecycle (shared across Reflect, Duas, DailyLoop)

```text
mixin BypassFlowMixin<S> on StateNotifier<S>
  fields:
    String? _activeBypassReservationId
    Future<BypassReservation?>? _inflightReserveFuture
    bool _submitInFlight
  abstract:
    GatedFeature get bypassFeature
  helpers:
    Future<BypassReservation?> reserveActiveBypass()
      // sets _submitInFlight, captures _inflightReserveFuture, awaits, clears
      // ownership when identical(_inflightReserveFuture, future). Returns
      // null if rejected. Caller checks !mounted before writing state.
    Future<void> commitActiveBypassIfAny()
    Future<void> cancelActiveBypassIfAny()
    void disposeBypassFlow()
      // call from each notifier's dispose() BEFORE super.dispose():
      // 1. if _activeBypassReservationId != null -> fire-and-forget cancel
      // 2. else if _inflightReserveFuture != null -> chain a cancel on resolve
      // both wrapped try/catch + .ignore()
```

### DailyLoop Bypass Lifecycle (consumes BypassFlowMixin)

```text
discoverNameWithBypass()
  |
  +-- guard: checkinLoading or _submitInFlight -> return
  |
  +-- reserveActiveBypass() [mixin]
  |     |
  |     +-- mixin sets _inflightReserveFuture, awaits, transfers to id on success
  |
  +-- if !mounted -> return (dispose chain owns cleanup)
  +-- if null reservation -> state.error = "Bypass unavailable. Try again."
  |
  +-- await discoverName()
  |     |
  |     +-- success -> state.error == null
  |     +-- failure -> discoverName catches and sets state.error
  |
  +-- if !mounted -> return (dispose chain owns cleanup)
  +-- if state.error != null -> cancelActiveBypassIfAny()
  +-- else                  -> commitActiveBypassIfAny()
  +-- finally: _submitInFlight = false  // unconditional, matches Reflect

discoverNameWithFirstBypass()
  |
  +-- guard: checkinLoading or _submitInFlight -> return  // NEW: shared flag
  |
  +-- claimFirstBypass(discoverName)
  +-- if !claimed -> error
  +-- await discoverName()
  +-- finally: _submitInFlight = false
```

## Task 1 — Add CI for Flutter and SQL Tests

**Files:**
- Create: `.github/workflows/test.yml`
- Create: `flutter/scripts/run_sql_tests.sh`
- Create: `flutter/supabase/tests/_seed_test_user.sql` (shared helper)
- Modify (self-seed audit): every `flutter/supabase/tests/*.sql` that currently does `SELECT id INTO ... FROM auth.users ORDER BY created_at LIMIT 1`. Confirmed candidates: `freemium_guards_bypass_fields_test.sql`, `dismiss_iap_upsell_banner_test.sql`, `freemium_gating_lockdown_test.sql`, `rpc_eligibility_test.sql`, `rpc_eligibility_reminder_time_test.sql`, `sync_all_user_data_returns_verses_test.sql`, `backend_rls_test.sql`. Audit each at Step 1.2.

- [ ] **Step 1.1: Create SQL runner script**

Create `flutter/scripts/run_sql_tests.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

if [ -z "${DATABASE_URL:-}" ]; then
  echo "DATABASE_URL is required" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

for file in $(find supabase/tests -maxdepth 1 -type f -name '*.sql' | sort); do
  echo "::group::SQL test: $file"
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$file"
  echo "::endgroup::"
done
```

- [ ] **Step 1.2: Audit + self-seed every SQL test that depends on existing `auth.users` data**

Each candidate file (listed under Files above) currently starts with a fragment like:

```sql
do $$
declare v_uid uuid;
begin
  select id into v_uid from auth.users order by created_at limit 1;
  if v_uid is null then raise exception 'No auth.users'; end if;
  perform set_config('test.uid', v_uid::text, false);
end $$;
```

This silently no-ops on a fresh branch DB (returns NULL → seed query selects nothing → guard asserts pass vacuously). Replace each with an in-transaction insert into `auth.users`, matching `ai_bypass_rpc_test.sql:78`:

```sql
do $$
declare v_uid uuid := gen_random_uuid();
begin
  insert into auth.users (id, instance_id, aud, role, email, encrypted_password,
                          email_confirmed_at, created_at, updated_at)
  values (v_uid, '00000000-0000-0000-0000-000000000000', 'authenticated',
          'authenticated', 'plan-test-' || v_uid::text || '@example.com',
          '', now(), now(), now());
  perform set_config('test.uid', v_uid::text, false);
end $$;
```

If multiple tests grow this exact 10 lines, extract a `flutter/supabase/tests/_seed_test_user.sql` snippet and `\i` it from each test. Otherwise inline per file.

Expected behavior:
- Tests do not depend on production or branch DB data.
- Tests remain wrapped in `BEGIN`/`ROLLBACK`.
- Existing guard/RPC assertions stay the same.
- Each test exits with the same final `raise exception 'FAILURES: ...'` semantics (so `psql -v ON_ERROR_STOP=1` fails the CI job).

Verification: run the runner against a freshly created Supabase branch with zero users — all tests must pass. Pre-fix they would silently no-op; post-fix they exercise real assertions.

- [ ] **Step 1.3: Create GitHub Actions workflow**

Create `.github/workflows/test.yml` with two jobs running in parallel:

```yaml
name: test
on:
  pull_request:
  push:
    branches: [master]

jobs:
  flutter-tests:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: flutter
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.6'
          channel: stable
          cache: true
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test

  sql-tests:
    runs-on: ubuntu-latest
    # Skip on push-to-master since master commits don't get a preview branch
    if: github.event_name == 'pull_request'
    steps:
      - uses: actions/checkout@v4

      - name: Install psql client
        run: sudo apt-get update && sudo apt-get install -y postgresql-client

      - name: Install Supabase CLI
        uses: supabase/setup-cli@v1
        with:
          version: latest

      - name: Wait for preview branch + fetch DATABASE_URL
        id: branch
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
          SUPABASE_PROJECT_ID:   ${{ secrets.SUPABASE_PROJECT_ID }}
          PR_BRANCH:             ${{ github.head_ref }}
        run: |
          set -euo pipefail
          # Poll until the preview branch for this PR shows ACTIVE.
          # Per Supabase docs the branch is keyed by git branch name.
          for i in {1..30}; do
            BRANCH_JSON=$(supabase branches list \
              --project-ref "$SUPABASE_PROJECT_ID" \
              --output json 2>/dev/null \
              | jq -r --arg b "$PR_BRANCH" \
                  '.[] | select(.name == $b)')
            STATUS=$(printf '%s' "$BRANCH_JSON" | jq -r '.status // empty')
            if [ "$STATUS" = "ACTIVE_HEALTHY" ] || [ "$STATUS" = "ACTIVE" ]; then
              echo "Branch ready (status=$STATUS)"
              break
            fi
            echo "Branch not ready yet (status=${STATUS:-pending}), retry $i/30..."
            sleep 10
          done
          # Fetch the branch DB connection string.
          DB_URL=$(supabase branches get "$PR_BRANCH" \
            --project-ref "$SUPABASE_PROJECT_ID" \
            --output json | jq -r '.db.postgres_url // .postgres_version // empty')
          if [ -z "$DB_URL" ] || [ "$DB_URL" = "null" ]; then
            echo "Failed to resolve DATABASE_URL for branch $PR_BRANCH" >&2
            exit 1
          fi
          # Mask the URL in CI logs and export to subsequent steps.
          echo "::add-mask::$DB_URL"
          echo "database_url=$DB_URL" >> "$GITHUB_OUTPUT"

      - name: Run SQL tests
        env:
          DATABASE_URL: ${{ steps.branch.outputs.database_url }}
        working-directory: flutter
        run: ./scripts/run_sql_tests.sh
```

Required GitHub secrets (configure in repo Settings → Secrets and variables → Actions):
- `SUPABASE_ACCESS_TOKEN` — personal access token from Supabase dashboard, scope: branches read.
- `SUPABASE_PROJECT_ID` — the project ref (e.g. `smhvsqrxqoehqncphjrq`).

Assumption: Supabase GitHub Preview Branches integration is already enabled. If not, the user must enable it once in the Supabase dashboard before this CI workflow can succeed (it auto-applies `supabase/migrations/*.sql` on every PR push). Verification step: open PR, see a `Supabase / Preview Branch` check appear within ~30s of pushing.

Notes on field names: `supabase branches get --output json` schema has shifted across CLI versions; the workflow tolerates both `.db.postgres_url` (newer) and a fallback path. If neither exists, the step fails fast with a clear error so we don't run psql against a placeholder.

## Task 2 — Extract `BypassFlowMixin` and adopt across 3 notifiers

This is now a 3-step refactor:
- **2.0** Extract the mixin (covers Issues 4, 5 from /plan-eng-review).
- **2.1** Refactor Reflect + Duas to consume it (verifies the abstraction).
- **2.2** Hoist DailyLoop's local reservation into the mixin (closes the original gap).

The mixin is structural — no behavioral change for Reflect/Duas. Their existing dispose-cancel tests (`reflect_dispose_cancel_test.dart`, `build_dua_dispose_cancel_test.dart`) MUST keep passing without modification, which proves the refactor preserves behavior.

**Files:**
- Create: `flutter/lib/services/bypass_flow_mixin.dart`
- Modify: `flutter/lib/features/reflect/providers/reflect_provider.dart` (remove duplicated lifecycle fields/helpers, adopt mixin)
- Modify: `flutter/lib/features/duas/providers/duas_provider.dart` (same)
- Modify: `flutter/lib/features/daily/providers/daily_loop_provider.dart` (adopt mixin, hoist local reservation, add re-entry guard, add mounted checks)
- Create: `flutter/test/features/daily/discover_name_dispose_cancel_test.dart`
- Create: `flutter/test/services/bypass_flow_mixin_test.dart` (mixin unit tests)

### Step 2.0 — Extract `BypassFlowMixin`

- [ ] **Step 2.0a: Write the mixin**

Create `flutter/lib/services/bypass_flow_mixin.dart`:

```dart
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:state_notifier/state_notifier.dart';
import 'package:sakina/services/gating_service.dart';

/// Shared bypass-flow lifecycle for the 3 notifiers that consume the
/// AI-bypass reservation pattern (reflect, build-a-dua, discover-name).
///
/// Lifecycle:
///   1. submit guarded by [bypassInFlight]
///   2. caller awaits [reserveActiveBypass] which captures the in-flight
///      future, so [disposeBypassFlow] can cancel late-resolving reserves
///   3. caller assigns the returned BypassReservation? — null means rejected
///   4. on AI success, caller invokes [commitActiveBypassIfAny]
///   5. on AI failure, caller invokes [cancelActiveBypassIfAny]
///   6. on notifier dispose, [disposeBypassFlow] fires-and-forgets a cancel
///      for either an assigned-but-uncommitted reservation OR a still-in-
///      flight reserveBypass future (chained via .then)
///
/// All async cleanup wraps `try { ... .ignore(); } catch (_) {}` so app
/// shutdown can't escape unhandled errors. The 15-min orphan cron is the
/// last-resort safety net if Dart dispose never runs (e.g., iOS hard-kill).
mixin BypassFlowMixin<S> on StateNotifier<S> {
  /// The gated feature this notifier owns. Used as the cancel arg.
  GatedFeature get bypassFeature;

  String? _activeBypassReservationId;
  Future<BypassReservation?>? _inflightReserveFuture;
  bool _submitInFlight = false;

  @visibleForTesting
  String? get debugActiveBypassReservationId => _activeBypassReservationId;
  @visibleForTesting
  Future<BypassReservation?>? get debugInflightReserveFuture =>
      _inflightReserveFuture;

  /// True if a bypass-funded submit is in flight. Callers should also check
  /// their own loading flags (e.g., `state.checkinLoading`) as appropriate.
  bool get bypassInFlight => _submitInFlight;

  /// Reserve a bypass, tracking the in-flight future for dispose-chain
  /// cleanup. Returns null if rejected (no tokens, cap reached, premium).
  /// Callers MUST check `mounted` after this await before writing state.
  /// On non-null return, caller MUST assign the reservation id via
  /// [trackActiveBypassReservation] before any further awaits.
  Future<BypassReservation?> reserveActiveBypass() async {
    _submitInFlight = true;
    final future = GatingService().reserveBypass(bypassFeature);
    _inflightReserveFuture = future;
    try {
      final reservation = await future;
      if (identical(_inflightReserveFuture, future)) {
        _inflightReserveFuture = null;
      }
      return reservation;
    } catch (_) {
      if (identical(_inflightReserveFuture, future)) {
        _inflightReserveFuture = null;
      }
      rethrow;
    }
  }

  void trackActiveBypassReservation(String reservationId) {
    _activeBypassReservationId = reservationId;
  }

  /// Unconditional re-entry flag reset. Safe to call after !mounted —
  /// instance-field writes don't throw on disposed notifiers.
  void clearBypassInFlight() {
    _submitInFlight = false;
  }

  Future<void> commitActiveBypassIfAny() async {
    final id = _activeBypassReservationId;
    if (id == null) return;
    _activeBypassReservationId = null;
    await GatingService().commitBypass(id);
  }

  Future<void> cancelActiveBypassIfAny() async {
    final id = _activeBypassReservationId;
    if (id == null) return;
    _activeBypassReservationId = null;
    await GatingService().cancelBypass(id, bypassFeature);
  }

  /// Call from each consumer's `dispose()` BEFORE `super.dispose()`.
  /// Fires a cancel for either the assigned-but-uncommitted reservation,
  /// or chains one for a still-in-flight reserve future.
  void disposeBypassFlow() {
    final id = _activeBypassReservationId;
    final inflight = _inflightReserveFuture;
    _activeBypassReservationId = null;
    _inflightReserveFuture = null;
    if (id != null) {
      try {
        GatingService().cancelBypass(id, bypassFeature).ignore();
      } catch (_) {
        // Tearing down; orphan cron will refund.
      }
    } else if (inflight != null) {
      inflight.then((reservation) {
        if (reservation != null) {
          try {
            GatingService()
                .cancelBypass(reservation.reservationId, bypassFeature)
                .ignore();
          } catch (_) {}
        }
      }).catchError((_) {
        // Reserve RPC threw — no server-side reservation to cancel.
      });
    }
  }
}
```

- [ ] **Step 2.0b: Write mixin unit tests**

Create `flutter/test/services/bypass_flow_mixin_test.dart` covering:
1. `reserveActiveBypass` returns the RPC result on success.
2. `reserveActiveBypass` propagates throw on RPC throw, clears `_inflightReserveFuture`.
3. `commitActiveBypassIfAny` no-ops when no active id.
4. `cancelActiveBypassIfAny` no-ops when no active id.
5. `disposeBypassFlow` with active id → cancel RPC fires.
6. `disposeBypassFlow` with in-flight future, future resolves to reservation → cancel fires on the resolved id.
7. `disposeBypassFlow` with in-flight future, future resolves to null → NO cancel fires.
8. `disposeBypassFlow` with in-flight future, future throws → no cancel, no crash.

Use a tiny throwaway `_TestNotifier extends StateNotifier<int> with BypassFlowMixin` keyed on `GatedFeature.reflect` to exercise the mixin in isolation.

Run: `flutter test test/services/bypass_flow_mixin_test.dart` — all 8 pass.

### Step 2.1 — Refactor Reflect + Duas to consume the mixin

- [ ] **Step 2.1a: Edit `lib/features/reflect/providers/reflect_provider.dart`**

- Add `with BypassFlowMixin<ReflectState>` to the class declaration.
- Override `GatedFeature get bypassFeature => GatedFeature.reflect;`.
- Delete the duplicated fields (`_activeBypassReservationId`, `_inflightReserveFuture`, `_submitInFlight` — keep `_submitInFlight` shadow only if there are non-bypass uses; otherwise delete and use the mixin's `bypassInFlight`).
- Delete the local `_commitActiveBypassIfAny()` / `_cancelActiveBypassIfAny()` if they were private — use the mixin's.
- Delete the dispose() body for the bypass cleanup and replace with `disposeBypassFlow()` before `super.dispose()`.
- In `submitWithBypass`, replace the manual reserve/track sequence with `reserveActiveBypass()` + `trackActiveBypassReservation()`. Keep the `!mounted` guard.

The pre-stated comment at `reflect_provider.dart:323-324` ("If a 4th gated feature is added...") can be deleted — the abstraction is now in place.

- [ ] **Step 2.1b: Edit `lib/features/duas/providers/duas_provider.dart`**

Same shape as 2.1a, with `GatedFeature.builtDua`. Keep `_progressTimer?.cancel()` in dispose; just call `disposeBypassFlow()` alongside it.

- [ ] **Step 2.1c: Run the existing dispose-cancel tests UNCHANGED**

```bash
flutter test test/features/reflect/reflect_dispose_cancel_test.dart \
              test/features/duas/build_dua_dispose_cancel_test.dart \
              test/services/gating_service_bypass_test.dart \
              test/features/reflect/reflect_bypass_flow_test.dart
```

All MUST pass without test edits. If any fails, the mixin refactor changed behavior and needs to be revised — the mixin is the abstraction-under-test here, the existing tests are the regression pin.

### Step 2.2 — Adopt the mixin in DailyLoop + hoist the local reservation

- [ ] **Step 2.2a: Edit `lib/features/daily/providers/daily_loop_provider.dart`**

- Add `with BypassFlowMixin<DailyLoopState>` to the class declaration.
- Override `GatedFeature get bypassFeature => GatedFeature.discoverName;`.
- Extend `dispose()` to call `disposeBypassFlow()` alongside the existing `_deeperReflectGeneration++` and `_grantsSub?.cancel()`.

- [ ] **Step 2.2b: Refactor `discoverNameWithBypass`**

Replace the current body (lines 495-516) with:

```dart
Future<void> discoverNameWithBypass() async {
  if (state.checkinLoading || bypassInFlight) return;
  try {
    final reservation = await reserveActiveBypass();
    if (!mounted) return; // dispose chain owns cleanup
    if (reservation == null) {
      state = state.copyWith(error: 'Bypass unavailable. Try again.');
      return;
    }
    trackActiveBypassReservation(reservation.reservationId);
    await discoverName();
    if (!mounted) return; // dispose chain owns commit/cancel
    if (state.error != null) {
      await cancelActiveBypassIfAny();
    } else {
      await commitActiveBypassIfAny();
    }
  } finally {
    // Per /plan-eng-review Issue 6: unconditional. Instance-field writes
    // don't throw on disposed notifiers — only `state =` does, and the
    // mounted-checks above guard those.
    clearBypassInFlight();
  }
}
```

- [ ] **Step 2.2c: Gate `discoverNameWithFirstBypass` on the same flag (Issue 7)**

Edit lines 523-532 to add the same re-entry guard:

```dart
Future<void> discoverNameWithFirstBypass() async {
  if (state.checkinLoading || bypassInFlight) return;
  try {
    final claimed =
        await GatingService().claimFirstBypass(GatedFeature.discoverName);
    if (!mounted) return;
    if (!claimed) {
      state = state.copyWith(error: 'Freebie unavailable. Try again.');
      return;
    }
    await discoverName();
  } finally {
    clearBypassInFlight();
  }
}
```

Rationale: rapid-tap on the freebie button could double-claim the Day-1 grant otherwise — the server's `claim_first_bypass` is atomic per request, but the second tap would see `already_consumed` and surface a confusing error instead of a clean no-op.

- [ ] **Step 2.2d: Add regression tests**

Create `flutter/test/features/daily/discover_name_dispose_cancel_test.dart` with these test cases (matches the existing dispose-cancel test pattern):

**Critical regression tests** (mandatory — modifying existing behavior):
1. **Happy commit regression**: reserve succeeds → `discoverName()` succeeds (state.error == null) → `commit_ai_bypass` fires, NOT `cancel_ai_bypass`.
2. **Cancel-on-state.error regression**: reserve succeeds → `discoverName()` sets state.error → `cancel_ai_bypass` fires, NOT commit.

**Dispose tests** (the original gap):
3. Dispose AFTER reserve resolves but before `discoverName` work completes → cancels the reservation.
4. Dispose BEFORE reserve resolves, late reservation arrives → chained cancel fires for the late id.
5. Dispose BEFORE reserve resolves, reserve rejected (null) → NO cancel fires.

**Re-entry tests**:
6. Two rapid `discoverNameWithBypass` calls → only one `reserve_ai_bypass` RPC fires.
7. Two rapid `discoverNameWithFirstBypass` calls → only one `claim_first_bypass` RPC fires (Issue 7 pin).

Use `FakeSupabaseSyncService` from `test/support/fake_supabase_sync_service.dart`. The fake's `rpcHandlers` can return a `Completer<...>().future` to stall a reserve. For tests 3 + 4 you'll need `engageCard` (called inside `discoverName`) to stall too — add a minimal delay hook to the fake if not already present, scoped narrowly to avoid coupling production code to test-only DI.

Verification: `flutter test test/features/daily/discover_name_dispose_cancel_test.dart` — all 7 pass.

## Task 3 — Verification

- [ ] Run mixin unit tests:

```bash
cd "/Users/appleuser/CS Work/Repos/sakina/flutter"
flutter test test/services/bypass_flow_mixin_test.dart
```

- [ ] Run sibling lifecycle regression tests UNCHANGED (proves Step 2.1 refactor is behavior-preserving):

```bash
flutter test test/features/reflect/reflect_dispose_cancel_test.dart \
              test/features/duas/build_dua_dispose_cancel_test.dart \
              test/features/reflect/reflect_bypass_flow_test.dart \
              test/services/gating_service_bypass_test.dart
```

- [ ] Run new DailyLoop tests:

```bash
flutter test test/features/daily/discover_name_dispose_cancel_test.dart
```

- [ ] Run all Flutter tests:

```bash
flutter test
```

Expected: total count = 899 (baseline) + 8 mixin + 7 DailyLoop = **914 passing**. Any drop from the baseline 899 means the Step 2.1 refactor broke behavior — debug before continuing.

- [ ] Validate SQL runner against a freshly-migrated branch database (zero users):

```bash
DATABASE_URL="postgres://..." ./scripts/run_sql_tests.sh
```

Expected: every test file passes by self-seeding its own `auth.users` row. Pre-fix any of them would have silently no-opped on an empty DB.

- [ ] Open a PR and verify both GitHub Actions jobs pass. First-run smoke for the workflow itself: intentionally break a SQL test file (e.g., add `raise exception 'CI test';` to one), push, confirm `sql-tests` job goes red, revert, confirm green.

## Failure Modes to Cover

| Flow | Failure mode | Expected handling | Test coverage |
|------|--------------|-------------------|---------------|
| CI SQL runner | A SQL file fails midway | `psql ON_ERROR_STOP=1` fails the job | Manual smoke at Task 3 (intentional break + revert) |
| CI preview branch unready | psql connects before migrations applied | 30-attempt poll with 10s backoff in workflow Step 1.3 | Manual smoke: open PR, watch the wait step succeed |
| SQL tests | Branch DB has zero users | Each test self-seeds `auth.users` inline | Task 1.2 audit covers all 7 candidate files |
| DailyLoop reserve | Reserve returns null/rejected | User sees bypass unavailable, no cancel called | Test 5 in 2.2d |
| DailyLoop reserve | Reserve RPC throws | Caller catches, no orphan reservation server-side | Mixin test 2 (rethrow + clear in-flight) |
| DailyLoop **commit success path** | Refactor breaks happy commit | **CRITICAL regression** | Test 1 in 2.2d (mandatory) |
| DailyLoop **cancel-on-error path** | Refactor breaks failure-cancel branch | **CRITICAL regression** | Test 2 in 2.2d (mandatory) |
| DailyLoop dispose after reserve | User backgrounds during discover-name work | Reservation cancelled immediately | Test 3 in 2.2d |
| DailyLoop dispose before reserve | Late reservation arrives after notifier disposed | Chained cancel refunds tokens via mixin | Test 4 in 2.2d + mixin test 6 |
| DailyLoop dispose, null reserve | Phantom-cancel risk on rejected reserve | NO cancel fires | Test 5 in 2.2d + mixin test 7 |
| DailyLoop rapid bypass taps | Two calls before loading flips | Only one `reserve_ai_bypass` RPC | Test 6 in 2.2d |
| DailyLoop rapid freebie taps | Two calls before loading flips | Only one `claim_first_bypass` RPC (Issue 7) | Test 7 in 2.2d |
| Mixin dispose during teardown | Cancel RPC throws on torn-down Supabase client | Swallowed by try/catch + .ignore() | Implicit in mixin tests 5-8 |

**Critical gaps after this plan:** **0**. All previously-flagged silent-failure modes from /plan-eng-review (commit regression, cancel-on-error regression, freebie rapid-tap, preview-branch readiness) now have test coverage or explicit handler.

## Worktree Parallelization

| Step | Modules touched | Depends on |
|------|-----------------|------------|
| Task 1 — CI workflow + SQL runner + self-seed audit | `.github/`, `flutter/scripts/`, `flutter/supabase/tests/` | — |
| Task 2.0 — `BypassFlowMixin` extraction + unit tests | `flutter/lib/services/`, `flutter/test/services/` | — |
| Task 2.1 — Reflect + Duas adopt mixin | `flutter/lib/features/reflect/`, `flutter/lib/features/duas/`, `flutter/test/features/reflect/`, `flutter/test/features/duas/` | Task 2.0 |
| Task 2.2 — DailyLoop adopt mixin + hoist + tests | `flutter/lib/features/daily/`, `flutter/test/features/daily/`, maybe `flutter/test/support/` | Task 2.0 |

Parallel lanes:
- **Lane A:** Task 1 (CI workflow + SQL self-seed audit).
- **Lane B:** Task 2.0 → then Task 2.1 + Task 2.2 in parallel.

Execution order: Launch Lane A and Lane B Task 2.0 in parallel worktrees. Once 2.0 lands on lane B, fan out to 2.1 and 2.2 as parallel sub-lanes (no shared files). Merge everything, then run full verification.

Conflict flags:
- Lanes A and B touch entirely separate trees — zero file overlap.
- Within Lane B, sub-lanes 2.1 and 2.2 touch separate feature dirs but both import the new mixin from `lib/services/bypass_flow_mixin.dart` — Task 2.0 must land first.
- If a fake-sync delay hook is needed (Task 2.2d), keep that change narrowly scoped to avoid conflicts with any concurrent test-support edits.

## /plan-eng-review revision log (2026-05-24)

7 issues identified by `/plan-eng-review` and folded into this plan:

1. **CI under-spec (P1):** Step 1.3 now contains the actual workflow YAML, including the supabase CLI poll loop for preview-branch readiness, the `supabase branches get` invocation, and DB URL masking. No prose hand-wave.
2. **Flutter action pin (P2):** Tech Stack header pins `subosito/flutter-action@v2` + channel `stable` + version `3.41.6`. Workflow YAML reflects this.
3. **SQL self-seed DRY (P2):** Step 1.2 now covers all 7 candidate test files, not just one. Each gets the same `auth.users` insert pattern, optionally extracted into `_seed_test_user.sql` if duplication crosses 3 sites.
4. **`BypassFlowMixin` extraction (P1, project's own threshold):** Task 2.0 added. Mixin lives at `lib/services/bypass_flow_mixin.dart`. Reflect + Duas refactor to consume in Task 2.1; DailyLoop adopts in Task 2.2. Code's own comment ("3 sites is the YAGNI threshold") now satisfied.
5. **Naming inconsistency (P2):** Resolved by Issue 4 — mixin uses `_submitInFlight` / `bypassInFlight` across all 3 consumers.
6. **mounted-gate on `finally` (P2):** Removed. Step 2.2b's `finally` block calls `clearBypassInFlight()` unconditionally; mixin docs note that instance-field writes are safe on disposed notifiers, only `state =` writes throw.
7. **`discoverNameWithFirstBypass` rapid-tap (P2):** Step 2.2c gates the freebie path on the same `bypassInFlight` flag. Test 7 in Step 2.2d pins.

Plus 2 mandatory regression tests (REGRESSION RULE — modifying existing behavior):
- Test 1 (happy commit path)
- Test 2 (cancel-on-state.error path)

Both added to Step 2.2d.

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | CLEAR (PLAN) | 7 issues found + 2 mandatory regression tests, all addressed in revision log above |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | n/a | infra + lifecycle refactor only |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | n/a | not a dev-facing change |

**VERDICT:** ENG CLEARED — ready to implement.

