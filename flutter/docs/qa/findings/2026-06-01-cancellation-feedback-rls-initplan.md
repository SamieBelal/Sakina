# Finding: `cancellation_feedback` RLS skips initplan optimization

- **Found:** 2026-06-01, Gate 0 (full-regression run), Supabase `get_advisors performance`
- **Severity:** Low (perf-only, no correctness/security impact at current scale)
- **Status:** FIXED (verified 2026-07-26) — migration `20260602004027_cancellation_feedback_rls_initplan.sql` rewrites all three policies to `(select auth.uid()) = user_id`.
- **Source migration:** `supabase/migrations/20260531000000_create_cancellation_feedback.sql`

## What

All three RLS policies on `public.cancellation_feedback` call `auth.uid()` directly, so Postgres
re-evaluates the function **per row** instead of once per query:

```sql
-- line 58  (SELECT policy)
using (auth.uid() = user_id);
-- line 65  (INSERT policy)
with check (auth.uid() = user_id);
-- lines 72-73  (UPDATE policy)
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
```

The rest of the schema was migrated to the initplan-optimized form in
`20260510172453_rls_initplan_optimization`. This new table (added 2026-05-31) regressed the
established convention. Supabase advisor flags it as `auth_rls_initplan` (0003).

## Fix

New migration replacing each `auth.uid()` with `(select auth.uid())`:

```sql
-- example for the SELECT policy
using ((select auth.uid()) = user_id);
```

Apply to all three policies. Behavior is identical; the planner caches the auth lookup.

## Why it matters

Cheap, established-pattern fix that keeps the advisor clean and avoids a per-row function
call as the table grows. Not a release blocker.

Ref: https://supabase.com/docs/guides/database/postgres/row-level-security#call-functions-with-select
