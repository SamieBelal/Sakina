-- Revoke EXECUTE on SECURITY DEFINER economy / lifecycle functions from anon
-- (Supabase linter 0028 remediation). Most of these functions were created
-- without an explicit `REVOKE ... FROM PUBLIC`, so Postgres' default
-- `EXECUTE` grant to PUBLIC silently exposed them to /rest/v1/rpc/* for
-- signed-out users.
--
-- Strategy: REVOKE EXECUTE FROM PUBLIC, anon, authenticated for every
-- function (clean slate), then GRANT EXECUTE back to `authenticated` only
-- where the Flutter app calls the RPC as the signed-in user. Edge functions
-- run with `service_role`, which bypasses GRANT checks, so no GRANT is
-- needed for webhook/cron callers.
--
-- Caller map (verified via grep over lib/ and supabase/functions/):
--   authenticated (Flutter):
--     award_xp, earn_tokens, earn_scrolls, spend_tokens, spend_scrolls,
--     claim_daily_reward, grant_premium_monthly, consume_streak_freeze,
--     sync_all_user_data
--   service_role only (edge functions):
--     clawback_consumable_grant, upsert_user_subscription_if_newer
--       (revenuecat-webhook)
--     get_eligible_notification_users
--       (send-scheduled-notifications)
--   service_role only (trigger / admin):
--     handle_new_user (auth.users trigger; runs via the trigger, not REST)
--     cleanup_orphaned_users (admin-only)

-- ---------------------------------------------------------------------------
-- User-scoped economy RPCs: revoke from PUBLIC/anon/authenticated, then
-- re-grant to authenticated so the Flutter app keeps working.
-- ---------------------------------------------------------------------------
REVOKE EXECUTE ON FUNCTION public.award_xp(amount integer) FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.award_xp(amount integer) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.earn_tokens(amount integer) FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.earn_tokens(amount integer) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.earn_scrolls(amount integer) FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.earn_scrolls(amount integer) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.spend_tokens(amount integer) FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.spend_tokens(amount integer) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.spend_scrolls(amount integer) FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.spend_scrolls(amount integer) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.claim_daily_reward() FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.claim_daily_reward() TO authenticated;

REVOKE EXECUTE ON FUNCTION public.grant_premium_monthly() FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.grant_premium_monthly() TO authenticated;

REVOKE EXECUTE ON FUNCTION public.consume_streak_freeze() FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.consume_streak_freeze() TO authenticated;

REVOKE EXECUTE ON FUNCTION public.sync_all_user_data() FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.sync_all_user_data() TO authenticated;

-- ---------------------------------------------------------------------------
-- Server-only RPCs: no re-grant. service_role bypasses GRANT checks, so
-- edge functions and triggers continue to work; REST callers can't touch
-- them.
-- ---------------------------------------------------------------------------
-- Trigger function (auth.users trigger; never invoked via REST)
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;

-- Admin-only. Created out-of-band on prod (no committed creating migration),
-- so guard the REVOKE: it runs on prod where the function exists and no-ops on
-- a fresh `db reset` / CI where it was never created.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'cleanup_orphaned_users'
  ) THEN
    REVOKE EXECUTE ON FUNCTION public.cleanup_orphaned_users() FROM PUBLIC, anon, authenticated;
  END IF;
END $$;

-- Cron caller (send-scheduled-notifications edge function, service_role)
REVOKE EXECUTE ON FUNCTION public.get_eligible_notification_users(
  p_pref_column text,
  p_sent_column text,
  p_target_hour integer,
  p_requires_streak boolean,
  p_inactive_days integer,
  p_day_of_week integer
) FROM PUBLIC, anon, authenticated;

-- Webhook callers (revenuecat-webhook edge function, service_role)
REVOKE EXECUTE ON FUNCTION public.upsert_user_subscription_if_newer(payload jsonb)
  FROM PUBLIC, anon, authenticated;

REVOKE EXECUTE ON FUNCTION public.clawback_consumable_grant(
  p_user_id uuid,
  p_sku text,
  p_kind text,
  p_amount integer,
  p_transaction_id text,
  p_event_timestamp timestamp with time zone
) FROM PUBLIC, anon, authenticated;
