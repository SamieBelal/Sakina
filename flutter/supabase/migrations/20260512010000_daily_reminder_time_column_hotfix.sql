-- HOTFIX 2026-05-12: The 20260512000000 migration assumed user_profiles.reminder_time
-- was `text` (per its declaring migration comment at 20260418000000) and used a
-- regex + split_part to extract the hour. In production the column is actually
-- `time without time zone` — Postgres serializes time values as 'HH:mm:ss', not
-- 'HH:mm', so the regex never matched any real row. Every user with a
-- reminder_time fell back to p_target_hour=9 silently.
--
-- This hotfix switches to native `extract(hour from p.reminder_time)::integer`,
-- which works regardless of whether the column is `time` or `text`: Postgres
-- will coerce text 'HH:mm' / 'HH:mm:ss' to time and extract the hour. NULL-safe
-- via the existing `is not null` guard. The malformed-input regex guard is no
-- longer needed because `time` rejects invalid values at INSERT, eliminating
-- the cron-batch-crash failure mode the regex was originally guarding against.

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
            -- Column is `time without time zone` in production. Native
            -- extract(hour from ...) handles HH, HH:mm, and HH:mm:ss
            -- alike, and is NULL-safe via the guard. No regex needed
            -- because `time` rejects invalid values at INSERT.
            when $6 and p.reminder_time is not null
              then extract(hour from p.reminder_time)::integer
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
