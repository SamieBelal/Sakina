begin;

select plan(11);

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

select public.test_insert_auth_user(
  '00000000-0000-0000-0000-000000000101',
  'daily@example.com',
  now() - interval '10 days'
);
select public.test_insert_auth_user(
  '00000000-0000-0000-0000-000000000102',
  'streak@example.com',
  now() - interval '10 days'
);
select public.test_insert_auth_user(
  '00000000-0000-0000-0000-000000000103',
  'reengage@example.com',
  now() - interval '10 days'
);
select public.test_insert_auth_user(
  '00000000-0000-0000-0000-000000000104',
  'recent@example.com',
  now() - interval '10 days'
);
select public.test_insert_auth_user(
  '00000000-0000-0000-0000-000000000105',
  'expired@example.com',
  now() - interval '10 days'
);
select public.test_insert_auth_user(
  '00000000-0000-0000-0000-000000000106',
  'bootstrap@example.com',
  now() - interval '4 days'
);
select public.test_insert_auth_user(
  '00000000-0000-0000-0000-000000000107',
  'weekly@example.com',
  now() - interval '10 days'
);
select public.test_insert_auth_user(
  '00000000-0000-0000-0000-000000000108',
  'weeklywrong@example.com',
  now() - interval '10 days'
);
select public.test_insert_auth_user(
  '00000000-0000-0000-0000-000000000109',
  'weeklynull@example.com',
  now() - interval '10 days'
);
select public.test_insert_auth_user(
  '00000000-0000-0000-0000-000000000110',
  'active-today@example.com',
  now() - interval '10 days'
);

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

update public.user_notification_preferences
set notify_daily = true
where user_id = '00000000-0000-0000-0000-000000000101';

update public.user_streaks
set last_active = timezone('utc', now())::date - 1
where user_id = '00000000-0000-0000-0000-000000000101';

update public.user_notification_preferences
set notify_streak = true
where user_id = '00000000-0000-0000-0000-000000000102';

update public.user_streaks
set current_streak = 5, longest_streak = 5, last_active = timezone('utc', now())::date - 1
where user_id = '00000000-0000-0000-0000-000000000102';

update public.user_notification_preferences
set notify_reengagement = true
where user_id in (
  '00000000-0000-0000-0000-000000000103',
  '00000000-0000-0000-0000-000000000104',
  '00000000-0000-0000-0000-000000000105',
  '00000000-0000-0000-0000-000000000106'
);

update public.user_streaks
set last_active = timezone('utc', now())::date - 4
where user_id in (
  '00000000-0000-0000-0000-000000000103',
  '00000000-0000-0000-0000-000000000104',
  '00000000-0000-0000-0000-000000000105'
);

update public.user_notification_preferences
set last_reengagement_sent_at = now() - interval '3 days'
where user_id = '00000000-0000-0000-0000-000000000104';

update public.user_notification_preferences
set last_reengagement_sent_at = now() - interval '8 days'
where user_id = '00000000-0000-0000-0000-000000000105';

update public.user_notification_preferences
set notify_weekly = true
where user_id in (
  '00000000-0000-0000-0000-000000000107',
  '00000000-0000-0000-0000-000000000108',
  '00000000-0000-0000-0000-000000000109'
);

-- User 110: active today with notify_daily = true → should be EXCLUDED from daily
update public.user_notification_preferences
set notify_daily = true
where user_id = '00000000-0000-0000-0000-000000000110';

update public.user_streaks
set last_active = timezone('utc', now())::date
where user_id = '00000000-0000-0000-0000-000000000110';

select is(
  (
    select count(*)
    from public.get_eligible_notification_users(
      'notify_daily',
      'last_daily_sent_at',
      extract(hour from timezone('utc', now()))::integer,
      false,
      0,
      null
    )
    where user_id = '00000000-0000-0000-0000-000000000101'
  ),
  1::bigint,
  'daily reminder returns the active daily-enabled user'
);

select is(
  (
    select count(*)
    from public.get_eligible_notification_users(
      'notify_streak',
      'last_streak_sent_at',
      extract(hour from timezone('utc', now()))::integer,
      true,
      0,
      null
    )
    where user_id = '00000000-0000-0000-0000-000000000102'
  ),
  1::bigint,
  'streak reminder returns the at-risk streak user'
);

select is(
  (
    select count(*)
    from public.get_eligible_notification_users(
      'notify_reengagement',
      'last_reengagement_sent_at',
      extract(hour from timezone('utc', now()))::integer,
      false,
      3,
      null
    )
    where user_id = '00000000-0000-0000-0000-000000000103'
  ),
  1::bigint,
  're-engagement returns an inactive user with no prior send'
);

select is(
  (
    select count(*)
    from public.get_eligible_notification_users(
      'notify_reengagement',
      'last_reengagement_sent_at',
      extract(hour from timezone('utc', now()))::integer,
      false,
      3,
      null
    )
    where user_id = '00000000-0000-0000-0000-000000000104'
  ),
  0::bigint,
  're-engagement excludes users still inside the 7-day dedup window'
);

select is(
  (
    select count(*)
    from public.get_eligible_notification_users(
      'notify_reengagement',
      'last_reengagement_sent_at',
      extract(hour from timezone('utc', now()))::integer,
      false,
      3,
      null
    )
    where user_id = '00000000-0000-0000-0000-000000000105'
  ),
  1::bigint,
  're-engagement returns users once the dedup window expires'
);

select is(
  (
    select count(*)
    from public.get_eligible_notification_users(
      'notify_reengagement',
      'last_reengagement_sent_at',
      extract(hour from timezone('utc', now()))::integer,
      false,
      3,
      null
    )
    where user_id = '00000000-0000-0000-0000-000000000106'
  ),
  1::bigint,
  're-engagement falls back to auth.users.created_at when last_active is null'
);

select is(
  (
    select count(*)
    from public.get_eligible_notification_users(
      'notify_weekly',
      'last_weekly_sent_at',
      extract(hour from timezone('utc', now()))::integer,
      false,
      0,
      extract(dow from timezone('utc', now()))::integer
    )
    where user_id = '00000000-0000-0000-0000-000000000107'
  ),
  1::bigint,
  'weekly reflection returns users when the local day matches'
);

select is(
  (
    select count(*)
    from public.get_eligible_notification_users(
      'notify_weekly',
      'last_weekly_sent_at',
      extract(hour from timezone('utc', now()))::integer,
      false,
      0,
      ((extract(dow from timezone('utc', now()))::integer + 1) % 7)
    )
    where user_id = '00000000-0000-0000-0000-000000000108'
  ),
  0::bigint,
  'weekly reflection excludes users when the local day does not match'
);

select throws_ok(
  $$
    select *
    from public.get_eligible_notification_users(
      'DROP TABLE users',
      'last_daily_sent_at',
      0,
      false,
      0,
      null
    )
  $$,
  'Unsupported preference column: DROP TABLE users',
  'invalid preference columns are rejected'
);

select is(
  (
    select count(*)
    from public.get_eligible_notification_users(
      'notify_weekly',
      'last_weekly_sent_at',
      extract(hour from timezone('utc', now()))::integer,
      false,
      -1,
      null
    )
    where user_id = '00000000-0000-0000-0000-000000000109'
  ),
  1::bigint,
  'weekly with inactive_days=-1 skips the activity filter'
);

select is(
  (
    select count(*)
    from public.get_eligible_notification_users(
      'notify_daily',
      'last_daily_sent_at',
      extract(hour from timezone('utc', now()))::integer,
      false,
      0,
      null
    )
    where user_id = '00000000-0000-0000-0000-000000000110'
  ),
  0::bigint,
  'daily reminder excludes users who already checked in today'
);

select * from finish();
rollback;
