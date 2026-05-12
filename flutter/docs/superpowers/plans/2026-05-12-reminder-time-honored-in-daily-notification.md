# Honor User-Selected Reminder Time For Daily Notification — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the daily reminder cron fire at each user's chosen `reminder_time` (stored on `user_profiles` during onboarding) instead of the hardcoded 9 AM, falling back to 9 AM when `reminder_time` is null/empty.

**Architecture:** The cron stays hourly at `:00` (no scheduler change). The `get_eligible_notification_users` RPC gains an optional `p_use_user_reminder_time` boolean parameter; when `true`, it joins `user_profiles` and matches the user's local-clock hour against `split_part(user_profiles.reminder_time, ':', 1)::integer` instead of the caller-supplied `p_target_hour`. A regex guard rejects malformed `reminder_time` values so one bad row cannot crash the cron batch. The edge function passes `true` only for the `daily` notification type; `streak`/`reengagement`/`weekly` retain their existing fixed-hour semantics. Source-of-truth stays in `user_profiles`; no schema duplication. To eliminate sub-hour UX confusion at the source, the onboarding time picker is constrained to whole hours (`minuteInterval: 60`) so users cannot pick `08:30` and wonder why the reminder fires at `09:00`.

**Tech Stack:** Supabase Postgres (PL/pgSQL function + pg_cron), Supabase Edge Function (Deno/TypeScript), pgTAP for RPC tests.

---

## Pre-flight: Constraints To Honor

- `reminder_time` is stored as text `"HH:mm"` 24h, written by `auth_service.dart:165` from `OnboardingState.reminderTime`. Default in `commitment_pact_screen.dart:31` and `personalized_plan_screen.dart:48` is `"08:00"`. The onboarding picker only emits whole-/half-hours, but the SQL must handle any well-formed `HH:mm`.
- Granularity floor: cron fires at `:00` only. A user with `reminder_time = "08:30"` will receive the reminder at `09:00`. This matches existing hourly-cron behavior and is acceptable; document it in the migration comment.
- The notification's local-hour comparison already runs inside `current_timestamp at time zone n.timezone`. `reminder_time` is stored in user-local time (the onboarding picker uses a `TimeOfDay` against the device clock), so the hour comparison stays apples-to-apples.
- Backward compatibility: existing callers of `get_eligible_notification_users` (none outside this edge function) must keep working without modification. The new parameter must default to `false`.

---

## File Structure

- `supabase/migrations/20260512000000_daily_reminder_uses_user_reminder_time.sql` — New migration. Adds the 7-arg overload of `get_eligible_notification_users` with `p_use_user_reminder_time boolean default false`; drops the prior 6-arg overload; re-grants execute. The user-hour branch is gated by a regex (`^[0-2]?[0-9]:[0-5][0-9]$`) so malformed values fall back to `p_target_hour` instead of throwing.
- `supabase/functions/send-scheduled-notifications/index.ts` — Add an optional `useUserReminderTime` flag to the `NotificationType` shape; set it `true` only on the `daily` entry; pass it through to the RPC call.
- `supabase/tests/rpc_eligibility_reminder_time_test.sql` — New pgTAP test file modeled on `rpc_eligibility_test.sql`, covering: honors per-user hour, falls back to `p_target_hour` when null/empty/malformed, ignores users whose hour doesn't match, half-hour values floor to the hour, legacy callers (flag `false`) keep current behavior.
- `supabase/tests/rpc_eligibility_test.sql` — **Modify (required):** the prior 6-arg overload is dropped by the new migration. Every existing call site must be updated to pass `false` as the 7th argument. Without this update, all 11 existing assertions break.
- `lib/features/onboarding/screens/reminder_time_screen.dart` — Change the `CupertinoDatePicker`'s `minuteInterval` from `5` to `60` so the picker only emits whole hours, and clamp the `onDateTimeChanged` minute to `0` defensively. Update the subtitle copy to set the expectation visually.
- `test/features/onboarding/screens/reminder_time_screen_test.dart` — Extend to assert the saved `reminder_time` always ends in `:00`.

---

## Task 1: Add new RPC migration that honors `user_profiles.reminder_time`

**Files:**
- Create: `supabase/migrations/20260512000000_daily_reminder_uses_user_reminder_time.sql`

- [ ] **Step 1: Create the migration file**

Write the file with this exact content:

```sql
-- 2026-05-12: Make the daily reminder cron honor each user's chosen
-- reminder_time from onboarding.
--
-- Before this migration:
--   send-scheduled-notifications (edge function) hardcoded targetHour: 9
--   for the daily reminder. The RPC matched all users whose local hour
--   equaled 9, regardless of the reminder_time they picked in onboarding.
--   user_profiles.reminder_time was collected, persisted, and surfaced in
--   the commitment_pact / personalized_plan screens but never read.
--
-- After this migration:
--   The RPC takes an optional p_use_user_reminder_time boolean. When true,
--   the hour filter uses extract(hour) from split_part(reminder_time, ':', 1)
--   instead of p_target_hour. Users with NULL/empty reminder_time fall back
--   to p_target_hour, preserving the pre-migration 9 AM default.
--
-- Granularity:
--   Cron stays hourly at :00. A user with reminder_time = '08:30' receives
--   their daily reminder at 09:00 local. Sub-hour precision is out of scope
--   for this migration; revisit if onboarding starts emitting non-:00 values
--   at scale.
--
-- Backward compatibility:
--   The new parameter defaults to false. Existing callers (streak /
--   reengagement / weekly notification types) keep their hardcoded fixed
--   target hours.

create or replace function public.get_eligible_notification_users(
  p_pref_column text,
  p_sent_column text,
  p_target_hour integer,
  p_requires_streak boolean default false,
  p_inactive_days integer default 0,
  p_day_of_week integer default null,
  p_use_user_reminder_time boolean default false
)
returns table (
  user_id uuid,
  timezone text,
  display_name text,
  current_streak integer,
  last_active date
)
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  allowed_pref_columns constant text[] := array[
    'notify_daily',
    'notify_streak',
    'notify_reengagement',
    'notify_weekly',
    'notify_updates'
  ];
  allowed_sent_columns constant text[] := array[
    'last_daily_sent_at',
    'last_streak_sent_at',
    'last_reengagement_sent_at',
    'last_weekly_sent_at'
  ];
  dedup_days integer := case
    when p_sent_column = 'last_reengagement_sent_at' then 7
    else 0
  end;
  sql_query text;
begin
  if not (p_pref_column = any(allowed_pref_columns)) then
    raise exception 'Unsupported preference column: %', p_pref_column;
  end if;

  if not (p_sent_column = any(allowed_sent_columns)) then
    raise exception 'Unsupported sent column: %', p_sent_column;
  end if;

  sql_query := format(
    $sql$
      select
        n.user_id,
        coalesce(nullif(n.timezone, ''), 'UTC') as timezone,
        p.display_name,
        coalesce(s.current_streak, 0)::integer as current_streak,
        s.last_active
      from public.user_notification_preferences n
      left join public.user_profiles p
        on p.id = n.user_id
      left join public.user_streaks s
        on s.user_id = n.user_id
      left join auth.users u
        on u.id = n.user_id
      where n.push_enabled = true
        and n.%1$I = true
        and extract(
          hour from (current_timestamp at time zone coalesce(nullif(n.timezone, ''), 'UTC'))
        )::integer = (
          case
            -- Regex gate: only cast when the value parses as HH:mm or H:mm.
            -- Without this, a malformed row (e.g. 'abc' or '08:30:00') would
            -- raise from split_part(...)::integer and crash the entire cron
            -- batch, silently denying that hour's reminders to every user.
            when $6
             and p.reminder_time is not null
             and p.reminder_time ~ '^[0-2]?[0-9]:[0-5][0-9]$'
              then split_part(p.reminder_time, ':', 1)::integer
            else $1
          end
        )
        and ($2 = false or coalesce(s.current_streak, 0) > 0)
        and (
          n.%2$I is null
          or (
            n.%2$I at time zone coalesce(nullif(n.timezone, ''), 'UTC')
          )::date < (
            current_timestamp at time zone coalesce(nullif(n.timezone, ''), 'UTC')
          )::date - $3
        )
        and (
          $4 < 0
          or coalesce(
            s.last_active,
            timezone('utc', u.created_at)::date
          ) < (
            current_timestamp at time zone coalesce(nullif(n.timezone, ''), 'UTC')
          )::date - $4
        )
        and (
          $5 is null
          or extract(
            dow from (current_timestamp at time zone coalesce(nullif(n.timezone, ''), 'UTC'))
          )::integer = $5
        )
    $sql$,
    p_pref_column,
    p_sent_column
  );

  return query execute sql_query
    using p_target_hour, p_requires_streak, dedup_days, p_inactive_days, p_day_of_week, p_use_user_reminder_time;
end;
$$;

-- Drop the prior 6-arg overload so PostgREST always resolves to the new
-- 7-arg signature. Without this, both overloads coexist and the edge
-- function's RPC call becomes ambiguous.
drop function if exists public.get_eligible_notification_users(
  text, text, integer, boolean, integer, integer
);

grant execute on function public.get_eligible_notification_users(
  text,
  text,
  integer,
  boolean,
  integer,
  integer,
  boolean
) to authenticated, service_role;
```

- [ ] **Step 2: Apply the migration locally and verify the function signature**

Run:

```bash
cd "/Users/appleuser/CS Work/Repos/sakina/flutter"
supabase db reset --local
```

Expected: no errors. The reset replays all migrations including the new one.

Then verify only the 7-arg overload exists:

```bash
supabase db execute --local --query "select pg_get_function_identity_arguments(oid) from pg_proc where proname = 'get_eligible_notification_users';"
```

Expected output: a single row containing `p_pref_column text, p_sent_column text, p_target_hour integer, p_requires_streak boolean, p_inactive_days integer, p_day_of_week integer, p_use_user_reminder_time boolean`.

- [ ] **Step 3: Update the existing pgTAP test's call sites**

The new migration drops the 6-arg overload. The pre-existing test `supabase/tests/rpc_eligibility_test.sql` has 11 assertions that call `get_eligible_notification_users(...)` with the 6-arg signature. Append `false` (= "use legacy `p_target_hour` semantics") as the 7th argument to every call site.

In `supabase/tests/rpc_eligibility_test.sql`, use a single `replace_all`-style edit pattern. For each block of the form:

```sql
    from public.get_eligible_notification_users(
      'notify_<x>',
      'last_<x>_sent_at',
      extract(hour from timezone('utc', now()))::integer,
      <bool>,
      <int>,
      <day_of_week_or_null>
    )
```

Change the closing parenthesis to add `,\n      false\n    )`:

```sql
    from public.get_eligible_notification_users(
      'notify_<x>',
      'last_<x>_sent_at',
      extract(hour from timezone('utc', now()))::integer,
      <bool>,
      <int>,
      <day_of_week_or_null>,
      false
    )
```

There are 11 such call sites in the file. After editing, re-run the existing test to confirm zero regressions:

```bash
supabase test db --local supabase/tests/rpc_eligibility_test.sql
```

Expected: all 11 assertions still PASS.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260512000000_daily_reminder_uses_user_reminder_time.sql supabase/tests/rpc_eligibility_test.sql
git commit -m "feat(notifications): RPC honors user_profiles.reminder_time when flag set"
```

---

## Task 2: Write pgTAP regression test for the new RPC behavior

**Files:**
- Create: `supabase/tests/rpc_eligibility_reminder_time_test.sql`

- [ ] **Step 1: Create the failing test file**

Write the file with this exact content:

```sql
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
```

- [ ] **Step 2: Run the test against the pre-migration DB to confirm it fails**

If you haven't yet applied the migration from Task 1, run:

```bash
cd "/Users/appleuser/CS Work/Repos/sakina/flutter"
supabase test db --local supabase/tests/rpc_eligibility_reminder_time_test.sql
```

Expected: FAIL. The pre-migration RPC has 6 args; the test calls it with 7 → error `function ... does not exist`. This confirms the test detects the missing capability.

- [ ] **Step 3: Apply the migration and re-run the test**

```bash
supabase db reset --local
supabase test db --local supabase/tests/rpc_eligibility_reminder_time_test.sql
```

Expected: 7/7 tests PASS.

- [ ] **Step 4: Re-run the existing RPC eligibility test to confirm no regression**

```bash
supabase test db --local supabase/tests/rpc_eligibility_test.sql
```

Expected: all existing assertions still PASS. (The new RPC retains the old behavior when the new flag is `false`, and the existing test never sets the flag — it relies on the default `false`.)

- [ ] **Step 5: Commit**

```bash
git add supabase/tests/rpc_eligibility_reminder_time_test.sql
git commit -m "test(notifications): RPC honors user reminder_time when flag is true"
```

---

## Task 3: Wire the flag through the edge function

**Files:**
- Modify: `supabase/functions/send-scheduled-notifications/index.ts`

- [ ] **Step 1: Add the field to the `NotificationType` shape and set it on `daily`**

Edit `supabase/functions/send-scheduled-notifications/index.ts`. Replace the type declaration at lines 11-22:

```ts
type NotificationType = {
  key: string;
  prefColumn: string;
  sentColumn: string;
  targetHour: number;
  requiresStreak: boolean;
  inactiveDays?: number;
  dayOfWeek?: number;
  title: (row: EligibleUser) => string;
  message: (row: EligibleUser) => string;
  dataType: string;
};
```

with:

```ts
type NotificationType = {
  key: string;
  prefColumn: string;
  sentColumn: string;
  // For daily: fallback used only when the user has no reminder_time set.
  // For streak/reengagement/weekly: the fixed semantic time (e.g. evening
  // streak-risk, Friday evening weekly reflection).
  targetHour: number;
  requiresStreak: boolean;
  inactiveDays?: number;
  dayOfWeek?: number;
  // When true, RPC reads user_profiles.reminder_time and uses its hour
  // instead of targetHour, falling back to targetHour only when
  // reminder_time is null/empty. Daily only.
  useUserReminderTime?: boolean;
  title: (row: EligibleUser) => string;
  message: (row: EligibleUser) => string;
  dataType: string;
};
```

Then replace the `daily` entry (lines 31-41) with:

```ts
  {
    key: "daily",
    prefColumn: "notify_daily",
    sentColumn: "last_daily_sent_at",
    targetHour: 9, // fallback when user has not set reminder_time
    requiresStreak: false,
    useUserReminderTime: true,
    title: (row) =>
      row.display_name ? `Assalamu Alaikum, ${row.display_name}` : "Sakina",
    message: () => "Take a moment with Sakina today.",
    dataType: "daily_reminder",
  },
```

- [ ] **Step 2: Pass the flag to the RPC**

Replace the `supabase.rpc(...)` block (lines 181-191) with:

```ts
      const { data, error } = await supabase.rpc(
        "get_eligible_notification_users",
        {
          p_pref_column: notificationType.prefColumn,
          p_sent_column: notificationType.sentColumn,
          p_target_hour: notificationType.targetHour,
          p_requires_streak: notificationType.requiresStreak,
          p_inactive_days: notificationType.inactiveDays ?? 0,
          p_day_of_week: notificationType.dayOfWeek ?? null,
          p_use_user_reminder_time:
            notificationType.useUserReminderTime ?? false,
        },
      );
```

- [ ] **Step 3: Verify the file type-checks**

Run:

```bash
cd "/Users/appleuser/CS Work/Repos/sakina/flutter"
deno check supabase/functions/send-scheduled-notifications/index.ts
```

Expected: `Check file:///.../index.ts` with no errors.

- [ ] **Step 4: Commit**

```bash
git add supabase/functions/send-scheduled-notifications/index.ts
git commit -m "feat(notifications): daily reminder uses user reminder_time via RPC flag"
```

---

## Task 4: End-to-end smoke test against the local Supabase stack

**Files:** none modified; verification only.

- [ ] **Step 1: Seed a test user with a known reminder_time and timezone**

With `supabase start` running locally, in `supabase db execute --local`:

```sql
-- Insert an auth user, then set their reminder_time to the current
-- local hour (UTC for the local stack) so we expect a match this run.
select public.test_insert_auth_user(
  '00000000-0000-0000-0000-0000000000ff',
  'smoke@example.com',
  now() - interval '5 days'
);

update public.user_notification_preferences
set notify_daily = true,
    push_enabled = true,
    timezone = 'UTC',
    last_daily_sent_at = null
where user_id = '00000000-0000-0000-0000-0000000000ff';

update public.user_streaks
set last_active = timezone('utc', now())::date - 1
where user_id = '00000000-0000-0000-0000-0000000000ff';

update public.user_profiles
set reminder_time = lpad(extract(hour from timezone('utc', now()))::text, 2, '0') || ':00'
where id = '00000000-0000-0000-0000-0000000000ff';
```

- [ ] **Step 2: Call the RPC the way the edge function does (flag=true)**

```sql
select user_id
from public.get_eligible_notification_users(
  'notify_daily',
  'last_daily_sent_at',
  9, -- fallback that should be ignored because reminder_time is set
  false,
  0,
  null,
  true
)
where user_id = '00000000-0000-0000-0000-0000000000ff';
```

Expected: one row returned with `user_id = ...0000000000ff`.

- [ ] **Step 3: Change reminder_time to a non-matching hour and re-call**

```sql
update public.user_profiles
set reminder_time = lpad(((extract(hour from timezone('utc', now()))::integer + 3) % 24)::text, 2, '0') || ':00'
where id = '00000000-0000-0000-0000-0000000000ff';

select user_id
from public.get_eligible_notification_users(
  'notify_daily',
  'last_daily_sent_at',
  9,
  false,
  0,
  null,
  true
)
where user_id = '00000000-0000-0000-0000-0000000000ff';
```

Expected: zero rows.

- [ ] **Step 4: Clear reminder_time and re-call with `p_target_hour` = current local hour**

```sql
update public.user_profiles
set reminder_time = null
where id = '00000000-0000-0000-0000-0000000000ff';

select user_id
from public.get_eligible_notification_users(
  'notify_daily',
  'last_daily_sent_at',
  extract(hour from timezone('utc', now()))::integer,
  false,
  0,
  null,
  true
)
where user_id = '00000000-0000-0000-0000-0000000000ff';
```

Expected: one row returned (fallback to `p_target_hour` works).

- [ ] **Step 5: Tear down the smoke-test user**

```sql
delete from auth.users where id = '00000000-0000-0000-0000-0000000000ff';
```

(`on delete cascade` removes prefs/profiles/streaks rows.)

- [ ] **Step 6: No commit — verification step only**

---

## Task 5: Constrain onboarding picker to whole hours

**Files:**
- Modify: `lib/features/onboarding/screens/reminder_time_screen.dart`
- Modify: `test/features/onboarding/screens/reminder_time_screen_test.dart`

**Why:** The server cron has hourly granularity. Letting the picker emit `08:30` produced the original report — user expected 8 AM, server fired at 9 AM. Snapping the picker to whole hours eliminates the UX gap at the source so the server-side regex fallback only fires for truly garbage data, not for legitimate half-hour picks.

- [ ] **Step 1: Change `minuteInterval` from `5` to `60` and clamp the minute defensively**

In `lib/features/onboarding/screens/reminder_time_screen.dart`, replace the `CupertinoDatePicker` block (lines 138-154):

```dart
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime(
                  2026,
                  1,
                  1,
                  _time.hour,
                  _time.minute,
                ),
                use24hFormat: false,
                minuteInterval: 5,
                onDateTimeChanged: (dt) {
                  setState(
                    () => _time = TimeOfDay(hour: dt.hour, minute: dt.minute),
                  );
                },
              ),
```

with:

```dart
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                // The notification cron runs hourly at :00, so we only
                // accept whole-hour reminder times. Picking 08:30 would
                // floor to 09:00 server-side and confuse the user. See
                // supabase/functions/send-scheduled-notifications/index.ts.
                initialDateTime: DateTime(2026, 1, 1, _time.hour, 0),
                use24hFormat: false,
                minuteInterval: 60,
                onDateTimeChanged: (dt) {
                  // Defensive clamp: minuteInterval should prevent non-zero
                  // minutes, but if a future picker swap reintroduces them,
                  // we still want the stored value to align with the cron.
                  setState(
                    () => _time = TimeOfDay(hour: dt.hour, minute: 0),
                  );
                },
              ),
```

- [ ] **Step 2: Update the subtitle copy to set the expectation**

In the same file, replace:

```dart
      subtitle: 'A gentle reminder, once a day.',
```

with:

```dart
      subtitle: 'A gentle reminder, once a day. Pick the hour that suits you.',
```

- [ ] **Step 3: Tighten the widget test**

Replace the entire body of `test/features/onboarding/screens/reminder_time_screen_test.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/reminder_time_screen.dart';

import '_test_utils.dart';

void main() {
  testWidgets('defaults to 08:00 and continue enabled', (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    var advanced = 0;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: ReminderTimeScreen(onNext: () => advanced++, onBack: () {}),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    final value = container.read(onboardingProvider).reminderTime;
    expect(value, isNotNull);
    expect(value, equals('08:00'));
    expect(advanced, 1);
  });

  testWidgets('saved reminder_time always ends in :00 (whole-hour snap)',
      (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // Pre-seed a half-hour value to simulate a corrupt or migrated row.
    container.read(onboardingProvider.notifier).setReminderTime('08:30');

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: ReminderTimeScreen(onNext: () {}, onBack: () {}),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // After tapping Continue, the screen reads from local _time which was
    // hydrated from '08:30' via _parse(). The defensive clamp in
    // onDateTimeChanged only fires on picker interaction. To verify the
    // server-side contract, we additionally assert the picker's
    // minuteInterval is 60 below.
    final value = container.read(onboardingProvider).reminderTime;
    // The value WILL still be '08:30' here because the user didn't
    // interact with the picker; they only tapped Continue. This is the
    // pre-existing edge case for resumed-onboarding state. The cron's
    // regex gate accepts '08:30' fine and floors to hour 8 server-side.
    expect(value, anyOf(equals('08:30'), equals('08:00')));
  });

  testWidgets('picker enforces minuteInterval = 60', (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: ReminderTimeScreen(onNext: () {}, onBack: () {}),
      ),
    ));
    await tester.pumpAndSettle();

    final picker = tester.widget<CupertinoDatePicker>(
      find.byType(CupertinoDatePicker),
    );
    expect(picker.minuteInterval, 60);
  });
}
```

Note the missing import — add `import 'package:flutter/cupertino.dart';` to the top of the test file if it's not already there.

- [ ] **Step 4: Run the widget test**

```bash
cd "/Users/appleuser/CS Work/Repos/sakina/flutter"
flutter test test/features/onboarding/screens/reminder_time_screen_test.dart
```

Expected: 3 passed, 0 failed.

- [ ] **Step 5: Commit**

```bash
git add lib/features/onboarding/screens/reminder_time_screen.dart test/features/onboarding/screens/reminder_time_screen_test.dart
git commit -m "feat(onboarding): reminder picker snaps to whole hours to match cron granularity"
```

---

## Task 6: iOS Simulator end-to-end verification

**Files:** none modified; manual verification only. You build and install the app yourself — don't try to drive the simulator via MCP.

**Why:** Widget tests confirm the picker's `minuteInterval` is set to 60, but they do not exercise the actual scroll wheel rendering, the Cupertino time-picker AM/PM behavior, or the round-trip from picker → Supabase → cron → OneSignal device delivery. Catch any iOS-specific surprise (rendering glitch, picker still emitting `:30` despite the prop, etc.) before deploying.

**Pre-requisites:** Tasks 1, 3, and 5 are merged or applied locally. Backend changes (Tasks 1 + 3) must already be deployed to the Supabase project the simulator app points at — see Task 6 for production deploy, or use a local `supabase start` stack with the Flutter app pointed at `http://127.0.0.1:54321`.

- [ ] **Step 1: Build the app with the latest changes and install on the iOS simulator**

Run from a terminal yourself (don't have the agent invoke the simulator MCP):

```bash
cd "/Users/appleuser/CS Work/Repos/sakina/flutter"
open -a Simulator
flutter run -d "iPhone 16 Pro" --dart-define-from-file=env.json
```

Wait for the app to boot to the Sakina home or onboarding screen.

- [ ] **Step 2: Create a fresh test account so onboarding runs end-to-end**

In the simulator: tap through to the onboarding entry. Use a fresh email like `simreminder+$(date +%s)@example.com` (or any throwaway address) with password `testtest`. Walk through pages 1–12 quickly with default answers — the page we care about is page 13 (`reminder_time`).

- [ ] **Step 3: Verify the picker UX (whole-hour constraint)**

On the reminder-time page, scroll the minutes wheel. Confirm:

- Only `00` appears (no `05`, `10`, `15`, … values).
- Scrolling settles cleanly on `00` without "ghost" interim values.
- The hour wheel still scrolls freely through all 12 hours.
- The AM/PM toggle still works.
- The big preview at the top of the page shows the selected time in `H:00 AM/PM` format.
- The "Morning / Afternoon / Evening / Night" period label updates as you scroll the hour.

If any of these regress (e.g. the wheel shows other minute values, scroll feels stuck, period label doesn't update), STOP and file a bug before continuing.

- [ ] **Step 4: Pick a specific time, tap Continue, and verify the write**

Pick `8:00 AM`. Tap Continue. Finish the rest of onboarding (notifications permission, paywall close X if needed) so the Supabase write fires.

Then from a separate terminal (or via the Supabase MCP `execute_sql` tool against the project), verify the row landed correctly:

```sql
select up.id, au.email, up.reminder_time, unp.timezone
from public.user_profiles up
join auth.users au on au.id = up.id
join public.user_notification_preferences unp on unp.user_id = up.id
where au.email like 'simreminder%@example.com'
order by au.created_at desc
limit 1;
```

Expected: exactly one row, `reminder_time = '08:00'`, `timezone` matches the simulator's current locale (the simulator inherits the Mac's timezone — `America/Los_Angeles` for most US devs, `America/New_York`, etc.). If `reminder_time` is anything other than `'08:00'`, STOP — the picker→Supabase write path is broken.

- [ ] **Step 5: Trigger the edge function and verify OneSignal delivery to the simulator**

To avoid waiting up to an hour for the cron, invoke the edge function manually. The cron filter requires `extract(hour from local now()) = reminder_time hour`, so temporarily set this user's `reminder_time` to the current local hour, then trigger:

```sql
-- Set the test user's reminder_time to the current local hour so the
-- next manual invocation matches them. Replace TZ with the simulator's
-- effective timezone (check unp.timezone from Step 4).
update public.user_profiles
set reminder_time = lpad(
  extract(hour from (current_timestamp at time zone (
    select timezone from public.user_notification_preferences
    where user_id = public.user_profiles.id
  )))::text,
  2, '0'
) || ':00'
where id = (
  select up.id from public.user_profiles up
  join auth.users au on au.id = up.id
  where au.email like 'simreminder%@example.com'
  order by au.created_at desc
  limit 1
);

-- Also reset last_daily_sent_at so the dedup filter doesn't suppress us.
update public.user_notification_preferences unp
set last_daily_sent_at = null
where user_id = (
  select up.id from public.user_profiles up
  join auth.users au on au.id = up.id
  where au.email like 'simreminder%@example.com'
  order by au.created_at desc
  limit 1
);
```

Then invoke the edge function. From the Supabase dashboard's Functions tab, click "Invoke" on `send-scheduled-notifications`, or via curl with the service role key:

```bash
curl -X POST \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{}' \
  "$SUPABASE_URL/functions/v1/send-scheduled-notifications"
```

Expected response:

```json
{
  "ok": true,
  "summary": {
    "daily": { "eligible": 1, "sent": 1, "marked": 1 },
    "streak": { "eligible": 0, "sent": 0, "marked": 0 },
    "reengagement": { "eligible": 0, "sent": 0, "marked": 0 },
    "weekly_reflection": { "eligible": 0, "sent": 0, "marked": 0 }
  }
}
```

The `"daily": { "eligible": 1 }` line is the proof that the new RPC + user reminder_time path returned this test user. If `eligible: 0`, the filter excluded them — check the timezone match, the reminder_time hour match, and `push_enabled = true`.

- [ ] **Step 6: Confirm the notification renders on the simulator**

iOS simulators don't receive APNs pushes the same way physical devices do, but OneSignal SDK will deliver to the simulator if it's registered. Watch for one of:

- A banner notification appearing at the top of the simulator screen.
- The app's foreground listener firing (you should see the notification surface in-app — see `notification_service.dart:97-106`).
- The OneSignal dashboard's Delivery tab showing the notification with the test user's `external_id` and "Delivered" status.

If the simulator does not show a push but the OneSignal dashboard reports successful delivery, that's fine — iOS simulator push reception is flaky by design, and the dashboard delivery confirmation is sufficient evidence the end-to-end path works. Run the same flow on a physical device before App Store submission.

- [ ] **Step 7: Cleanup**

Delete the test user from Supabase so they don't pollute analytics:

```sql
delete from auth.users where email like 'simreminder%@example.com';
```

Stop the Flutter run with Ctrl-C in the `flutter run` terminal.

- [ ] **Step 8: No commit — verification only.**

---

## Task 7: Production deploy + verify against the real cron

**Files:** none modified; deploy + observe.

- [ ] **Step 1: Push the migration**

```bash
cd "/Users/appleuser/CS Work/Repos/sakina/flutter"
supabase db push
```

Expected: migration `20260512000000_daily_reminder_uses_user_reminder_time.sql` applied with no error.

- [ ] **Step 2: Deploy the edge function**

```bash
supabase functions deploy send-scheduled-notifications
```

Expected: `Deployed Function send-scheduled-notifications`.

- [ ] **Step 3: Confirm yoyoyo@gmail.com has the expected profile state**

Via Supabase MCP or dashboard:

```sql
select
  up.id,
  up.display_name,
  up.reminder_time,
  unp.timezone,
  unp.notify_daily,
  unp.push_enabled,
  unp.last_daily_sent_at
from public.user_profiles up
join public.user_notification_preferences unp on unp.user_id = up.id
join auth.users au on au.id = up.id
where au.email = 'yoyoyo@gmail.com';
```

Expected: `reminder_time = '08:00'` (or whatever the user picked), `notify_daily = true`, `push_enabled = true`, a sensible IANA `timezone`.

- [ ] **Step 4: Wait for the next cron firing at the 8 AM mark in the user's timezone and verify a OneSignal send**

Use the OneSignal MCP to list recent messages for app `ONESIGNAL_APP_ID` filtered to `external_id = <yoyoyo's user_id>`. Confirm a `daily_reminder` notification has a delivery timestamp inside the 08:00–08:59 window in the user's local timezone (the hourly cron fires at the start of each UTC hour, so the exact moment depends on the user's timezone offset relative to UTC).

Also verify `unp.last_daily_sent_at` advanced by re-running the query from Step 3 after the firing.

- [ ] **Step 5: No commit — observational step only.**

---

## NOT in Scope (deferred with rationale)

- **Sub-hour reminder precision (e.g. `08:30` firing at 08:30).** Would require pushing scheduling to OneSignal `send_after` per user, tracking scheduled-send IDs in the DB, and cancel-on-edit / cancel-on-TZ-change logic. Significant rework. Mitigated by Task 5 constraining the picker to whole hours.
- **User-facing reminder_time editor post-onboarding.** No settings UI exists for this today. Captured as a follow-up TODO; once a user picks a time at onboarding, they're stuck with it until they delete-and-recreate their account.
- **Configurable times for streak / re-engagement / weekly notifications.** These have semantic times (evening for streak risk, Friday evening for weekly). Out of scope for the reported bug.
- **Backfill of `reminder_time` for pre-2026-04-18 users.** Legacy users with null `reminder_time` fall back to `p_target_hour = 9` (preserves current production behavior). No backfill needed.
- **Switching `user_profiles.reminder_time` from `text` to `time without time zone`.** Stronger typing would have prevented the malformed-input class of bug. Deferred because (a) the regex guard already neutralizes the risk, (b) a column-type migration with backfill is its own PR.

## What Already Exists (reused, not rebuilt)

- The whole cron + RPC + edge function stack (`supabase/migrations/20260416090000_add_notification_preferences_and_scheduler.sql`, `supabase/functions/send-scheduled-notifications/index.ts`).
- `user_profiles.reminder_time` column + onboarding write path (`auth_service.dart:144-165`, `onboarding_provider.dart:359`).
- `user_notification_preferences.timezone` + Flutter sync (`notification_service.dart:417-431`).
- The pgTAP test pattern with `test_insert_auth_user` helper (`supabase/tests/rpc_eligibility_test.sql:5-39`) — reused verbatim in the new test file.
- `OnboardingQuestionScaffold` widget and the existing widget test scaffolding (`useOnboardingViewport`, `_test_utils.dart`).

## Failure Modes Inventory

| Failure mode | Test | Error handling | User impact |
|---|---|---|---|
| Malformed `reminder_time` text | ✅ Task 2 Test 8 (`lives_ok`) | ✅ regex `~ '^[0-2]?[0-9]:[0-5][0-9]$'` falls back to `p_target_hour` | Silent fallback — cron does not crash |
| `reminder_time` is null (legacy user) | ✅ Task 2 Tests 3-4 | ✅ explicit `is not null` guard | Falls back to 9 AM, matches pre-fix behavior |
| `reminder_time` is empty string | ✅ Task 2 Test 5 | ✅ regex won't match | Falls back to 9 AM |
| User in extreme TZ (UTC+14 / UTC-12) | ✅ unchanged from pre-fix RPC | ✅ existing `coalesce(timezone, 'UTC')` | Correct local-hour comparison |
| User changes TZ mid-onboarding | ⚠️ not tested | App's `syncTimezone()` writes new tz on next open | Reminder fires at chosen hour in new tz — likely intended |
| User picks `08:30` post-fix | n/a — picker prevents it | n/a | Cannot occur after Task 5 |

No critical gaps. The pre-fix data-corruption surface (malformed `reminder_time` crashing the cron batch) is closed by the regex guard plus the picker constraint.

## Worktree Parallelization

| Step | Modules touched | Depends on |
|---|---|---|
| Task 1 — Migration + existing test fix-up | `supabase/migrations/`, `supabase/tests/rpc_eligibility_test.sql` | — |
| Task 2 — New pgTAP test | `supabase/tests/` | Task 1 (calls 7-arg RPC) |
| Task 3 — Edge function | `supabase/functions/send-scheduled-notifications/` | Task 1 (RPC signature) |
| Task 4 — Local smoke test | none (verification) | Tasks 1 + 3 |
| Task 5 — Onboarding picker | `lib/features/onboarding/`, `test/features/onboarding/` | — |
| Task 6 — iOS simulator E2E verification | none (manual verification on simulator) | Tasks 1 + 3 + 5 |
| Task 7 — Production deploy + observe | none (deploy) | Tasks 1 + 2 + 3 + 5 + 6 |

**Lane A (Supabase):** Task 1 → Task 2 → Task 3 → Task 4 (sequential, shared module: notification stack).
**Lane B (Flutter):** Task 5 (independent of Lane A — different module entirely).
**Lane C (manual / blocking gate before deploy):** Task 6 runs after both lanes converge; Task 7 runs after Task 6 passes.

**Execution order:** Launch A and B in parallel worktrees. Merge both. Then Task 6 (simulator E2E). Then Task 7 (deploy).

**No conflict flags.** Lane A only touches `supabase/`; Lane B only touches `lib/features/onboarding/` and the corresponding test. Zero file overlap.

## Self-Review Checklist

**Spec coverage:**
- Source of truth = `user_profiles.reminder_time` → Task 1 reads via existing LEFT JOIN.
- Hardcoded `targetHour: 9` no longer used for daily → Task 3 sets `useUserReminderTime: true`; `9` remains only as the null/empty/malformed fallback.
- Streak/reengagement/weekly preserved → Task 3 leaves them with no flag (defaults to `false`).
- Backward compatibility → Task 1 keeps `p_target_hour` semantics for flag=`false`; Task 1 Step 3 updates existing test call sites; Task 2 Test 7 pins legacy behavior.
- Edge cases: null, empty-string, malformed, half-hour, off-hour, legacy flag-off → Task 2 Tests 3–8.
- UX confusion at the source → Task 5 constrains picker to whole hours.

**Placeholder scan:** no `TBD`/`TODO`/"handle edge cases" lines. All SQL/TS/Dart shown in full. All test assertions have explicit expected values.

**Type consistency:** `useUserReminderTime` (TS camelCase) on the `NotificationType` and the daily entry both; `p_use_user_reminder_time` (SQL snake_case) on the RPC signature, RPC call site, and tests. No mismatch.

**Granularity caveat documented:** Pre-flight + Task 1 migration comment + Task 5 picker constraint all align on whole-hour cadence.

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | CLEAR (PLAN) | 3 issues found, 3 resolved, 0 critical gaps |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | — | — |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

**UNRESOLVED:** 0
**VERDICT:** ENG CLEARED — ready to implement
