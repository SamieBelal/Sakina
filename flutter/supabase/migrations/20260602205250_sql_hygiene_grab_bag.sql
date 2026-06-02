-- SQL hygiene grab-bag — posture + readability, no behavior change for users.
-- Surfaced by the 2026-05-24 master review (subagent migration review). None of
-- these were exploitable; this migration makes two of the four items durable at
-- the database level. The other two (a forward-ref comment on the earlier
-- ai_bypass migration, and a 2-arg cron.schedule overload in the local-dev cron
-- stub) are source-only edits to their original files — see TODO.md
-- "SQL hygiene grab-bag".
--
-- Both statements below are idempotent and non-breaking:
--   * the GRANT re-affirms an execute privilege service_role already holds, so
--     it cannot remove access from any current caller;
--   * the ALTER only narrows search_path resolution and the function's lone
--     cross-schema reference (auth.users) is already schema-qualified, so
--     resolution is unchanged.

-- ---------------------------------------------------------------------------
-- Item 2: explicit service_role GRANT on grant_winback_tokens.
--
-- grant_winback_tokens is server-only (scheduled edge function via
-- service_role). It already has EXECUTE for service_role via Supabase's
-- default-privilege configuration (proacl: service_role=X/postgres), but that
-- grant is implicit. Making it explicit defends against a future
-- `revoke all on schema public from service_role` (or a change to Supabase's
-- default privileges) silently stripping the cron's ability to grant win-back
-- tokens. Belt-and-braces; no current caller is affected.
grant execute on function public.grant_winback_tokens(uuid, integer) to service_role;

-- ---------------------------------------------------------------------------
-- Item 4: tighten search_path on get_eligible_notification_users.
--
-- The function is SECURITY DEFINER and was created with
-- `set search_path = public, auth`. Its only auth-schema reference
-- (`left join auth.users u`) is already fully qualified, so the wider `auth`
-- entry is unnecessary. Narrowing to `public, pg_temp` matches the project
-- convention used by the AI-bypass RPCs and shrinks the trust surface of a
-- DEFINER function. ALTER FUNCTION changes only the config — the body is
-- untouched — so the daily/streak/reengagement reminder crons keep working.
alter function public.get_eligible_notification_users(
  text, text, integer, boolean, integer, integer, boolean
) set search_path = public, pg_temp;
