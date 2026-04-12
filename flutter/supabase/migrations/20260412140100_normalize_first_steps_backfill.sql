-- =============================================================================
-- Normalize First Steps quests into user_quest_progress (data backfill)
-- =============================================================================
-- Moves first_steps_completed / first_steps_bundle_claimed from user_profiles
-- into user_quest_progress rows with cadence = 'one_time'.
--
-- Quest IDs:
--   first_muhasabah, first_reflect, first_built_dua, first_steps_bundle
--
-- period_start is anchored to the user's UTC created_at date so each user gets
-- a single stable uniqueness key for one-time quests.
-- =============================================================================

insert into public.user_quest_progress
  (user_id, quest_id, cadence, progress, completed, period_start)
select
  p.id,
  unnest(p.first_steps_completed),
  'one_time'::public.quest_cadence,
  1,
  true,
  timezone('utc', p.created_at)::date
from public.user_profiles p
where array_length(p.first_steps_completed, 1) > 0
on conflict (user_id, quest_id, period_start) do nothing;

insert into public.user_quest_progress
  (user_id, quest_id, cadence, progress, completed, period_start)
select
  p.id,
  'first_steps_bundle',
  'one_time'::public.quest_cadence,
  1,
  true,
  timezone('utc', p.created_at)::date
from public.user_profiles p
where p.first_steps_bundle_claimed = true
on conflict (user_id, quest_id, period_start) do nothing;

alter table public.user_profiles
  drop column if exists first_steps_completed,
  drop column if exists first_steps_bundle_claimed;
