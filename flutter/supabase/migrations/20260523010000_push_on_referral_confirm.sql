-- 2026-05-23: Push notification when a referral is confirmed.
--
-- A thin AFTER UPDATE trigger on public.referrals fires `net.http_post` to
-- the `notify-referral-confirmed` edge function. The edge function holds the
-- OneSignal REST key (already deployed as a Supabase Edge Function secret —
-- same secret that powers `send-scheduled-notifications`) and shapes the
-- modern transactional-push v2 request.
--
-- Design notes (UPDATED post-/review hardening):
--
--   1. Why edge-function indirection (not a direct call to api.onesignal.com
--      from plpgsql, not Supabase Vault): the REST key MUST NOT live in the
--      DB. Keeping it as an Edge Function secret matches the only existing
--      OneSignal call site in this project (`send-scheduled-notifications`)
--      and avoids introducing a Vault dependency for one function.
--
--   2. Why SECURITY DEFINER: `net.http_post` requires extension privileges
--      that authenticated/anon roles do not have. The function runs as the
--      migration owner (postgres) so the HTTP call goes through; the trigger
--      body is otherwise side-effect-free on user data.
--
--   3. Why `set search_path = public, extensions, pg_temp`: pinned so a
--      malicious search_path mutation can't redirect `net.http_post` to a
--      shadowed function (matches the pattern in 20260510000000). All
--      `net.*` calls are fully qualified anyway, but pinning is belt+braces.
--
--   4. Why the tightened WHEN clause `OLD.status = 'pending' AND NEW.status
--      = 'confirmed'` (S4 fix): the original `IS DISTINCT FROM 'confirmed'`
--      would fire on `rejected -> confirmed` resurrection if support ever
--      reverses a moderation decision. The only legitimate transition that
--      should produce a push is `pending -> confirmed`, matching what
--      `confirm_referral_if_pending` actually performs (it only UPDATEs
--      rows `where status = 'pending'`).
--
--   5. Why the EXCEPTION swallow: push delivery is best-effort. The trigger
--      fires inside the `confirm_referral_if_pending` RPC's transaction; a
--      RAISE there would roll back the confirmation itself, defeating the
--      point. We swallow with RAISE WARNING so failures surface in logs
--      without corrupting state.
--
--   6. Why env-bound URL via `current_setting` (S3 fix): the migration
--      MUST NOT hardcode the project subdomain. If applied to a staging
--      project, staging confirmations would fire pushes to the PRODUCTION
--      edge function (and thus production OneSignal users). The trigger
--      reads `app.notify_referral_url` and silently no-ops if unset, so the
--      migration can be applied to any environment safely and the URL is
--      configured per-environment.
--
--   7. Why shared-secret header via `current_setting` (S1 fix): the edge
--      function is deployed `--no-verify-jwt`. Without an additional gate,
--      anyone who discovers the function URL could spam pushes to any user
--      and weaponize the display-name interpolation as a phishing channel.
--      The trigger reads `app.notify_referral_secret` and passes it as
--      `X-Notify-Secret`; the edge function fails-closed on a missing or
--      mismatched secret. If the secret is unset locally, the trigger
--      no-ops (push won't fire — better than firing without auth).
--
-- Environment setup (run ONCE per environment, not in this migration):
--
--   alter database postgres set app.notify_referral_url =
--     'https://<your-project-ref>.supabase.co/functions/v1/notify-referral-confirmed';
--   alter database postgres set app.notify_referral_secret =
--     '<random-32-char-secret>';
--   -- And on the edge side:
--   supabase secrets set NOTIFY_REFERRAL_SECRET=<same-secret>
--
-- After setting GUCs, sessions need to reconnect to pick them up. The
-- trigger reads with the `missing_ok = true` flag so unset GUCs return
-- NULL (handled gracefully) instead of raising.
--
-- ---------------------------------------------------------------------------
-- 1. notify_referrer_on_confirm() — trigger function
-- ---------------------------------------------------------------------------
create or replace function public.notify_referrer_on_confirm()
returns trigger
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  v_url    text;
  v_secret text;
begin
  begin
    v_url    := current_setting('app.notify_referral_url',    true);
    v_secret := current_setting('app.notify_referral_secret', true);

    -- Fail-soft: if URL or secret is unset (unconfigured environment, e.g.
    -- a fresh branch DB), no-op rather than fire an unauthenticated push.
    -- RAISE WARNING so misconfiguration is visible in logs without breaking
    -- the confirmation transaction.
    if v_url is null or v_url = '' or v_secret is null or v_secret = '' then
      raise warning 'notify_referrer_on_confirm: app.notify_referral_url and/or app.notify_referral_secret unset; skipping push';
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

-- ---------------------------------------------------------------------------
-- 2. Trigger — single fire per real pending->confirmed flip.
--
-- Tightened WHEN clause (S4): OLD.status = 'pending' instead of
-- IS DISTINCT FROM 'confirmed'. Blocks resurrection paths like
-- rejected -> confirmed from firing pushes. Matches the only legitimate
-- transition that confirm_referral_if_pending actually performs.
-- ---------------------------------------------------------------------------
drop trigger if exists trg_notify_referrer_on_confirm on public.referrals;
create trigger trg_notify_referrer_on_confirm
  after update of status on public.referrals
  for each row
  when (old.status = 'pending' and new.status = 'confirmed')
  execute function public.notify_referrer_on_confirm();

-- ---------------------------------------------------------------------------
-- 3. Lockdown — only trigger machinery should invoke this function.
--    Matches the EXECUTE lockdown pattern from 20260514175600_referrals.sql.
-- ---------------------------------------------------------------------------
revoke execute on function public.notify_referrer_on_confirm() from public, anon, authenticated;
