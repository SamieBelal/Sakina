-- F-02 (2026-06-01): cancellation_feedback RLS policies used bare auth.uid(),
-- which Postgres re-evaluates per row. The rest of the schema moved to
-- (select auth.uid()) in 20260510172453_rls_initplan_optimization; the new
-- table (20260531000000) regressed the convention. Switch to the initplan-
-- optimized form (behavior identical, planner caches the auth lookup).
-- See docs/qa/findings/2026-06-01-cancellation-feedback-rls-initplan.md

alter policy "Users can view own cancellation feedback"
  on public.cancellation_feedback
  using ((select auth.uid()) = user_id);

alter policy "Users can insert own cancellation feedback"
  on public.cancellation_feedback
  with check ((select auth.uid()) = user_id);

alter policy "Users can update own cancellation feedback"
  on public.cancellation_feedback
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
