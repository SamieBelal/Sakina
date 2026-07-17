-- 20260717121000_dua_precise_notifications_enqueue_columns.sql
--
-- Duʿā Scheduled Notifications (Phase 2) — server-enqueue columns for the
-- precise-window push path.
--
-- Plan: docs/superpowers/plans/2026-07-16-dua-scheduled-notifications.md (§4, T1).
-- Base table: 20260716120000_dua_precise_notifications.sql (RLS + fire_utc).
--
-- AGREED SCHEMA (client + server both code against this):
--   dua_precise_notifications(
--     id, user_id, window_type, fire_utc, sync_version, created_at,
--     sent_at timestamptz NULL, title text, body text)
--
-- The client writes window_type/fire_utc/sync_version/title/body (the copy is
-- localized on-device — no Arabic/English mixing, done client-side). The server
-- cron (send-scheduled-notifications) sends the row's title/body via OneSignal
-- and stamps sent_at to prevent double-send.
--
-- title/body are nullable so a pre-existing row (synced before this migration)
-- or a client that hasn't yet populated copy can't break the schema; the cron
-- coalesces to a safe default and still fires. The client SHOULD always send
-- both going forward.

alter table public.dua_precise_notifications
  add column if not exists sent_at timestamptz,
  add column if not exists title   text,
  add column if not exists body    text;

comment on column public.dua_precise_notifications.sent_at is
  'NULL until the cron enqueues this row to OneSignal, then stamped now() in the '
  'same statement to prevent double-send (plan 2026-07-16 §4).';
comment on column public.dua_precise_notifications.title is
  'Client-localized push heading for this precise window (Arabic/English never '
  'mixed — localization happens on-device).';
comment on column public.dua_precise_notifications.body is
  'Client-localized push body for this precise window.';

-- The server due-query is:
--   WHERE sent_at IS NULL AND fire_utc <= now() AND fire_utc > now() - interval '1 hour'
-- A PARTIAL index on (fire_utc) WHERE sent_at IS NULL keeps the scan tight (only
-- unsent rows are indexed; sent rows drop out of the index entirely) and matches
-- the predicate exactly. This supersedes the plain fire_utc index from the base
-- migration for the due-query; that index is retained as it also serves ad-hoc
-- range scans, but the partial one is what the cron hits.
create index if not exists dua_precise_notifications_due_idx
  on public.dua_precise_notifications (fire_utc)
  where sent_at is null;
