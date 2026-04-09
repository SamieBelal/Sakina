-- =============================================================================
-- Sakina: Initial Database Schema
-- =============================================================================
-- Phase 1: Foundation (triggers, enums)
-- Phase 2: Static content tables (8 tables)
-- Phase 3: User data tables (15 tables)
-- Phase 4: Row Level Security policies
-- Phase 5: Helper functions
-- =============================================================================

-- =============================================================================
-- PHASE 1: Foundation
-- =============================================================================

-- 1a. updated_at trigger function
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- 1b. Enums
create type public.card_tier as enum ('bronze', 'silver', 'gold');
create type public.quest_cadence as enum ('daily', 'weekly', 'monthly');
create type public.dua_category as enum (
  'anxiety', 'grief', 'hope', 'gratitude', 'morning', 'evening',
  'protection', 'forgiveness', 'sleep', 'travel', 'food', 'general',
  'wealth', 'family', 'guidance'
);

-- =============================================================================
-- PHASE 2: Static Content Tables
-- =============================================================================

-- 2a. names_of_allah (99 Names — core reference)
create table public.names_of_allah (
  id int primary key,
  name_arabic text not null,
  transliteration text not null,
  name_english text not null,
  meaning text not null default '',
  lesson text not null default '',
  description text not null default '',
  emotions text[] not null default '{}',
  created_at timestamptz not null default now()
);

create index idx_names_emotions on public.names_of_allah using gin (emotions);

-- 2b. name_teachings (deep teachings from knowledge base)
create table public.name_teachings (
  id uuid primary key default gen_random_uuid(),
  name_transliteration text not null,
  name_arabic text not null,
  emotional_context text[] not null default '{}',
  core_teaching text not null,
  prophetic_story text not null,
  dua_arabic text not null default '',
  dua_transliteration text not null default '',
  dua_translation text not null default '',
  dua_source text not null default '',
  created_at timestamptz not null default now()
);

create index idx_teachings_name on public.name_teachings (name_transliteration);
create index idx_teachings_emotions on public.name_teachings using gin (emotional_context);

-- 2c. name_guidance (invocation guides from dua_knowledge)
create table public.name_guidance (
  id uuid primary key default gen_random_uuid(),
  name_transliteration text not null,
  name_arabic text not null,
  episode int not null default 0,
  call_for text[] not null default '{}',
  invocation_style text not null default '',
  sample_phrase text not null default '',
  created_at timestamptz not null default now()
);

create index idx_guidance_name on public.name_guidance (name_transliteration);
create index idx_guidance_call_for on public.name_guidance using gin (call_for);

-- 2d. browse_duas (curated duas)
create table public.browse_duas (
  id text primary key,
  category public.dua_category not null,
  title text not null,
  arabic text not null,
  transliteration text not null,
  translation text not null,
  source text not null default '',
  emotion_tags text[] not null default '{}',
  when_to_recite text,
  created_at timestamptz not null default now()
);

create index idx_duas_category on public.browse_duas (category);
create index idx_duas_emotion_tags on public.browse_duas using gin (emotion_tags);

-- 2e. daily_questions (rotating questions)
create table public.daily_questions (
  id int primary key,
  question text not null,
  options jsonb not null default '[]',
  created_at timestamptz not null default now()
);

-- 2f. discovery_quiz_questions (quiz questions with scoring)
create table public.discovery_quiz_questions (
  id text primary key,
  prompt text not null,
  options jsonb not null default '[]',
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

-- 2g. name_anchors (anchor results for discovery quiz)
create table public.name_anchors (
  name_key text primary key,
  name text not null,
  arabic text not null,
  anchor text not null,
  detail text not null,
  created_at timestamptz not null default now()
);

-- 2h. collectible_names (99 Names with tier content for card collection)
create table public.collectible_names (
  id int primary key,
  arabic text not null,
  transliteration text not null,
  english text not null,
  meaning text not null default '',
  lesson text not null default '',
  hadith text not null default '',
  dua_arabic text not null default '',
  dua_transliteration text not null default '',
  dua_translation text not null default '',
  created_at timestamptz not null default now()
);

-- =============================================================================
-- PHASE 3: User Data Tables
-- =============================================================================

-- 3a. user_profiles
create table public.user_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  onboarding_completed boolean not null default false,
  onboarding_intention text,
  onboarding_struggles text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger user_profiles_updated_at before update on public.user_profiles
  for each row execute function public.handle_updated_at();

-- 3b. user_streaks
create table public.user_streaks (
  user_id uuid primary key references auth.users(id) on delete cascade,
  current_streak int not null default 0,
  longest_streak int not null default 0,
  last_active date,
  streak_freeze_available boolean not null default false,
  updated_at timestamptz not null default now()
);

create trigger user_streaks_updated_at before update on public.user_streaks
  for each row execute function public.handle_updated_at();

-- 3c. user_activity_log
create table public.user_activity_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  active_date date not null,
  created_at timestamptz not null default now(),
  unique (user_id, active_date)
);

create index idx_activity_user_date on public.user_activity_log (user_id, active_date desc);

-- 3d. user_xp
create table public.user_xp (
  user_id uuid primary key references auth.users(id) on delete cascade,
  total_xp int not null default 0,
  updated_at timestamptz not null default now()
);

create trigger user_xp_updated_at before update on public.user_xp
  for each row execute function public.handle_updated_at();

-- 3e. user_tokens
create table public.user_tokens (
  user_id uuid primary key references auth.users(id) on delete cascade,
  balance int not null default 50,
  updated_at timestamptz not null default now()
);

create trigger user_tokens_updated_at before update on public.user_tokens
  for each row execute function public.handle_updated_at();

-- 3f. user_achievements
create table public.user_achievements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  achievement_id text not null,
  unlocked_at timestamptz not null default now(),
  unique (user_id, achievement_id)
);

create index idx_achievements_user on public.user_achievements (user_id);

-- 3g. user_card_collection
create table public.user_card_collection (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name_id int not null,
  tier public.card_tier not null default 'bronze',
  discovered_at timestamptz not null default now(),
  last_engaged_at timestamptz not null default now(),
  unique (user_id, name_id)
);

create index idx_collection_user on public.user_card_collection (user_id);
create index idx_collection_user_name on public.user_card_collection (user_id, name_id);

-- 3h. user_checkin_history
create table public.user_checkin_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  checked_in_at timestamptz not null default now(),
  q1 text not null,
  q2 text not null,
  q3 text not null,
  q4 text,
  name_returned text not null,
  name_arabic text not null
);

create index idx_checkin_user_date on public.user_checkin_history (user_id, checked_in_at desc);

-- 3i. user_reflections
create table public.user_reflections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  saved_at timestamptz not null default now(),
  user_text text not null,
  name text not null,
  name_arabic text not null,
  reframe_preview text not null default '',
  reframe text not null default '',
  story text not null default '',
  dua_arabic text not null default '',
  dua_transliteration text not null default '',
  dua_translation text not null default '',
  dua_source text not null default '',
  related_names jsonb not null default '[]'
);

create index idx_reflections_user_date on public.user_reflections (user_id, saved_at desc);

-- 3j. user_built_duas
create table public.user_built_duas (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  saved_at timestamptz not null default now(),
  need text not null,
  arabic text not null,
  transliteration text not null,
  translation text not null
);

create index idx_built_duas_user_date on public.user_built_duas (user_id, saved_at desc);

-- 3k. user_daily_rewards
create table public.user_daily_rewards (
  user_id uuid primary key references auth.users(id) on delete cascade,
  current_day int not null default 0,
  last_claim_date date,
  streak_freeze_owned boolean not null default false,
  guaranteed_tier_up boolean not null default false,
  updated_at timestamptz not null default now()
);

create trigger user_daily_rewards_updated_at before update on public.user_daily_rewards
  for each row execute function public.handle_updated_at();

-- 3l. user_daily_usage
create table public.user_daily_usage (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  usage_date date not null default current_date,
  reflect_uses int not null default 0,
  built_dua_uses int not null default 0,
  unique (user_id, usage_date)
);

create index idx_usage_user_date on public.user_daily_usage (user_id, usage_date desc);

-- 3m. user_quest_progress
create table public.user_quest_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  quest_id text not null,
  cadence public.quest_cadence not null,
  progress int not null default 0,
  completed boolean not null default false,
  period_start date not null,
  updated_at timestamptz not null default now(),
  unique (user_id, quest_id, period_start)
);

create index idx_quest_user_period on public.user_quest_progress (user_id, period_start desc);

create trigger user_quest_progress_updated_at before update on public.user_quest_progress
  for each row execute function public.handle_updated_at();

-- 3n. user_daily_answers
create table public.user_daily_answers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  answered_at timestamptz not null default now(),
  question_id int not null,
  selected_option text not null,
  name_returned text not null default '',
  name_arabic text not null default '',
  teaching text not null default '',
  dua_arabic text not null default '',
  dua_transliteration text not null default '',
  dua_translation text not null default ''
);

create index idx_daily_answers_user on public.user_daily_answers (user_id, answered_at desc);

-- 3o. user_discovery_results
create table public.user_discovery_results (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  completed_at timestamptz not null default now(),
  anchor_names jsonb not null default '[]'
);

create index idx_discovery_user on public.user_discovery_results (user_id);

-- =============================================================================
-- PHASE 4: Row Level Security
-- =============================================================================

-- ---- Static content tables: authenticated read-only ----

alter table public.names_of_allah enable row level security;
create policy "Anyone authenticated can read" on public.names_of_allah
  for select to authenticated using (true);

alter table public.name_teachings enable row level security;
create policy "Anyone authenticated can read" on public.name_teachings
  for select to authenticated using (true);

alter table public.name_guidance enable row level security;
create policy "Anyone authenticated can read" on public.name_guidance
  for select to authenticated using (true);

alter table public.browse_duas enable row level security;
create policy "Anyone authenticated can read" on public.browse_duas
  for select to authenticated using (true);

alter table public.daily_questions enable row level security;
create policy "Anyone authenticated can read" on public.daily_questions
  for select to authenticated using (true);

alter table public.discovery_quiz_questions enable row level security;
create policy "Anyone authenticated can read" on public.discovery_quiz_questions
  for select to authenticated using (true);

alter table public.name_anchors enable row level security;
create policy "Anyone authenticated can read" on public.name_anchors
  for select to authenticated using (true);

alter table public.collectible_names enable row level security;
create policy "Anyone authenticated can read" on public.collectible_names
  for select to authenticated using (true);

-- ---- User tables: full CRUD scoped to own data ----

-- user_profiles (PK is id, not user_id)
alter table public.user_profiles enable row level security;

create policy "Users can view own profile" on public.user_profiles
  for select to authenticated using ((select auth.uid()) = id);

create policy "Users can insert own profile" on public.user_profiles
  for insert to authenticated with check ((select auth.uid()) = id);

create policy "Users can update own profile" on public.user_profiles
  for update to authenticated using ((select auth.uid()) = id);

create policy "Users can delete own profile" on public.user_profiles
  for delete to authenticated using ((select auth.uid()) = id);

-- user_streaks
alter table public.user_streaks enable row level security;

create policy "Users can view own streaks" on public.user_streaks
  for select to authenticated using ((select auth.uid()) = user_id);

create policy "Users can insert own streaks" on public.user_streaks
  for insert to authenticated with check ((select auth.uid()) = user_id);

create policy "Users can update own streaks" on public.user_streaks
  for update to authenticated using ((select auth.uid()) = user_id);

create policy "Users can delete own streaks" on public.user_streaks
  for delete to authenticated using ((select auth.uid()) = user_id);

-- user_activity_log
alter table public.user_activity_log enable row level security;

create policy "Users can view own activity" on public.user_activity_log
  for select to authenticated using ((select auth.uid()) = user_id);

create policy "Users can insert own activity" on public.user_activity_log
  for insert to authenticated with check ((select auth.uid()) = user_id);

create policy "Users can update own activity" on public.user_activity_log
  for update to authenticated using ((select auth.uid()) = user_id);

create policy "Users can delete own activity" on public.user_activity_log
  for delete to authenticated using ((select auth.uid()) = user_id);

-- user_xp
alter table public.user_xp enable row level security;

create policy "Users can view own xp" on public.user_xp
  for select to authenticated using ((select auth.uid()) = user_id);

create policy "Users can insert own xp" on public.user_xp
  for insert to authenticated with check ((select auth.uid()) = user_id);

create policy "Users can update own xp" on public.user_xp
  for update to authenticated using ((select auth.uid()) = user_id);

create policy "Users can delete own xp" on public.user_xp
  for delete to authenticated using ((select auth.uid()) = user_id);

-- user_tokens
alter table public.user_tokens enable row level security;

create policy "Users can view own tokens" on public.user_tokens
  for select to authenticated using ((select auth.uid()) = user_id);

create policy "Users can insert own tokens" on public.user_tokens
  for insert to authenticated with check ((select auth.uid()) = user_id);

create policy "Users can update own tokens" on public.user_tokens
  for update to authenticated using ((select auth.uid()) = user_id);

create policy "Users can delete own tokens" on public.user_tokens
  for delete to authenticated using ((select auth.uid()) = user_id);

-- user_achievements
alter table public.user_achievements enable row level security;

create policy "Users can view own achievements" on public.user_achievements
  for select to authenticated using ((select auth.uid()) = user_id);

create policy "Users can insert own achievements" on public.user_achievements
  for insert to authenticated with check ((select auth.uid()) = user_id);

create policy "Users can update own achievements" on public.user_achievements
  for update to authenticated using ((select auth.uid()) = user_id);

create policy "Users can delete own achievements" on public.user_achievements
  for delete to authenticated using ((select auth.uid()) = user_id);

-- user_card_collection
alter table public.user_card_collection enable row level security;

create policy "Users can view own collection" on public.user_card_collection
  for select to authenticated using ((select auth.uid()) = user_id);

create policy "Users can insert own collection" on public.user_card_collection
  for insert to authenticated with check ((select auth.uid()) = user_id);

create policy "Users can update own collection" on public.user_card_collection
  for update to authenticated using ((select auth.uid()) = user_id);

create policy "Users can delete own collection" on public.user_card_collection
  for delete to authenticated using ((select auth.uid()) = user_id);

-- user_checkin_history
alter table public.user_checkin_history enable row level security;

create policy "Users can view own checkins" on public.user_checkin_history
  for select to authenticated using ((select auth.uid()) = user_id);

create policy "Users can insert own checkins" on public.user_checkin_history
  for insert to authenticated with check ((select auth.uid()) = user_id);

create policy "Users can update own checkins" on public.user_checkin_history
  for update to authenticated using ((select auth.uid()) = user_id);

create policy "Users can delete own checkins" on public.user_checkin_history
  for delete to authenticated using ((select auth.uid()) = user_id);

-- user_reflections
alter table public.user_reflections enable row level security;

create policy "Users can view own reflections" on public.user_reflections
  for select to authenticated using ((select auth.uid()) = user_id);

create policy "Users can insert own reflections" on public.user_reflections
  for insert to authenticated with check ((select auth.uid()) = user_id);

create policy "Users can update own reflections" on public.user_reflections
  for update to authenticated using ((select auth.uid()) = user_id);

create policy "Users can delete own reflections" on public.user_reflections
  for delete to authenticated using ((select auth.uid()) = user_id);

-- user_built_duas
alter table public.user_built_duas enable row level security;

create policy "Users can view own built duas" on public.user_built_duas
  for select to authenticated using ((select auth.uid()) = user_id);

create policy "Users can insert own built duas" on public.user_built_duas
  for insert to authenticated with check ((select auth.uid()) = user_id);

create policy "Users can update own built duas" on public.user_built_duas
  for update to authenticated using ((select auth.uid()) = user_id);

create policy "Users can delete own built duas" on public.user_built_duas
  for delete to authenticated using ((select auth.uid()) = user_id);

-- user_daily_rewards
alter table public.user_daily_rewards enable row level security;

create policy "Users can view own daily rewards" on public.user_daily_rewards
  for select to authenticated using ((select auth.uid()) = user_id);

create policy "Users can insert own daily rewards" on public.user_daily_rewards
  for insert to authenticated with check ((select auth.uid()) = user_id);

create policy "Users can update own daily rewards" on public.user_daily_rewards
  for update to authenticated using ((select auth.uid()) = user_id);

create policy "Users can delete own daily rewards" on public.user_daily_rewards
  for delete to authenticated using ((select auth.uid()) = user_id);

-- user_daily_usage
alter table public.user_daily_usage enable row level security;

create policy "Users can view own daily usage" on public.user_daily_usage
  for select to authenticated using ((select auth.uid()) = user_id);

create policy "Users can insert own daily usage" on public.user_daily_usage
  for insert to authenticated with check ((select auth.uid()) = user_id);

create policy "Users can update own daily usage" on public.user_daily_usage
  for update to authenticated using ((select auth.uid()) = user_id);

create policy "Users can delete own daily usage" on public.user_daily_usage
  for delete to authenticated using ((select auth.uid()) = user_id);

-- user_quest_progress
alter table public.user_quest_progress enable row level security;

create policy "Users can view own quest progress" on public.user_quest_progress
  for select to authenticated using ((select auth.uid()) = user_id);

create policy "Users can insert own quest progress" on public.user_quest_progress
  for insert to authenticated with check ((select auth.uid()) = user_id);

create policy "Users can update own quest progress" on public.user_quest_progress
  for update to authenticated using ((select auth.uid()) = user_id);

create policy "Users can delete own quest progress" on public.user_quest_progress
  for delete to authenticated using ((select auth.uid()) = user_id);

-- user_daily_answers
alter table public.user_daily_answers enable row level security;

create policy "Users can view own daily answers" on public.user_daily_answers
  for select to authenticated using ((select auth.uid()) = user_id);

create policy "Users can insert own daily answers" on public.user_daily_answers
  for insert to authenticated with check ((select auth.uid()) = user_id);

create policy "Users can update own daily answers" on public.user_daily_answers
  for update to authenticated using ((select auth.uid()) = user_id);

create policy "Users can delete own daily answers" on public.user_daily_answers
  for delete to authenticated using ((select auth.uid()) = user_id);

-- user_discovery_results
alter table public.user_discovery_results enable row level security;

create policy "Users can view own discovery results" on public.user_discovery_results
  for select to authenticated using ((select auth.uid()) = user_id);

create policy "Users can insert own discovery results" on public.user_discovery_results
  for insert to authenticated with check ((select auth.uid()) = user_id);

create policy "Users can update own discovery results" on public.user_discovery_results
  for update to authenticated using ((select auth.uid()) = user_id);

create policy "Users can delete own discovery results" on public.user_discovery_results
  for delete to authenticated using ((select auth.uid()) = user_id);

-- =============================================================================
-- PHASE 5: Helper Functions
-- =============================================================================

-- 5a. Auto-create user rows on signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.user_profiles (id) values (new.id);
  insert into public.user_streaks (user_id) values (new.id);
  insert into public.user_xp (user_id) values (new.id);
  insert into public.user_tokens (user_id) values (new.id);
  insert into public.user_daily_rewards (user_id) values (new.id);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 5b. Atomic token spend (prevents races)
create or replace function public.spend_tokens(amount int)
returns int as $$
declare
  new_balance int;
begin
  update public.user_tokens
  set balance = balance - amount
  where user_id = (select auth.uid()) and balance >= amount
  returning balance into new_balance;

  if not found then
    raise exception 'Insufficient tokens';
  end if;

  return new_balance;
end;
$$ language plpgsql security definer;

-- 5c. Atomic token earn
create or replace function public.earn_tokens(amount int)
returns int as $$
declare
  new_balance int;
begin
  update public.user_tokens
  set balance = balance + amount
  where user_id = (select auth.uid())
  returning balance into new_balance;

  return new_balance;
end;
$$ language plpgsql security definer;

-- 5d. Atomic XP award
create or replace function public.award_xp(amount int)
returns int as $$
declare
  new_total int;
begin
  update public.user_xp
  set total_xp = total_xp + amount
  where user_id = (select auth.uid())
  returning total_xp into new_total;

  return new_total;
end;
$$ language plpgsql security definer;
