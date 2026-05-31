-- 2026-05-10: Drop redundant RLS policies + duplicate indexes flagged
-- by Supabase advisor (lints 0006 multiple_permissive_policies, 0009
-- duplicate_index). Each removal is a strict subset of an existing
-- policy/index — no behavior change for callers.

-- A. Catalog tables: anon+auth "Anyone can read" policies already cover
-- authenticated SELECT. Drop the duplicate auth-only mirrors so Postgres
-- only OR-evaluates one permissive policy per row.
drop policy if exists "Authenticated can read duas"         on public.browse_duas;
drop policy if exists "Authenticated can read collectibles" on public.collectible_names;
drop policy if exists "Authenticated can read questions"    on public.daily_questions;
drop policy if exists "Authenticated can read quiz"         on public.discovery_quiz_questions;
drop policy if exists "Authenticated can read anchors"      on public.name_anchors;

-- B. user_notification_preferences: legacy "Users can read..." policy
-- (role public, unwrapped auth.uid()) duplicates the optimized
-- "Users can view..." policy (role authenticated, (select auth.uid())).
-- Dropping it also resolves the auth_rls_initplan warning on this table,
-- since the surviving policy already uses the optimized initplan form.
drop policy if exists "Users can read own notification preferences"
  on public.user_notification_preferences;

-- C. user_card_collection: drop the duplicate unique on (user_id, name_id)
-- and the redundant non-unique covering index on the same columns.
--
-- user_card_collection_user_name_unique is backed by a UNIQUE constraint
-- (verified via pg_constraint.contype='u'), so it must be dropped via
-- ALTER TABLE ... DROP CONSTRAINT — a bare `drop index` would fail with
-- "cannot drop index ... because constraint ... requires it".
--
-- The surviving user_card_collection_user_id_name_id_key (also constraint-
-- backed) preserves the uniqueness invariant. The non-unique
-- idx_collection_user_name is a strict subset of either unique index for
-- planner selectivity — pure write overhead, safe to drop.
alter table public.user_card_collection
  drop constraint if exists user_card_collection_user_name_unique;

drop index if exists public.idx_collection_user_name;
