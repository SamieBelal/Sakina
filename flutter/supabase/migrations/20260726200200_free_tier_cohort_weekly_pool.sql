-- One Ship W1 / Migration C — cohort assignment, weekly pool, guard extension
-- (docs/superpowers/plans/2026-07-26-one-ship-01-data-layer.md §Migration C)
--
-- Design rule (review blockers F1/F2): no economy math on client-asserted
-- inputs. The cohort is SERVER-assigned in handle_new_user; the weekly pool
-- resets monotonically with a wall-clock anchor so no timezone choreography
-- can manufacture a reset.

-- 1. Columns -----------------------------------------------------------------

alter table public.user_profiles
  add column if not exists acquisition_promise     jsonb
    check (acquisition_promise is null or acquisition_promise ? 'contract'),
  add column if not exists first_problem_text      text,
  add column if not exists onboarding_flow         text
    check (onboarding_flow is null or onboarding_flow in ('reel_v1','legacy')),
  add column if not exists free_tier_cohort        text
    check (free_tier_cohort is null or free_tier_cohort in ('reel_v1','legacy')),
  add column if not exists weekly_pool_used        int not null default 0
    check (weekly_pool_used >= 0),
  add column if not exists weekly_pool_week_start  date,
  add column if not exists weekly_pool_reset_at    timestamptz,
  add column if not exists softener_notice_ends_at timestamptz;

comment on column public.user_profiles.acquisition_promise is
  'Canonical reel-arrival payload {reel_id?, hook_type, contract, problem_category?} (§V6.8). Client-written during onboarding; frozen once onboarding_completed.';
comment on column public.user_profiles.free_tier_cohort is
  'Which free-tier LIMITS apply. SERVER-assigned in handle_new_user from app_config.new_signup_cohort; never client-writable. NULL = account predates cohort activation (legacy limits).';
comment on column public.user_profiles.onboarding_flow is
  'Which onboarding EXPERIENCE the user went through (reel_v1 | legacy). Client-written during onboarding; frozen once onboarding_completed. Segmentation + tour suppression key.';

-- 2. app_config dials (seed BEFORE handle_new_user reads them) ---------------
-- new_signup_cohort stays 'legacy' until T0 release day (runbook flip →
-- 'reel_v1'). Flipping early would stamp 3/3 warmups on signups still using
-- the shipped app — a silent user-facing change (one-change-at-a-time).
-- If the reel_first_onboarding_enabled kill switch is ever flipped off
-- post-T0, flip new_signup_cohort back to 'legacy' in the same action.

insert into public.app_config (key, value) values
  ('weekly_pool_size', '3'),
  ('warmup_reflect_size', '3'),
  ('warmup_built_dua_size', '3'),
  ('new_signup_cohort', '"legacy"'),
  ('reel_first_onboarding_enabled', 'true')
on conflict (key) do nothing;

-- 3. handle_new_user — server-assigned cohort (review F2) ---------------------
-- Re-emitted from the prod-verified body (pre-flight diff 2026-07-26: prod ==
-- repo 20260416090000). New: free_tier_cohort stamped from config; reel_v1
-- signups get warmup 3/3 AT INSERT (unconditional — not contingent on any
-- client write, which was the F2 hole).

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_cohort text;
begin
  select value #>> '{}' into v_cohort
  from public.app_config where key = 'new_signup_cohort';
  if v_cohort is null or v_cohort not in ('reel_v1', 'legacy') then
    v_cohort := 'legacy';
  end if;

  if v_cohort = 'reel_v1' then
    insert into public.user_profiles
      (id, display_name, free_tier_cohort,
       warmup_reflect_remaining, warmup_built_dua_remaining)
    values
      (new.id, new.raw_user_meta_data->>'full_name', 'reel_v1',
       coalesce((select (value::text)::int from public.app_config
                 where key = 'warmup_reflect_size'), 3),
       coalesce((select (value::text)::int from public.app_config
                 where key = 'warmup_built_dua_size'), 3));
  else
    insert into public.user_profiles (id, display_name, free_tier_cohort)
    values (new.id, new.raw_user_meta_data->>'full_name', 'legacy');
  end if;

  insert into public.user_streaks (user_id) values (new.id);
  insert into public.user_xp (user_id) values (new.id);
  insert into public.user_tokens (user_id) values (new.id);
  insert into public.user_daily_rewards (user_id) values (new.id);
  insert into public.user_notification_preferences (user_id) values (new.id);
  return new;
end;
$$;

-- 4. Guard extension ----------------------------------------------------------
-- Re-emitted verbatim from 20260616204630 (pre-flight diff 2026-07-26: prod ==
-- repo) with the One Ship clauses appended. Trigger binding unchanged.

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

  -- Existing rule from 20260616204630_reverse_trial_backend
  if new.trial_premium_until is distinct from old.trial_premium_until then
    raise exception
      'cannot modify trial_premium_until directly; must go through SECURITY DEFINER RPC (activate_trial)'
      using errcode = 'check_violation';
  end if;

  -- New rules (2026-07-26 one-ship-01-data-layer) -----------------------------

  -- RPC-only columns: any non-exempt-role change raises.
  if new.free_tier_cohort is distinct from old.free_tier_cohort then
    raise exception
      'cannot modify free_tier_cohort; server-assigned (handle_new_user / softener wave) only'
      using errcode = 'check_violation';
  end if;
  if new.weekly_pool_used is distinct from old.weekly_pool_used then
    raise exception
      'cannot modify weekly_pool_used; must go through SECURITY DEFINER RPC (consume_weekly_allowance)'
      using errcode = 'check_violation';
  end if;
  if new.weekly_pool_week_start is distinct from old.weekly_pool_week_start then
    raise exception
      'cannot modify weekly_pool_week_start; must go through SECURITY DEFINER RPC (consume_weekly_allowance)'
      using errcode = 'check_violation';
  end if;
  if new.weekly_pool_reset_at is distinct from old.weekly_pool_reset_at then
    raise exception
      'cannot modify weekly_pool_reset_at; must go through SECURITY DEFINER RPC (consume_weekly_allowance)'
      using errcode = 'check_violation';
  end if;
  if new.softener_notice_ends_at is distinct from old.softener_notice_ends_at then
    raise exception
      'cannot modify softener_notice_ends_at; softener-wave script only'
      using errcode = 'check_violation';
  end if;

  -- Freeze-after-completion (NOT naive write-once: persistOnboardingToSupabase
  -- runs 2-4x per signup with swallowed errors — same-value re-sends and
  -- back-nav edits during onboarding must pass; post-onboarding rewrites raise).
  if old.onboarding_completed = true
     and new.acquisition_promise is distinct from old.acquisition_promise then
    raise exception 'cannot modify acquisition_promise after onboarding completion'
      using errcode = 'check_violation';
  end if;
  if old.onboarding_completed = true
     and new.onboarding_flow is distinct from old.onboarding_flow then
    raise exception 'cannot modify onboarding_flow after onboarding completion'
      using errcode = 'check_violation';
  end if;

  return new;
end
$$;

-- 5. consume_weekly_allowance -------------------------------------------------
-- Server authority for the 3-combined weekly pool (Reflect + Build-a-Dua).
-- Reset is (a) MONOTONIC: only a strictly LATER local Monday counts — hopping
-- "back" across the dateline can never reset; and (b) WALL-CLOCK ANCHORED:
-- at most one reset per >=6 real days regardless of timezone choreography
-- (review F1). Initialization (first-ever call) stamps week_start WITHOUT the
-- anchor so an honest first week still resets on its first real Monday.
-- No refund path by design (founder decision 2026-07-26): a consumed use that
-- errors client-side is eaten, matching the warmup posture.

create or replace function public.consume_weekly_allowance(p_feature text)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid         uuid := auth.uid();
  v_tz          text;
  v_week_local  date;
  v_used        int;
  v_stored_week date;
  v_reset_at    timestamptz;
  v_pool        int;
begin
  if v_uid is null then
    raise exception 'consume_weekly_allowance: not authenticated'
      using errcode = 'insufficient_privilege';
  end if;
  if p_feature not in ('reflect', 'built_dua') then
    raise exception 'consume_weekly_allowance: invalid feature % (discover_name is never pooled)', p_feature
      using errcode = 'check_violation';
  end if;

  select weekly_pool_used, weekly_pool_week_start, weekly_pool_reset_at
  into v_used, v_stored_week, v_reset_at
  from public.user_profiles
  where id = v_uid
  for update;

  if not found then
    raise exception 'consume_weekly_allowance: no profile row'
      using errcode = 'no_data_found';
  end if;

  v_tz         := public.safe_user_tz(v_uid);
  v_week_local := (date_trunc('week', now() at time zone v_tz))::date; -- ISO Monday

  if v_stored_week is null then
    -- first-ever call: initialize, no anchor stamp (used is 0 already)
    v_stored_week := v_week_local;
  elsif v_week_local > v_stored_week
        and (v_reset_at is null or now() - v_reset_at >= interval '6 days') then
    v_used        := 0;
    v_stored_week := v_week_local;
    v_reset_at    := now();
  end if;

  v_pool := coalesce((select (value::text)::int from public.app_config
                      where key = 'weekly_pool_size'), 3);

  if v_used >= v_pool then
    update public.user_profiles
    set weekly_pool_used       = v_used,
        weekly_pool_week_start = v_stored_week,
        weekly_pool_reset_at   = v_reset_at
    where id = v_uid;
    return jsonb_build_object(
      'allowed', false, 'remaining', 0, 'week_start', v_stored_week);
  end if;

  v_used := v_used + 1;
  update public.user_profiles
  set weekly_pool_used       = v_used,
      weekly_pool_week_start = v_stored_week,
      weekly_pool_reset_at   = v_reset_at
  where id = v_uid;

  return jsonb_build_object(
    'allowed', true, 'remaining', v_pool - v_used, 'week_start', v_stored_week);
end
$$;

revoke execute on function public.consume_weekly_allowance(text) from public, anon;
grant execute on function public.consume_weekly_allowance(text) to authenticated;
