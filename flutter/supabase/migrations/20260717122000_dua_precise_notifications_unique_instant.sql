-- 20260717122000_dua_precise_notifications_unique_instant.sql
--
-- Duʿā Scheduled Notifications (Phase 2) — enforce ONE row per user per precise
-- fire instant so the client sync race can NEVER double-enqueue a push.
--
-- Plan: docs/superpowers/plans/2026-07-16-dua-scheduled-notifications.md (§4, Risk 2).
-- Base table: 20260716120000_dua_precise_notifications.sql.
--
-- WHY (code-review P2-1): the client sync is a 3-step non-atomic replace —
-- fetch max(sync_version) → insert fresh rows at max+1 → delete rows below max+1.
-- Two concurrent syncs (two devices, or a fast double foreground-resume) can
-- both read prior=N, both insert at N+1, and each delete-below-N+1 leaves the
-- OTHER run's rows in place → DUPLICATE rows for the same
-- (user_id, window_type, fire_utc). The send-scheduled-notifications cron dedups
-- identical instants today, but correctness must not lean on the sender.
--
-- This UNIQUE constraint makes two rows for the same instant physically
-- impossible. The client pairs it with an UPSERT (ON CONFLICT ... DO UPDATE
-- sync_version/title/body): re-syncing the SAME instants bumps their version so
-- they survive the delete-below, while stale instants keep the old version and
-- are retired — no CONFLICT-driven insert failure that would empty the schedule.
--
-- Guarded so re-applying (or applying over a table that already has it) is a
-- no-op. fire_utc is stored as the exact UTC instant the client computed, so the
-- (user_id, window_type, fire_utc) tuple is a stable natural key.

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'dua_precise_notifications_user_window_instant_uniq'
      and conrelid = 'public.dua_precise_notifications'::regclass
  ) then
    alter table public.dua_precise_notifications
      add constraint dua_precise_notifications_user_window_instant_uniq
      unique (user_id, window_type, fire_utc);
  end if;
end $$;

comment on constraint dua_precise_notifications_user_window_instant_uniq
  on public.dua_precise_notifications is
  'One row per user per precise fire instant. Prevents the client sync race '
  '(concurrent syncs both inserting at max+1) from double-enqueuing a push; the '
  'client upserts ON CONFLICT to bump sync_version so re-synced instants survive '
  'the delete-below-version step (plan 2026-07-16 §4, Risk 2 / review P2-1).';
