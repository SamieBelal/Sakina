-- Reconcile repo <-> prod drift for `push_enabled_last_verified_at`.
--
-- BACKGROUND: on 2026-04-26 a migration named
-- `add_push_enabled_last_verified_at_with_cron_filter` was applied DIRECTLY to
-- production via the Supabase MCP tool but its SQL was never committed to this
-- migrations directory. Production therefore carries the column + partial index
-- (confirmed via information_schema / pg_indexes), yet a fresh rebuild from
-- these migration files would NOT — and the client
-- (`notification_service.dart._writePushEnabledVerifiedAtToSupabase`) upserts
-- this column on every foregrounded, iOS-permission-granted session. This
-- migration re-establishes the repo as source-of-truth. Every statement is
-- guarded with IF NOT EXISTS, so it is a no-op against production (which already
-- has both objects) and only takes effect on fresh/reset databases.
--
-- DELIBERATELY OMITTED — the cron freshness filter:
-- The 2026-04-26 change also added
--   `AND n.push_enabled_last_verified_at > now() - interval '7 days'`
-- to `get_eligible_notification_users`. That filter was subsequently clobbered
-- by `20260512212403_daily_reminder_uses_user_reminder_time` (a CREATE OR
-- REPLACE that did not carry it forward) and is NOT present in production today.
-- It is intentionally NOT restored here: as of 2026-07-26 only 37 of 1,239
-- push-enabled users have a fresh `verified_at` (1,106 are NULL — they predate
-- the stamping client / have not foregrounded since), so re-adding the filter
-- would drop notification eligibility from 1,239 to 37 and silently suppress
-- daily/streak/re-engagement pushes for ~1,200 real users. The client-side
-- `push_enabled` reconcile (F2, 2026-04-26) remains the live protection against
-- push_enabled drift. Re-enabling the defense-in-depth filter is a tracked
-- follow-up that first requires a full backfill of `verified_at` for existing
-- push-enabled rows AND broadened client stamp coverage (e.g. on every
-- AppLifecycleState.resumed), not a bare filter flip.

ALTER TABLE public.user_notification_preferences
  ADD COLUMN IF NOT EXISTS push_enabled_last_verified_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_user_notification_preferences_verified
  ON public.user_notification_preferences
  USING btree (push_enabled_last_verified_at)
  WHERE (push_enabled = true);
