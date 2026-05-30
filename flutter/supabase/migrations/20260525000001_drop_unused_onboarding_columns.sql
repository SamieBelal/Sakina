-- 2026-05-25: onboarding refactor — three columns are no longer captured.
-- The Flutter client stopped writing these in the same release. Forward-only;
-- no rollback (the data was never load-bearing — Mixpanel had a copy of
-- onboarding_quran_connection / common_emotions / aspirations for any
-- retro analysis we still want).
alter table public.user_profiles
  drop column if exists onboarding_quran_connection,
  drop column if exists common_emotions,
  drop column if exists aspirations;
