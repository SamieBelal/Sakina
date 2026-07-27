-- Cosmetics hardening: unlock_cosmetic must refuse premium-exclusive and
-- out-of-window seasonal catalog rows even when they carry a Noor price, and
-- defensive CHECK constraints must reject bad economy data.
--
-- Invariants under test:
--   1. A premium-exclusive item WITH a noor_price is NOT Noor-buyable
--      (unlock_cosmetic raises 'item not Noor-purchasable or inactive').
--   2. An EXPIRED seasonal item (available_until in the past) is NOT buyable.
--   3. noor_grants.amount <= 0 is rejected by a CHECK constraint.
--
-- auth.uid() is driven the same way cosmetics_award_noor_test.sql does it:
--   set local role authenticated + request.jwt.claims with a 'sub' uuid.
-- Starting balance is seeded as the owner role with the app.cosmetics_rpc GUC
-- flipped on so the freemium-guard trigger permits the direct write.
--
-- Run via:  psql "$SUPABASE_DB_URL" -f supabase/tests/cosmetics_hardening_test.sql
-- pgTAP style (plan/is/finish), matching the project's pgtap harness.

begin;
select plan(3);

-- Premium-exclusive item WITH a price (should still be un-buyable via Noor).
insert into public.cosmetic_catalog(item_type, item_id, noor_price, is_premium_exclusive, active)
values ('lantern_skin', '_t_prem', 50, true, true)
on conflict (item_type, item_id) do update
  set noor_price = excluded.noor_price,
      is_premium_exclusive = excluded.is_premium_exclusive,
      active = excluded.active;

-- Expired seasonal item (window closed yesterday).
insert into public.cosmetic_catalog(item_type, item_id, noor_price, is_premium_exclusive, available_until, active)
values ('lantern_skin', '_t_expired', 50, false, now() - interval '1 day', true)
on conflict (item_type, item_id) do update
  set noor_price = excluded.noor_price,
      is_premium_exclusive = excluded.is_premium_exclusive,
      available_until = excluded.available_until,
      active = excluded.active;

-- Seed an auth user + profile.
insert into auth.users(id, email)
values ('00000000-0000-0000-0000-0000000000d1', 'cosmetics-harden@test.local')
on conflict do nothing;
insert into public.user_profiles(id)
values ('00000000-0000-0000-0000-0000000000d1')
on conflict do nothing;

-- Seed starting balance (100) as the owner with the guard GUC flipped on.
select set_config('app.cosmetics_rpc', 'on', true);
update public.user_profiles set noor_balance = 100
  where id = '00000000-0000-0000-0000-0000000000d1';
select set_config('app.cosmetics_rpc', 'off', true);

-- Impersonate the seeded user so auth.uid() resolves inside the RPC.
set local role authenticated;
select set_config(
  'request.jwt.claims',
  jsonb_build_object(
    'sub',  '00000000-0000-0000-0000-0000000000d1',
    'role', 'authenticated')::text,
  true);

-- (1) Premium-exclusive item cannot be Noor-purchased.
select throws_ok(
  $$ select public.unlock_cosmetic('lantern_skin', '_t_prem') $$,
  'item not Noor-purchasable or inactive',
  'unlock_cosmetic refuses a premium-exclusive item even with a price');

-- (2) Expired seasonal item cannot be Noor-purchased.
select throws_ok(
  $$ select public.unlock_cosmetic('lantern_skin', '_t_expired') $$,
  'item not Noor-purchasable or inactive',
  'unlock_cosmetic refuses an out-of-window seasonal item');

-- (3) Negative Noor grant is rejected by the CHECK constraint.
-- noor_grants has RLS with no policy, so run as owner to reach the CHECK.
reset role;
select set_config('request.jwt.claims', '', true);
select throws_ok(
  $$ insert into public.noor_grants(user_id, reason_key, amount)
     values ('00000000-0000-0000-0000-0000000000d1', '_t_neg', -5) $$,
  '23514'::char(5),
  null::text,
  'noor_grants rejects a non-positive amount via CHECK constraint');

select * from finish();
rollback;
