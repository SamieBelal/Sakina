-- =============================================================================
-- First Steps (Beginner Quests)
-- =============================================================================
-- Adds columns to user_profiles to track First Steps quest completion.
-- Eligibility is gated client-side by comparing user_profiles.created_at to
-- the ship date constant in the Flutter app — only accounts created on or
-- after the ship date see the First Steps section.
-- =============================================================================

alter table public.user_profiles
  add column if not exists first_steps_completed text[] not null default '{}',
  add column if not exists first_steps_bundle_claimed boolean not null default false;
