-- 2026-05-10: Close the DELETE/recreate bypass on freemium gating tables.
--
-- Background:
--   The lock_freemium_gating_fields migration (20260510010000) added BEFORE
--   UPDATE triggers preventing clients from refilling warmup_*, resetting
--   *_uses, or flipping had_trial back to false. But triggers only fire on
--   UPDATE — DELETE went unprotected, and the original RLS allowed
--   authenticated users to delete their own rows on:
--     * user_profiles                (initial_schema.sql:401)
--     * user_daily_usage             (initial_schema.sql:566)
--
--   Bypass attack:
--     1. Authenticated client deletes their user_daily_usage row for today
--        (or their user_profiles row).
--     2. Next legitimate write upserts a fresh row with default column
--        values (warmup_* back to 10/10/5, had_trial=false, *_uses=0).
--     3. Repeat for unlimited free AI calls / repeated trial.
--
--   No client code legitimately deletes from these tables. Account deletion
--   is handled by `delete_own_account()` (SECURITY DEFINER, deletes
--   auth.users which CASCADEs to all user-data tables — runs as postgres,
--   bypasses RLS entirely).
--
-- Fix (defense in depth):
--   1. DROP the "Users can delete own ..." policies. RLS stays enabled on
--      both tables, so without a DELETE policy authenticated and anon
--      clients are denied. service_role / postgres bypass RLS by default,
--      so backend rollovers and `delete_own_account` still work.
--
--   2. Add BEFORE DELETE triggers that raise an exception for non-service
--      roles. This is belt-and-suspenders: if a future migration
--      accidentally re-adds a DELETE policy, the trigger still blocks the
--      bypass.
--
-- Both triggers mirror the pattern in 20260510010000_lock_freemium_gating_fields.sql:
-- security invoker so current_user reflects the actual session role,
-- service_role/postgres/supabase_admin allowed through, errcode = check_violation.

-- ---------------------------------------------------------------------------
-- user_profiles
-- ---------------------------------------------------------------------------

drop policy if exists "Users can delete own profile" on public.user_profiles;

create or replace function public.guard_user_profiles_freemium_delete()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  if current_user in ('service_role', 'postgres', 'supabase_admin') then
    return old;
  end if;

  raise exception
    'cannot delete user_profiles row from a client session (resets warmup_* and had_trial)'
    using errcode = 'check_violation';
end
$$;

drop trigger if exists guard_user_profiles_freemium_delete on public.user_profiles;
create trigger guard_user_profiles_freemium_delete
  before delete on public.user_profiles
  for each row
  execute function public.guard_user_profiles_freemium_delete();

-- ---------------------------------------------------------------------------
-- user_daily_usage
-- ---------------------------------------------------------------------------

-- The user_daily_usage delete policy was renamed to "Own data delete" by
-- 20260510172511_drop_redundant_policies_and_indexes — drop both names so
-- this migration is correct whether replayed before or after that one.
drop policy if exists "Users can delete own daily usage" on public.user_daily_usage;
drop policy if exists "Own data delete" on public.user_daily_usage;

create or replace function public.guard_user_daily_usage_freemium_delete()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  if current_user in ('service_role', 'postgres', 'supabase_admin') then
    return old;
  end if;

  raise exception
    'cannot delete user_daily_usage row from a client session (resets daily *_uses counters)'
    using errcode = 'check_violation';
end
$$;

drop trigger if exists guard_user_daily_usage_freemium_delete on public.user_daily_usage;
create trigger guard_user_daily_usage_freemium_delete
  before delete on public.user_daily_usage
  for each row
  execute function public.guard_user_daily_usage_freemium_delete();
