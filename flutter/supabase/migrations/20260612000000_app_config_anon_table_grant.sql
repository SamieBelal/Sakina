-- 2026-06-12: grant table-level SELECT on public.app_config to anon (and
-- authenticated, for symmetry with its read policy).
--
-- 20260529030441_app_config_anon_read.sql added an RLS *policy* allowing the
-- anon role to read app_config, but RLS policies only filter rows AFTER the
-- role already holds the table-level SELECT privilege. Without an explicit
-- GRANT, anon's access depends on Postgres default privileges, which is
-- order-sensitive in an ephemeral `supabase start` stack — so the pgtap test
-- supabase/tests/00041_app_config_onboarding_flags.sql flakes with
-- "permission denied for table app_config" when anon never received the
-- table grant. Making the grant explicit removes the flake and guarantees
-- the kill-switch flags (onboarding_trim_enabled, guided_tour_enabled) are
-- readable pre-auth as intended.
--
-- Read-only: writes stay locked to the service role (no anon/authenticated
-- insert/update/delete policy exists). Idempotent — re-granting is a no-op.

grant select on public.app_config to anon, authenticated;
