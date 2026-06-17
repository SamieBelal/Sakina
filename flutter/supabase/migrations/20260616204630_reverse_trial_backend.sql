-- 20260616204630_reverse_trial_backend.sql
--
-- Phase B DB backend for the reverse-trial ADR
-- (docs/decisions/2026-06-14-onboarding-paywall-reverse-trial.md → "Code changes"
-- DB section + "Eng-review hardening" #5).
--
-- Adds a server-authoritative 3-day reverse trial. Mirrors the existing
-- gift_premium_until / referral_premium_until time-based-premium posture:
--   * a timestamptz window column on user_profiles,
--   * a SECURITY DEFINER RPC (the ONLY legitimate writer), idempotent via
--     GREATEST() so a re-call at the same clock cannot extend the window,
--   * a freemium-guard clause that blocks direct client mutation of the column
--     (otherwise a JWT-bearing user self-grants infinite premium), and
--   * read-back-only exposure in sync_all_user_data() so a reinstall / second
--     device restores the trial window from server truth.
--
-- CRITICAL CORRECTNESS POINT (ADR Eng-review #5 / test G6):
--   sync_all_user_data() must READ trial_premium_until back ONLY. It already
--   never UPDATEs user_profiles from the client payload — it is a pure
--   read aggregator — so adding the column to the `profile` jsonb is safe and
--   does NOT trip the freemium guard. The sole writer is activate_trial
--   (SECURITY DEFINER, owned by postgres, exempt from the guard's check).

-- ---------------------------------------------------------------------------
-- 1. trial_premium_until column on user_profiles
-- ---------------------------------------------------------------------------
-- Fast-lookup window for PurchaseService.isPremium() (OR'd with RC entitlement,
-- referral_premium_until, gift_premium_until). NULL = no trial granted yet.
alter table public.user_profiles
  add column if not exists trial_premium_until timestamptz;

-- ---------------------------------------------------------------------------
-- 2. activate_trial(p_days int) RPC
-- ---------------------------------------------------------------------------
-- SECURITY DEFINER, operates on auth.uid() (no p_user param — the caller can
-- only ever activate their own trial). Idempotent: GREATEST(coalesce(existing,
-- now()), now() + p_days) means a re-call at the same clock returns the same
-- window — it never extends an already-running trial. had_trial is stamped true
-- (irreversible per the guard's existing had_trial clause).
--
-- search_path pinned per 20260510172453_pin_function_search_path posture,
-- mirroring claim_sakina_gift.
create or replace function public.activate_trial(p_days int)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid        uuid := auth.uid();
  v_expires_at timestamptz;
begin
  if v_uid is null then
    return jsonb_build_object('activated', false, 'reason', 'unauthorized');
  end if;

  if p_days is null or p_days <= 0 then
    return jsonb_build_object('activated', false, 'reason', 'invalid_days');
  end if;

  -- Idempotent extend-guard: GREATEST keeps the longer of the existing window
  -- and (now + p_days). Because both operands are computed from the same now(),
  -- a second call inside the same transaction/clock produces an identical
  -- result and cannot push the expiry further out.
  update public.user_profiles
     set trial_premium_until =
           greatest(coalesce(trial_premium_until, now()),
                    now() + make_interval(days => p_days)),
         had_trial = true
   where id = v_uid
   returning trial_premium_until into v_expires_at;

  if not found then
    return jsonb_build_object('activated', false, 'reason', 'no_profile');
  end if;

  return jsonb_build_object(
    'activated', true,
    'trial_premium_until', v_expires_at
  );
end
$$;

-- Execute posture mirrors claim_sakina_gift: functions default-grant EXECUTE to
-- PUBLIC, so revoke from public/anon and grant only to authenticated. The
-- definer body still runs as postgres (the guard-bypass owner).
revoke execute on function public.activate_trial(int) from public;
revoke execute on function public.activate_trial(int) from anon;
grant  execute on function public.activate_trial(int) to authenticated;

-- ---------------------------------------------------------------------------
-- 3. Extend guard_user_profiles_freemium_fields() to cover trial_premium_until
-- ---------------------------------------------------------------------------
-- Mirror the gift_premium_until / referral_premium_until `is distinct from`
-- clauses exactly. Without this, an authenticated user could
--   `update user_profiles set trial_premium_until = '2999-01-01'`
-- and self-grant ~977 years of premium with no payment. The only legitimate
-- writer is activate_trial (SECURITY DEFINER, current_user = postgres inside
-- the body → matches the guard's bypass list, so its honest UPDATE passes).
--
-- Re-emitted verbatim from 20260525200000 with one new clause appended; the
-- trigger binding is unchanged (CREATE OR REPLACE swaps the body atomically).
create or replace function public.guard_user_profiles_freemium_fields()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  if current_user in ('service_role', 'postgres', 'supabase_admin') then
    return new;
  end if;

  -- Existing rules (verbatim from 20260510010000)
  if new.warmup_reflect_remaining > old.warmup_reflect_remaining then
    raise exception 'cannot reset/refill freemium gating field: warmup_reflect_remaining (% -> %)',
      old.warmup_reflect_remaining, new.warmup_reflect_remaining using errcode = 'check_violation';
  end if;
  if new.warmup_built_dua_remaining > old.warmup_built_dua_remaining then
    raise exception 'cannot reset/refill freemium gating field: warmup_built_dua_remaining (% -> %)',
      old.warmup_built_dua_remaining, new.warmup_built_dua_remaining using errcode = 'check_violation';
  end if;
  if new.warmup_discover_name_remaining > old.warmup_discover_name_remaining then
    raise exception 'cannot reset/refill freemium gating field: warmup_discover_name_remaining (% -> %)',
      old.warmup_discover_name_remaining, new.warmup_discover_name_remaining using errcode = 'check_violation';
  end if;
  if old.had_trial = true and new.had_trial = false then
    raise exception 'cannot reset/refill freemium gating field: had_trial (true -> false is forbidden)'
      using errcode = 'check_violation';
  end if;
  if old.referral_code is not null and new.referral_code is distinct from old.referral_code then
    raise exception 'cannot modify referral_code after initial assignment (% -> %)',
      old.referral_code, new.referral_code using errcode = 'check_violation';
  end if;
  if new.referral_premium_until is distinct from old.referral_premium_until then
    raise exception 'cannot modify referral_premium_until directly; must go through SECURITY DEFINER RPC'
      using errcode = 'check_violation';
  end if;

  -- Existing rules from 20260524050655_extend_freemium_guards_for_bypass_fields
  if old.first_bypass_consumed = true and new.first_bypass_consumed = false then
    raise exception
      'cannot reset/refill freemium gating field: first_bypass_consumed (true -> false is forbidden)'
      using errcode = 'check_violation';
  end if;

  if new.lifetime_bypasses_purchased < old.lifetime_bypasses_purchased then
    raise exception
      'cannot reset/refill freemium gating field: lifetime_bypasses_purchased (% -> %)',
      old.lifetime_bypasses_purchased, new.lifetime_bypasses_purchased
      using errcode = 'check_violation';
  end if;

  -- Existing rules from 20260524154019_ai_bypass_p1_security_bundle (P1-3 fix)
  if new.last_winback_grant_at is distinct from old.last_winback_grant_at then
    raise exception 'cannot modify freemium gating field: last_winback_grant_at; must go through SECURITY DEFINER RPC'
      using errcode = 'check_violation';
  end if;
  if new.iap_upsell_banner_dismissed_at is distinct from old.iap_upsell_banner_dismissed_at then
    raise exception 'cannot modify freemium gating field: iap_upsell_banner_dismissed_at; must go through SECURITY DEFINER RPC'
      using errcode = 'check_violation';
  end if;

  -- Existing rule from 20260525200000_extend_freemium_guard_for_gift_premium_until
  if new.gift_premium_until is distinct from old.gift_premium_until then
    raise exception
      'cannot modify gift_premium_until directly; must go through SECURITY DEFINER RPC (claim_sakina_gift)'
      using errcode = 'check_violation';
  end if;

  -- New rule (2026-06-16 — this migration)
  if new.trial_premium_until is distinct from old.trial_premium_until then
    raise exception
      'cannot modify trial_premium_until directly; must go through SECURITY DEFINER RPC (activate_trial)'
      using errcode = 'check_violation';
  end if;

  return new;
end
$$;

-- Trigger binding unchanged (re-uses existing). CREATE OR REPLACE FUNCTION
-- above swapped the body atomically.

-- ---------------------------------------------------------------------------
-- 4. sync_all_user_data(): read trial_premium_until + had_trial back ONLY
-- ---------------------------------------------------------------------------
-- Re-emitted from the newest definition (20260603000000_onboarding_gate_columns)
-- with `trial_premium_until` added to BOTH the populated and the no-row
-- fallback `profile` objects. had_trial is already present. This RPC is a pure
-- read aggregator (no UPDATE of user_profiles), so the column round-trips
-- without ever tripping the freemium guard (ADR Eng-review #5 / test G6).
create or replace function public.sync_all_user_data()
 returns jsonb
 language plpgsql
 stable security definer
 set search_path to 'public'
as $function$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'Not authenticated';
  end if;

  return jsonb_build_object(
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
            'streak_freeze_owned', r.streak_freeze_owned, 'last_premium_grant_month', r.last_premium_grant_month)
         from public.user_daily_rewards r where r.user_id = current_user_id),
        jsonb_build_object('current_day', 0, 'last_claim_date', null, 'streak_freeze_owned', false, 'last_premium_grant_month', null)
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
            'tour_step_index', p.tour_step_index)
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
          'tour_step_index', null)
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
end;
$function$;
