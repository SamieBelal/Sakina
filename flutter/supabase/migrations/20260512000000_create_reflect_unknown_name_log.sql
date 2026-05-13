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

-- `on delete set null` preserves the aggregate aliasing signal when a user
-- account is deleted (GDPR / account closure). The per-user attribution
-- vanishes (which is the privacy intent), but the `ai_returned_name` rows
-- stay so we can still see "the AI returned 'Al-Rahmaan' 47 times last
-- month" even after some of those users delete their accounts.
create table public.reflect_unknown_name_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  -- Cap row size: canonical Name transliterations top out at ~30 chars;
  -- 512 is generous and protects against an AI hallucination returning
  -- a multi-KB blob that would bloat the table.
  ai_returned_name text not null check (char_length(ai_returned_name) <= 512),
  created_at timestamptz not null default now()
);

create index reflect_unknown_name_log_created_at_idx
  on public.reflect_unknown_name_log (created_at desc);

create index reflect_unknown_name_log_user_id_idx
  on public.reflect_unknown_name_log (user_id);

alter table public.reflect_unknown_name_log enable row level security;

-- Users may insert rows attributed to themselves. `to authenticated` mirrors
-- the proven pattern in 20260510000001_rls_initplan_optimization.sql — anon
-- can never satisfy `auth.uid() = user_id` so the scope is functionally
-- equivalent, but the explicit role grant silences Supabase advisor lint 0003.
create policy "users insert own unknown-name rows"
  on public.reflect_unknown_name_log
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

-- Users may read their own rows. Project owner reads aggregate via Studio /
-- service role; this policy is for app-side debug surfaces if we ever build one.
create policy "users read own unknown-name rows"
  on public.reflect_unknown_name_log
  for select to authenticated
  using ((select auth.uid()) = user_id);
