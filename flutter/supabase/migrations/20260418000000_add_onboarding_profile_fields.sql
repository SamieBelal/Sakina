-- Onboarding refactor (spec 2026-04-16):
-- Additive columns for the new quiz fields. All nullable; no defaults that
-- force a rewrite. Zero-downtime. RLS on user_profiles is already in place.
alter table public.user_profiles
  add column if not exists age_range text,
  add column if not exists prayer_frequency text,
  add column if not exists resonant_name_id uuid references public.names_of_allah(id) on delete set null,
  add column if not exists dua_topics text[] not null default '{}',
  add column if not exists dua_topics_other text,
  add column if not exists common_emotions text[] not null default '{}',
  add column if not exists aspirations text[] not null default '{}',
  add column if not exists daily_commitment_minutes integer,
  add column if not exists reminder_time time,
  add column if not exists commitment_accepted boolean not null default false;

comment on column public.user_profiles.age_range is 'Onboarding quiz: one of 13_17,18_24,25_34,35_44,45_54,55plus';
comment on column public.user_profiles.prayer_frequency is 'Onboarding quiz: fivePlus|someDaily|fridaysOnly|rarely|learning';
comment on column public.user_profiles.daily_commitment_minutes is 'Onboarding quiz: 1|3|5|10';
comment on column public.user_profiles.reminder_time is 'Local time of day the user wants the daily check-in reminder';
