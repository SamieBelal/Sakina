-- Unified streak-notification decision model (T5 / spec §5 S1, decisions D6/D7/D8/D11/D12).
--
-- Replaces the sprayed, per-segment streak push with ONE server-computed
-- decision per eligible user per LOCAL day. Collapses saver + milestone +
-- win-back into a single mutually-exclusive `kind`, and replaces the per-type
-- sent-columns with ONE `last_streak_family_sent_at` dedup key so the
-- `0,30 * * * *` cron cannot double-fire the same family at :00 and :30.
--
-- Highest blast-radius change in the plan (D12): it feeds the same
-- send-scheduled-notifications machinery every push type depends on, so it
-- ships LAST with the most testing. No kill-switch / feature flag (D12 — user
-- declined per-segment flags).
--
-- NOT YET APPLIED to the live DB at authoring time — review first.

-- ── 1. Local-day reflection marker (D8/A1) ───────────────────────────────────
-- `user_streaks.last_active` is a UTC date and cannot express the user's LOCAL
-- reflection day: an east-of-UTC user who reflects in their local evening writes
-- a UTC date that may already be "tomorrow" (or, near midnight, still be
-- "yesterday" relative to their local calendar). The decision must never false-
-- fire "your lantern rests tonight" at someone who already reflected today
-- LOCALLY, so we add a client-written LOCAL date and read that instead.
-- NULL = eligible (no backfill; a user simply becomes ineligible the first time
-- they reflect after this ships — fail-safe: no false push).
alter table public.user_streaks
  add column if not exists last_reflected_local date;

-- ── 2. ONE streak-family dedup key (D11) ─────────────────────────────────────
-- Replaces the per-segment sent columns. `last_streak_family_sent_at` is stamped
-- (as the user's LOCAL today) after ANY streak-family push fires, so the decision
-- RPC skips a user already served this local day → kills the :00/:30 double-fire.
-- `last_streak_family_kind` records which member fired (saver|milestone|winback)
-- for observability + future D6-style transitions.
alter table public.user_notification_preferences
  add column if not exists last_streak_family_sent_at date;
alter table public.user_notification_preferences
  add column if not exists last_streak_family_kind text;

-- ── 3. Unified decision RPC ──────────────────────────────────────────────────
-- Returns ONE decision per eligible user whose LOCAL hour = p_target_hour.
-- Priority (spec §5 decide()):
--   1. reflected this LOCAL day (last_reflected_local = local_today)  -> skip (none)
--   2. dormant >= 2 local days (last_active < local_today - 1)        -> winback
--   3. exactly 1 day before a milestone (streak+1 in thresholds)      -> milestone
--   4. current_streak >= 1, not reflected this local day              -> saver
--   else                                                             -> skip (none)
--
-- Guards mirror get_eligible_notification_users:
--   * push_enabled = true
--   * the right pref column: notify_streak for saver+milestone,
--     notify_reengagement for winback (a user who muted re-engagement should not
--     get the dormant win-back).
--   * local-hour = p_target_hour
--   * family dedup: skip if last_streak_family_sent_at = local_today.
--
-- D6 (win-back suppression) falls out for free: winback only fires at dormancy
-- >= 2 local days, so it can never overlap the evening-of-lapse saver — no
-- separate suppression flag / conversion tracking needed.
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
        -- 2. dormant >= 2 local days (last_active at least 2 local days behind)
        when s.last_active is not null
             and s.last_active < s.local_today - 1 then 'winback'
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

-- ── 4. Grants: service_role ONLY (matches get_eligible_notification_users) ───
-- This is a SET-RETURNING function over ALL users (the cron's recipient query),
-- so it must NOT be callable by authenticated end-users — that would leak every
-- user's streak + display name. The edge function invokes it with the
-- service_role key, never as the signed-in user.
revoke execute on function public.get_streak_notification_decisions(integer)
  from public, anon, authenticated;
grant execute on function public.get_streak_notification_decisions(integer)
  to service_role;
