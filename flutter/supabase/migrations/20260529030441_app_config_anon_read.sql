-- 2026-05-28: allow the anon role to SELECT public.app_config.
--
-- Bug C3 (CRITICAL): the existing "Authenticated can read app_config" policy
-- (20260523213854_ai_bypass_reservations_and_rpcs.sql) is scoped `to authenticated`
-- only. But the kill-switch feature flags `onboarding_trim_enabled` and
-- `guided_tour_enabled` are read as the ANON role — during onboarding (before
-- sign-up) and in main.dart primeCache at cold launch. On a fresh install the
-- SELECT returns 0 rows under RLS, so the app silently falls back to the
-- hardcoded default (true) and the kill switch can never turn the trim/tour OFF
-- for new installs.
--
-- These are non-secret feature flags (bypass pricing + onboarding/tour toggles),
-- the same public-read posture as the public catalog tables
-- (20260409190000_public_catalog_anon_read.sql). Reads only — writes stay locked
-- to the service role (no insert/update/delete policy exists, so RLS denies all
-- client mutation). Adding an anon SELECT policy is safe and intended.

alter table public.app_config enable row level security;

-- Guarded create so this forward-only migration is idempotent on re-run.
drop policy if exists "Anon can read app_config" on public.app_config;

create policy "Anon can read app_config"
  on public.app_config
  for select
  to anon
  using (true);
