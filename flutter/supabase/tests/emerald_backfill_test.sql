-- Regression test for:
--   * 20260720120000_add_emerald_card_tier.sql
--   * 20260720120100_backfill_emerald_cards_rpc.sql
--
-- Verifies the Emerald premium-backing backfill RPC end-to-end:
--   * A PREMIUM user (active 'premium' user_subscriptions row, webhook-only)
--     who owns gold + bronze + silver cards: backfill_emerald_cards()
--     promotes ONLY the gold rows to 'emerald', leaves bronze/silver
--     untouched, and returns exactly the promoted name_ids.
--   * IDEMPOTENCY: a second call returns zero rows and changes nothing.
--   * A FREE user (no subscription, no *_premium_until grant) with gold rows:
--     backfill_emerald_cards() returns zero rows and promotes nothing (the
--     server-side premium check short-circuits — the client boolean is never
--     trusted).
--
-- Harness mirrors referrals_test.sql / activate_trial_test.sql:
--   * one transaction, rollback at end;
--   * self-seed auth.users as superuser (test_insert_auth_user);
--   * seed the webhook-only user_subscriptions row as superuser (RLS on that
--     table only allows own-user SELECT, and premium is judged server-side by
--     has_active_premium_entitlement — there is no client write path);
--   * impersonate the authenticated session via request.jwt.claim.sub +
--     `set local role authenticated` before each RPC call, exactly as the
--     app calls it.
--
-- Run via: psql "$DATABASE_URL" -f supabase/tests/emerald_backfill_test.sql

begin;

create extension if not exists pgtap;

-- Superuser helper: seed an auth.users row (mirrors referrals_test.sql).
create or replace function pg_temp.test_insert_auth_user(
  p_id uuid,
  p_email text
) returns void
language sql
as $$
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at
  )
  values (
    '00000000-0000-0000-0000-000000000000'::uuid,
    p_id, 'authenticated', 'authenticated', p_email, '',
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('full_name', split_part(p_email, '@', 1)),
    now(), now()
  );
$$;

select plan(8);

-- Two users: premium (webhook entitlement) and free (no premium at all).
select pg_temp.test_insert_auth_user(
  '00000000-0000-0000-0000-000000006201', 'p-emerald@test.sakina.local');
select pg_temp.test_insert_auth_user(
  '00000000-0000-0000-0000-000000006202', 'f-emerald@test.sakina.local');

-- Seed the PREMIUM user's active webhook entitlement AS SUPERUSER. This is the
-- only server-side truth backfill_emerald_cards trusts for RC-paid premium.
insert into public.user_subscriptions (
  user_id, entitlement, product_id, expires_at, last_event_type, last_event_at
) values (
  '00000000-0000-0000-0000-000000006201', 'premium', 'sakina_premium_annual',
  now() + interval '30 days', 'INITIAL_PURCHASE', now()
);

-- Premium user's cards: 3 gold (should promote), 1 bronze + 1 silver (controls).
insert into public.user_card_collection (user_id, name_id, tier) values
  ('00000000-0000-0000-0000-000000006201', 10, 'gold'),
  ('00000000-0000-0000-0000-000000006201', 11, 'gold'),
  ('00000000-0000-0000-0000-000000006201', 12, 'gold'),
  ('00000000-0000-0000-0000-000000006201', 20, 'bronze'),
  ('00000000-0000-0000-0000-000000006201', 21, 'silver');

-- Free user's cards: 2 gold (must NOT promote — no premium).
insert into public.user_card_collection (user_id, name_id, tier) values
  ('00000000-0000-0000-0000-000000006202', 30, 'gold'),
  ('00000000-0000-0000-0000-000000006202', 31, 'gold');

-- ===========================================================================
-- 1. PREMIUM user: backfill promotes ONLY gold, returns exactly the gold ids.
-- ===========================================================================
set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000006201',
                    'role', 'authenticated')::text, true);

select results_eq(
  'select public.backfill_emerald_cards() order by 1',
  'values (10),(11),(12)',
  '1.1 premium: backfill returns exactly the promoted gold name_ids');

reset role;
select set_config('request.jwt.claims', '', true);

select is(
  (select count(*)::int from public.user_card_collection
     where user_id = '00000000-0000-0000-0000-000000006201'
       and tier = 'emerald'),
  3,
  '1.2 premium: all three gold rows are now emerald');

select is(
  (select tier::text from public.user_card_collection
     where user_id = '00000000-0000-0000-0000-000000006201' and name_id = 20),
  'bronze',
  '1.3 premium: bronze control row is untouched');

select is(
  (select tier::text from public.user_card_collection
     where user_id = '00000000-0000-0000-0000-000000006201' and name_id = 21),
  'silver',
  '1.4 premium: silver control row is untouched');

-- ===========================================================================
-- 2. IDEMPOTENCY: a second call returns zero rows and changes nothing.
-- ===========================================================================
set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000006201',
                    'role', 'authenticated')::text, true);

select is(
  (select count(*)::int from public.backfill_emerald_cards()),
  0,
  '2.1 idempotent: second call promotes nothing (no gold rows remain)');

reset role;
select set_config('request.jwt.claims', '', true);

select is(
  (select count(*)::int from public.user_card_collection
     where user_id = '00000000-0000-0000-0000-000000006201'
       and tier = 'emerald'),
  3,
  '2.2 idempotent: emerald count unchanged after second call');

-- ===========================================================================
-- 3. FREE user: no subscription, no *_premium_until grant → no-op.
-- ===========================================================================
set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000006202',
                    'role', 'authenticated')::text, true);

select is(
  (select count(*)::int from public.backfill_emerald_cards()),
  0,
  '3.1 free: backfill returns zero rows (server-side premium check fails)');

reset role;
select set_config('request.jwt.claims', '', true);

select is(
  (select count(*)::int from public.user_card_collection
     where user_id = '00000000-0000-0000-0000-000000006202'
       and tier = 'gold'),
  2,
  '3.2 free: both gold rows remain gold (nothing promoted)');

select * from finish();

rollback;
