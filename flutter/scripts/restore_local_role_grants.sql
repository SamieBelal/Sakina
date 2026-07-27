-- Post-migration grant fixup for LOCAL / CI databases only. Never run against
-- production — the hosted platform does this itself.
--
-- WHY
-- ---
-- A Supabase CLI/image release changed the local stack's default privileges, so
-- the client roles (anon, authenticated, service_role) stopped receiving the
-- table-level grants the hosted platform provides. Supabase grants broadly and
-- relies on RLS for access control, so without this, role-scoped pgTAP suites
-- fail with "permission denied for table" (app_config, user_tokens,
-- user_profiles, …) for reasons that have nothing to do with the code under
-- test. Identical migrations passed on 2026-06-09 and failed afterwards purely
-- from that change.
--
-- Shared by .github/workflows/test.yml (sql-tests) and
-- scripts/run_sql_tests_clean.sh so the two can't drift.
--
-- WHAT IS DELIBERATELY *NOT* RESTORED
-- -----------------------------------
-- Function EXECUTE grants: migrations revoke specific ones (award_noor,
-- grant_cosmetic_iap, clawback_cosmetic_iap, reinstate_cosmetic_iap …) and the
-- negative execute-denial tests must stay valid.
--
-- Table grants that a migration deliberately revoked. `grant all on all tables`
-- is a blunt instrument and would silently undo those lockdowns, making local
-- and CI runs disagree with production. Each one is therefore re-applied below.
-- IF YOU ADD A `revoke ... on <table> from anon, authenticated` TO A MIGRATION,
-- ADD IT HERE TOO — otherwise it evaporates in CI. The matching pgTAP suite is
-- what catches the omission.

grant usage on schema public to anon, authenticated, service_role;
grant all on all tables in schema public to anon, authenticated, service_role;
grant all on all sequences in schema public to anon, authenticated, service_role;

-- ── Deliberate lockdowns, re-applied ────────────────────────────────────────

-- 20260726201100_lock_down_noor_grants.sql — the Noor idempotency ledger must
-- stay unforgeable by anything but the SECURITY DEFINER mint RPCs, which run as
-- the owner and are unaffected. Pinned by noor_grants_lockdown_test.sql.
revoke all on public.noor_grants from anon, authenticated;
