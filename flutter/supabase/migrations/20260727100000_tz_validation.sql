-- One Ship W1 / Migration A — timezone input hardening
-- (docs/superpowers/plans/2026-07-26-one-ship-01-data-layer.md, review F5)
--
-- user_notification_preferences.timezone is client-written free text. The
-- notification scheduler already coalesces empty→UTC, but a NON-empty junk
-- string ('nonsense') makes `at time zone tz` RAISE — breaking the scheduler
-- row and every economy RPC that derives a user-local date. From W1 onward
-- that column feeds economy math (weekly pool reset, queue unseal), so:
--   1. reject invalid zones at write time (loud > silent — honest clients
--      send IANA names from FlutterTimezone and never hit this), and
--   2. coalesce defensively at read time for rows written before this
--      trigger existed, via safe_user_tz().

-- 1. Write-time validation ---------------------------------------------------

create or replace function public.validate_notification_timezone()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  -- Validate ONLY when the value actually changes (review P2-2): on an UPDATE
  -- that doesn't mention timezone, NEW inherits OLD — validating it would make
  -- a row holding a legacy-invalid value permanently un-updatable (all roles),
  -- and one such row aborts the notification cron's whole batch sent-column
  -- UPDATE. A future tzdata rename (e.g. Pacific/Enderbury→Kanton) must
  -- degrade to safe_user_tz's UTC fallback, never brick the scheduler.
  if (tg_op = 'INSERT' or new.timezone is distinct from old.timezone)
     and new.timezone is not null
     and btrim(new.timezone) <> ''
     and not exists (select 1 from pg_timezone_names where name = new.timezone) then
    raise exception 'invalid timezone: %', new.timezone using errcode = 'check_violation';
  end if;
  return new;
end
$$;

drop trigger if exists validate_notification_timezone on public.user_notification_preferences;
create trigger validate_notification_timezone
  before insert or update on public.user_notification_preferences
  for each row execute function public.validate_notification_timezone();

-- 2. Read-time coalesce ------------------------------------------------------
-- SECURITY INVOKER on purpose: for direct authenticated callers RLS limits the
-- read to their own row (others resolve to 'UTC'); inside SECURITY DEFINER
-- RPCs the owner role bypasses RLS and resolves the target user's real zone.

create or replace function public.safe_user_tz(p_user uuid)
returns text
language plpgsql
stable
set search_path = public, pg_temp
as $$
declare
  v_tz text;
begin
  select nullif(btrim(timezone), '') into v_tz
  from public.user_notification_preferences
  where user_id = p_user;

  if v_tz is null or not exists (select 1 from pg_timezone_names where name = v_tz) then
    return 'UTC';
  end if;
  return v_tz;
end
$$;

revoke execute on function public.validate_notification_timezone() from public, anon;
revoke execute on function public.safe_user_tz(uuid) from public, anon;
grant execute on function public.safe_user_tz(uuid) to authenticated;
