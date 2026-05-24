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

### Wire CI for flutter test + SQL test suites

**What:** Add `.github/workflows/test.yml` that runs `flutter test` and a script to execute every `supabase/tests/*.sql` file against a branch DB on every PR.

**Why:** The 2,500+ lines of new Dart tests and ~1,400 lines of SQL pgTAP-style tests added across the AI-bypass feature (PRs #20-24) and the P0 hotfix bundle (PR #26) are aspirational-only. The repo has zero `.github/workflows/`. Any regression in those areas ships silently until someone runs the tests locally.

**Pros:** Existing test investment becomes load-bearing. PRs get a green check before merge. SQL guard regressions caught at PR time, not in production.

**Cons:** Supabase branch DB cost (small). CI run time (~3 min flutter test). Requires `flutter` setup action + psql client + a way to seed at least one auth user for the SQL tests.

**Context:** PR #26 plan — `docs/superpowers/plans/2026-05-23-ai-bypass-p0-bundle.md`. Eng review (`/plan-eng-review`) surfaced this as a P2 distribution gap; deferred from the P0 bundle to keep scope tight.

**Depends on / blocked by:** none.

### Hoist DailyLoopNotifier bypass reservation into a field so dispose can cancel it

**What:** `DailyLoopNotifier.discoverNameWithBypass` currently holds the reservation id as a local variable inside the function body (awaiting `reserveBypass` → `discoverName()` → `commit`/`cancel` inline). Move it to a field like `_activeBypassReservationId` matching `ReflectNotifier` and `DuasNotifier`, then add the same `dispose()` override.

**Why:** P0-4 fixed dispose-mid-flight reservation leaks for Reflect and Build-a-Dua. The discover-name flow has the same leak — if the user backgrounds the app during the AI call, 25 tokens are locked until the 15-min orphan cron rescues. Lower-impact than reflect (less frequent flow) but architecturally inconsistent.

**Pros:** Closes the last dispose-leak gap. Restores symmetry across the three bypass notifiers.

**Cons:** Requires a small refactor of `discoverNameWithBypass` to thread the field correctly across the await points. Need to verify no other code path concurrently overwrites the field. ~30 min including regression test.

**Context:** PR #26 plan + the P0-4 commit message explicitly flags this as deferred. Test pattern is `test/features/reflect/reflect_dispose_cancel_test.dart` — copy and adapt.

**Depends on / blocked by:** none.

### Drop the 1-arg reserve_ai_bypass shim after IPA drain

**What:** PR #26 kept the 1-arg `reserve_ai_bypass(text)` as a backwards-compat shim that auto-generates a server-side idempotency key. Once enough time has passed for pre-PR-26 IPAs to drain (via App Store auto-update), drop the shim. Track Mixpanel app version segments for adoption.

**Why:** Old IPAs lose idempotency (each call generates fresh key), keeping their original double-debit bug. Acceptable transitional state but should not be permanent. Removing the shim simplifies the migration history and tightens the contract.

**Pros:** Single canonical signature. Cleaner schema. Forces upgrades for the holdouts.

**Cons:** Holdout users will see a silent failure if they're still on the old IPA. Need to set a threshold (e.g., "drop shim when ≤1% of `reserve_ai_bypass` calls come from app versions <= X.Y.Z").

**Context:** PR #26 plan — `supabase/migrations/20260524010000_reserve_ai_bypass_idempotency.sql` ships the shim with a note in the file comment explaining when to drop it.

**Depends on / blocked by:** 60+ days of adoption telemetry from PR #26 deployment.
