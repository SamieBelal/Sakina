-- Reconcile anon EXECUTE grants on SECURITY DEFINER RPCs to match prod.
--
-- Backstory: prod's anon-revoke posture was built up across several migrations
-- (revoke_anon_rpc_execute, its never-committed v2, and per-feature hardening in
-- the referrals / ai_bypass / iap-upsell / winback migrations). Only the v1
-- revoke (12 functions) ever made it into the repo as an explicit revoke; the
-- rest of prod's posture (28 functions total) was never represented in the
-- migration chain. A fresh `db reset` would therefore leave ~16 SECURITY
-- DEFINER functions anon-executable.
--
-- This migration is a single, idempotent reconciliation derived directly from
-- prod's live grants (pg_proc + has_function_privilege on 2026-05-31). It is
-- dated after every function it references so the replay never targets a
-- not-yet-created function. Applying it to prod is a no-op (prod already
-- matches). It supersedes the missing revoke_anon_rpc_execute_v2.
--
-- Rule: every public SECURITY DEFINER function has EXECUTE revoked from
-- public/anon/authenticated; the user-facing RPCs are then re-granted to
-- `authenticated`. Service-role / trigger-only functions get no re-grant.

-- ── Revoke from everyone ──────────────────────────────────────────────────
revoke execute on function public._current_bypass_count(p_user_id uuid, p_feature text, p_date date) from public, anon, authenticated;
revoke execute on function public._replay_reservation_response(p_reservation_id uuid, p_user_id uuid, p_feature text, p_today date) from public, anon, authenticated;
revoke execute on function public.apply_referral(p_code text, p_referee uuid) from public, anon, authenticated;
revoke execute on function public.award_xp(amount integer) from public, anon, authenticated;
revoke execute on function public.cancel_ai_bypass(p_reservation_id uuid) from public, anon, authenticated;
revoke execute on function public.claim_daily_reward() from public, anon, authenticated;
revoke execute on function public.claim_first_bypass(p_feature text) from public, anon, authenticated;
revoke execute on function public.clawback_consumable_grant(p_user_id uuid, p_sku text, p_kind text, p_amount integer, p_transaction_id text, p_event_timestamp timestamp with time zone) from public, anon, authenticated;
-- cleanup_orphaned_users exists out-of-band on prod with no creating migration;
-- guard so a fresh db reset / CI (where it doesn't exist) skips it.
do $$
begin
  if exists (
    select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'cleanup_orphaned_users'
  ) then
    revoke execute on function public.cleanup_orphaned_users() from public, anon, authenticated;
  end if;
end $$;
revoke execute on function public.commit_ai_bypass(p_reservation_id uuid) from public, anon, authenticated;
revoke execute on function public.confirm_referral_if_pending(p_referee uuid) from public, anon, authenticated;
revoke execute on function public.consume_streak_freeze() from public, anon, authenticated;
revoke execute on function public.delete_own_account() from public, anon, authenticated;
revoke execute on function public.dismiss_iap_upsell_banner() from public, anon, authenticated;
revoke execute on function public.earn_scrolls(amount integer) from public, anon, authenticated;
revoke execute on function public.earn_tokens(amount integer) from public, anon, authenticated;
revoke execute on function public.ensure_referral_code(p_user uuid) from public, anon, authenticated;
revoke execute on function public.grant_premium_monthly() from public, anon, authenticated;
revoke execute on function public.grant_winback_tokens(p_user_id uuid, p_amount integer) from public, anon, authenticated;
revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.notify_referrer_on_confirm() from public, anon, authenticated;
revoke execute on function public.reserve_ai_bypass(p_feature text) from public, anon, authenticated;
revoke execute on function public.reserve_ai_bypass(p_feature text, p_idempotency_key text) from public, anon, authenticated;
revoke execute on function public.spend_scrolls(amount integer) from public, anon, authenticated;
revoke execute on function public.spend_tokens(amount integer) from public, anon, authenticated;
revoke execute on function public.sync_all_user_data() from public, anon, authenticated;
revoke execute on function public.upsert_user_subscription_if_newer(payload jsonb) from public, anon, authenticated;

-- ── Re-grant the user-facing RPCs to authenticated ───────────────────────
grant execute on function public.apply_referral(p_code text, p_referee uuid) to authenticated;
grant execute on function public.award_xp(amount integer) to authenticated;
grant execute on function public.cancel_ai_bypass(p_reservation_id uuid) to authenticated;
grant execute on function public.claim_daily_reward() to authenticated;
grant execute on function public.claim_first_bypass(p_feature text) to authenticated;
grant execute on function public.commit_ai_bypass(p_reservation_id uuid) to authenticated;
grant execute on function public.confirm_referral_if_pending(p_referee uuid) to authenticated;
grant execute on function public.consume_streak_freeze() to authenticated;
grant execute on function public.delete_own_account() to authenticated;
grant execute on function public.dismiss_iap_upsell_banner() to authenticated;
grant execute on function public.earn_scrolls(amount integer) to authenticated;
grant execute on function public.earn_tokens(amount integer) to authenticated;
grant execute on function public.ensure_referral_code(p_user uuid) to authenticated;
grant execute on function public.grant_premium_monthly() to authenticated;
grant execute on function public.reserve_ai_bypass(p_feature text) to authenticated;
grant execute on function public.reserve_ai_bypass(p_feature text, p_idempotency_key text) to authenticated;
grant execute on function public.spend_scrolls(amount integer) to authenticated;
grant execute on function public.spend_tokens(amount integer) to authenticated;
grant execute on function public.sync_all_user_data() to authenticated;

-- Service-role / trigger-only (no authenticated grant): _current_bypass_count,
-- _replay_reservation_response, clawback_consumable_grant, cleanup_orphaned_users,
-- grant_winback_tokens, handle_new_user, notify_referrer_on_confirm,
-- upsert_user_subscription_if_newer.
