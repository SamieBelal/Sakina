-- 2026-08-02: the nightly muḥāsabah becomes a durable journal entry.
-- Plan: docs/superpowers/plans/2026-08-02-journaling-and-name-mastery-plan.md §B1
-- Design: docs/superpowers/specs/2026-08-02-journaling-and-name-mastery-design.md §4
--
-- Until now a completed muḥāsabah left NO artifact: `user_checkin_history`
-- carries no answer text (the discover path writes q1='discover' with q2-q4
-- empty) and the AI reflection was never persisted at all — the user's own
-- words survived only in a device-local per-day SharedPreferences blob.
--
-- We reuse `user_reflections` rather than adding a table (design §4): it
-- already has `user_text`, `name`, `name_arabic`, `verses`, the four `dua_*`
-- columns, `related_names` and `beat_data`, plus RLS, length caps and a
-- `sync_all_user_data()` union. Four columns tell the two kinds of row apart
-- and give the night somewhere to grow:
--
--   source          'reflect' (the Reflect feature) | 'muhasabah' (the night)
--   entry_local_day the user's LOCAL calendar day — NOT saved_at. The streak,
--                   the launch gate and the reward ladder all key on a day
--                   boundary; a timestamp disagrees with them near midnight
--                   (see launch_gate_state.dart:14-22 for the same bug class).
--   thread          Wave C's "add to tonight" appends: [{at, text}, ...]
--   azm             Wave C's one line of forward resolve
--
-- Length / shape caps follow 20260524164841 (length caps) and
-- 20260714000000 + 20260715000000 (beat_data shape + hardening) EXACTLY:
-- client-side clamps do not apply to a hand-crafted PostgREST insert, so
-- unbounded user text inside a jsonb array is precisely the storage-abuse hole
-- those migrations exist to close.

alter table public.user_reflections
  add column if not exists source text not null default 'reflect',
  add column if not exists entry_local_day date,
  add column if not exists thread jsonb not null default '[]'::jsonb,
  add column if not exists azm text;

-- Two values, and only two. A third would silently escape every `source =`
-- predicate the journal, the time machine and the unique index below rely on.
alter table public.user_reflections drop constraint if exists user_reflections_source_check;
alter table public.user_reflections add constraint user_reflections_source_check
  check (source in ('reflect', 'muhasabah'));

-- `azm` is one short line of forward resolve. 500 chars is ~5x any honest one
-- and rejects the blob class, matching the 20260524164841 sizing rationale.
alter table public.user_reflections drop constraint if exists user_reflections_azm_length_cap;
alter table public.user_reflections add constraint user_reflections_azm_length_cap
  check (length(coalesce(azm, '')) <= 500);

-- Top-level type + element-count cap for `thread`. The per-element validator
-- below is a trigger for the same reason verses[] is: a CHECK cannot loop.
alter table public.user_reflections drop constraint if exists user_reflections_thread_array_cap;
alter table public.user_reflections add constraint user_reflections_thread_array_cap
  check (
    jsonb_typeof(thread) = 'array'
    and jsonb_array_length(thread) <= 20
  );

-- Per-append shape validator. Each thread[] element MUST be an object with a
-- string `text` (<= 2048, the same cap `user_text` carries — an append is the
-- same kind of writing as the answer) and an optional string `at` (an ISO
-- instant). Unknown keys are rejected outright, mirroring the beat_data
-- hardening (20260715000000): without a key whitelist an authenticated client
-- can park an arbitrarily large blob under a key nothing reads.
create or replace function public._validate_user_reflections_thread_shape()
returns trigger language plpgsql security invoker set search_path = public, pg_temp as $$
declare v_entry jsonb;
begin
  if new.thread is not null and jsonb_typeof(new.thread) = 'array' then
    -- Total-size backstop. 20 appends x 2048 chars is ~40KB of legitimate
    -- worst case; 48KB is the headroom above it and nothing more.
    if pg_column_size(new.thread) > 49152 then
      raise exception 'user_reflections.thread exceeds size cap'
        using errcode = 'check_violation';
    end if;

    for v_entry in select jsonb_array_elements(new.thread) loop
      if jsonb_typeof(v_entry) <> 'object' then
        raise exception 'user_reflections.thread[] element must be an object: %', v_entry
          using errcode = 'check_violation';
      end if;

      if exists (
        select 1 from jsonb_object_keys(v_entry) k where k not in ('at', 'text')
      ) then
        raise exception 'user_reflections.thread[] element has unexpected keys: %', v_entry
          using errcode = 'check_violation';
      end if;

      if jsonb_typeof(v_entry->'text') <> 'string'
         or length(v_entry->>'text') > 2048 then
        raise exception 'user_reflections.thread[] element fails text validation: %', v_entry
          using errcode = 'check_violation';
      end if;

      if v_entry ? 'at'
         and (jsonb_typeof(v_entry->'at') <> 'string'
              or length(v_entry->>'at') > 64) then
        raise exception 'user_reflections.thread[] element fails at validation: %', v_entry
          using errcode = 'check_violation';
      end if;
    end loop;
  end if;
  return new;
end $$;

drop trigger if exists user_reflections_thread_shape on public.user_reflections;
create trigger user_reflections_thread_shape
  before insert or update on public.user_reflections
  for each row execute function public._validate_user_reflections_thread_shape();

-- ONE muḥāsabah row per user per LOCAL day.
--
-- This is the idempotency guarantee, not a nicety: `completeDeeper()` writes
-- best-effort and may be replayed (a retry, a cold restart, a second entry
-- path), and the row must neither duplicate nor overwrite. It is also the key
-- the Wave C time machine joins on (entry_local_day - 30 / -90 / -365).
-- Partial, so 'reflect' rows — which have no local day and are unlimited per
-- day — are untouched.
create unique index if not exists uniq_muhasabah_per_local_day
  on public.user_reflections (user_id, entry_local_day)
  where source = 'muhasabah';

-- Supports both the journal's per-source feed and the time machine's exact-day
-- lookup without a sequential scan over a daily journaler's ~365 rows a year.
create index if not exists idx_reflections_user_source_day
  on public.user_reflections (user_id, source, entry_local_day desc);

-- ---------------------------------------------------------------------------
-- sync_all_user_data() — RE-EMITTED AS A SUPERSET of 20260727100300.
--
-- ⚠️ This function has collided once already (20260726000300 vs
-- 20260727100300): whichever CREATE OR REPLACE runs last wins, and version
-- order on a fresh reset differs from wall-clock order in prod. So this body is
-- 20260727100300_sync_one_ship_profile_keys.sql VERBATIM — the six W1 profile
-- keys AND the lantern noor/equipped/cosmetics unions — with exactly four
-- additions, all inside the `reflections` union: source, entry_local_day,
-- thread, azm. Nothing else differs; diff this file's function body against
-- that one before touching it, and re-emit the same way from Wave E and F.
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
