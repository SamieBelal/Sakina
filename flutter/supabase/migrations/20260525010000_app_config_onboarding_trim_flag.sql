-- 2026-05-25: kill-switch flags for the onboarding trim + guided tour features.
-- Both default to true (new behavior enabled). Flip either to false in app_config
-- to roll back without a client redeploy.
insert into public.app_config (key, value) values
  ('onboarding_trim_enabled', 'true'::jsonb),
  ('guided_tour_enabled', 'true'::jsonb)
on conflict (key) do nothing;
