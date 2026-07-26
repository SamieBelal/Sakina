-- equip_cosmetic: the ownership gate must accept THREE classes of item, not one.
--
-- Before 20260726200500 the gate was `exists(user_cosmetics row)` only, which
-- rejected two legitimately-equippable classes:
--
--   a) The always-owned catalog DEFAULTS ('lantern_skin'/'classic_gold' and
--      'backdrop'/'default'). These are never rows in user_cosmetics — the
--      client treats them as owned by convention (CosmeticsState.owns) and the
--      user_profiles.equipped_* columns default to exactly these values. With
--      the old gate there was NO path back to the default lantern once a user
--      equipped anything else.
--   b) PREMIUM-EXCLUSIVE items while premium is active (e.g. 'ramadan_royal').
--      These are equippable-while-active and must NEVER be converted to
--      permanent ownership, so they are deliberately absent from user_cosmetics
--      and the old gate made the marquee premium perk entirely non-functional.
--
-- Invariants under test:
--   1. Equipping a genuinely OWNED item still works (regression).
--   2. Equipping 'classic_gold' succeeds for a user with NO user_cosmetics rows
--      and actually moves user_profiles.equipped_lantern_skin.
--   3. Equipping backdrop 'default' likewise moves equipped_backdrop.
--   4. A PREMIUM user can equip 'ramadan_royal' AND no user_cosmetics row is
--      created (the "never converts to ownership" invariant).
--   5. A NON-premium user equipping 'ramadan_royal' still raises.
--   6. A genuinely unowned, non-default, non-exclusive item still raises — the
--      gate must not become permissive.
--   7. The premium check is the UNION of PurchaseService.isPremium()'s sources,
--      not just subscriptions: a gift-premium user can equip too.
--
-- auth.uid() is driven the same way cosmetics_unlock_equip_test.sql does it:
--   set local role authenticated + request.jwt.claims with a 'sub' uuid.
--
-- Run via:  psql "$SUPABASE_DB_URL" -f supabase/tests/equip_defaults_premium_test.sql

begin;
select plan(13);

-- ---------------------------------------------------------------------------
-- Fixtures. Each auth.users insert fires handle_new_user(), which creates the
-- user_profiles row for us; the explicit inserts below are on-conflict no-ops
-- that keep the fixture readable if that trigger ever goes away.
-- ---------------------------------------------------------------------------

-- d1 — owns obsidian_gold outright (regression + "still rejects unowned").
insert into auth.users(id, email)
values ('00000000-0000-0000-0000-0000000000d1', 'equip-owner@test.local')
on conflict do nothing;
insert into public.user_profiles(id)
values ('00000000-0000-0000-0000-0000000000d1')
on conflict do nothing;

-- d2 — owns NOTHING at all (the default-restore case).
insert into auth.users(id, email)
values ('00000000-0000-0000-0000-0000000000d2', 'equip-empty@test.local')
on conflict do nothing;
insert into public.user_profiles(id)
values ('00000000-0000-0000-0000-0000000000d2')
on conflict do nothing;

-- d3 — premium via an active RevenueCat subscription row.
insert into auth.users(id, email)
values ('00000000-0000-0000-0000-0000000000d3', 'equip-premium-sub@test.local')
on conflict do nothing;
insert into public.user_profiles(id)
values ('00000000-0000-0000-0000-0000000000d3')
on conflict do nothing;

-- d4 — no premium of any kind.
insert into auth.users(id, email)
values ('00000000-0000-0000-0000-0000000000d4', 'equip-free@test.local')
on conflict do nothing;
insert into public.user_profiles(id)
values ('00000000-0000-0000-0000-0000000000d4')
on conflict do nothing;

-- d5 — premium via the GIFT column only (no subscription row at all).
insert into auth.users(id, email)
values ('00000000-0000-0000-0000-0000000000d5', 'equip-premium-gift@test.local')
on conflict do nothing;
insert into public.user_profiles(id)
values ('00000000-0000-0000-0000-0000000000d5')
on conflict do nothing;

-- d1's inventory row. Seeded directly (the RPC path is covered elsewhere).
insert into public.user_cosmetics(user_id, item_type, item_id, acquired_via)
values ('00000000-0000-0000-0000-0000000000d1', 'lantern_skin', 'obsidian_gold', 'noor')
on conflict (user_id, item_type, item_id) do nothing;

-- d3's active premium entitlement.
insert into public.user_subscriptions
  (user_id, entitlement, product_id, expires_at, last_event_type, last_event_at)
values
  ('00000000-0000-0000-0000-0000000000d3', 'premium', 'sakina.premium.monthly',
   now() + interval '30 days', 'INITIAL_PURCHASE', now())
on conflict (user_id, entitlement) do update
  set expires_at = excluded.expires_at;

-- d5's gift premium. The freemium guard exempts the 'postgres' role, so this
-- direct write is permitted here (clients must go through claim_sakina_gift).
update public.user_profiles
   set gift_premium_until = now() + interval '7 days'
 where id = '00000000-0000-0000-0000-0000000000d5';

-- Move d2 OFF the defaults so "equip the default" is a real state change and
-- not a no-op that would pass vacuously. Guard GUC flipped as the owner.
select set_config('app.cosmetics_rpc', 'on', true);
update public.user_profiles
   set equipped_lantern_skin = 'moonlit_silver',
       equipped_backdrop     = 'laylat_night'
 where id = '00000000-0000-0000-0000-0000000000d2';
select set_config('app.cosmetics_rpc', 'off', true);

-- ---------------------------------------------------------------------------
-- d1 — owned item still equips (regression), unowned still rejected.
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config(
  'request.jwt.claims',
  jsonb_build_object(
    'sub',  '00000000-0000-0000-0000-0000000000d1',
    'role', 'authenticated')::text,
  true);

-- (1)
select is(
  public.equip_cosmetic('lantern_skin', 'obsidian_gold'),
  true,
  'equip_cosmetic still returns true for a genuinely owned skin');

-- (2)
select is(
  (select equipped_lantern_skin from public.user_profiles
     where id = '00000000-0000-0000-0000-0000000000d1'),
  'obsidian_gold',
  'equipped_lantern_skin is set to the owned skin');

-- (3) A real skin the user does not own, is not the default, is not exclusive.
select throws_ok(
  $$ select public.equip_cosmetic('lantern_skin', 'crystal_star') $$,
  null::text,
  'cannot equip unowned item',
  'equip_cosmetic still rejects an unowned non-default non-exclusive skin');

-- ---------------------------------------------------------------------------
-- d2 — owns nothing; must still be able to return to BOTH slot defaults.
-- ---------------------------------------------------------------------------
reset role;
set local role authenticated;
select set_config(
  'request.jwt.claims',
  jsonb_build_object(
    'sub',  '00000000-0000-0000-0000-0000000000d2',
    'role', 'authenticated')::text,
  true);

-- (4)
select is(
  public.equip_cosmetic('lantern_skin', 'classic_gold'),
  true,
  'equip_cosmetic returns true for the default skin with no inventory rows');

-- (5)
select is(
  (select equipped_lantern_skin from public.user_profiles
     where id = '00000000-0000-0000-0000-0000000000d2'),
  'classic_gold',
  'equipped_lantern_skin actually moves back to classic_gold');

-- (6)
select is(
  public.equip_cosmetic('backdrop', 'default'),
  true,
  'equip_cosmetic returns true for the default backdrop with no inventory rows');

-- (7)
select is(
  (select equipped_backdrop from public.user_profiles
     where id = '00000000-0000-0000-0000-0000000000d2'),
  'default',
  'equipped_backdrop actually moves back to default');

-- ---------------------------------------------------------------------------
-- d3 — subscription premium equips the premium-exclusive skin, WITHOUT
-- gaining permanent ownership of it.
-- ---------------------------------------------------------------------------
reset role;
set local role authenticated;
select set_config(
  'request.jwt.claims',
  jsonb_build_object(
    'sub',  '00000000-0000-0000-0000-0000000000d3',
    'role', 'authenticated')::text,
  true);

-- (8)
select is(
  public.equip_cosmetic('lantern_skin', 'ramadan_royal'),
  true,
  'premium user can equip the premium-exclusive skin');

-- (9)
select is(
  (select equipped_lantern_skin from public.user_profiles
     where id = '00000000-0000-0000-0000-0000000000d3'),
  'ramadan_royal',
  'equipped_lantern_skin is set to the premium-exclusive skin');

-- (10) The invariant: equipping a perk must NEVER mint permanent ownership.
select is(
  (select count(*)::int from public.user_cosmetics
     where user_id = '00000000-0000-0000-0000-0000000000d3'),
  0,
  'equipping a premium-exclusive creates NO user_cosmetics row');

-- ---------------------------------------------------------------------------
-- d4 — no premium: the exclusive stays locked.
-- ---------------------------------------------------------------------------
reset role;
set local role authenticated;
select set_config(
  'request.jwt.claims',
  jsonb_build_object(
    'sub',  '00000000-0000-0000-0000-0000000000d4',
    'role', 'authenticated')::text,
  true);

-- (11)
select throws_ok(
  $$ select public.equip_cosmetic('lantern_skin', 'ramadan_royal') $$,
  null::text,
  'cannot equip unowned item',
  'non-premium user is rejected for the premium-exclusive skin');

-- ---------------------------------------------------------------------------
-- d5 — GIFT premium (no subscription row). Proves the server check is the
-- union of PurchaseService.isPremium()'s sources, not the subscription helper
-- alone; a subscription-only check would reproduce the very bug being fixed.
-- ---------------------------------------------------------------------------
reset role;
set local role authenticated;
select set_config(
  'request.jwt.claims',
  jsonb_build_object(
    'sub',  '00000000-0000-0000-0000-0000000000d5',
    'role', 'authenticated')::text,
  true);

-- (12)
select is(
  public.equip_cosmetic('lantern_skin', 'ramadan_royal'),
  true,
  'gift-premium user can equip the premium-exclusive skin (union, not sub-only)');

-- (13)
select is(
  (select count(*)::int from public.user_cosmetics
     where user_id = '00000000-0000-0000-0000-0000000000d5'),
  0,
  'gift-premium equip also creates NO user_cosmetics row');

reset role;
select set_config('request.jwt.claims', '', true);

select * from finish();
rollback;
