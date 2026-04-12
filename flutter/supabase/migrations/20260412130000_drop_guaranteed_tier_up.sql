-- =============================================================================
-- Drop unused guaranteed_tier_up column from user_daily_rewards
-- =============================================================================
-- This column was defined in 20260407000000_initial_schema.sql but is never
-- read or written by Flutter, RPCs, or server-side grant logic.
-- Tier-up rewards are represented by user_tokens.tier_up_scrolls instead.
-- =============================================================================

alter table public.user_daily_rewards
  drop column if exists guaranteed_tier_up;
