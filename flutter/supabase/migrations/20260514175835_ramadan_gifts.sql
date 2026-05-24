-- 2026-05-14: Sakina Gifts — occasion-based 7-day premium grants.
--
-- Committed to git on 2026-05-25 in PR #27 (hotfix/ai-bypass-p1-bundle) because
-- 20260525000000_ai_bypass_p1_security_bundle.sql adds a freemium guard on
-- user_profiles.gift_premium_until — the column is defined here. Without
-- this migration in local CI, the guard test (Test 14 honest-path) errors
-- with "column gift_premium_until does not exist".
--
-- Prod version: 20260514175835. Source pulled verbatim from prod via MCP.

create table if not exists public.islamic_occasions (
  id           text primary key,
  display_name text not null,
  starts_at    timestamptz not null,
  ends_at      timestamptz not null,
  constraint occasion_window_valid check (ends_at >= starts_at)
);

alter table public.islamic_occasions enable row level security;

drop policy if exists "occasions readable by all" on public.islamic_occasions;
create policy "occasions readable by all"
  on public.islamic_occasions for select using (true);

create table if not exists public.sakina_gifts (
  user_id     uuid not null references auth.users(id) on delete cascade,
  occasion_id text not null references public.islamic_occasions(id),
  granted_at  timestamptz not null default now(),
  expires_at  timestamptz not null,
  primary key (user_id, occasion_id)
);

alter table public.sakina_gifts enable row level security;

drop policy if exists "gifts readable by owner" on public.sakina_gifts;
create policy "gifts readable by owner"
  on public.sakina_gifts for select using ((select auth.uid()) = user_id);

alter table public.user_profiles
  add column if not exists gift_premium_until timestamptz;

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

insert into public.islamic_occasions(id, display_name, starts_at, ends_at) values
  ('ramadan_2027',    'Ramadan 2027',     '2027-02-17 00:00:00+00', '2027-03-19 23:59:59+00'),
  ('eid_fitr_2027',   'Eid al-Fitr 2027', '2027-03-20 00:00:00+00', '2027-03-22 23:59:59+00'),
  ('eid_adha_2027',   'Eid al-Adha 2027', '2027-05-27 00:00:00+00', '2027-06-04 23:59:59+00'),
  ('mawlid_2027',     'Mawlid 2027',      '2027-09-04 00:00:00+00', '2027-09-04 23:59:59+00')
on conflict (id) do nothing;
