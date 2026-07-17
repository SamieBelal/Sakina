-- 20260717120000_notify_dua_windows_pref.sql
--
-- Duʿā Scheduled Notifications (Phase 2) — one new per-category opt-in switch.
--
-- Plan: docs/superpowers/plans/2026-07-16-dua-scheduled-notifications.md (§6).
--
-- The Flutter Settings notifications section already reads/writes this
-- preference key (`_setNotificationPreference('notify_dua_windows', value)`);
-- this migration just lands the column so those upserts succeed. It gates BOTH
-- the LOCAL calendar schedule AND the SERVER precise-window enqueue.
--
-- Default ON — consistent with the other five categories, all of which default
-- true once the user granted notification permission in onboarding. The master
-- `push_enabled` toggle still gates everything; this Settings row is the
-- per-category off-ramp.
--
-- RLS: `user_notification_preferences` already has per-user SELECT/INSERT/
-- UPDATE/DELETE policies (auth.uid() = user_id) from
-- 20260416090000_add_notification_preferences_and_scheduler.sql — a new column
-- inherits them unchanged, so no policy edits are needed here.

alter table public.user_notification_preferences
  add column if not exists notify_dua_windows boolean not null default true;

comment on column public.user_notification_preferences.notify_dua_windows is
  'Per-category opt-in for duʿā-acceptance-window reminders (calendar windows '
  'local; precise windows server-push via send-scheduled-notifications). '
  'Default true once push permission granted (plan 2026-07-16 §6).';
