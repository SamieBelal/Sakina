-- 2026-07-17: send-scheduled-notifications cron auth (P2-2).
--
-- Close the public-trigger hole: the edge function now REQUIRES a dedicated
-- CRON_SECRET bearer (see index.ts `isAuthorized`). This migration re-schedules
-- the pg_cron job to send `Authorization: Bearer <cron_secret>`, embedding the
-- secret read from Vault AT APPLY TIME (privileged) rather than at run time —
-- pg_cron's execution role cannot reliably read vault.decrypted_secrets, so a
-- run-time subquery would send an empty bearer and 401. Embedding a DEDICATED,
-- rotatable CRON_SECRET (not the service-role key) is the accepted trade for the
-- key landing in cron.job.command.
--
-- The SAME value must be set as the CRON_SECRET edge-function secret:
--   supabase secrets set CRON_SECRET=<value> --project-ref <ref>
-- and stored in Vault as `cron_secret` (both done out-of-band on prod).
--
-- CI-safe: if `cron_secret` is absent from Vault (fresh/CI stack), the bearer is
-- embedded as empty — the migration applies cleanly (CI never runs the cron).
-- Do NOT raise here; a raise aborts the whole local stack. The function 500s on
-- an unset CRON_SECRET, so a real misconfig is loud at request time, not silent.
--
-- DEPLOY ORDER (zero-outage, as executed on prod): set the edge secret + Vault
-- value → deploy an ACCEPT-phase function (CRON_SECRET or no-auth) → verify the
-- secret matches → apply THIS migration (cron sends the secret) → deploy the
-- REQUIRE-phase function. Never deploy require before the cron sends the secret.

create extension if not exists pg_net with schema extensions;

do $$
declare
  v_secret text;
begin
  select decrypted_secret into v_secret
  from vault.decrypted_secrets
  where name = 'cron_secret';

  if exists (
    select 1 from cron.job where jobname = 'send-scheduled-notifications'
  ) then
    perform cron.unschedule('send-scheduled-notifications');
  end if;

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
      coalesce(v_secret, '')
    )
  );
end$$;
