-- One Ship W1 / Migration D — surface the new profile columns via sync
-- (docs/superpowers/plans/2026-07-26-one-ship-01-data-layer.md §Migration D)
--
-- ⚠️ UNION BODY — SUPERSEDES the lantern branch's 20260726000300
-- sync_cosmetics_sections migration (review P1). Both W1 and the lantern
-- cosmetics branch re-emit this function; whichever CREATE OR REPLACE runs
-- last wins, and version order (fresh reset) differs from wall-clock order
-- (prod). This file therefore carries BOTH key sets:
--   * W1: six profile keys (below) in populated + fallback objects
--   * lantern: the noor / equipped / cosmetics sections, reproduced verbatim
--     from feat/lantern-cosmetics 20260726000300 (columns + user_cosmetics
--     table come from 20260726000000_cosmetics_economy.sql, already in master
--     and version-ordered before this file)
-- This file is numbered 20260727* so it sorts AFTER the entire lantern set —
-- a fresh reset always lands this union last. WHEN THE LANTERN PR MERGES:
-- its 20260726000300 must be dropped or re-emitted as this same union,
-- otherwise applying it to prod AFTER this file strips the W1 keys there.
-- The one_ship_w1_data_layer_test asserts both key sets so CI fails loudly
-- if either side is ever dropped.
--
-- Base body re-emitted verbatim from 20260722000000_streak_freeze_premium_tier
-- §6 (pre-flight 2026-07-26: prod == repo via pg_get_functiondef diff; re-diff
-- immediately before applying). W1 keys added to BOTH the populated and
-- fallback profile objects:
--   acquisition_promise, first_problem_text, onboarding_flow,
--   free_tier_cohort, weekly_pool_used, weekly_pool_week_start
-- (weekly_pool_reset_at stays server-internal — the client never needs the
-- anchor, only the mirror counter + week for display.)
-- Shipped clients parse named keys only and ignore unknowns — backward-safe.
-- Fallback cohort/flow are null (= legacy limits), matching the "NULL predates
-- activation" contract; the missing-profile race hands out nothing new.

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
            'dua_translation', r.dua_translation, 'dua_source', r.dua_source, 'related_names', r.related_names)
          order by r.saved_at desc)
         from public.user_reflections r where r.user_id = current_user_id),
        '[]'::jsonb
      ),
    'built_duas',
      coalesce(
        (select jsonb_agg(
          jsonb_build_object('id', d.id, 'saved_at', d.saved_at, 'need', d.need,
            'arabic', d.arabic, 'transliteration', d.transliteration, 'translation', d.translation)
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
