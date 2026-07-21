-- 20260721030000_winback_cooldown.sql
--
-- Add a 7-day cooldown to the winback branch of get_streak_notification_decisions().
--
-- Problem: a dormant user currently qualifies for a 'winback' push every eligible
-- evening — the existing family dedup (last_streak_family_sent_at <> local_today)
-- only blocks a same-day resend.  With the daily cron firing every 30 min
-- across multiple hours, a user who ignored Monday's winback gets another one on
-- Tuesday, Wednesday, … endlessly.
--
-- Fix: suppress 'winback' if a winback was already sent within the last 6 local
-- days (i.e. allow re-qualification only after >= 7 local days have passed).
--
-- Implementation:
--   1. Add last_streak_family_kind to the base CTE (it exists on
--      user_notification_preferences but was not previously read by this function).
--   2. In the winback CASE branch of decided, add a NOT (...) guard:
--        NOT (
--          d.last_streak_family_kind = 'winback'
--          AND d.last_streak_family_sent_at IS NOT NULL
--          AND d.last_streak_family_sent_at > d.local_today - 7
--        )
--      Reading: "do NOT emit winback when the last-sent family was winback
--      AND it was sent fewer than 7 local days ago."
--      A winback sent exactly 7 days ago satisfies sent_at = local_today - 7
--      which is NOT > local_today - 7, so the cooldown has expired and the
--      user becomes eligible again (>= 7 days).
--
-- Everything else (security definer, search_path, grants, saver/milestone branches,
-- per-day dedup filter, pref gates) is unchanged.

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
      n.last_streak_family_sent_at,
      n.last_streak_family_kind
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
        -- 2. dormant >= 2 local days -> winback, UNLESS cooldown active.
        --    Use last_reflected_local (accurate local date) when available;
        --    fall back to normalizing last_active from UTC to the user's
        --    local timezone for rows that predate the column.
        --    Cooldown: suppress if a winback was already sent within the last
        --    6 local days (re-qualifies after >= 7 local days).
        when s.last_active is not null
             and coalesce(
                   s.last_reflected_local,
                   ((s.last_active::timestamp at time zone 'UTC')
                    at time zone s.tz)::date
                 ) < s.local_today - 1
             and not (
                   s.last_streak_family_kind = 'winback'
                   and s.last_streak_family_sent_at is not null
                   and s.last_streak_family_sent_at > s.local_today - 7
                 ) then 'winback'
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

-- Grants: service_role ONLY (unchanged from prior migrations).
revoke execute on function public.get_streak_notification_decisions(integer)
  from public, anon, authenticated;
grant execute on function public.get_streak_notification_decisions(integer)
  to service_role;
