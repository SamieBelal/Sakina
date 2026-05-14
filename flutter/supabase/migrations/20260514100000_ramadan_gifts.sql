-- 20260514100000_ramadan_gifts.sql
--
-- Ramadan / Eid "Sakina Gift" mechanic. See
-- docs/superpowers/plans/2026-05-14-ramadan-gift.md and
-- docs/decisions/2026-05-14-islamic-occasion-calendar-source.md.
--
-- Tables: islamic_occasions (calendar) + sakina_gifts (per-user claims).
-- RPC: claim_sakina_gift(p_user, p_occasion) — SECURITY DEFINER, idempotent.

-- ---------------------------------------------------------------------------
-- islamic_occasions
-- ---------------------------------------------------------------------------
create table if not exists public.islamic_occasions (
  id           text primary key,
  display_name text not null,
  starts_at    timestamptz not null,
  ends_at      timestamptz not null,
  constraint occasion_window_valid check (ends_at >= starts_at)
);

alter table public.islamic_occasions enable row level security;

-- Public read; anon can see the calendar but cannot write. Matches the
-- public-catalog policy posture from 20260410031133_public_catalog_anon_read.
drop policy if exists "occasions readable by all" on public.islamic_occasions;
create policy "occasions readable by all"
  on public.islamic_occasions for select using (true);

-- ---------------------------------------------------------------------------
-- sakina_gifts
-- ---------------------------------------------------------------------------
create table if not exists public.sakina_gifts (
  user_id     uuid not null references auth.users(id) on delete cascade,
  occasion_id text not null references public.islamic_occasions(id),
  granted_at  timestamptz not null default now(),
  expires_at  timestamptz not null,
  primary key (user_id, occasion_id)
);

alter table public.sakina_gifts enable row level security;

-- Cover the occasion_id FK so backfill / per-occasion analytics queries
-- don't sequential-scan. The (user_id, occasion_id) PK already covers the
-- user_id side; this index covers the occasion_id side.
create index if not exists sakina_gifts_occasion_id_idx
  on public.sakina_gifts (occasion_id);

-- Owner-only SELECT. No INSERT/UPDATE/DELETE policy — only the
-- SECURITY DEFINER RPC writes.
drop policy if exists "gifts readable by owner" on public.sakina_gifts;
create policy "gifts readable by owner"
  on public.sakina_gifts for select using ((select auth.uid()) = user_id);

-- ---------------------------------------------------------------------------
-- user_profiles companion column
-- ---------------------------------------------------------------------------
-- Mirrored fast-lookup window so `isPremium()` can check entitlement without
-- a join. Authoritative value lives in sakina_gifts.expires_at; this column
-- is best-effort cache populated by the RPC.
alter table public.user_profiles
  add column if not exists gift_premium_until timestamptz;

-- ---------------------------------------------------------------------------
-- claim_sakina_gift RPC
-- ---------------------------------------------------------------------------
-- Idempotent: re-calling within the window returns the existing grant payload
-- without re-stamping. Self-validates auth.uid() == p_user so a caller cannot
-- claim a gift on someone else's behalf. search_path pinned per
-- 20260510172453_pin_function_search_path posture.
create or replace function public.claim_sakina_gift(p_user uuid, p_occasion text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_occ        public.islamic_occasions%rowtype;
  v_existing   public.sakina_gifts%rowtype;
  v_expires_at timestamptz;
begin
  if auth.uid() is null or auth.uid() <> p_user then
    return jsonb_build_object('granted', false, 'reason', 'unauthorized');
  end if;

  select * into v_occ from public.islamic_occasions where id = p_occasion;
  if not found then
    return jsonb_build_object('granted', false, 'reason', 'unknown_occasion');
  end if;

  if now() < v_occ.starts_at or now() > v_occ.ends_at then
    return jsonb_build_object('granted', false, 'reason', 'outside_window');
  end if;

  -- Idempotency: if already claimed for this occasion, return existing grant.
  select * into v_existing
    from public.sakina_gifts
   where user_id = p_user and occasion_id = p_occasion;

  if found then
    return jsonb_build_object(
      'granted', true,
      'granted_at', v_existing.granted_at,
      'expires_at', v_existing.expires_at,
      'reused', true
    );
  end if;

  v_expires_at := now() + interval '7 days';

  insert into public.sakina_gifts(user_id, occasion_id, granted_at, expires_at)
  values (p_user, p_occasion, now(), v_expires_at);

  -- Mirror to user_profiles for cheap premium gate. If a previous occasion
  -- claim left a later expiry on the row, GREATEST keeps the longer window.
  update public.user_profiles
     set gift_premium_until = greatest(coalesce(gift_premium_until, now()), v_expires_at)
   where id = p_user;

  return jsonb_build_object(
    'granted', true,
    'granted_at', now(),
    'expires_at', v_expires_at,
    'reused', false
  );
end
$$;

revoke execute on function public.claim_sakina_gift(uuid, text) from anon;

-- ---------------------------------------------------------------------------
-- Seed 2027 occasions. Idempotent via ON CONFLICT DO NOTHING.
-- ---------------------------------------------------------------------------
insert into public.islamic_occasions(id, display_name, starts_at, ends_at) values
  ('ramadan_2027',    'Ramadan 2027',     '2027-02-17 00:00:00+00', '2027-03-19 23:59:59+00'),
  ('eid_fitr_2027',   'Eid al-Fitr 2027', '2027-03-20 00:00:00+00', '2027-03-22 23:59:59+00'),
  ('eid_adha_2027',   'Eid al-Adha 2027', '2027-05-27 00:00:00+00', '2027-06-04 23:59:59+00'),
  ('mawlid_2027',     'Mawlid 2027',      '2027-09-04 00:00:00+00', '2027-09-04 23:59:59+00')
on conflict (id) do nothing;
