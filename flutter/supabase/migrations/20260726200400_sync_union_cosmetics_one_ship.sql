-- Union of two independently-authored re-emits of public.sync_all_user_data().
--
-- WHAT THIS UNIONS
--   * 20260726200300_sync_one_ship_profile_keys.sql (PR #62 / One Ship W1
--     Migration D) — all base sections plus six keys added to BOTH the
--     populated and fallback `profile` objects: acquisition_promise,
--     first_problem_text, onboarding_flow, free_tier_cohort,
--     weekly_pool_used, weekly_pool_week_start. (weekly_pool_reset_at stays
--     server-internal and is deliberately NOT exposed.)
--   * 20260726000300_sync_cosmetics_sections.sql (PR #61 / lantern cosmetics)
--     — the three cosmetics-economy sections: noor, equipped, cosmetics.
--
-- WHY
--   sync_all_user_data() is a single monolithic function, so each PR shipped a
--   full `create or replace` re-emitted from the same older base
--   (20260722000000_streak_freeze_premium_tier.sql §6). Migrations apply in
--   timestamp order, so 20260726200300 (One Ship) lands AFTER 20260726000300
--   (cosmetics) and its body — built from the pre-cosmetics base — silently
--   drops noor/equipped/cosmetics. That clobber already happened on the local
--   DB. This migration restores both lineages in one definition.
--
-- ORDERING
--   This file MUST sort AFTER 20260726200300 (hence 20260726200400). If either
--   PR's timestamp changes on rebase, re-check that this is still last.
--
-- FUTURE RE-EMITS
--   Any future `create or replace` of sync_all_user_data() MUST carry ALL
--   sections from BOTH lineages — every base section, the six One-Ship profile
--   keys in both profile objects, and the three cosmetics sections. Diff
--   against this file, not against an older migration.
--   supabase/tests/sync_union_sections_test.sql pins the full key set; run it
--   after any change to this function.
--
-- PRE-APPLY SAFETY (the step both PRs use)
--   Immediately before applying to prod, re-diff the live definition:
--     select pg_get_functiondef('public.sync_all_user_data()'::regprocedure);
--   against the base this file was built from, to confirm no third re-emit
--   landed in between.
--
-- Signature / returns jsonb / language plpgsql / stable / security definer /
-- search_path and every section expression are preserved byte-for-byte from
-- their source migrations; only the section LIST is combined.

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
            -- One-Ship (PR #62) columns, read via to_jsonb so this migration is
            -- MERGE-ORDER INDEPENDENT. The columns are created by #62's
            -- 20260726200200_free_tier_cohort_weekly_pool.sql, which is NOT on
            -- this branch. A direct `p.acquisition_promise` reference compiles
            -- fine (plpgsql resolves columns at RUNTIME, not at CREATE) and then
            -- raises undefined_column on EVERY call — i.e. total sync failure —
            -- if this branch merges first. `to_jsonb(p) -> 'key'` instead yields
            -- SQL NULL for an absent column, and null is exactly #62's
            -- documented "NULL predates activation" legacy signal.
            'acquisition_promise', to_jsonb(p) -> 'acquisition_promise',
            'first_problem_text', to_jsonb(p) -> 'first_problem_text',
            'onboarding_flow', to_jsonb(p) -> 'onboarding_flow',
            'free_tier_cohort', to_jsonb(p) -> 'free_tier_cohort',
            'weekly_pool_used', to_jsonb(p) -> 'weekly_pool_used',
            'weekly_pool_week_start', to_jsonb(p) -> 'weekly_pool_week_start')
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

  -- Cosmetics-economy sections (additive).
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
