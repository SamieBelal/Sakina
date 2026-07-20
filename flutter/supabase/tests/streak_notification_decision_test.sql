-- streak_notification_decision_test.sql
--
-- pgtap coverage for the unified streak-notification decision model
-- (migration 20260720010000_streak_notification_decision.sql — T5 / spec §5 S1,
--  decisions D5/D6/D7/D8/D11).
--
-- Asserts the get_streak_notification_decisions(p_target_hour) selection:
--   (struct) the col + RPC exist.
--   (a) reflected this LOCAL day               -> NO decision (skip).
--   (b) east-of-UTC user reflected local-morning (last_reflected_local =
--       local today) is EXCLUDED even though last_active is yesterday-UTC.
--   (c) streak >= 1, not reflected this local day -> 'saver'.
--   (d) streak 6 (7 tomorrow)                   -> 'milestone'.
--   (e) dormant >= 2 local days                 -> 'winback'.
--   (f) last_streak_family_sent_at = today      -> skipped (no :00/:30 double-fire).
--
-- Because the RPC filters `local-hour = p_target_hour`, each user's timezone is
-- chosen so its LOCAL hour is deterministic, and each assertion calls the RPC
-- with THAT user's current local hour (derived from the wall clock at test time)
-- then filters the returned set to the user under test. This keeps the test
-- clock-independent (it never hard-codes an hour) while still exercising the
-- hour gate.
--
-- Style mirrors dua_precise_notifications_test.sql (begin / plan / … / rollback).

begin;

select plan(8);

-- ---------------------------------------------------------------------------
-- (struct) — the new column + RPC exist.
-- ---------------------------------------------------------------------------
select has_column('public', 'user_streaks', 'last_reflected_local',
  'user_streaks.last_reflected_local exists');

select has_function('public', 'get_streak_notification_decisions',
  array['integer'],
  'get_streak_notification_decisions(integer) exists');

-- ---------------------------------------------------------------------------
-- Fixtures. Six users, each in a fixed IANA timezone. We use 'UTC' for the
-- users whose LOCAL day == UTC day (a,c,d,e,f) and an east-of-UTC zone for (b).
-- ---------------------------------------------------------------------------
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at
)
values
  ('00000000-0000-0000-0000-000000000000'::uuid, '00000000-0000-0000-0000-0000000c0a01'::uuid, 'authenticated','authenticated','sn-a@test.sakina.local','',now(),'{"provider":"email"}'::jsonb,'{}'::jsonb,now(),now()),
  ('00000000-0000-0000-0000-000000000000'::uuid, '00000000-0000-0000-0000-0000000c0a02'::uuid, 'authenticated','authenticated','sn-b@test.sakina.local','',now(),'{"provider":"email"}'::jsonb,'{}'::jsonb,now(),now()),
  ('00000000-0000-0000-0000-000000000000'::uuid, '00000000-0000-0000-0000-0000000c0a03'::uuid, 'authenticated','authenticated','sn-c@test.sakina.local','',now(),'{"provider":"email"}'::jsonb,'{}'::jsonb,now(),now()),
  ('00000000-0000-0000-0000-000000000000'::uuid, '00000000-0000-0000-0000-0000000c0a04'::uuid, 'authenticated','authenticated','sn-d@test.sakina.local','',now(),'{"provider":"email"}'::jsonb,'{}'::jsonb,now(),now()),
  ('00000000-0000-0000-0000-000000000000'::uuid, '00000000-0000-0000-0000-0000000c0a05'::uuid, 'authenticated','authenticated','sn-e@test.sakina.local','',now(),'{"provider":"email"}'::jsonb,'{}'::jsonb,now(),now()),
  ('00000000-0000-0000-0000-000000000000'::uuid, '00000000-0000-0000-0000-0000000c0a06'::uuid, 'authenticated','authenticated','sn-f@test.sakina.local','',now(),'{"provider":"email"}'::jsonb,'{}'::jsonb,now(),now());

-- handle_new_user seeds prefs/streaks rows; set the fields we care about.
-- user_profiles rows exist from the trigger; leave display_name null.

-- Timezones per user.
update public.user_notification_preferences set timezone = 'UTC'          where user_id = '00000000-0000-0000-0000-0000000c0a01'::uuid;
update public.user_notification_preferences set timezone = 'Asia/Karachi' where user_id = '00000000-0000-0000-0000-0000000c0a02'::uuid; -- UTC+5
update public.user_notification_preferences set timezone = 'UTC'          where user_id = '00000000-0000-0000-0000-0000000c0a03'::uuid;
update public.user_notification_preferences set timezone = 'UTC'          where user_id = '00000000-0000-0000-0000-0000000c0a04'::uuid;
update public.user_notification_preferences set timezone = 'UTC'          where user_id = '00000000-0000-0000-0000-0000000c0a05'::uuid;
update public.user_notification_preferences set timezone = 'UTC'          where user_id = '00000000-0000-0000-0000-0000000c0a06'::uuid;

-- (a) reflected this LOCAL day (UTC): streak 5, reflected today -> skip.
update public.user_streaks
  set current_streak = 5,
      last_active = (current_timestamp at time zone 'UTC')::date,
      last_reflected_local = (current_timestamp at time zone 'UTC')::date
  where user_id = '00000000-0000-0000-0000-0000000c0a01'::uuid;

-- (b) east-of-UTC user reflected local-morning: last_reflected_local = LOCAL
--     today (Karachi), last_active is yesterday's UTC date. Must be EXCLUDED.
update public.user_streaks
  set current_streak = 5,
      last_active = ((current_timestamp at time zone 'UTC')::date - 1),
      last_reflected_local = (current_timestamp at time zone 'Asia/Karachi')::date
  where user_id = '00000000-0000-0000-0000-0000000c0a02'::uuid;

-- (c) streak >= 1, not reflected this local day -> saver. last_active yesterday
--     so it is not "dormant >= 2 days"; last_reflected_local null.
update public.user_streaks
  set current_streak = 3,
      last_active = ((current_timestamp at time zone 'UTC')::date - 1),
      last_reflected_local = null
  where user_id = '00000000-0000-0000-0000-0000000c0a03'::uuid;

-- (d) streak 6 (7 tomorrow) -> milestone. Not reflected today, not dormant.
update public.user_streaks
  set current_streak = 6,
      last_active = ((current_timestamp at time zone 'UTC')::date - 1),
      last_reflected_local = null
  where user_id = '00000000-0000-0000-0000-0000000c0a04'::uuid;

-- (e) dormant >= 2 local days -> winback. last_active 3 days ago; streak reset.
update public.user_streaks
  set current_streak = 0,
      last_active = ((current_timestamp at time zone 'UTC')::date - 3),
      last_reflected_local = null
  where user_id = '00000000-0000-0000-0000-0000000c0a05'::uuid;

-- (f) saver-eligible BUT already sent the family today -> skipped.
update public.user_streaks
  set current_streak = 4,
      last_active = ((current_timestamp at time zone 'UTC')::date - 1),
      last_reflected_local = null
  where user_id = '00000000-0000-0000-0000-0000000c0a06'::uuid;
update public.user_notification_preferences
  set last_streak_family_sent_at = (current_timestamp at time zone 'UTC')::date,
      last_streak_family_kind = 'saver'
  where user_id = '00000000-0000-0000-0000-0000000c0a06'::uuid;

-- ---------------------------------------------------------------------------
-- Assertions. Each queries the RPC at the user's OWN current local hour, then
-- filters to that user. `local_hour_for` derives the hour from the wall clock so
-- the test is clock-independent.
-- ---------------------------------------------------------------------------

-- (a) reflected today -> no decision row for user A.
select is(
  (select kind
     from public.get_streak_notification_decisions(
       extract(hour from (current_timestamp at time zone 'UTC'))::int)
    where user_id = '00000000-0000-0000-0000-0000000c0a01'::uuid),
  null,
  '(a) reflected this local day -> no decision'
);

-- (b) east-of-UTC local-morning reflection -> excluded from saver, even though
--     last_active is yesterday-UTC. Query at Karachi local hour.
select is(
  (select kind
     from public.get_streak_notification_decisions(
       extract(hour from (current_timestamp at time zone 'Asia/Karachi'))::int)
    where user_id = '00000000-0000-0000-0000-0000000c0a02'::uuid),
  null,
  '(b) east-of-UTC local-morning reflection excluded despite yesterday-UTC last_active'
);

-- (c) active streak, not reflected -> saver.
select is(
  (select kind
     from public.get_streak_notification_decisions(
       extract(hour from (current_timestamp at time zone 'UTC'))::int)
    where user_id = '00000000-0000-0000-0000-0000000c0a03'::uuid),
  'saver',
  '(c) streak>=1 not reflected -> saver'
);

-- (d) streak 6 -> milestone (7 tomorrow).
select is(
  (select kind
     from public.get_streak_notification_decisions(
       extract(hour from (current_timestamp at time zone 'UTC'))::int)
    where user_id = '00000000-0000-0000-0000-0000000c0a04'::uuid),
  'milestone',
  '(d) streak 6 -> milestone (7-day flame tomorrow)'
);

-- (e) dormant >= 2 days -> winback.
select is(
  (select kind
     from public.get_streak_notification_decisions(
       extract(hour from (current_timestamp at time zone 'UTC'))::int)
    where user_id = '00000000-0000-0000-0000-0000000c0a05'::uuid),
  'winback',
  '(e) dormant >= 2 local days -> winback'
);

-- (f) family already sent today -> skipped (kills :00/:30 double-fire).
select is(
  (select kind
     from public.get_streak_notification_decisions(
       extract(hour from (current_timestamp at time zone 'UTC'))::int)
    where user_id = '00000000-0000-0000-0000-0000000c0a06'::uuid),
  null,
  '(f) last_streak_family_sent_at = today -> skipped (no double-fire)'
);

select * from finish();

rollback;
