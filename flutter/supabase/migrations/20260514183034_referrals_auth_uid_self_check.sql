-- 2026-05-14: Refer-to-Unlock — critical follow-up.
--
-- The original migration (20260514175600_referrals.sql) shipped apply_referral
-- and confirm_referral_if_pending as SECURITY DEFINER without enforcing
-- `auth.uid() = p_referee`. Because both RPCs take p_referee as a bare
-- parameter and run with elevated privileges, ANY authenticated user could
-- pass an arbitrary uuid and:
--
--   1. Plant a `referrals` row keyed on a victim's referee_id (the unique
--      constraint then PERMANENTLY locks that victim out of being legitimately
--      referred), while also crediting the attacker's own code as referrer.
--   2. Grant the 7-day premium window to a victim of their choosing (low
--      severity on its own — premium for free is "good" for the victim — but
--      part of the same trust break).
--   3. Call `confirm_referral_if_pending(victim_uuid)` to PREMATURELY flip a
--      pending referral to confirmed before the victim has finished
--      onboarding. This bypasses the intended gate ("onboarding completion is
--      proof-of-life that the referee is a real user") and lets an attacker
--      who recruited a single curious clicker re-fire the 30d-grant threshold
--      check without the recruit ever finishing the app.
--
-- Fix: when there's a signed-in user (auth.uid() IS NOT NULL), require
-- auth.uid() = p_referee. When auth.uid() IS NULL the caller is either anon
-- (already blocked by REVOKE EXECUTE) or a trusted backend context
-- (service_role, postgres, supabase_admin, pg_cron) — bypass intentionally.
--
-- Why not `current_user`? SECURITY DEFINER functions execute with current_user
-- set to the function owner (postgres), so it's a poor signal here.
-- Why not `session_user`? PostgREST connects as 'authenticator' regardless
-- of whether the user is signed in, so session_user can't distinguish
-- "anon" from "authenticated". auth.uid() reads the JWT claims directly
-- and is the canonical signal — same one used everywhere else in our schema.
--
-- ensure_referral_code(p_user) is also tightened the same way — only the user
-- themselves should be able to (lazily) provision their own referral_code.

create or replace function public.ensure_referral_code(p_user uuid)
returns text
language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_existing text;
  v_alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- no I/O/0/1
  v_code text;
  v_attempt int := 0;
begin
  -- Self-check: when called with a JWT, the caller must equal p_user.
  -- auth.uid() IS NULL is allowed (anon already blocked by REVOKE EXECUTE,
  -- so this branch only triggers for service_role / postgres / pg_cron).
  if auth.uid() is not null and auth.uid() <> p_user then
    raise exception 'ensure_referral_code: caller must equal p_user'
      using errcode = 'insufficient_privilege';
  end if;

  select referral_code into v_existing from public.user_profiles where id = p_user;
  if v_existing is not null then
    return v_existing;
  end if;

  while v_attempt < 5 loop
    v_code := '';
    for i in 1..8 loop
      v_code := v_code || substr(v_alphabet, 1 + floor(random() * length(v_alphabet))::int, 1);
    end loop;

    begin
      update public.user_profiles
         set referral_code = v_code
       where id = p_user
         and referral_code is null;
      if found then
        return v_code;
      end if;
      select referral_code into v_existing from public.user_profiles where id = p_user;
      if v_existing is not null then
        return v_existing;
      end if;
    exception when unique_violation then
      v_attempt := v_attempt + 1;
      continue;
    end;
    v_attempt := v_attempt + 1;
  end loop;

  raise exception 'failed_to_generate_referral_code_after_5_attempts';
end $$;

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

  return jsonb_build_object('ok', true, 'granted_referee_7d', false);
end $$;

create or replace function public.confirm_referral_if_pending(p_referee uuid)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_referrer uuid;
  v_last_grant_at timestamptz;
  v_new_confirmed_count int;
  v_existing_until timestamptz;
  v_new_until timestamptz;
  v_card_name_id constant int := 1; -- Ar-Rahman
  v_card_tier constant public.card_tier := 'gold';
begin
  -- CRITICAL: enforce auth.uid() = p_referee. Without this, any authenticated
  -- user could call confirm_referral_if_pending(victim_uuid) to prematurely
  -- credit themselves (as the victim's referrer) toward the 3-confirmed
  -- threshold without the victim having finished onboarding. Same auth.uid()
  -- IS NOT NULL guard as apply_referral above.
  if auth.uid() is not null and auth.uid() <> p_referee then
    return jsonb_build_object('ok', false, 'reason', 'not_authorized');
  end if;

  update public.referrals
     set status = 'confirmed', confirmed_at = now()
   where referee_id = p_referee and status = 'pending'
   returning referrer_id into v_referrer;

  if v_referrer is null then
    return jsonb_build_object('ok', true, 'confirmed', false);
  end if;

  select max(granted_at) into v_last_grant_at
    from public.referral_grants
   where referrer_id = v_referrer;

  select count(*) into v_new_confirmed_count
    from public.referrals
   where referrer_id = v_referrer
     and status = 'confirmed'
     and (v_last_grant_at is null or confirmed_at > v_last_grant_at);

  if v_new_confirmed_count < 3 then
    return jsonb_build_object(
      'ok', true, 'confirmed', true,
      'new_confirmed_count', v_new_confirmed_count,
      'granted', false
    );
  end if;

  select referral_premium_until into v_existing_until
    from public.user_profiles where id = v_referrer;

  if v_existing_until is not null and v_existing_until > now() then
    return jsonb_build_object(
      'ok', true, 'confirmed', true,
      'new_confirmed_count', v_new_confirmed_count,
      'granted', false, 'reason', 'window_still_active'
    );
  end if;

  v_new_until := now() + interval '30 days';

  update public.user_profiles
     set referral_premium_until = v_new_until
   where id = v_referrer;

  insert into public.referral_grants(referrer_id, expires_at, card_name_id, card_tier)
    values (v_referrer, v_new_until, v_card_name_id, v_card_tier);

  insert into public.user_card_collection(user_id, name_id, tier)
    values (v_referrer, v_card_name_id, v_card_tier)
    on conflict (user_id, name_id) do update
      set tier = case
        when public.user_card_collection.tier in ('bronze','silver') then 'gold'::public.card_tier
        else public.user_card_collection.tier
      end,
      last_engaged_at = now();

  return jsonb_build_object(
    'ok', true, 'confirmed', true,
    'new_confirmed_count', v_new_confirmed_count,
    'granted', true,
    'referral_premium_until', v_new_until
  );
end $$;

-- Re-apply the EXECUTE lockdown (CREATE OR REPLACE FUNCTION does NOT preserve
-- prior REVOKE/GRANT state on the new function body).
revoke execute on function public.ensure_referral_code(uuid) from public, anon, authenticated;
grant  execute on function public.ensure_referral_code(uuid) to authenticated;

revoke execute on function public.apply_referral(text, uuid) from public, anon, authenticated;
grant  execute on function public.apply_referral(text, uuid) to authenticated;

revoke execute on function public.confirm_referral_if_pending(uuid) from public, anon, authenticated;
grant  execute on function public.confirm_referral_if_pending(uuid) to authenticated;
