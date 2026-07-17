-- 2026-07-17: Send the service-role bearer from the send-scheduled-notifications
-- pg_cron job so the edge function can REQUIRE authorization.
--
-- WHY (code-review finding P2-2 — close the public-trigger hole):
--   The edge function (supabase/functions/send-scheduled-notifications/index.ts)
--   sends real pushes and now also DRAINS dua_precise_notifications (stamps
--   sent_at). Its old auth guard treated a MISSING Authorization header as
--   authorized, so anyone who knew the URL could trigger a full send. The guard
--   is tightened to REQUIRE the service-role bearer. But the prod cron previously
--   invoked net.http_post with ONLY a Content-Type header (it relied on the
--   null-allow). So this migration re-schedules the cron to ALSO send
--       Authorization: Bearer <service_role_key>
--   read from Supabase Vault AT CRON-RUN TIME.
--
--   This is the ONLY behavior change to the cron. The schedule ('0,30 * * * *',
--   set by 20260512212403) and the URL are preserved verbatim.
--
-- WHY read at RUN time (not embedded at schedule time):
--   * The Authorization header is a Vault subquery INSIDE the scheduled command,
--     evaluated each run. So the literal key never lands in cron.job.command
--     (an embed-via-format() would leak it into that table + backups).
--   * The migration itself needs NO secret to apply — it just stores the job.
--     This keeps CI / fresh local stacks (which have no service_role_key in
--     Vault) applying cleanly, instead of aborting the whole stack.
--   * Self-healing: set the Vault secret any time before the next run and the
--     cron starts sending the bearer with no re-migration.
--
-- WHY VAULT (matches 20260525000000_push_referral_vault_secrets.sql):
--   vault.secrets is encrypted at rest (pgsodium); the key never appears in
--   plaintext in logs / cron.job / backups. Supabase-managed Postgres forbids
--   ALTER DATABASE/ROLE ... SET app.* for non-supabase_admin roles, so a GUC
--   approach 42501s — Vault is the portable per-environment replacement.
--
-- ─────────────────────────────────────────────────────────────────────────────
-- DEPLOY RUNBOOK (ORDER MATTERS — do NOT reorder):
--
--   1. Set the Vault secret on the target env (idempotent; reads, never hardcodes
--      into the cron):
--        insert into vault.secrets (name, secret) values
--          ('service_role_key', '<this project''s SUPABASE_SERVICE_ROLE_KEY>')
--        on conflict (name) do update set secret = excluded.secret;
--   2. Apply THIS migration (re-schedules the cron to send the bearer). NO
--      OUTAGE: the OLD deployed function still tolerates the service-role bearer,
--      so the cron keeps working the instant this lands.
--   3. THEN deploy the new function that REQUIRES the bearer:
--        supabase functions deploy send-scheduled-notifications
--
--   NEVER deploy the require-header function BEFORE step 1+2 — the cron would
--   send an empty bearer and every run would 401 (all scheduled pushes + dua
--   windows silently stop). If the Vault secret is missing at run time the header
--   is 'Bearer ' (empty) → the function 401s that run: a visible, self-correcting
--   misconfig (set the secret), NOT a migration/CI failure.
-- ─────────────────────────────────────────────────────────────────────────────

create extension if not exists pg_net with schema extensions;

do $$
begin
  if exists (
    select 1 from cron.job where jobname = 'send-scheduled-notifications'
  ) then
    perform cron.unschedule('send-scheduled-notifications');
  end if;
end$$;

-- Same schedule ('0,30 * * * *', from 20260512212403) and URL as before; the ONLY
-- change is the Authorization header, whose value is read from Vault each run.
select cron.schedule(
  'send-scheduled-notifications',
  '0,30 * * * *',
  $cron$
    select net.http_post(
      url := 'https://smhvsqrxqoehqncphjrq.supabase.co/functions/v1/send-scheduled-notifications',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || coalesce(
          (select decrypted_secret from vault.decrypted_secrets
             where name = 'service_role_key'),
          ''
        )
      ),
      body := '{}'::jsonb
    );
  $cron$
);
