-- 2026-07-17: Send the service-role bearer from the send-scheduled-notifications
-- pg_cron job so the edge function can REQUIRE authorization.
--
-- WHY (code-review finding P2-2 — close the public-trigger hole):
--   The edge function (supabase/functions/send-scheduled-notifications/index.ts)
--   sends real pushes and now also DRAINS dua_precise_notifications (stamps
--   sent_at). Its old auth guard was:
--       if (authHeader !== null && authHeader !== 'Bearer '+serviceRoleKey) 401
--   i.e. a MISSING Authorization header was treated as authorized. Anyone who
--   knew the function URL could therefore trigger a full send. The guard is
--   being tightened to REQUIRE the service-role bearer:
--       if (authHeader !== 'Bearer '+serviceRoleKey) 401
--   But the prod cron previously invoked net.http_post with ONLY a
--   Content-Type header (it relied on the null-allow). So this migration
--   re-schedules the cron to ALSO send
--       Authorization: Bearer <service_role_key>
--   read from Supabase Vault — matching what an admin manual invoke sends.
--
--   This is the ONLY behavior change to the cron. The schedule ('0,30 * * * *',
--   set by 20260512212403) and the URL are preserved verbatim.
--
-- WHY VAULT (matches the established pattern in
-- 20260525000000_push_referral_vault_secrets.sql):
--   * vault.secrets is encrypted at rest via pgsodium; the key never appears in
--     plaintext in logs / pg_stat_activity / backups / the cron.job table.
--   * Supabase-managed Postgres forbids ALTER DATABASE/ROLE ... SET app.* for
--     non-supabase_admin roles, so a GUC-based approach 42501s. Vault is the
--     portable, per-environment replacement.
--   * We store the key under the name 'service_role_key'. This is a NEW vault
--     secret — the referral migration only stored notify_referral_url /
--     notify_referral_secret, so nothing to reuse here.
--
-- ─────────────────────────────────────────────────────────────────────────────
-- DEPLOY RUNBOOK (ORDER MATTERS — do NOT reorder):
--
--   1. Apply THIS migration to prod FIRST (or together with the function
--      deploy). It (a) stores service_role_key in Vault and (b) re-schedules
--      the cron to send the Authorization bearer.
--      NO OUTAGE: the OLD deployed function still tolerates the service-role
--      bearer (its current guard `authHeader !== 'Bearer '+key` accepts it),
--      so the cron keeps working the instant this migration lands.
--
--   2. THEN deploy the new function (index.ts) that REQUIRES the bearer:
--        supabase functions deploy send-scheduled-notifications
--      Safe because step 1 already makes the cron send the header.
--
--   NEVER deploy the require-header function BEFORE this migration is applied —
--   the cron would still be sending only Content-Type and every run would 401
--   (all scheduled pushes + dua windows would silently stop firing).
--
-- SETUP PER ENVIRONMENT (run ONCE, before/with this migration on each env whose
-- vault does not yet hold the key — the block below is idempotent and safe to
-- re-run; it reads the key from Vault, it does not hardcode it):
--
--   insert into vault.secrets (name, secret) values
--     ('service_role_key', '<this-project''s SUPABASE_SERVICE_ROLE_KEY>')
--   on conflict (name) do update set secret = excluded.secret;
--
-- If 'service_role_key' is missing from Vault when this migration runs, the
-- guard below RAISEs (rather than scheduling a cron that sends a NULL/empty
-- bearer, which would 401 every run). Populate Vault first, then re-run.
-- ─────────────────────────────────────────────────────────────────────────────

create extension if not exists pg_net with schema extensions;

do $$
declare
  v_service_role_key text;
begin
  select decrypted_secret
    into v_service_role_key
  from vault.decrypted_secrets
  where name = 'service_role_key';

  if v_service_role_key is null or v_service_role_key = '' then
    raise exception
      'send-scheduled-notifications cron auth: vault secret ''service_role_key'' is missing or empty. Insert it into vault.secrets before applying this migration (see the SETUP PER ENVIRONMENT block in this file).';
  end if;

  if exists (
    select 1 from cron.job where jobname = 'send-scheduled-notifications'
  ) then
    perform cron.unschedule('send-scheduled-notifications');
  end if;

  -- Same schedule ('0,30 * * * *', from 20260512212403) and URL as before; the
  -- ONLY change is the added Authorization header carrying the service-role
  -- bearer the (now stricter) edge function requires.
  perform cron.schedule(
    'send-scheduled-notifications',
    '0,30 * * * *',
    format(
      $cron$
        select net.http_post(
          url := 'https://smhvsqrxqoehqncphjrq.supabase.co/functions/v1/send-scheduled-notifications',
          headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer %s'
          ),
          body := '{}'::jsonb
        );
      $cron$,
      v_service_role_key
    )
  );
end$$;
