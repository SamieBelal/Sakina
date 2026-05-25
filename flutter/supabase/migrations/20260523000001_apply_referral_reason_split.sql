-- 2026-05-23: Refer-to-Unlock — behavior-preserving patch to apply_referral.
--
-- See docs/superpowers/plans/2026-05-23-onboarding-referral-code-entry.md
-- (closes A1 from eng review).
--
-- The original migration (20260514175600_referrals.sql) returns the same
-- shape (`ok=true, granted_referee_7d=false`) for BOTH:
--   1. The same code re-applied (genuine idempotent no-op — expected).
--   2. A DIFFERENT code applied to a referee who is already-referred
--      (silent clobber — the unique(referee_id) constraint drops the
--      second code on the floor and the UI has no way to surface that the
--      user was just locked out of redeeming a friend's gift).
--
-- This migration ONLY changes the duplicate-conflict tail to differentiate
-- those two paths via a `reason` field:
--   * `idempotent_same_code`         — same friend, same code (no-op).
--   * `already_referred_other_code`  — different friend's code; the
--                                       existing referrer wins and the new
--                                       code is dropped. UI can now warn
--                                       the user explicitly.
--
-- Everything else (signature, language, security definer, search_path,
-- the invalid_code / self_referral / chain_referral guards, the
-- v_inserted insert+grant block) is preserved verbatim from the original
-- migration. The auth.uid() = p_referee self-check added in
-- 20260514183034_referrals_auth_uid_self_check.sql is also preserved.
--
-- Re-runnable: uses create or replace.

create or replace function public.apply_referral(p_code text, p_referee uuid)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_referrer uuid;
  v_inserted boolean := false;
  v_referee_until timestamptz;
begin
  -- CRITICAL: enforce auth.uid() = p_referee. Without this, any authenticated
  -- user can plant a pending referral row on any victim's account (the
  -- referee_id unique constraint then permanently blocks the victim from
  -- being legitimately referred). When auth.uid() IS NULL the caller is a
  -- trusted backend context (anon is blocked by REVOKE EXECUTE).
  if auth.uid() is not null and auth.uid() <> p_referee then
    return jsonb_build_object('ok', false, 'reason', 'not_authorized');
  end if;

  select id into v_referrer from public.user_profiles where referral_code = p_code;
  if v_referrer is null then
    return jsonb_build_object('ok', false, 'reason', 'invalid_code');
  end if;
  if v_referrer = p_referee then
    return jsonb_build_object('ok', false, 'reason', 'self_referral');
  end if;
  if exists (select 1 from public.referrals where referrer_id = p_referee) then
    return jsonb_build_object('ok', false, 'reason', 'chain_referral');
  end if;

  with ins as (
    insert into public.referrals(referrer_id, referee_id, status)
      values (v_referrer, p_referee, 'pending')
      on conflict (referee_id) do nothing
      returning 1
  )
  select exists(select 1 from ins) into v_inserted;

  if v_inserted then
    v_referee_until := now() + interval '7 days';
    update public.user_profiles
       set referral_premium_until = v_referee_until
     where id = p_referee
       and (referral_premium_until is null or referral_premium_until < v_referee_until);
    return jsonb_build_object(
      'ok', true,
      'referee_premium_until', v_referee_until,
      'granted_referee_7d', true
    );
  end if;

  -- Duplicate (referee_id) conflict: differentiate so the UI can tell the
  -- user whether their gesture was a no-op (same code re-applied) or a
  -- silent lockout (they typed a DIFFERENT code than the one already on
  -- their account). The unique(referee_id) constraint means the second
  -- code is dropped; previously the UI had no way to surface that.
  declare v_existing_referrer uuid;
  begin
    select referrer_id into v_existing_referrer
      from public.referrals where referee_id = p_referee;
    if v_existing_referrer = v_referrer then
      return jsonb_build_object('ok', true, 'granted_referee_7d', false,
                                'reason', 'idempotent_same_code');
    else
      return jsonb_build_object('ok', true, 'granted_referee_7d', false,
                                'reason', 'already_referred_other_code');
    end if;
  end;
end $$;

-- Re-apply the EXECUTE lockdown (CREATE OR REPLACE FUNCTION does NOT
-- preserve prior REVOKE/GRANT state on the new function body).
revoke execute on function public.apply_referral(text, uuid) from public, anon, authenticated;
grant  execute on function public.apply_referral(text, uuid) to authenticated;
