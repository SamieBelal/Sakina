-- 2026-05-24: Drop the `dblink` extension that was installed during P1-A
-- live concurrent-race verification on prod (see PR #25 review history).
--
-- The extension was installed via `mcp__supabase__apply_migration` to test
-- whether two concurrent connections could trigger the unhandled
-- unique_violation in reserve_ai_bypass. After confirming the EXCEPTION
-- block now handles it correctly, the extension has no production use.
--
-- Supabase's database linter flags `extension_in_public` as a security
-- warning since extensions in the public schema can clutter the namespace
-- and complicate RLS reasoning. Cleanest fix is to drop it entirely — we
-- have no Dart or Edge Function code that consumes dblink.
--
-- If we ever need cross-database connectivity again, install dblink into a
-- dedicated `extensions` schema:
--   CREATE EXTENSION dblink SCHEMA extensions;
-- and reference it as `extensions.dblink_connect(...)`.

DROP EXTENSION IF EXISTS dblink;
