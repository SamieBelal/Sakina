begin;

select plan(14);

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
create or replace function public.test_insert_auth_user_gifts(
  p_id uuid,
  p_email text
)
returns void
language sql
as $$
  insert into auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
  )
  values (
    '00000000-0000-0000-0000-000000000000'::uuid,
    p_id,
    'authenticated',
    'authenticated',
    p_email,
    '',
    now() - interval '10 days',
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('full_name', split_part(p_email, '@', 1)),
    now() - interval '10 days',
    now() - interval '10 days'
  );
$$;

select public.test_insert_auth_user_gifts(
  '00000000-0000-0000-0000-000000000201',
  'gift-a@example.com'
);
select public.test_insert_auth_user_gifts(
  '00000000-0000-0000-0000-000000000202',
  'gift-b@example.com'
);

-- Test occasions: one currently active (now ± 1 day), one strictly past.
insert into public.islamic_occasions(id, display_name, starts_at, ends_at)
values
  ('test_active', 'Active Test Occasion', now() - interval '1 day', now() + interval '1 day'),
  ('test_past',   'Past Test Occasion',   now() - interval '30 days', now() - interval '20 days');

-- ---------------------------------------------------------------------------
-- 1. In-window first call grants + writes sakina_gifts + writes user_profiles
-- ---------------------------------------------------------------------------
set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000201';

select is(
  (public.claim_sakina_gift(
    '00000000-0000-0000-0000-000000000201'::uuid,
    'test_active'
  ))->>'granted',
  'true',
  'in-window first claim returns granted=true'
);

select is(
  (public.claim_sakina_gift(
    '00000000-0000-0000-0000-000000000201'::uuid,
    'test_active'
  ))->>'reused',
  'true',
  're-call in same window returns reused=true (idempotent)'
);

-- Row written
select ok(
  exists(
    select 1 from public.sakina_gifts
     where user_id = '00000000-0000-0000-0000-000000000201'::uuid
       and occasion_id = 'test_active'
  ),
  'sakina_gifts row exists for user A'
);

-- expiry ~7 days from now
select ok(
  (select expires_at from public.sakina_gifts
    where user_id = '00000000-0000-0000-0000-000000000201'::uuid
      and occasion_id = 'test_active')
    between now() + interval '6 days 23 hours' and now() + interval '7 days 1 hour',
  'expires_at is ~now()+7d'
);

-- user_profiles.gift_premium_until mirrors the expiry
select ok(
  (select gift_premium_until from public.user_profiles
    where id = '00000000-0000-0000-0000-000000000201'::uuid) is not null,
  'user_profiles.gift_premium_until written'
);

-- ---------------------------------------------------------------------------
-- 2. Idempotency: granted_at + expires_at unchanged on re-claim
-- ---------------------------------------------------------------------------
-- Snapshot the existing row's timestamps, re-call the RPC, then assert the
-- row's timestamps did NOT shift. Previously this block used unreferenced
-- CTEs that Postgres optimized away, so the re-call never fired and only
-- the row count was asserted (already implied by the PK). Now we stash the
-- pre-call snapshot in a temp table, run the recall as its own statement
-- (so its side effects definitely materialize), and compare in-place.
create temporary table _gift_test_snapshot on commit drop as
select granted_at, expires_at
  from public.sakina_gifts
 where user_id = '00000000-0000-0000-0000-000000000201'::uuid
   and occasion_id = 'test_active';

select public.claim_sakina_gift(
  '00000000-0000-0000-0000-000000000201'::uuid,
  'test_active'
);

select is(
  (select count(*) from public.sakina_gifts
    where user_id = '00000000-0000-0000-0000-000000000201'::uuid
      and occasion_id = 'test_active')::int,
  1,
  'idempotent — no duplicate row inserted'
);

select ok(
  (select s.granted_at = g.granted_at and s.expires_at = g.expires_at
     from _gift_test_snapshot s
     join public.sakina_gifts g
       on g.user_id = '00000000-0000-0000-0000-000000000201'::uuid
      and g.occasion_id = 'test_active'),
  'idempotent — granted_at + expires_at unchanged on re-call'
);

-- ---------------------------------------------------------------------------
-- 3. Outside-window past occasion returns outside_window
-- ---------------------------------------------------------------------------
select is(
  (public.claim_sakina_gift(
    '00000000-0000-0000-0000-000000000201'::uuid,
    'test_past'
  ))->>'reason',
  'outside_window',
  'past occasion returns outside_window'
);

select ok(
  not exists(
    select 1 from public.sakina_gifts
     where user_id = '00000000-0000-0000-0000-000000000201'::uuid
       and occasion_id = 'test_past'
  ),
  'no row written for past occasion'
);

-- ---------------------------------------------------------------------------
-- 4. Unknown occasion id returns unknown_occasion
-- ---------------------------------------------------------------------------
select is(
  (public.claim_sakina_gift(
    '00000000-0000-0000-0000-000000000201'::uuid,
    'does_not_exist'
  ))->>'reason',
  'unknown_occasion',
  'unknown occasion id returns unknown_occasion'
);

-- ---------------------------------------------------------------------------
-- 5. auth.uid() mismatch returns unauthorized
-- ---------------------------------------------------------------------------
-- Still authenticated as user A; pass p_user = user B.
select is(
  (public.claim_sakina_gift(
    '00000000-0000-0000-0000-000000000202'::uuid,
    'test_active'
  ))->>'reason',
  'unauthorized',
  'auth.uid() != p_user returns unauthorized'
);

select ok(
  not exists(
    select 1 from public.sakina_gifts
     where user_id = '00000000-0000-0000-0000-000000000202'::uuid
  ),
  'unauthorized attempt did not stamp user B row'
);

-- ---------------------------------------------------------------------------
-- 6. greatest() coalesce keeps the longer window
-- ---------------------------------------------------------------------------
-- Pre-set a far-future gift_premium_until on user A and re-run claim — the
-- column must NOT regress to the new (closer) expiry.
update public.user_profiles
   set gift_premium_until = now() + interval '90 days'
 where id = '00000000-0000-0000-0000-000000000201'::uuid;

-- Insert a fresh active occasion so we can re-trigger the update path.
insert into public.islamic_occasions(id, display_name, starts_at, ends_at)
values ('test_active_2', 'Active 2', now() - interval '1 day', now() + interval '1 day');

select public.claim_sakina_gift(
  '00000000-0000-0000-0000-000000000201'::uuid,
  'test_active_2'
);

select ok(
  (select gift_premium_until from public.user_profiles
    where id = '00000000-0000-0000-0000-000000000201'::uuid)
    > now() + interval '89 days',
  'greatest() preserves the longer pre-existing window'
);

-- ---------------------------------------------------------------------------
-- 7. RLS: user B cannot SELECT user A's sakina_gifts row
-- ---------------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000202';

select is(
  (select count(*) from public.sakina_gifts
    where user_id = '00000000-0000-0000-0000-000000000201'::uuid)::int,
  0,
  'user B sees 0 rows of user A under RLS'
);

reset role;

select * from finish();
rollback;
