-- 20260512000000_create_reflect_unknown_name_log.sql
--
-- Captures every firing of the "unknown-name" safety-net fallback in
-- `normalizeApprovedVerses` (lib/features/reflect/data/reflection_verse_catalog.dart).
-- When the AI returns a Name not in approvedReflectVersesByName, we serve the
-- two always-safe verses (_heartsRestVerse + _noBurdenVerse). This table lets
-- us measure how often that happens and which non-canonical spellings the AI
-- keeps returning, so we can either alias them or expand the catalog.
--
-- Mirrors the shape and RLS pattern of `reflect_classifier_log`.
--
-- Operator query for weekly review:
--
--   select ai_returned_name, count(*) as hits, max(created_at) as last_seen
--   from public.reflect_unknown_name_log
--   where created_at > now() - interval '7 days'
--   group by 1
--   order by hits desc
--   limit 25;

create table public.reflect_unknown_name_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  ai_returned_name text not null,
  created_at timestamptz not null default now()
);

create index reflect_unknown_name_log_created_at_idx
  on public.reflect_unknown_name_log (created_at desc);

create index reflect_unknown_name_log_user_id_idx
  on public.reflect_unknown_name_log (user_id);

alter table public.reflect_unknown_name_log enable row level security;

-- Users may insert rows attributed to themselves.
create policy "users insert own unknown-name rows"
  on public.reflect_unknown_name_log
  for insert
  with check ((select auth.uid()) = user_id);

-- Users may read their own rows. Project owner reads aggregate via Studio /
-- service role; this policy is for app-side debug surfaces if we ever build one.
create policy "users read own unknown-name rows"
  on public.reflect_unknown_name_log
  for select
  using ((select auth.uid()) = user_id);
