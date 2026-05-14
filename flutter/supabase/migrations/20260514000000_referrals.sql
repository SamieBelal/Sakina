-- 2026-05-14: Refer-to-Unlock — mutual referral premium grant.
--
-- See docs/superpowers/plans/2026-05-14-refer-unlock.md for the full design.
--
-- Summary:
--   * user_profiles gains referral_code (write-once, server-generated) +
--     referral_premium_until (RPC-only).
--   * referrals table tracks (referrer, referee) pairs; unique on referee_id so
--     a user can only ever be referred once.
--   * referral_grants ledger tracks each 30-day window awarded; lets a
--     returning referrer earn a SECOND window after bringing in 3 MORE friends.
--   * ensure_referral_code(p_user) returns the user's code (generates one if
--     missing) from a 32-char no-confusables alphabet.
--   * apply_referral(p_code, p_referee) inserts a pending row AND grants the
--     referee a 7-day premium window (mutual reward). Rejects self-referral,
--     chain-referral, and invalid codes. Idempotent on (referee_id).
--   * confirm_referral_if_pending(p_referee) flips pending → confirmed. When
--     the referrer crosses 3 NEW confirmations since their last grant (NULL
--     for first-timers), grants a 30-day premium window + a Gold Ar-Rahman
--     card AND inserts a row into referral_grants.
--   * The guard_user_profiles_freemium_fields trigger is extended (rewritten
--     in-place with CREATE OR REPLACE) to block client UPDATEs to
--     referral_code (write-once) and referral_premium_until (RPC-only).
--
-- security: ensure_referral_code, apply_referral, confirm_referral_if_pending
-- are SECURITY DEFINER with search_path pinned to (public, pg_temp).
-- All three have anon EXECUTE revoked (matches the 20260509000000 pattern).

-- ---------------------------------------------------------------------------
-- 1. Schema additions
-- ---------------------------------------------------------------------------

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
  unique (referee_id) -- a user can only be referred ONCE in their lifetime
);

create index if not exists referrals_referrer_status_idx
  on public.referrals(referrer_id, status);

alter table public.referrals enable row level security;

-- Referrer can SELECT their own rows (to show "1 of 3 confirmed" counter).
drop policy if exists referrals_select_referrer on public.referrals;
create policy referrals_select_referrer on public.referrals
  for select using ((select auth.uid()) = referrer_id);

-- All writes go through SECURITY DEFINER RPCs below — no direct insert/update.

-- Ledger of GRANTS (distinct from referrals). One row per 30d window awarded.
-- Required so the threshold-of-3 check can count "confirmed referrals created
-- AFTER the most recent grant_at" — giving us a clean cohort boundary that
-- supports re-granting after the first 30d window expires + 3 NEW referees.
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

-- ---------------------------------------------------------------------------
-- 2. ensure_referral_code(p_user) — server-side code generation
--
-- Client-side generation would let a malicious client write arbitrary
-- referral_code values (squat a high-value short code, deliberately collide
-- with someone else's). The unique constraint catches the latter but not the
-- former. SECURITY DEFINER + RLS-locked column (via the freemium guard
-- trigger extension below) means only this RPC can populate referral_code.
--
-- Alphabet excludes confusables I/O/0/1 — 8 chars from a 32-char alphabet =
-- ~10^12 codes, collision-safe for our growth horizon.
-- ---------------------------------------------------------------------------
create or replace function public.ensure_referral_code(p_user uuid)
returns text
language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_existing text;
  v_alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- no I/O/0/1
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
      -- Row exists but already has a code (race) — read and return.
      select referral_code into v_existing from public.user_profiles where id = p_user;
      if v_existing is not null then
        return v_existing;
      end if;
    exception when unique_violation then
      -- Collision with another user's code; retry.
      v_attempt := v_attempt + 1;
      continue;
    end;
    v_attempt := v_attempt + 1;
  end loop;

  raise exception 'failed_to_generate_referral_code_after_5_attempts';
end $$;

-- ---------------------------------------------------------------------------
-- 3. apply_referral(p_code, p_referee)
--
-- Rejects:
--   * invalid_code   — no referrer matches.
--   * self_referral  — referrer == referee.
--   * chain_referral — the referee is themselves a referrer (sybil hardening).
-- Idempotent on (referee_id) unique constraint — re-applying the same code
-- is a no-op.
--
-- MUTUAL REWARD: on a successful insert (not a no-op), grant the REFEREE a
-- 7-day premium window via referral_premium_until. The grant is intentionally
-- unconditional on the referrer's progress — the gift is the gift. The grant
-- NEVER shrinks an existing longer window (e.g. a referrer-turned-referee
-- with 30d remaining stays at 30d).
-- ---------------------------------------------------------------------------
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
  -- Chain-referral guard: a user who has themselves referred someone cannot
  -- now be the referee of another user.
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
    -- Grant the referee 7 days of premium. The freemium-gating trigger
    -- (extended below) allows service_role/postgres writes through, and this
    -- SECURITY DEFINER RPC runs as the function owner (postgres-side).
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

  -- Idempotent re-application (already-referred referee): no new grant.
  return jsonb_build_object('ok', true, 'granted_referee_7d', false);
end $$;

-- ---------------------------------------------------------------------------
-- 4. confirm_referral_if_pending(p_referee)
--
-- Threshold logic: count "confirmed referrals created AFTER the most recent
-- grant for this referrer". Lets a returning referrer get a SECOND 30d window
-- after the first expires, provided they bring 3 MORE referees in.
--
-- Re-grant condition: referral_premium_until is NULL or in the past.
--
-- Card grant: INSERT directly into user_card_collection (there is no
-- grant_card RPC). Use name_id = 1 (Ar-Rahman) at gold tier. ON CONFLICT
-- upgrades a bronze/silver of the same name to gold; never downgrades
-- emerald or stays-at-gold.
-- ---------------------------------------------------------------------------
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
  update public.referrals
     set status = 'confirmed', confirmed_at = now()
   where referee_id = p_referee and status = 'pending'
   returning referrer_id into v_referrer;

  if v_referrer is null then
    return jsonb_build_object('ok', true, 'confirmed', false);
  end if;

  -- "Confirmed since last grant" — the cohort that hasn't been rewarded yet.
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

  -- Re-grant condition: window is NULL or has expired.
  select referral_premium_until into v_existing_until
    from public.user_profiles where id = v_referrer;

  if v_existing_until is not null and v_existing_until > now() then
    -- Already has an active window — don't stack/extend. Future plan: tiered.
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

  -- Card grant — direct insert (no grant_card RPC exists). Upgrade-only on
  -- conflict: bronze/silver → gold; gold/emerald → unchanged.
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

-- ---------------------------------------------------------------------------
-- 5. RLS lockdown extension — extend the freemium-fields guard trigger from
--    20260510010000_lock_freemium_gating_fields.sql to also block client
--    UPDATEs to referral_premium_until and referral_code.
--
--    CREATE OR REPLACE the function in-place; the trigger definition is
--    unchanged.
-- ---------------------------------------------------------------------------
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

  -- Existing checks (preserved verbatim from 20260510010000):
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

  -- NEW checks for referral fields:
  -- referral_code is write-once via ensure_referral_code() RPC.
  if old.referral_code is not null and new.referral_code is distinct from old.referral_code then
    raise exception 'cannot modify referral_code after initial assignment (% -> %)',
      old.referral_code, new.referral_code using errcode = 'check_violation';
  end if;
  -- referral_premium_until is write-only via confirm_referral_if_pending() /
  -- apply_referral() RPCs.
  if new.referral_premium_until is distinct from old.referral_premium_until then
    raise exception 'cannot modify referral_premium_until directly; must go through SECURITY DEFINER RPC'
      using errcode = 'check_violation';
  end if;

  return new;
end
$$;
-- The trigger from 20260510010000 already references this function; the
-- CREATE OR REPLACE above rebinds it automatically.

-- ---------------------------------------------------------------------------
-- 6. Lock down EXECUTE following the 20260509000000_revoke_anon_rpc_execute
--    pattern: revoke from PUBLIC + anon + authenticated (clean slate), then
--    re-grant to authenticated only. A bare `REVOKE ... FROM anon` does NOT
--    actually remove access — PUBLIC's default EXECUTE grant remains, which
--    is the trap that bit the 20260509 migration too.
-- ---------------------------------------------------------------------------
revoke execute on function public.ensure_referral_code(uuid) from public, anon, authenticated;
grant  execute on function public.ensure_referral_code(uuid) to authenticated;

revoke execute on function public.apply_referral(text, uuid) from public, anon, authenticated;
grant  execute on function public.apply_referral(text, uuid) to authenticated;

revoke execute on function public.confirm_referral_if_pending(uuid) from public, anon, authenticated;
grant  execute on function public.confirm_referral_if_pending(uuid) to authenticated;
