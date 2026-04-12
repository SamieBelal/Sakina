alter table public.user_profiles
  add column if not exists selected_title text,
  add column if not exists is_auto_title boolean not null default true;
