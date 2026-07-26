-- Lantern cosmetics: server-authoritative economy (inventory, catalog, Noor).
-- All mutation via SECURITY DEFINER RPCs (later tasks); direct writes blocked (later task).

alter table public.user_profiles
  add column if not exists noor_balance      integer not null default 0 check (noor_balance >= 0),
  add column if not exists noor_total_earned integer not null default 0,
  add column if not exists noor_total_spent  integer not null default 0,
  add column if not exists equipped_lantern_skin text not null default 'classic_gold',
  add column if not exists equipped_backdrop     text not null default 'default';

create table if not exists public.cosmetic_catalog (
  item_type   text not null check (item_type in ('lantern_skin','backdrop')),
  item_id     text not null,
  noor_price        integer,
  iap_product_id    text,
  is_premium_exclusive boolean not null default false,
  is_seasonal          boolean not null default false,
  season_key           text,
  milestone_day        integer,
  early_access_at      timestamptz,
  general_release_at   timestamptz,
  available_from       timestamptz,
  available_until      timestamptz,
  min_app_version      text not null default '0.0.0',
  grant_retention      text not null default 'permanent'
                       check (grant_retention in ('permanent','while_active')),
  sort        integer not null default 0,
  active      boolean not null default true,
  primary key (item_type, item_id)
);

create table if not exists public.user_cosmetics (
  user_id     uuid not null references auth.users(id) on delete cascade,
  item_type   text not null check (item_type in ('lantern_skin','backdrop')),
  item_id     text not null,
  acquired_via text not null check (acquired_via in
                ('default','noor','iap','milestone','seasonal','premium')),
  acquired_at timestamptz not null default now(),
  primary key (user_id, item_type, item_id)
);

create table if not exists public.noor_grants (
  user_id    uuid not null references auth.users(id) on delete cascade,
  reason_key text not null,
  amount     integer not null,
  created_at timestamptz not null default now(),
  primary key (user_id, reason_key)
);

create index if not exists idx_user_cosmetics_user on public.user_cosmetics(user_id);

-- Guard: economy columns are writable ONLY by trusted RPCs (which set the GUC flag).
create or replace function public.cosmetics_guard() returns trigger
language plpgsql as $$
begin
  if current_setting('app.cosmetics_rpc', true) = 'on' then
    return NEW;
  end if;
  if NEW.noor_balance is distinct from OLD.noor_balance
     or NEW.noor_total_earned is distinct from OLD.noor_total_earned
     or NEW.noor_total_spent  is distinct from OLD.noor_total_spent
     or NEW.equipped_lantern_skin is distinct from OLD.equipped_lantern_skin
     or NEW.equipped_backdrop     is distinct from OLD.equipped_backdrop then
    raise exception 'cosmetics columns are RPC-only';
  end if;
  return NEW;
end $$;

drop trigger if exists trg_cosmetics_guard on public.user_profiles;
create trigger trg_cosmetics_guard before update on public.user_profiles
  for each row execute function public.cosmetics_guard();

alter table public.user_cosmetics enable row level security;
alter table public.noor_grants     enable row level security;
drop policy if exists user_cosmetics_read on public.user_cosmetics;
create policy user_cosmetics_read on public.user_cosmetics
  for select using ((select auth.uid()) = user_id);
-- no insert/update/delete policy → clients cannot write; RPCs are SECURITY DEFINER

alter table public.cosmetic_catalog enable row level security;
drop policy if exists cosmetic_catalog_read on public.cosmetic_catalog;
create policy cosmetic_catalog_read on public.cosmetic_catalog
  for select using (true);

-- award_noor: grant earned Noor with a SERVER-DERIVED amount (never trust a
-- client amount), idempotent per (user, reason_key) via the noor_grants ledger
-- so a grant can never double-credit (stops streak-rebuild farming).
create or replace function public.award_noor(p_reason text, p_reason_key text)
returns integer
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_amount integer;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  v_amount := case
    when p_reason = 'daily'          then 10
    when p_reason = 'milestone:7'    then 40
    when p_reason = 'milestone:14'   then 75
    when p_reason = 'milestone:30'   then 150
    when p_reason = 'milestone:60'   then 250
    when p_reason = 'milestone:100'  then 400
    when p_reason = 'quest'          then 15
    else null end;
  if v_amount is null then raise exception 'unknown noor reason: %', p_reason; end if;

  insert into public.noor_grants(user_id, reason_key, amount)
    values (v_uid, p_reason_key, v_amount)
    on conflict (user_id, reason_key) do nothing;
  if not found then return 0; end if;

  perform set_config('app.cosmetics_rpc','on', true);
  update public.user_profiles
     set noor_balance = noor_balance + v_amount,
         noor_total_earned = noor_total_earned + v_amount
   where id = v_uid;
  return v_amount;
end $$;

revoke execute on function public.award_noor(text,text) from public, anon;
grant  execute on function public.award_noor(text,text) to authenticated;
