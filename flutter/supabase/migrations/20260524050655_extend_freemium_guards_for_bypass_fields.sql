-- 2026-05-24: Extend freemium guards to cover AI-bypass counters.
--
-- Background:
--   PRs #20-#24 (the 2026-05-23 ai-bypass-token-spend feature) added 3 new
--   columns to user_daily_usage and 2 new columns to user_profiles that all
--   participate in freemium gating:
--
--     user_daily_usage
--       reflect_bypasses_used         monotonic non-decreasing (cap = 2/day)
--       built_dua_bypasses_used       monotonic non-decreasing
--       discover_name_bypasses_used   monotonic non-decreasing
--
--     user_profiles
--       first_bypass_consumed         one-way latch (false -> true only)
--       lifetime_bypasses_purchased   monotonic non-decreasing
--
--   The existing freemium guards in
--   20260510010000_lock_freemium_gating_fields.sql were not extended in PR
--   #20, leaving these 5 columns updatable by any authenticated user against
--   their own row (RLS permits self-row UPDATE).
--
-- Threat model (verified live on prod 2026-05-24):
--   * Reset reflect_bypasses_used / built_dua_bypasses_used /
--     discover_name_bypasses_used -> defeat the 2-bypass-per-day cap, become
--     unlimited per day given enough tokens (purchasable IAP).
--   * Flip first_bypass_consumed true -> false -> re-claim the Day-1 freebie
--     every 24h forever.
--   * Decrement lifetime_bypasses_purchased -> never trigger the IAP -> sub
--     upsell banner (EXP-3), and hide spend from product analytics.
--
-- Fix:
--   Extend both BEFORE UPDATE trigger functions to enforce the same
--   monotonicity rules. Service-role bypass preserved verbatim from the
--   original migration. Honest increment paths (commit_ai_bypass,
--   claim_first_bypass, reserve_ai_bypass, cancel_ai_bypass) all run as
--   SECURITY DEFINER owned by `postgres` (verified via pg_proc.proowner),
--   so current_user inside those functions is `postgres` which is in the
--   bypass list -- they continue to work unchanged. Pinned by
--   supabase/tests/freemium_guards_bypass_fields_test.sql TEST 8.

create or replace function public.guard_user_daily_usage_freemium_fields()
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
  if new.reflect_uses < old.reflect_uses then
    raise exception
      'cannot reset/refill freemium gating field: reflect_uses (% -> %)',
      old.reflect_uses, new.reflect_uses
      using errcode = 'check_violation';
  end if;

  if new.built_dua_uses < old.built_dua_uses then
    raise exception
      'cannot reset/refill freemium gating field: built_dua_uses (% -> %)',
      old.built_dua_uses, new.built_dua_uses
      using errcode = 'check_violation';
  end if;

  if new.discover_name_uses < old.discover_name_uses then
    raise exception
      'cannot reset/refill freemium gating field: discover_name_uses (% -> %)',
      old.discover_name_uses, new.discover_name_uses
      using errcode = 'check_violation';
  end if;

  -- New rules (2026-05-24 — this migration)
  if new.reflect_bypasses_used < old.reflect_bypasses_used then
    raise exception
      'cannot reset/refill freemium gating field: reflect_bypasses_used (% -> %)',
      old.reflect_bypasses_used, new.reflect_bypasses_used
      using errcode = 'check_violation';
  end if;

  if new.built_dua_bypasses_used < old.built_dua_bypasses_used then
    raise exception
      'cannot reset/refill freemium gating field: built_dua_bypasses_used (% -> %)',
      old.built_dua_bypasses_used, new.built_dua_bypasses_used
      using errcode = 'check_violation';
  end if;

  if new.discover_name_bypasses_used < old.discover_name_bypasses_used then
    raise exception
      'cannot reset/refill freemium gating field: discover_name_bypasses_used (% -> %)',
      old.discover_name_bypasses_used, new.discover_name_bypasses_used
      using errcode = 'check_violation';
  end if;

  return new;
end
$$;

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

  -- New rules (2026-05-24 — this migration)
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

  return new;
end
$$;

-- Triggers themselves are unchanged (re-use existing names + bindings).
-- The CREATE OR REPLACE FUNCTION above swaps out the body atomically.
