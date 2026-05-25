-- 2026-05-25: Move notify_referrer_on_confirm's URL+secret reads from
-- `current_setting('app.*')` (PostgreSQL GUCs) to `vault.decrypted_secrets`
-- (Supabase Vault).
--
-- Why this change is needed:
--   Supabase managed Postgres restricts `ALTER DATABASE ... SET app.*` and
--   `ALTER ROLE ... SET app.*` to supabase_admin only. The migration that
--   shipped in PR-19 (`20260523010000_push_on_referral_confirm.sql`) was
--   designed around `current_setting('app.notify_referral_url')` so each
--   environment could set its own per-project URL+secret. That design works
--   on self-hosted Postgres but fails with 42501 permission_denied when
--   anyone (including dashboard SQL editor / service_role) tries to SET
--   the GUC on Supabase-managed projects. The function was therefore
--   silently no-op'ing in production with a WARNING in logs.
--
-- Why Vault is the canonical replacement:
--   * `vault.secrets` is encrypted at rest via pgsodium; the secret never
--     appears in plaintext at any layer (logs, pg_stat_activity, backups).
--   * Per-environment portability is preserved — each env inserts its own
--     row into vault.secrets, the function reads by name.
--   * SECURITY DEFINER functions owned by postgres can read
--     `vault.decrypted_secrets` without needing additional grants.
--
-- Setup per environment (run ONCE after applying this migration):
--   insert into vault.secrets (name, secret) values
--     ('notify_referral_url',
--      'https://<your-project-ref>.supabase.co/functions/v1/notify-referral-confirmed'),
--     ('notify_referral_secret', '<random-32-char-hex>')
--   on conflict (name) do update set secret = excluded.secret;
--
--   -- And on the edge side (unchanged):
--   supabase secrets set NOTIFY_REFERRAL_SECRET=<same-secret>
--
-- The function is fail-soft: if either secret is missing from vault,
-- raises WARNING and returns NEW without firing the push. This matches
-- the pre-PR behavior so a fresh branch DB without vault entries doesn't
-- spam pushes.

create or replace function public.notify_referrer_on_confirm()
returns trigger
language plpgsql
security definer
set search_path = public, vault, extensions, pg_temp
as $$
declare
  v_url    text;
  v_secret text;
begin
  begin
    -- Read both secrets in a single roundtrip.
    select
      max(case when name = 'notify_referral_url'    then decrypted_secret end),
      max(case when name = 'notify_referral_secret' then decrypted_secret end)
    into v_url, v_secret
    from vault.decrypted_secrets
    where name in ('notify_referral_url', 'notify_referral_secret');

    if v_url is null or v_url = '' or v_secret is null or v_secret = '' then
      raise warning 'notify_referrer_on_confirm: vault entry notify_referral_url and/or notify_referral_secret missing or empty; skipping push';
      return new;
    end if;

    perform net.http_post(
      url := v_url,
      body := jsonb_build_object(
        'referrer_id', new.referrer_id::text,
        'referee_id',  new.referee_id::text
      ),
      headers := jsonb_build_object(
        'Content-Type',     'application/json',
        'X-Notify-Secret',  v_secret
      )
    );
  exception when others then
    raise warning 'notify_referrer_on_confirm: net.http_post failed (referrer=%, referee=%): %',
      new.referrer_id, new.referee_id, sqlerrm;
  end;
  return new;
end
$$;

-- Lockdown stays identical to PR-19.
revoke execute on function public.notify_referrer_on_confirm() from public, anon, authenticated;
