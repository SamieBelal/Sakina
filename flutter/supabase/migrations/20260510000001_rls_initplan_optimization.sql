-- 2026-05-10: Rewrite bare auth.uid() to (select auth.uid()) in RLS
-- policies flagged by Supabase advisor (lint 0003 auth_rls_initplan).
--
-- Bare auth.uid() is volatile, so the Postgres planner re-evaluates it
-- for every row scanned by the policy. Wrapped in a SELECT it becomes
-- an InitPlan — evaluated once per query and cached for the duration.
-- The performance benefit scales with table size: these policies cover
-- per-user reads today, but reflect_classifier_log will grow steadily
-- as the AI reflect feature accumulates classifier audit rows.
--
-- We also tighten the role grant from `public` to `authenticated`.
-- `auth.uid()` returns NULL for the `anon` role, so `auth.uid() = user_id`
-- can never be satisfied anonymously — this change is functionally
-- equivalent and aligns with the rest of the codebase's RLS conventions.
--
-- See: https://supabase.com/docs/guides/database/postgres/row-level-security#call-functions-with-select

-- user_subscriptions: SELECT policy
drop policy if exists "Users can view own subscriptions" on public.user_subscriptions;
create policy "Users can view own subscriptions" on public.user_subscriptions
  for select to authenticated
  using ((select auth.uid()) = user_id);

-- reflect_classifier_log: INSERT policy
drop policy if exists "users insert own classifier rows" on public.reflect_classifier_log;
create policy "users insert own classifier rows" on public.reflect_classifier_log
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

-- reflect_classifier_log: SELECT policy
drop policy if exists "users read own classifier rows" on public.reflect_classifier_log;
create policy "users read own classifier rows" on public.reflect_classifier_log
  for select to authenticated
  using ((select auth.uid()) = user_id);
