-- winback_cooldown_test.sql
--
-- Verifies the 7-day winback cooldown in get_streak_notification_decisions():
-- a dormant user who received a winback push within the last 6 local days
-- must NOT be classified as 'winback' again until 7+ local days have elapsed.
--
-- SCENARIOS:
--   (c1) Cooldown ACTIVE: last winback was 3 local days ago -> NOT winback.
--   (c2) Cooldown ELAPSED: last winback was 8 local days ago -> winback-eligible.
--   (c3) Never sent winback (kind=null) -> winback-eligible.
--
-- User IDs use prefix 00000000-0000-0000-cccc- to avoid collision with other tests.
-- All users are UTC for simplicity; all are set to be dormant (>= 2 local days).
-- Style mirrors streak_notification_decision_test.sql.

begin;

select plan(3);

-- ---------------------------------------------------------------------------
-- Fixtures: three dormant users
-- ---------------------------------------------------------------------------

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at
)
values
  -- c1: cooldown active (last winback 3 days ago)
  ('00000000-0000-0000-0000-000000000000'::uuid,
   '00000000-0000-0000-cccc-000000000c01'::uuid,
   'authenticated','authenticated','wc-1@test.sakina.local','',
   now(),'{"provider":"email"}'::jsonb,'{}'::jsonb,now(),now()),
  -- c2: cooldown elapsed (last winback 8 days ago)
  ('00000000-0000-0000-0000-000000000000'::uuid,
   '00000000-0000-0000-cccc-000000000c02'::uuid,
   'authenticated','authenticated','wc-2@test.sakina.local','',
   now(),'{"provider":"email"}'::jsonb,'{}'::jsonb,now(),now()),
  -- c3: never had a winback sent
  ('00000000-0000-0000-0000-000000000000'::uuid,
   '00000000-0000-0000-cccc-000000000c03'::uuid,
   'authenticated','authenticated','wc-3@test.sakina.local','',
   now(),'{"provider":"email"}'::jsonb,'{}'::jsonb,now(),now());

-- All UTC.
update public.user_notification_preferences
  set timezone = 'UTC'
  where user_id in (
    '00000000-0000-0000-cccc-000000000c01'::uuid,
    '00000000-0000-0000-cccc-000000000c02'::uuid,
    '00000000-0000-0000-cccc-000000000c03'::uuid
  );

-- All dormant: last reflected 5 local days ago, streak reset to 0.
update public.user_streaks
  set current_streak       = 0,
      last_active          = (current_timestamp at time zone 'UTC')::date - 5,
      last_reflected_local = (current_timestamp at time zone 'UTC')::date - 5
  where user_id in (
    '00000000-0000-0000-cccc-000000000c01'::uuid,
    '00000000-0000-0000-cccc-000000000c02'::uuid,
    '00000000-0000-0000-cccc-000000000c03'::uuid
  );

-- c1: last winback 3 local days ago (cooldown active, within 7-day window).
update public.user_notification_preferences
  set last_streak_family_kind    = 'winback',
      last_streak_family_sent_at = (current_timestamp at time zone 'UTC')::date - 3
  where user_id = '00000000-0000-0000-cccc-000000000c01'::uuid;

-- c2: last winback 8 local days ago (cooldown elapsed, >= 7 days).
update public.user_notification_preferences
  set last_streak_family_kind    = 'winback',
      last_streak_family_sent_at = (current_timestamp at time zone 'UTC')::date - 8
  where user_id = '00000000-0000-0000-cccc-000000000c02'::uuid;

-- c3: never sent (kind null, sent_at null — default from trigger).

-- ---------------------------------------------------------------------------
-- Assertions
-- ---------------------------------------------------------------------------

-- (c1) Cooldown active: winback sent 3 days ago -> NOT returned as winback.
select is(
  (select kind
     from public.get_streak_notification_decisions(
       extract(hour from (current_timestamp at time zone 'UTC'))::int)
    where user_id = '00000000-0000-0000-cccc-000000000c01'::uuid),
  null,
  '(c1) cooldown active (winback 3 days ago) -> suppressed, not returned'
);

-- (c2) Cooldown elapsed: winback sent 8 days ago -> IS returned as winback.
select is(
  (select kind
     from public.get_streak_notification_decisions(
       extract(hour from (current_timestamp at time zone 'UTC'))::int)
    where user_id = '00000000-0000-0000-cccc-000000000c02'::uuid),
  'winback',
  '(c2) cooldown elapsed (winback 8 days ago) -> winback-eligible again'
);

-- (c3) Never sent winback -> IS returned as winback.
select is(
  (select kind
     from public.get_streak_notification_decisions(
       extract(hour from (current_timestamp at time zone 'UTC'))::int)
    where user_id = '00000000-0000-0000-cccc-000000000c03'::uuid),
  'winback',
  '(c3) no prior winback (kind null) -> winback-eligible'
);

select * from finish();

rollback;
