# supabase/checks/ — audits you run against a POPULATED database

Scripts here assert things about a database that **has real data in it**:
seeded public catalogs, out-of-band tables, live RLS policies. They are
deliberately **outside `supabase/tests/`**, because `run_sql_tests.sh` globs that
directory and CI runs it against a database built from `supabase/migrations/`
and nothing else.

Same reasoning as [`../staged/`](../staged/README.md): a directory whose contents
must never be picked up automatically has to sit outside the glob. Naming alone
does not protect you — `backend_rls_audit.sql` was called `backend_rls_test.sql`
and lived in `tests/` until 2026-08-02.

## Why that file moved

It is not a pgTAP suite. Its own header says so — *"runnable via
`mcp__supabase__execute_sql` (no supabase CLI / no pgTAP required)"* — and it
asserts conditions that are **false by construction on a clean database**:

- `§17.1 daily_questions / collectible_names anon-readable` — the public
  catalogs are seeded by an import step, not by a migration. A fresh CI database
  has the tables and no rows.
- `§17.3 reflect_classifier_log has RLS + a policy` — this table has **no
  creating migration**; it "lives out-of-band on prod", which
  `20260510000001_rls_initplan_optimization.sql` states outright and handles with
  `if to_regclass('public.reflect_classifier_log') is not null`. On prod it
  exists and has policies. On a clean database it does not exist at all.
- `§16.1 payload has exactly the documented 11 keys` — `sync_all_user_data()`
  has since gained keys (the lantern-cosmetics work). This assertion is a real
  finding worth re-checking against prod; it is not a clean-database question.

So the failures were the script being pointed at the wrong kind of database, not
a regression. Running it under `run_sql_tests.sh` was the bug.

**It had never actually run in CI** — it was untracked until 2026-08-02, so CI
had never seen it. Committing it into `tests/` would have turned the build red
for the first time, during release week, on a script that was never a member of
that suite. `run_sql_tests_clean.sh` hides this locally by listing it in
`SQL_TESTS_KNOWN_FAILING`; the CI workflow sets that variable to `''` and
tolerates nothing.

## Running it

Against prod or another populated database, via MCP:

```
mcp__supabase__execute_sql query=$(cat supabase/checks/backend_rls_audit.sql)
```

It wraps everything in one transaction and rolls back, so it leaves no state.
Output is either `ALL PASS (N tests)` or an exception listing the failures.
