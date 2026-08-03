-- 2026-08-03: a built duʿā can be marked answered.
-- Plan: docs/superpowers/plans/2026-08-02-journaling-and-name-mastery-plan.md §E
-- Design: docs/superpowers/specs/2026-08-02-journaling-and-name-mastery-design.md §7
--
-- "You asked for this four months ago." Design §7 calls this the single
-- highest-emotion mechanic available to a Muslim app, and the only thing
-- standing between the app and it was that `user_built_duas` records the asking
-- and has nowhere to record the answer.
--
--   status       'open' (asked, still asked) | 'answered' (the user marked it)
--   answered_at  when they marked it — NOT when it was answered, which is not
--                ours to know and is deliberately not modelled.
--
-- Two values, and only two, for the same reason `user_reflections.source` has
-- two: a third silently escapes every `status =` predicate the prompt selector
-- and the journal chip rely on. There is no 'unanswered', no 'expired' and no
-- 'partially answered' — the app does not adjudicate duʿā.
--
-- Existing rows read back as 'open' via the column default. No backfill.
--
-- ⚠️ NO PUSH. `supabase/functions/send-scheduled-notifications/index.ts:29`
-- freezes COPY_VERSION at 'reel_v1' until the keep read. This migration adds no
-- notification template, no scheduled send and no due-query for one. Design §7
-- says the push half is worth scheduling deliberately later; that is a separate
-- decision with a separate gate.

alter table public.user_built_duas
  add column if not exists status text not null default 'open',
  add column if not exists answered_at timestamptz;

alter table public.user_built_duas drop constraint if exists user_built_duas_status_check;
alter table public.user_built_duas add constraint user_built_duas_status_check
  check (status in ('open', 'answered'));

-- The two columns are one fact stated twice, so they are constrained together.
-- Without this an 'answered' row with a null `answered_at` renders a chip with
-- no date under it, and an 'open' row carrying a stale `answered_at` survives an
-- undo — both are reachable from the client's own upsert path, which writes the
-- whole row.
alter table public.user_built_duas drop constraint if exists user_built_duas_answered_at_agrees;
alter table public.user_built_duas add constraint user_built_duas_answered_at_agrees
  check ((status = 'answered') = (answered_at is not null));

-- The prompt selector asks one question — "the oldest still-open duʿā for this
-- user" — and this is the index that answers it without walking every duʿā the
-- user has ever built.
create index if not exists idx_built_duas_user_status_saved
  on public.user_built_duas (user_id, status, saved_at asc);

-- ---------------------------------------------------------------------------
-- sync_all_user_data() — RE-EMITTED AS A SUPERSET of 20260802030000.
--
-- ⚠️ This function has collided once already (20260726000300 vs
-- 20260727100300): whichever CREATE OR REPLACE runs last wins, and version order
-- on a fresh reset differs from wall-clock order in prod. So this body is
-- 20260802030000_user_reflections_journal_entries.sql VERBATIM — which is itself
-- 20260727100300 verbatim plus the four reflections keys — with exactly two
-- additions, both inside the `built_duas` union: status, answered_at. Nothing
-- else differs; diff this file's function body against that one before touching
-- it, and re-emit the same way from Wave F.
--
-- Shipped clients parse named keys only and ignore unknowns — backward-safe.
-- ---------------------------------------------------------------------------

create or replace function public.sync_all_user_data()
 returns jsonb
 language plpgsql
 stable security definer
 set search_path to 'public'
as $function$
declare
  current_user_id uuid := auth.uid();
  result jsonb;
begin
  if current_user_id is null then
    raise exception 'Not authenticated';
  end if;

  result := jsonb_build_object(
    'xp',
      coalesce(
        (select jsonb_build_object('total_xp', x.total_xp)
         from public.user_xp x where x.user_id = current_user_id),
        jsonb_build_object('total_xp', 0)
      ),
    'tokens',
      coalesce(
        (select jsonb_build_object('balance', t.balance, 'total_spent', t.total_spent, 'tier_up_scrolls', t.tier_up_scrolls)
         from public.user_tokens t where t.user_id = current_user_id),
        jsonb_build_object('balance', 100, 'total_spent', 0, 'tier_up_scrolls', 0)
      ),
    'streak',
      coalesce(
        (select jsonb_build_object('current_streak', s.current_streak, 'longest_streak', s.longest_streak, 'last_active', s.last_active)
         from public.user_streaks s where s.user_id = current_user_id),
        jsonb_build_object('current_streak', 0, 'longest_streak', 0, 'last_active', null)
      ),
    'daily_rewards',
      coalesce(
        (select jsonb_build_object('current_day', r.current_day, 'last_claim_date', r.last_claim_date,
            'streak_freeze_owned', r.streak_freeze_owned, 'streak_freeze_count', r.streak_freeze_count,
            'last_premium_grant_month', r.last_premium_grant_month)
         from public.user_daily_rewards r where r.user_id = current_user_id),
        jsonb_build_object('current_day', 0, 'last_claim_date', null, 'streak_freeze_owned', false,
            'streak_freeze_count', 0, 'last_premium_grant_month', null)
      ),
    'checkin_history',
      coalesce(
        (select jsonb_agg(
          jsonb_build_object('checked_in_at', c.checked_in_at, 'q1', c.q1, 'q2', c.q2, 'q3', c.q3, 'q4', c.q4,
            'name_returned', c.name_returned, 'name_arabic', c.name_arabic)
          order by c.checked_in_at desc)
         from public.user_checkin_history c where c.user_id = current_user_id),
        '[]'::jsonb
      ),
    'reflections',
      coalesce(
        (select jsonb_agg(
          jsonb_build_object('id', r.id, 'saved_at', r.saved_at, 'user_text', r.user_text,
            'name', r.name, 'name_arabic', r.name_arabic, 'reframe_preview', r.reframe_preview,
            'reframe', r.reframe, 'story', r.story, 'verses', r.verses,
            'dua_arabic', r.dua_arabic, 'dua_transliteration', r.dua_transliteration,
            'dua_translation', r.dua_translation, 'dua_source', r.dua_source, 'related_names', r.related_names,
            -- Journaling wave B (the four additions):
            'source', r.source, 'entry_local_day', r.entry_local_day,
            'thread', r.thread, 'azm', r.azm)
          order by r.saved_at desc)
         from public.user_reflections r where r.user_id = current_user_id),
        '[]'::jsonb
      ),
    'built_duas',
      coalesce(
        (select jsonb_agg(
          jsonb_build_object('id', d.id, 'saved_at', d.saved_at, 'need', d.need,
            'arabic', d.arabic, 'transliteration', d.transliteration, 'translation', d.translation,
            -- Journaling wave E (the two additions):
            'status', d.status, 'answered_at', d.answered_at)
          order by d.saved_at desc)
         from public.user_built_duas d where d.user_id = current_user_id),
        '[]'::jsonb
      ),
    'card_collection',
      coalesce(
        (select jsonb_agg(jsonb_build_object('name_id', cc.name_id, 'tier', cc.tier, 'discovered_at', cc.discovered_at,
            'last_engaged_at', cc.last_engaged_at) order by cc.discovered_at asc)
         from public.user_card_collection cc where cc.user_id = current_user_id),
        '[]'::jsonb
      ),
    'profile',
      coalesce(
        (select jsonb_build_object(
            'selected_title', p.selected_title,
            'is_auto_title', p.is_auto_title,
            'created_at', p.created_at,
            'warmup_reflect_remaining', p.warmup_reflect_remaining,
            'warmup_built_dua_remaining', p.warmup_built_dua_remaining,
            'warmup_discover_name_remaining', p.warmup_discover_name_remaining,
            'had_trial', p.had_trial,
            'trial_premium_until', p.trial_premium_until,
            'first_bypass_consumed', p.first_bypass_consumed,
            'display_name', p.display_name,
            'lifetime_bypasses_purchased', p.lifetime_bypasses_purchased,
            'iap_upsell_banner_dismissed_at', p.iap_upsell_banner_dismissed_at,
            'onboarding_paywall_cleared', p.onboarding_paywall_cleared,
            'tour_step_index', p.tour_step_index,
            'acquisition_promise', p.acquisition_promise,
            'first_problem_text', p.first_problem_text,
            'onboarding_flow', p.onboarding_flow,
            'free_tier_cohort', p.free_tier_cohort,
            'weekly_pool_used', p.weekly_pool_used,
            'weekly_pool_week_start', p.weekly_pool_week_start)
         from public.user_profiles p where p.id = current_user_id),
        jsonb_build_object(
          'selected_title', null,
          'is_auto_title', true,
          'created_at', null,
          'warmup_reflect_remaining', 10,
          'warmup_built_dua_remaining', 10,
          'warmup_discover_name_remaining', 5,
          'had_trial', false,
          'trial_premium_until', null,
          'first_bypass_consumed', false,
          'display_name', 'Friend',
          'lifetime_bypasses_purchased', 0,
          'iap_upsell_banner_dismissed_at', null,
          'onboarding_paywall_cleared', null,
          'tour_step_index', null,
          'acquisition_promise', null,
          'first_problem_text', null,
          'onboarding_flow', null,
          'free_tier_cohort', null,
          'weekly_pool_used', 0,
          'weekly_pool_week_start', null)
      ),
    'achievements',
      coalesce(
        (select jsonb_agg(jsonb_build_object('achievement_id', a.achievement_id, 'unlocked_at', a.unlocked_at) order by a.unlocked_at desc)
         from public.user_achievements a where a.user_id = current_user_id),
        '[]'::jsonb
      ),
    'discovery_results',
      (select jsonb_build_object('anchor_names', d.anchor_names)
       from public.user_discovery_results d where d.user_id = current_user_id),
    'daily_usage',
      coalesce(
        (select jsonb_agg(jsonb_build_object('usage_date', u.usage_date, 'reflect_uses', u.reflect_uses,
            'built_dua_uses', u.built_dua_uses, 'discover_name_uses', u.discover_name_uses,
            'reflect_bypasses_used', u.reflect_bypasses_used, 'built_dua_bypasses_used', u.built_dua_bypasses_used,
            'discover_name_bypasses_used', u.discover_name_bypasses_used) order by u.usage_date desc)
         from public.user_daily_usage u where u.user_id = current_user_id
           and u.usage_date between timezone('utc', now())::date - 1 and timezone('utc', now())::date + 1),
        '[]'::jsonb
      ),
    'daily_answers',
      coalesce(
        (select jsonb_agg(jsonb_build_object('answered_at', da.answered_at, 'question_id', da.question_id,
            'selected_option', da.selected_option, 'name_returned', da.name_returned, 'name_arabic', da.name_arabic,
            'teaching', da.teaching, 'dua_arabic', da.dua_arabic, 'dua_transliteration', da.dua_transliteration,
            'dua_translation', da.dua_translation) order by da.answered_at desc)
         from public.user_daily_answers da where da.user_id = current_user_id
           and da.answered_at::date between timezone('utc', now())::date - 1 and timezone('utc', now())::date),
        '[]'::jsonb
      ),
    'quest_progress',
      coalesce(
        (select jsonb_agg(jsonb_build_object('quest_id', q.quest_id, 'cadence', q.cadence, 'progress', q.progress,
            'completed', q.completed, 'period_start', q.period_start, 'updated_at', q.updated_at) order by q.updated_at desc)
         from public.user_quest_progress q where q.user_id = current_user_id),
        '[]'::jsonb
      )
  );

  -- Cosmetics-economy sections (additive) — reproduced verbatim from the
  -- lantern branch's 20260726000300_sync_cosmetics_sections.sql (see header).
  result := result
    || jsonb_build_object('noor', (
         select jsonb_build_object(
           'balance', noor_balance,
           'total_earned', noor_total_earned,
           'total_spent', noor_total_spent)
         from public.user_profiles where id = current_user_id))
    || jsonb_build_object('equipped', (
         select jsonb_build_object(
           'lantern_skin', equipped_lantern_skin,
           'backdrop', equipped_backdrop)
         from public.user_profiles where id = current_user_id))
    || jsonb_build_object('cosmetics', coalesce((
         select jsonb_agg(jsonb_build_object(
           'item_type', item_type,
           'item_id', item_id,
           'acquired_via', acquired_via))
         from public.user_cosmetics where user_id = current_user_id), '[]'::jsonb));

  return result;
end;
$function$;

grant execute on function public.sync_all_user_data() to authenticated;
