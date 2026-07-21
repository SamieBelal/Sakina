-- 20260721020000_winback_local_day_fix.sql
--
-- Fix: winback branch in get_streak_notification_decisions() compared a UTC
-- date (last_active, written by Flutter's _todayString()/.toUtc()) against a
-- LOCAL-day threshold (local_today - 1), causing a ±1-day dormancy error for
-- east-of-UTC users.
--
-- Root cause (line 115 of 20260720010000_streak_notification_decision.sql):
--
--   when s.last_active is not null
--        and s.last_active < s.local_today - 1 then 'winback'
--
-- `last_active` is a UTC calendar date; `local_today` is the user's local
-- calendar date.  A UTC+12 user who reflects at 01:00 local (= 13:00 UTC
-- the previous calendar day) has last_active = two UTC days before
-- local_today, triggering 'winback' even though only 1 local day has passed.
--
-- Fix: use last_reflected_local (added by the same migration as the accurate
-- LOCAL date of the last reflection) when available, falling back to
-- normalizing last_active via UTC->local timezone conversion.
--
--   coalesce(
--     s.last_reflected_local,
--     ((s.last_active::timestamp at time zone 'UTC') at time zone s.tz)::date
--   ) < s.local_today - 1
--
-- Why prefer last_reflected_local over normalization alone:
--   The normalization ((last_active::timestamp at tz 'UTC') at tz tz)::date
--   takes midnight-UTC of last_active and converts it to the local timezone.
--   This is systematically off by up to 1 day for reflections that happen in
--   the early hours of the local calendar day (i.e., before UTC midnight).
--   last_reflected_local is the device's actual local calendar date at the
--   moment of reflection — the canonical correct value.  The coalesce
--   ensures backward compatibility for rows written before last_reflected_local
--   was added (NULL rows fall through to the normalized last_active).
--
-- Everything else (security definer, search_path, saver/milestone branches,
-- grants, family-dedup filter, pref gates) is unchanged — this is a one-line
-- logical change.

create or replace function public.get_streak_notification_decisions(
  p_target_hour integer
)
returns table (
  user_id uuid,
  timezone text,
  display_name text,
  current_streak integer,
  kind text
)
language sql
security definer
set search_path = public, auth
as $$
  with base as (
    select
      n.user_id,
      coalesce(nullif(n.timezone, ''), 'UTC') as tz,
      p.display_name,
      coalesce(s.current_streak, 0)::integer as current_streak,
      s.last_active,
      s.last_reflected_local,
      n.push_enabled,
      n.notify_streak,
      n.notify_reengagement,
      n.last_streak_family_sent_at
    from public.user_notification_preferences n
    left join public.user_profiles p
      on p.id = n.user_id
    left join public.user_streaks s
      on s.user_id = n.user_id
  ),
  scoped as (
    select
      b.*,
      (current_timestamp at time zone b.tz)::date as local_today
    from base b
    where b.push_enabled = true
      and extract(
        hour from (current_timestamp at time zone b.tz)
      )::integer = p_target_hour
  ),
  decided as (
    select
      s.user_id,
      s.tz,
      s.display_name,
      s.current_streak,
      s.notify_streak,
      s.notify_reengagement,
      case
        -- 1. reflected this LOCAL day -> not eligible
        when s.last_reflected_local is not null
             and s.last_reflected_local = s.local_today then null
        -- 2. dormant >= 2 local days.
        --    Use last_reflected_local (accurate local date) when available;
        --    fall back to normalizing last_active from UTC to the user's
        --    local timezone for rows that predate the column.
        when s.last_active is not null
             and coalesce(
                   s.last_reflected_local,
                   ((s.last_active::timestamp at time zone 'UTC')
                    at time zone s.tz)::date
                 ) < s.local_today - 1 then 'winback'
        -- 3. exactly 1 day before a milestone threshold
        when (s.current_streak + 1) in (7, 14, 30, 60, 90, 180, 365) then 'milestone'
        -- 4. active streak, not reflected today -> saver
        when s.current_streak >= 1 then 'saver'
        else null
      end as kind,
      s.last_streak_family_sent_at,
      s.local_today
    from scoped s
  )
  select
    d.user_id,
    d.tz as timezone,
    d.display_name,
    d.current_streak,
    d.kind
  from decided d
  where d.kind is not null
    -- family dedup: one streak-family push per user per local day (:00/:30 guard)
    and (
      d.last_streak_family_sent_at is null
      or d.last_streak_family_sent_at <> d.local_today
    )
    -- pref gate per family member: saver/milestone honor notify_streak,
    -- winback honors notify_reengagement.
    and (
      (d.kind in ('saver', 'milestone') and d.notify_streak = true)
      or (d.kind = 'winback' and d.notify_reengagement = true)
    );
$$;

-- Grants: service_role ONLY (unchanged from original migration).
revoke execute on function public.get_streak_notification_decisions(integer)
  from public, anon, authenticated;
grant execute on function public.get_streak_notification_decisions(integer)
  to service_role;
