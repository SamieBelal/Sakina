-- 2026-05-25: Extend freemium guard to cover gift_premium_until.
--
-- Background:
--   PR #17 (the Ramadan / Eid Sakina Gift feature) added a new column
--   `user_profiles.gift_premium_until` whose value drives premium entitlement
--   in `PurchaseService.isPremium()` via the `_isGiftPremium()` check. The
--   freemium guard `guard_user_profiles_freemium_fields` was not extended in
--   that PR — it couldn't be, since the column didn't exist on master until
--   PR #17 merged.
--
-- Threat model (verified live on prod 2026-05-24, recorded in
--   docs/qa/findings/2026-05-24-ai-bypass-p1-p2-review.md §P1-3):
--
--   Step | Actor                              | Call                                                                                  | Result
--   -----|------------------------------------|---------------------------------------------------------------------------------------|---------
--    1   | Victim (JWT, role=authenticated)   | `update user_profiles set gift_premium_until = '2999-01-01' where id = auth.uid()`    | succeeds
--    2   | Post-state                         | -                                                                                     | 977 years of free premium with no payment
--
--   The risk amplifier is that `gift_premium_until` is consulted directly by
--   entitlement-check code paths (`_isGiftPremium` in purchase_service.dart),
--   so the bypass is immediate — no cron tick required, no other state to
--   manipulate.
--
-- Fix:
--   Mirror the existing `referral_premium_until` clause shape in the
--   `guard_user_profiles_freemium_fields()` trigger function. Authenticated
--   users can no longer write to the column directly; the only legitimate
--   writer is the SECURITY DEFINER RPC `claim_sakina_gift` (owned by
--   `postgres`, so `current_user` inside it matches the guard's bypass
--   list, and its honest UPDATE goes through unaffected).
--
-- Verified live during this PR via Supabase MCP:
--   * Authenticated UPDATE on gift_premium_until → check_violation raised.
--   * claim_sakina_gift() → still grants and stamps the column.

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

  -- New rule (2026-05-25 — this migration)
  if new.gift_premium_until is distinct from old.gift_premium_until then
    raise exception
      'cannot modify gift_premium_until directly; must go through SECURITY DEFINER RPC (claim_sakina_gift)'
      using errcode = 'check_violation';
  end if;

  return new;
end
$$;

-- Trigger itself is unchanged (re-uses existing binding). CREATE OR REPLACE
-- FUNCTION above swaps out the body atomically.
