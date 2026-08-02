-- Softener wave step 2 — flip expired-notice users to the reel_v1 tier (§V6.10)
-- STAGED: run >=30 days after softener_1_notice. See README.md.
--
-- ⚠️ SUPERSEDED for the free-tier migration by `t0_flip_all_to_reel_v1.sql`
-- (D12, 2026-08-01). Two reasons this script cannot do the job any more:
--   1. Its `softener_notice_ends_at` gate is never stamped under D12, so it
--      matches ZERO rows.
--   2. It clamps only reflect and built_dua — `warmup_discover_name_remaining`
--      is missing, and would stay on the legacy default of 5.
-- Kept for the currency-merge wave. Fix (2) before reviving it.

do $$
begin
  if current_user not in ('postgres', 'service_role', 'supabase_admin') then
    raise exception 'softener_2_flip must run as an exempt role (got %); the freemium guard would half-block it', current_user;
  end if;
end $$;

update public.user_profiles
set free_tier_cohort           = 'reel_v1',
    warmup_reflect_remaining   = least(warmup_reflect_remaining, 3),
    warmup_built_dua_remaining = least(warmup_built_dua_remaining, 3),
    weekly_pool_used           = 0,
    weekly_pool_week_start     = null,
    weekly_pool_reset_at       = null
where free_tier_cohort is distinct from 'reel_v1'
  and softener_notice_ends_at is not null
  and softener_notice_ends_at <= now();
