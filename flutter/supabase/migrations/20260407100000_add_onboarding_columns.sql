alter table user_profiles
  add column if not exists onboarding_familiarity text,
  add column if not exists onboarding_quran_connection text,
  add column if not exists onboarding_attribution text[] default '{}';
