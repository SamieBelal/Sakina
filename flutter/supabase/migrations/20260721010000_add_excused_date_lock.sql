-- Fix: add_excused_date() concurrency — per-user advisory lock.
--
-- BUG (20260719000000_streaks_defense.sql):
--   add_excused_date() does:
--     SELECT count(*) ... WHERE excused_date > now()-30   -- reads cnt
--     IF cnt >= 8 THEN RAISE                             -- guard
--     INSERT ...                                         -- writes
--
--   There is NO lock between the count and the insert.  Two concurrent
--   sessions with DIFFERENT p_date values (so the PK uniqueness on
--   (user_id, excused_date) does NOT help) both read cnt=7, both pass
--   the >= 8 guard, both insert → 9 rows in the window (cap breached).
--
-- FIX: take a per-user advisory transaction lock at the top of the
--   function body, before the count.  pg_advisory_xact_lock() is:
--     • Transaction-scoped: released automatically at commit/rollback.
--     • Session-serializing: a second caller blocks until the first's
--       transaction ends, so it sees the committed row before its count.
--     • No manual release needed.
--
-- Everything else (security definer, search_path, idempotent early-return,
-- cap semantics, return shape, grants) is preserved verbatim.

create or replace function public.add_excused_date(p_date date)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  cnt int;
begin
  if uid is null then raise exception 'Not authenticated'; end if;

  -- Per-user serialization lock: blocks any concurrent add_excused_date call
  -- for the same user until this transaction commits.  This closes the
  -- count-then-insert gap: a second concurrent session will not see the
  -- pre-insert count because it waits here until the first session has
  -- committed (or rolled back).
  perform pg_advisory_xact_lock(hashtextextended(uid::text, 0));

  -- Idempotent: an already-excused date is a no-op and never trips the cap.
  if exists (
    select 1 from public.user_streak_excused_dates
      where user_id = uid and excused_date = p_date
  ) then
    select count(*) into cnt from public.user_streak_excused_dates
      where user_id = uid and excused_date > (timezone('utc', now())::date - 30);
    return jsonb_build_object('ok', true, 'count_in_window', cnt);
  end if;

  select count(*) into cnt
    from public.user_streak_excused_dates
    where user_id = uid
      and excused_date > (timezone('utc', now())::date - 30);

  if cnt >= 8 then
    raise exception 'Excused cap reached';
  end if;

  insert into public.user_streak_excused_dates (user_id, excused_date)
    values (uid, p_date);

  return jsonb_build_object('ok', true, 'count_in_window', cnt + 1);
end;
$$;

-- Re-grant (idempotent — matches 20260719000000_streaks_defense.sql).
revoke execute on function public.add_excused_date(date) from public, anon;
grant execute on function public.add_excused_date(date) to authenticated;
