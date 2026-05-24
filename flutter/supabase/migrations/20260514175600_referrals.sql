-- 2026-05-14: Refer-to-Unlock — mutual referral premium grant.
--
-- Committed to git on 2026-05-24 in PR #25 (hotfix/ai-bypass-p0-bundle) because
-- 20260524050655_extend_freemium_guards_for_bypass_fields.sql copy-pastes the
-- *current* prod body of guard_user_profiles_freemium_fields, which includes
-- referral_code + referral_premium_until column references added here. Without
-- this migration in local CI, the extension function compiles but errors at
-- first trigger fire with "column referral_code does not exist", breaking
-- freemium_guards_bypass_fields_test.sql TEST 7. Prod version: 20260514175600.

alter table public.user_profiles
  add column if not exists referral_code text unique,
  add column if not exists referral_premium_until timestamptz;

create table if not exists public.referrals (
  id uuid primary key default gen_random_uuid(),
  referrer_id uuid not null references auth.users(id) on delete cascade,
  referee_id  uuid not null references auth.users(id) on delete cascade,
  status text not null check (status in ('pending','confirmed','rejected')),
  created_at timestamptz not null default now(),
  confirmed_at timestamptz,
  unique (referee_id)
);

create index if not exists referrals_referrer_status_idx
  on public.referrals(referrer_id, status);

alter table public.referrals enable row level security;

drop policy if exists referrals_select_referrer on public.referrals;
create policy referrals_select_referrer on public.referrals
  for select using ((select auth.uid()) = referrer_id);

create table if not exists public.referral_grants (
  id uuid primary key default gen_random_uuid(),
  referrer_id uuid not null references auth.users(id) on delete cascade,
  granted_at timestamptz not null default now(),
  expires_at timestamptz not null,
  card_name_id int not null,
  card_tier public.card_tier not null
);
create index if not exists referral_grants_referrer_idx
  on public.referral_grants(referrer_id, granted_at desc);
alter table public.referral_grants enable row level security;
drop policy if exists referral_grants_select_owner on public.referral_grants;
create policy referral_grants_select_owner on public.referral_grants
  for select using ((select auth.uid()) = referrer_id);

create or replace function public.ensure_referral_code(p_user uuid)
returns text
language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_existing text;
  v_alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_code text;
  v_attempt int := 0;
begin
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
  v_card_name_id constant int := 1;
  v_card_tier constant public.card_tier := 'gold';
begin
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

create or replace function public.guard_user_profiles_freemium_fields()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  if current_user in ('service_role', 'postgres', 'supabase_admin') then
    return new;
  end if;

  if new.warmup_reflect_remaining > old.warmup_reflect_remaining then
    raise exception 'cannot reset/refill freemium gating field: warmup_reflect_remaining (% -> %)',
      old.warmup_reflect_remaining, new.warmup_reflect_remaining using errcode = 'check_violation';
  end if;
  if new.warmup_built_dua_remaining > old.warmup_built_dua_remaining then
    raise exception 'cannot reset/refill freemium gating field: warmup_built_dua_remaining (% -> %)',
      old.warmup_built_dua_remaining, new.warmup_built_dua_remaining using errcode = 'check_violation';
  end if;
  if new.warmup_discover_name_remaining > old.warmup_discover_name_remaining then
    raise exception 'cannot reset/refill freemium gating field: warmup_discover_name_remaining (% -> %)',
      old.warmup_discover_name_remaining, new.warmup_discover_name_remaining using errcode = 'check_violation';
  end if;
  if old.had_trial = true and new.had_trial = false then
    raise exception 'cannot reset/refill freemium gating field: had_trial (true -> false is forbidden)'
      using errcode = 'check_violation';
  end if;

  if old.referral_code is not null and new.referral_code is distinct from old.referral_code then
    raise exception 'cannot modify referral_code after initial assignment (% -> %)',
      old.referral_code, new.referral_code using errcode = 'check_violation';
  end if;
  if new.referral_premium_until is distinct from old.referral_premium_until then
    raise exception 'cannot modify referral_premium_until directly; must go through SECURITY DEFINER RPC'
      using errcode = 'check_violation';
  end if;

  return new;
end
$$;

revoke execute on function public.ensure_referral_code(uuid) from anon;
revoke execute on function public.apply_referral(text, uuid) from anon;
revoke execute on function public.confirm_referral_if_pending(uuid) from anon;
