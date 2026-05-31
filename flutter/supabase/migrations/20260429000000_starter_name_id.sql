-- Single-Name continuity (spec 2026-04-29):
-- Replace the unused `resonant_name_id` (text) with `starter_name_id` (int FK
-- → collectible_names.id). The starter Name is chosen on the first check-in
-- screen and seeded into user_card_collection at onboarding completion.
--
-- Drops `resonant_name_id` (the legacy text column that auth_service.dart was
-- writing to — silently failing on every onboarding completion). Also drops
-- `resonant_name_slug` defensively in case any environment still has it from
-- the abandoned 2026-04-18 migration. Per CLAUDE.md no production users exist
-- so a clean drop is safe.
--
-- The unique constraint on user_card_collection (user_id, name_id) needed for
-- seedStarterCard's idempotent upsert is already in place from
-- 20260409193219_add_user_card_collection_unique_constraint, so this
-- migration does not touch it.

alter table public.user_profiles
  drop column if exists resonant_name_slug,
  drop column if exists resonant_name_id;

alter table public.user_profiles
  add column if not exists starter_name_id integer
    references public.collectible_names(id) on delete set null;

comment on column public.user_profiles.starter_name_id is
  'Onboarding: catalog id of the Name surfaced on the first check-in. Seeded into user_card_collection at onboarding completion. Stable across the user lifetime.';
