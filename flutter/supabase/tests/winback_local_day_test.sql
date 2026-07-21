-- winback_local_day_test.sql
--
-- Proves the UTC/local mismatch in the winback branch of
-- get_streak_notification_decisions() (migration
-- 20260720010000_streak_notification_decision.sql, line 115):
--
--   when s.last_active is not null
--        and s.last_active < s.local_today - 1 then 'winback'
--
-- `last_active` is a UTC calendar date written by Flutter's _todayString()
-- (calls DateTime.now().toUtc()).  `local_today` is
-- (current_timestamp at time zone tz)::date — the user's LOCAL day.
-- Comparing a raw UTC date against a LOCAL threshold introduces a ±1-day
-- dormancy error for east-of-UTC users.
--
-- SCENARIO — false winback for a UTC+12 (Etc/GMT-12) user:
--
--   The user reflects at 01:00 UTC+12 (local morning of local-yesterday).
--   UTC at that moment is 13:00 of the PREVIOUS calendar day.
--   Flutter writes:  last_active          = UTC date = (local_today - 2)
--                    last_reflected_local = local date = (local_today - 1)
--
--   Now it is local_today.  Dormancy in LOCAL days = 1 (reflected yesterday
--   locally).  The correct push classification is 'saver', NOT 'winback'.
--
--   Buggy check:  last_active (local_today-2) < local_today-1  ->  TRUE  -> 'winback'  WRONG
--   Fixed check:  coalesce(last_reflected_local, ...) = local_today-1
--                 -> NOT < local_today-1  -> falls through to 'saver'  CORRECT
--
-- We construct last_active deterministically as
--   (current_timestamp at time zone 'Etc/GMT-12')::date - 2
-- and last_reflected_local as
--   (current_timestamp at time zone 'Etc/GMT-12')::date - 1
-- so the scenario is fully clock-independent.
--
-- USER IDs: b01 = UTC control, b02 = UTC+12 bug victim.
-- Distinct-id prefix: 00000000-0000-0000-aaaa-

begin;

select plan(3);

-- Fixtures

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at
)
values
  -- b01: UTC timezone control -- last_active yesterday UTC -> saver (1-day UTC gap).
  ('00000000-0000-0000-0000-000000000000'::uuid,
   '00000000-0000-0000-aaaa-000000000b01'::uuid,
   'authenticated','authenticated','wb-1@test.sakina.local','',
   now(),'{"provider":"email"}'::jsonb,'{}'::jsonb,now(),now()),
  -- b02: UTC+12 user. Reflected at local morning (UTC previous day).
  --      last_active = local_today-2 (UTC date), last_reflected_local = local_today-1.
  --      Correct answer: 'saver'. Buggy answer: 'winback'.
  ('00000000-0000-0000-0000-000000000000'::uuid,
   '00000000-0000-0000-aaaa-000000000b02'::uuid,
   'authenticated','authenticated','wb-2@test.sakina.local','',
   now(),'{"provider":"email"}'::jsonb,'{}'::jsonb,now(),now());

-- Timezones.
update public.user_notification_preferences
  set timezone = 'UTC'
  where user_id = '00000000-0000-0000-aaaa-000000000b01'::uuid;

update public.user_notification_preferences
  set timezone = 'Etc/GMT-12'
  where user_id = '00000000-0000-0000-aaaa-000000000b02'::uuid;

-- b01 (UTC control): last_active yesterday UTC (1-day UTC gap). No last_reflected_local.
-- Expected: 'saver' (not dormant enough for winback).
update public.user_streaks
  set current_streak       = 3,
      last_active          = (current_timestamp at time zone 'UTC')::date - 1,
      last_reflected_local = null
  where user_id = '00000000-0000-0000-aaaa-000000000b01'::uuid;

-- b02 (UTC+12 bug case):
--   Scenario: user reflected at 01:00 UTC+12 local-yesterday (= 13:00 UTC the
--   day before local-yesterday). Flutter wrote:
--     last_active          = (local_today - 2)  [UTC date, via .toUtc()]
--     last_reflected_local = (local_today - 1)  [local date, via _todayLocalString()]
--   Dormancy in LOCAL days = 1 -> should be 'saver'.
--   Buggy: last_active (local_today-2) < local_today-1 -> TRUE -> 'winback' (wrong)
--   Fixed: coalesce(last_reflected_local, ...) = local_today-1
--          not < local_today-1 -> 'saver' (correct)
update public.user_streaks
  set current_streak       = 3,
      last_active          = (current_timestamp at time zone 'Etc/GMT-12')::date - 2,
      last_reflected_local = (current_timestamp at time zone 'Etc/GMT-12')::date - 1
  where user_id = '00000000-0000-0000-aaaa-000000000b02'::uuid;

-- Assertions

-- (w1) UTC control: yesterday UTC -> 'saver'. Unaffected by the fix.
select is(
  (select kind
     from public.get_streak_notification_decisions(
       extract(hour from (current_timestamp at time zone 'UTC'))::int)
    where user_id = '00000000-0000-0000-aaaa-000000000b01'::uuid),
  'saver',
  '(w1) UTC control: last_active yesterday UTC -> saver'
);

-- (w2) UTC+12 user: last_active is 2 UTC-days behind local_today but
-- last_reflected_local is only 1 LOCAL day behind.
-- CORRECT: 'saver'  (reflected yesterday locally - not dormant enough for winback).
-- BUGGY:   'winback' (UTC date comparison says 2 days dormant).
select is(
  (select kind
     from public.get_streak_notification_decisions(
       extract(hour from (current_timestamp at time zone 'Etc/GMT-12'))::int)
    where user_id = '00000000-0000-0000-aaaa-000000000b02'::uuid),
  'saver',
  '(w2) UTC+12 user: last_reflected_local=yesterday-local, last_active=2-UTC-days-ago -> saver, NOT winback'
);

-- (w3) Sanity: confirm the seeded gaps for b02:
--   UTC gap  = local_today - last_active          = 2  (triggers bug)
--   LOCAL gap = local_today - last_reflected_local = 1  (correct: saver)
select ok(
  (select
       (current_timestamp at time zone 'Etc/GMT-12')::date
         - s.last_active = 2
     and
       (current_timestamp at time zone 'Etc/GMT-12')::date
         - s.last_reflected_local = 1
   from public.user_streaks s
   where s.user_id = '00000000-0000-0000-aaaa-000000000b02'::uuid),
  '(w3) sanity: b02 last_active is 2 UTC-days behind local_today; last_reflected_local is 1 LOCAL day behind'
);

select * from finish();

rollback;
