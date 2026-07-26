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
