# TODOs

Pre-launch code review findings, organized into four parallel workstreams.

| File | Items | Can start now? | Summary |
|------|-------|----------------|---------|
<!-- | TODOS-session-cleanup.md~~ | ~~5~~ | DONE | Sign-out data bleed, cache cleanup, hydration retry | -->
<!-- | [TODOS-economy-bugs.md](TODOS-economy-bugs.md) | 10 | YES | Double-tap spend, silent earn drops, non-atomic rewards | -->
<!-- | [TODOS-premium-grants-polish.md](TODOS-premium-grants-polish.md) | 5 | YES | Concurrency guard, totalSpent zeroing, hardcoded amounts | -->
<!-- | [TODOS-revenuecat-integration.md](TODOS-revenuecat-integration.md) | 15 | YES (RevenueCat setup) | Paywall wiring, entitlement guard, subscription state | -->

<!-- ## Pre-Launch Legal/Compliance
  - [x] Privacy policy update for Mixpanel user profiles + onboarding quiz fields — done 2026-04-21 in sakina-legal commit 7920f2e (https://ibrahim7860.github.io/sakina-legal/privacy.html §2.1, §4 Mixpanel block).
  - [x] Privacy policy update for Supabase notification preferences — done 2026-04-21 in same commit (see §2.2 and §4 OneSignal block). -->

## P1 — Deferred follow-ups from PR #26 (AI-bypass P0 hotfix bundle)

<!-- ### ~~Wire CI for flutter test + SQL test suites~~ — DONE 2026-05-24 in PR #25 commit 78ac6d0
  - Added `.github/workflows/test.yml` with `flutter-tests` job (always) +
    `sql-tests` job (PR-only) that polls Supabase Preview Branch readiness,
    fetches the DATABASE_URL, runs `flutter/scripts/run_sql_tests.sh`.
  - Required GitHub secrets to wire up before this can pass green:
    `SUPABASE_ACCESS_TOKEN` (PAT, branches:read scope), `SUPABASE_PROJECT_ID`.
  - Required toggle: Supabase GitHub Preview Branches integration must be
    enabled in the project dashboard so per-PR branch DBs auto-create.
  - Self-seed audit: `freemium_guards_bypass_fields_test.sql` updated; other 6
    SQL test files were already self-seeding via `pg_temp.test_insert_auth_user`. -->

<!-- ### ~~Hoist DailyLoopNotifier bypass reservation into a field so dispose can cancel it~~ — DONE 2026-05-24 in PR #25 commits c6e14f7 + 5e42281 + 8bf7a5f
  - Extracted `BypassFlowMixin` at `lib/services/bypass_flow_mixin.dart` (the
    code's own 3-site YAGNI threshold from `reflect_provider.dart:323-324`
    was crossed when DailyLoop became the 3rd consumer).
  - ReflectNotifier + DuasNotifier refactored to consume the mixin
    (-211/+52 lines net dedup, all existing dispose-cancel tests pass
    unchanged → regression contract preserved).
  - DailyLoopNotifier consumes the mixin, hoists the reservation through
    `trackActiveBypassReservation()`, adds `!mounted` guards after both
    awaits in `discoverNameWithBypass`, and extends the re-entry guard to
    `discoverNameWithFirstBypass` (closes the Day-1 freebie rapid-tap leak
    surfaced by /plan-eng-review).
  - Coverage: 8 mixin unit tests + 7 DailyLoop regression tests added
    (2 mandatory commit/cancel regressions, 3 dispose paths, 2 rapid-tap
    pins). Final test count 914/914. -->

### Drop the 1-arg reserve_ai_bypass shim after IPA drain

**What:** PR #26 kept the 1-arg `reserve_ai_bypass(text)` as a backwards-compat shim that auto-generates a server-side idempotency key. Once enough time has passed for pre-PR-26 IPAs to drain (via App Store auto-update), drop the shim. Track Mixpanel app version segments for adoption.

**Why:** Old IPAs lose idempotency (each call generates fresh key), keeping their original double-debit bug. Acceptable transitional state but should not be permanent. Removing the shim simplifies the migration history and tightens the contract.

**Pros:** Single canonical signature. Cleaner schema. Forces upgrades for the holdouts.

**Cons:** Holdout users will see a silent failure if they're still on the old IPA. Need to set a threshold (e.g., "drop shim when ≤1% of `reserve_ai_bypass` calls come from app versions <= X.Y.Z").

**Context:** PR #26 plan — `supabase/migrations/20260524010000_reserve_ai_bypass_idempotency.sql` ships the shim with a note in the file comment explaining when to drop it.

**Depends on / blocked by:** 60+ days of adoption telemetry from PR #26 deployment.
