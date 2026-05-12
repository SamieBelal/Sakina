begin;

select plan(8);

-- Reuse the same auth.users seeding helper pattern as rpc_eligibility_test.sql.
create or replace function public.test_insert_auth_user(
  p_id uuid,
  p_email text,
  p_created_at timestamptz
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
    p_created_at,
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('full_name', split_part(p_email, '@', 1)),
    p_created_at,
    p_created_at
  );
$$;

-- Six users covering the matrix:
--   201: reminder_time '08:00', UTC, notify_daily on  → should be eligible only when local hour = 8
--   202: reminder_time '09:00', UTC, notify_daily on  → should be eligible only when local hour = 9
--   203: reminder_time null,    UTC, notify_daily on  → falls back to p_target_hour
--   204: reminder_time '',      UTC, notify_daily on  → falls back to p_target_hour (empty string)
--   205: reminder_time '08:30', UTC, notify_daily on  → eligible at local hour = 8 (half-hour floors)
--   206: reminder_time '08:00', UTC, notify_daily on, but flag=false on call → falls back to p_target_hour
select public.test_insert_auth_user(
  '00000000-0000-0000-0000-000000000201',
  'rem8@example.com',
  now() - interval '10 days'
);
select public.test_insert_auth_user(
  '00000000-0000-0000-0000-000000000202',
  'rem9@example.com',
  now() - interval '10 days'
);
select public.test_insert_auth_user(
  '00000000-0000-0000-0000-000000000203',
  'remnull@example.com',
  now() - interval '10 days'
);
select public.test_insert_auth_user(
  '00000000-0000-0000-0000-000000000204',
  'rempty@example.com',
  now() - interval '10 days'
);
select public.test_insert_auth_user(
  '00000000-0000-0000-0000-000000000205',
  'remhalf@example.com',
  now() - interval '10 days'
);
select public.test_insert_auth_user(
  '00000000-0000-0000-0000-000000000206',
  'remflag@example.com',
  now() - interval '10 days'
);

-- Reset all prefs to a known baseline.
update public.user_notification_preferences
set
  notify_daily = false,
  notify_streak = false,
  notify_reengagement = false,
  notify_weekly = false,
  notify_updates = false,
  timezone = 'UTC',
  last_daily_sent_at = null,
  last_streak_sent_at = null,
  last_reengagement_sent_at = null,
  last_weekly_sent_at = null;

update public.user_streaks
set current_streak = 0, longest_streak = 0, last_active = null;

-- Enable daily for all six users; ensure last_active is yesterday (so the
-- not-active-today filter doesn't exclude them).
update public.user_notification_preferences
set notify_daily = true
where user_id in (
  '00000000-0000-0000-0000-000000000201',
  '00000000-0000-0000-0000-000000000202',
  '00000000-0000-0000-0000-000000000203',
  '00000000-0000-0000-0000-000000000204',
  '00000000-0000-0000-0000-000000000205',
  '00000000-0000-0000-0000-000000000206'
);

update public.user_streaks
set last_active = timezone('utc', now())::date - 1
where user_id in (
  '00000000-0000-0000-0000-000000000201',
  '00000000-0000-0000-0000-000000000202',
  '00000000-0000-0000-0000-000000000203',
  '00000000-0000-0000-0000-000000000204',
  '00000000-0000-0000-0000-000000000205',
  '00000000-0000-0000-0000-000000000206'
);

-- Set the reminder_time on user_profiles for each test row.
update public.user_profiles set reminder_time = '08:00' where id = '00000000-0000-0000-0000-000000000201';
update public.user_profiles set reminder_time = '09:00' where id = '00000000-0000-0000-0000-000000000202';
update public.user_profiles set reminder_time = null    where id = '00000000-0000-0000-0000-000000000203';
update public.user_profiles set reminder_time = ''      where id = '00000000-0000-0000-0000-000000000204';
update public.user_profiles set reminder_time = '08:30' where id = '00000000-0000-0000-0000-000000000205';
update public.user_profiles set reminder_time = '08:00' where id = '00000000-0000-0000-0000-000000000206';

-- Test 1: user 201 with reminder_time '08:00' is eligible when we pass
-- p_use_user_reminder_time=true and call as-if local hour is 8 (we cannot
-- mock now(), so we set p_target_hour to a sentinel value -1 and rely on
-- the user-time branch).
--
-- Strategy: ask "would user 201 be matched if we pretend the clock is
-- whatever hour they want?" Since the RPC compares to extract(hour from
-- now() at tz) we can only assert based on the current clock. Instead,
-- we invert: simulate the cron's behavior at the user's reminder hour by
-- passing p_target_hour = extract(hour from now()). Then we test that
-- only users whose reminder_time hour matches the current local hour are
-- returned.
--
-- We bucket the six test users by reminder_time hour and assert each
-- bucket is returned exactly when its hour matches.

-- Capture the current UTC hour once for stable assertions.
do $$
declare
  cur_hour integer := extract(hour from timezone('utc', now()))::integer;
begin
  perform set_config('test.cur_hour', cur_hour::text, true);
end$$;

-- Test 1: with flag=true, a user whose reminder_time hour equals the
-- current local hour is returned.
update public.user_profiles
set reminder_time = lpad(extract(hour from timezone('utc', now()))::text, 2, '0') || ':00'
where id = '00000000-0000-0000-0000-000000000201';

select is(
  (
    select count(*)
    from public.get_eligible_notification_users(
      'notify_daily',
      'last_daily_sent_at',
      -1, -- intentional bogus target hour; user-time branch should win
      false,
      0,
      null,
      true
    )
    where user_id = '00000000-0000-0000-0000-000000000201'
  ),
  1::bigint,
  'flag=true: user is matched when reminder_time hour equals current local hour'
);

-- Test 2: with flag=true, a user whose reminder_time hour does NOT match
-- the current local hour is excluded.
update public.user_profiles
set reminder_time = lpad(((extract(hour from timezone('utc', now()))::integer + 1) % 24)::text, 2, '0') || ':00'
where id = '00000000-0000-0000-0000-000000000202';

select is(
  (
    select count(*)
    from public.get_eligible_notification_users(
      'notify_daily',
      'last_daily_sent_at',
      -1,
      false,
      0,
      null,
      true
    )
    where user_id = '00000000-0000-0000-0000-000000000202'
  ),
  0::bigint,
  'flag=true: user is excluded when reminder_time hour != current local hour'
);

-- Test 3: with flag=true, a user with reminder_time = null falls back
-- to p_target_hour. We set p_target_hour = current local hour, expect
-- match; then run with p_target_hour = current+1, expect no match.
select is(
  (
    select count(*)
    from public.get_eligible_notification_users(
      'notify_daily',
      'last_daily_sent_at',
      extract(hour from timezone('utc', now()))::integer,
      false,
      0,
      null,
      true
    )
    where user_id = '00000000-0000-0000-0000-000000000203'
  ),
  1::bigint,
  'flag=true: null reminder_time falls back to p_target_hour (match case)'
);

select is(
  (
    select count(*)
    from public.get_eligible_notification_users(
      'notify_daily',
      'last_daily_sent_at',
      ((extract(hour from timezone('utc', now()))::integer + 1) % 24),
      false,
      0,
      null,
      true
    )
    where user_id = '00000000-0000-0000-0000-000000000203'
  ),
  0::bigint,
  'flag=true: null reminder_time fallback excludes when hour differs'
);

-- Test 4: with flag=true, empty-string reminder_time falls back to
-- p_target_hour (same behavior as null via the btrim() = '' guard).
select is(
  (
    select count(*)
    from public.get_eligible_notification_users(
      'notify_daily',
      'last_daily_sent_at',
      extract(hour from timezone('utc', now()))::integer,
      false,
      0,
      null,
      true
    )
    where user_id = '00000000-0000-0000-0000-000000000204'
  ),
  1::bigint,
  'flag=true: empty-string reminder_time falls back to p_target_hour'
);

-- Test 5: with flag=true, half-hour reminder_time floors to the hour.
update public.user_profiles
set reminder_time = lpad(extract(hour from timezone('utc', now()))::text, 2, '0') || ':30'
where id = '00000000-0000-0000-0000-000000000205';

select is(
  (
    select count(*)
    from public.get_eligible_notification_users(
      'notify_daily',
      'last_daily_sent_at',
      -1,
      false,
      0,
      null,
      true
    )
    where user_id = '00000000-0000-0000-0000-000000000205'
  ),
  1::bigint,
  'flag=true: half-hour reminder_time floors to the hour (HH:30 matches at HH:00)'
);

-- Test 6 (Test 8 in the plan numbering): with flag=true, a malformed
-- reminder_time falls back to p_target_hour instead of crashing.
-- This is the regression guard for the regex gate added in the
-- migration. Without that gate, split_part('abc',':',1)::integer
-- would raise and the entire cron batch would fail.
update public.user_profiles
set reminder_time = 'abc-not-a-time'
where id = '00000000-0000-0000-0000-000000000201';

select lives_ok(
  $$
    select *
    from public.get_eligible_notification_users(
      'notify_daily',
      'last_daily_sent_at',
      extract(hour from timezone('utc', now()))::integer,
      false,
      0,
      null,
      true
    )
  $$,
  'flag=true: malformed reminder_time does not raise — falls back to p_target_hour'
);

-- Restore a sane value before continuing (other tests below assume well-formed data).
update public.user_profiles
set reminder_time = lpad(extract(hour from timezone('utc', now()))::text, 2, '0') || ':00'
where id = '00000000-0000-0000-0000-000000000201';

-- Test 7 (Test 6 in original numbering): with flag=false, reminder_time
-- is ignored — caller's p_target_hour wins. User 206 has reminder_time
-- '08:00' but we pass a different target hour to assert the legacy
-- behavior is preserved.
update public.user_profiles
set reminder_time = '08:00'
where id = '00000000-0000-0000-0000-000000000206';

select is(
  (
    select count(*)
    from public.get_eligible_notification_users(
      'notify_daily',
      'last_daily_sent_at',
      extract(hour from timezone('utc', now()))::integer,
      false,
      0,
      null,
      false -- legacy callers
    )
    where user_id = '00000000-0000-0000-0000-000000000206'
  ),
  1::bigint,
  'flag=false: legacy callers ignore reminder_time, p_target_hour wins'
);

select * from finish();

rollback;
