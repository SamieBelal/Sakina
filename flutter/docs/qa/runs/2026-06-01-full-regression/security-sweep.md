# Cross-cutting Security + Perf Sweep (2026-06-01)

Read-only analysis against the production Supabase project (no prod data mutated). Complements the
per-lane RLS-isolation checks (each lane agent operates on its own account and relies on RLS).

## Migrations
- **94 / 94 applied**, through `20260531224601_user_subscription_cancellation_transition`. No drift. ✅

## RLS on new tables (this release)
| Table | RLS | Policies | Notes |
|-------|-----|----------|-------|
| `ai_bypass_reservations` | ✅ | 1 | read-own; writes via `reserve/commit/cancel_ai_bypass` RPC |
| `referrals` | ✅ | 1 | read-own; writes via referral RPCs |
| `referral_grants` | ✅ | 1 | read-own; writes via RPC |
| `sakina_gifts` | ✅ | 1 | read-own; writes via `claim_sakina_gift` |
| `cancellation_feedback` | ✅ | 3 | view/insert/update own — **but skips initplan opt (perf finding below)** |
| `islamic_occasions` | ✅ | 1 | public read (catalog) |
| `app_config` | ✅ | 2 | anon read (`20260529030441`) + admin write |

All new tables enforce RLS. Single-policy tables expose read-own and force writes through SECURITY
DEFINER RPCs — sound. Lane agents empirically confirm cross-user isolation on their own accounts.

## Freemium guard — COMPREHENSIVE ✅
`guard_user_profiles_freemium_fields()` (BEFORE UPDATE) bypasses only `service_role`/`postgres`/`supabase_admin`
and raises `check_violation` on direct client writes to **every** sensitive field, including all the new ones:
- `referral_premium_until` → RPC only
- `gift_premium_until` → RPC only (`claim_sakina_gift`)
- `first_bypass_consumed` → can't reset true→false
- `lifetime_bypasses_purchased` → can't decrease
- `iap_upsell_banner_dismissed_at` → RPC only
- `last_winback_grant_at` → RPC only
- `warmup_*_remaining` → can't refill; `had_trial` can't reset; `referral_code` immutable after assignment

Companion `guard_user_daily_usage_freemium_fields()` + DELETE guards on both tables. The premium-never-reaches-bypass
short-circuit is additionally tested in Lane C (client-side) and Lane P (real premium).

## SECURITY DEFINER advisor triage
The bulk of `get_advisors security` WARNs are the intended RPC architecture (economy/referral/gift/bypass
functions callable by `authenticated`). Two anon-executable functions inspected in depth:

1. **`claim_sakina_gift(uuid,text)` — SECURE despite anon EXECUTE.** Body rejects anon
   (`auth.uid() is null or auth.uid() <> p_user`), enforces occasion window + idempotent insert. Non-exploitable.
2. **`get_eligible_notification_users(...)` — 🔴 P1 EXPOSURE.** anon EXECUTE = true, no identity guard,
   returns user_id/display_name/timezone/streak for all push-enabled users. Only legit caller is the
   `send-scheduled-notifications` edge fn (service_role, bypasses grants). → fix filed:
   `docs/qa/findings/2026-06-01-notif-eligibility-anon-enumeration.md`.

## Performance
- 🟡 `cancellation_feedback` RLS uses bare `auth.uid()` (per-row re-eval) instead of `(select auth.uid())`.
  → `docs/qa/findings/2026-06-01-cancellation-feedback-rls-initplan.md`.
- INFO unused indexes (new, will populate): `user_profiles_starter_name_id_idx` + reflect-log indexes. No action.

## Pre-existing (not from this release, not blockers)
- `auth_leaked_password_protection` disabled — enable in Auth settings when convenient.

## Verdict
Backend security posture for the new features is **solid** (RLS everywhere, comprehensive freemium guard).
**One P1** (`get_eligible_notification_users` anon enumeration) should be fixed before release; one low perf nit.
Remaining unrun (need branch/local DB): pgtap suite + `supabase db reset` clean-reset validation.
