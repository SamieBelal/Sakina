# Gate 0 — Static + Backend Gates (2026-06-01)

Pre-flight gates from `docs/qa/plans/2026-06-01-full-regression-sim-test-plan.md §3` / §7.
Run before any device/simulator lane work.

## Results

| Check | Result | Notes |
|-------|--------|-------|
| `flutter analyze` | ✅ PASS | 19 issues, **all `info`**, 0 errors/0 warnings. Baseline ~18; +1 is `prefer_single_quotes` in `test/widgets/coachmark/coachmark_keyboard_test.dart` (new test file). Cosmetic. |
| `check_no_fake_strings.sh` | ✅ PASS | `OK: no FAKE_DO_NOT_SHIP_ placeholders in lib/.` |
| `flutter test` | ✅ PASS | **All 1213 tests passed** (exit 0). Covers dual-flow onboarding, tour coachmarks, AI-bypass reflect flow, IAP→sub banner, referral fields, provider error listeners, public-catalog export. |
| pgtap (`run_sql_tests.sh`) | ⚠️ SKIPPED | Requires `DATABASE_URL` (local stack / branch). Not set in this env. **Action:** run against a Supabase branch or local `supabase start` before release. 12 changed test files under `supabase/tests/`. |
| `supabase db reset` (clean reset) | ⚠️ NOT RUN | Same — needs local stack/branch. Validates cluster #10 guards (b6b2dd3, 4462c32, 419af95). |
| Supabase `list_migrations` | ✅ PASS | **94 migrations applied** on remote, through `20260531224601_user_subscription_cancellation_transition` (latest in range). No drift. |
| Supabase `get_advisors security` | ⚠️ REVIEW | All WARN. See below. |
| Supabase `get_advisors performance` | ⚠️ 1 NEW ACTIONABLE | `cancellation_feedback` RLS initplan. See below. |

## Security advisors — triage

Most WARNs are the **intended architecture** (the app routes economy/gift/referral through `SECURITY DEFINER`
RPCs callable by `authenticated`): `sync_all_user_data`, `reserve_ai_bypass`, `commit/cancel_ai_bypass`,
`claim_first_bypass`, `apply_referral`, `ensure_referral_code`, `dismiss_iap_upsell_banner`, economy RPCs, etc.
The anon RPC grants were deliberately reconciled in `20260531200000_reconcile_anon_rpc_grants`. **No new errors.**

**Two to actively verify in the security sweep (§5)** — `anon`-executable SECURITY DEFINER fns that take a
caller-supplied identity or expose other users:

1. **`claim_sakina_gift(p_user uuid, p_occasion text)` — executable by `anon`.** It grants premium. Must
   confirm the function body enforces `auth.uid() = p_user` (or rejects anon) so a caller can't claim a gift
   for an arbitrary uuid. → **Lane D test: call `/rest/v1/rpc/claim_sakina_gift` as anon with someone else's
   uuid; expect rejection.**
2. **`get_eligible_notification_users(...)` — executable by `anon`.** Returns notification-eligible users
   across the base. Confirm this is intended to be reachable only by the cron/service role and that anon
   EXECUTE doesn't leak a user list. → **Security-sweep test: anon RPC call should not return rows.**

Pre-existing minor: `auth_leaked_password_protection` disabled (enable in Auth settings — not a blocker).

## Performance advisors — 1 new actionable

**`cancellation_feedback` RLS does not use the initplan optimization.** All 3 policies (view/insert/update own)
call `auth.<function>()` per-row instead of `(select auth.<function>())`. Every other table got this fix in
`20260510172453_rls_initplan_optimization`; the new table (added `20260531193313`) regressed the pattern.
Low user impact at current scale but it's a clean, established-convention fix.
→ **Finding:** `docs/qa/findings/2026-06-01-cancellation-feedback-rls-initplan.md`

INFO (no action): unused indexes `user_profiles_starter_name_id_idx`, `idx_duas_emotion_tags`,
`reflect_classifier_log_off_topic_idx`, `reflect_unknown_name_log_created_at_idx` — all newish, will populate with usage.

## Gate 0 verdict

**Conditional PASS.** Static gates green, migrations clean. Blockers to clear before sign-off:
pgtap + `db reset` on a branch, plus verify the two anon RPC items above. One new perf finding filed (non-blocking).
