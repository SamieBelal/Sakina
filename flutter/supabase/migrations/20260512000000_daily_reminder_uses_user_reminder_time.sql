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
