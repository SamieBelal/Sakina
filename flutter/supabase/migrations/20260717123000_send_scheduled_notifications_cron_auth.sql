-- 2026-07-17: send-scheduled-notifications cron auth.
--
-- TODO(P2-2) — REVERTED. The intent of this migration was to close the
-- public-trigger hole on the send-scheduled-notifications edge function by
-- having the pg_cron job send a service-role bearer that the function requires.
-- It was deployed and then REVERTED at runtime: the bearer the cron sent (a
-- Vault-stored `service_role_key`) did NOT match the function's live
-- SUPABASE_SERVICE_ROLE_KEY env, so every authenticated cron run 401'd and
-- scheduled notifications (daily/streak/dua) stopped. To restore service the
-- function was reverted to accept a missing Authorization header (see
-- index.ts `isAuthorized` TODO(P2-2)) and the cron reverted to send NO auth.
--
-- This migration now just ensures the cron is scheduled in that WORKING,
-- no-auth form (idempotent; matches 20260512212403's schedule + URL). The Vault
-- secret `service_role_key` may already exist from the reverted attempt; it is
-- harmless and can be reused when P2-2 is redone correctly.
--
-- TO REDO P2-2 SAFELY (future work): use a DEDICATED cron secret set as BOTH an
-- edge-function secret (`supabase secrets set CRON_SECRET=<v>`) AND the Vault
-- value the cron sends, then gate the function on that ONE verified value —
-- rather than the auto-injected SUPABASE_SERVICE_ROLE_KEY, whose exact value
-- can't be confirmed from outside the function. Deploy order: cron sends the
-- secret BEFORE the function requires it.

create extension if not exists pg_net with schema extensions;

do $$
begin
  if exists (
    select 1 from cron.job where jobname = 'send-scheduled-notifications'
  ) then
    perform cron.unschedule('send-scheduled-notifications');
  end if;
end$$;

select cron.schedule(
  'send-scheduled-notifications',
  '0,30 * * * *',
  $cron$
    select net.http_post(
      url := 'https://smhvsqrxqoehqncphjrq.supabase.co/functions/v1/send-scheduled-notifications',
      headers := jsonb_build_object('Content-Type', 'application/json'),
      body := '{}'::jsonb
    );
  $cron$
);
