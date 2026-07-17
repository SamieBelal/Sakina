-- 20260716120000_dua_precise_notifications.sql
--
-- Duʿā Scheduled Notifications (Phase 2) — the server-enqueue table for the
-- PRECISE (location-dependent) windows: last-third-of-night, the Friday hour,
-- iftar.
--
-- Plan: docs/superpowers/plans/2026-07-16-dua-scheduled-notifications.md (§4).
--
-- ARCHITECTURE — client computes, server enqueues (Server Issue 1):
--   The on-device DuaWindowEngine is the ONLY prayer-time source. There is NO
--   server-side prayer math. The client computes a horizon of precise-window
--   {window_type, fire_utc} instants and syncs the list here. A later cron
--   (extends send-scheduled-notifications) enqueues OneSignal pushes for rows
--   due in the next tick via a simple indexed range scan — no per-user compute.
--
-- PRIVACY (Risk 3, HIGH if missed): these `fire_utc` instants are user-private
-- schedule data — they CORRELATE to coarse region (a determined observer could
-- infer approximate longitude from prayer-derived times). RLS is REQUIRED: a
-- user may read/write ONLY their own rows; NO anon and NO public access. Raw
-- coordinates are NEVER stored here — only derived timestamps.
--
-- sync_version: monotonic per-user stamp for the atomic targeted-replace on
-- re-sync (Risk 2 — never a blind delete-all mid-cron). The client bumps it
-- each sync and deletes rows below the current version. (The sync seam + cron
-- are separate slices; this migration only lands the RLS-guarded table.)

create table if not exists public.dua_precise_notifications (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  -- 'last_third_of_night' | 'friday_hour' | 'iftar' (the precise window types).
  window_type   text not null,
  -- The absolute UTC instant this precise window opens on the user's device —
  -- computed client-side from prayer times. The cron enqueues at this instant.
  fire_utc      timestamptz not null,
  -- Monotonic per-user sync stamp for atomic targeted-replace on re-sync.
  sync_version  integer not null default 0,
  created_at    timestamptz not null default timezone('utc', now())
);

comment on table public.dua_precise_notifications is
  'User-private, RLS-guarded queue of client-computed precise duʿā-window fire '
  'instants (fire_utc). Server NEVER computes prayer times or stores coords — '
  'it only enqueues due rows to OneSignal. Correlates to coarse region → never '
  'public/anon-readable (plan 2026-07-16 §4/§5, Risk 3).';

alter table public.dua_precise_notifications enable row level security;

-- The client owns this table: it may read, insert, update, and delete only its
-- OWN rows (auth.uid() = user_id). No service-role writes from the app; no anon
-- or public access. `auth.uid()` is wrapped in a scalar subselect so Postgres
-- caches it once per statement instead of per-row (initplan optimization, see
-- 20260602004027_cancellation_feedback_rls_initplan).

drop policy if exists "Users can view own dua precise notifications"
  on public.dua_precise_notifications;
create policy "Users can view own dua precise notifications"
  on public.dua_precise_notifications
  for select
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can insert own dua precise notifications"
  on public.dua_precise_notifications;
create policy "Users can insert own dua precise notifications"
  on public.dua_precise_notifications
  for insert
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update own dua precise notifications"
  on public.dua_precise_notifications;
create policy "Users can update own dua precise notifications"
  on public.dua_precise_notifications
  for update
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can delete own dua precise notifications"
  on public.dua_precise_notifications;
create policy "Users can delete own dua precise notifications"
  on public.dua_precise_notifications
  for delete
  using ((select auth.uid()) = user_id);

-- The server due-instants query is a range scan on fire_utc
-- (`WHERE fire_utc BETWEEN now() AND now() + tick`), so index it. Composite
-- (user_id, fire_utc) also serves the per-user targeted-replace delete.
create index if not exists dua_precise_notifications_fire_utc_idx
  on public.dua_precise_notifications (fire_utc);

create index if not exists dua_precise_notifications_user_fire_idx
  on public.dua_precise_notifications (user_id, fire_utc);
