-- Revoke the leftover client-role table grants on public.noor_grants.
--
-- ── THE GAP ─────────────────────────────────────────────────────────────────
-- noor_grants shipped (20260726000000) with RLS enabled and ZERO policies, so a
-- direct client write was already refused. But the table's underlying GRANTs
-- were never revoked:
--
--     has_table_privilege('authenticated','public.noor_grants','insert') -> true
--     has_table_privilege('authenticated','public.noor_grants','update') -> true
--     has_table_privilege('authenticated','public.noor_grants','select') -> true
--
-- so RLS was the ONLY thing standing between a user and the economy's
-- idempotency ledger. One stray `alter table ... disable row level security`,
-- or one policy added later for an unrelated read, and the ledger becomes
-- forgeable. That is a single point of failure on a table that gates money.
--
-- ── WHY IT MATTERS MORE THAN USUAL ──────────────────────────────────────────
-- 20260726200700's header explicitly banks on this table's unforgeability for a
-- planned tightening of the milestone guard:
--
--     "award_daily_noor() writes noor_grants rows keyed 'daily:'||<server UTC
--      date>, and noor_grants has RLS enabled with no write policy for
--      authenticated, so those rows are unforgeable and cannot be backdated.
--      Once that ledger is older than the longest milestone, this guard can be
--      tightened to count(distinct daily: grants) >= p_day."
--
-- A forgeable ledger would turn that future guard into a rubber stamp, and
-- award_noor's own (user_id, reason_key) dedupe — the thing that stops
-- streak-rebuild farming — is the same table.
--
-- ── SCOPE ───────────────────────────────────────────────────────────────────
-- SELECT is revoked too. Nothing reads noor_grants from a client: there is no
-- reference to it anywhere in lib/, no PostgREST access in
-- supabase/functions/, and no read of it outside the SECURITY DEFINER RPCs
-- (award_noor, award_daily_noor, claim_streak_milestone). Those execute as the
-- function owner, so revoking from the CALLER roles cannot affect them — pinned
-- by assertions 13-18 of noor_grants_lockdown_test.sql.
--
-- service_role is deliberately left alone: the webhook/admin path may need
-- direct access and is already trusted.
--
-- ── CI / LOCAL CAVEAT ───────────────────────────────────────────────────────
-- scripts/restore_local_role_grants.sql re-grants the client roles AFTER
-- migrations (the local Supabase image stopped providing the grants the hosted
-- platform gives), so it re-applies this revoke. If that file is ever changed to
-- a bare `grant all on all tables`, this lockdown silently evaporates locally
-- and in CI — noor_grants_lockdown_test.sql is what catches it.
revoke all on public.noor_grants from anon, authenticated;

comment on table public.noor_grants is
  'Idempotency ledger for every Noor mint, keyed (user_id, reason_key). '
  'Unforgeable by construction: RLS enabled with NO policies AND no table '
  'grants to anon/authenticated. Written only by SECURITY DEFINER RPCs '
  '(award_noor, award_daily_noor, claim_streak_milestone), which run as the '
  'owner. Nothing reads it client-side. Pinned by noor_grants_lockdown_test.sql.';
