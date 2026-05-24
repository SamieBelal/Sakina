-- 2026-05-10: Lock freemium gating fields against client tampering.
--
-- Background:
--   The freemium redesign migration (20260509120000_freemium_tier_redesign.sql)
--   added warmup counters + a one-way `had_trial` latch on user_profiles, and
--   a `discover_name_uses` column on user_daily_usage (joining the existing
--   reflect_uses, built_dua_uses).
--
--   The existing RLS on these tables (initial_schema.sql) is column-blind: it
--   only checks row ownership (auth.uid() = id / user_id). A signed-in user
--   with the supabase client SDK can therefore UPDATE any column on their own
--   row — including refilling warmups, resetting *_uses to 0, or flipping
--   had_trial false again to re-trigger a free trial.
--
-- Threat model:
--   * Reset warmup_*_remaining → unlimited free AI calls (warmup never runs out)
--   * Reset reflect_uses / built_dua_uses / discover_name_uses → unlimited 1/day
--     calls per day
--   * Flip had_trial true → false → fresh trial after subscription lapse,
--     repeatable indefinitely
--
-- Fix:
--   BEFORE UPDATE triggers enforce monotonicity at the row level.
--
--     user_profiles
--       warmup_*_remaining   : decrement-only (NEW <= OLD)
--       had_trial            : one-way latch (false→true ok, true→false rejected)
--
--     user_daily_usage
--       reflect_uses         : monotonic non-decreasing (NEW >= OLD)
--       built_dua_uses       : monotonic non-decreasing (NEW >= OLD)
--       discover_name_uses   : monotonic non-decreasing (NEW >= OLD)
--
--   Writes that don't change the column (NEW = OLD) are always allowed, so
--   unrelated UPDATEs (display_name edits, onboarding profile fields, etc.)
--   keep working unchanged.
--
-- Service-role bypass:
--   Triggers fire for every role, including service_role (which is otherwise
--   exempt from RLS). The daily_usage rollover, admin tools, and the
--   revenuecat webhook may legitimately need to reset these values. We allow
--   `current_user = 'service_role'` (the actual Postgres role Supabase uses
--   for service-key requests) and `current_user = 'postgres'` (superuser /
--   migrations) to bypass the trigger's checks. Authenticated and anon
--   sessions remain locked.
--
-- search_path is pinned to `public, pg_temp` per the project pattern (see
-- 20260510000000_pin_function_search_path.sql) — these triggers don't call
-- unqualified built-ins, but the pin matches the convention and removes any
-- future risk of search-path hijacking.

-- ---------------------------------------------------------------------------
-- user_profiles guard
-- ---------------------------------------------------------------------------

create or replace function public.guard_user_profiles_freemium_fields()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  -- Service-role + postgres (migration owner) bypass. Triggers run as the
  -- calling role, so current_user reflects the actual Postgres role for the
  -- session (service_role for backend API calls, authenticated for end users,
  -- postgres for direct DB / migration access).
  if current_user in ('service_role', 'postgres', 'supabase_admin') then
    return new;
  end if;

  -- warmup_reflect_remaining: decrement-only.
  if new.warmup_reflect_remaining > old.warmup_reflect_remaining then
    raise exception
      'cannot reset/refill freemium gating field: warmup_reflect_remaining (% -> %)',
      old.warmup_reflect_remaining, new.warmup_reflect_remaining
      using errcode = 'check_violation';
  end if;

  -- warmup_built_dua_remaining: decrement-only.
  if new.warmup_built_dua_remaining > old.warmup_built_dua_remaining then
    raise exception
      'cannot reset/refill freemium gating field: warmup_built_dua_remaining (% -> %)',
      old.warmup_built_dua_remaining, new.warmup_built_dua_remaining
      using errcode = 'check_violation';
  end if;

  -- warmup_discover_name_remaining: decrement-only.
  if new.warmup_discover_name_remaining > old.warmup_discover_name_remaining then
    raise exception
      'cannot reset/refill freemium gating field: warmup_discover_name_remaining (% -> %)',
      old.warmup_discover_name_remaining, new.warmup_discover_name_remaining
      using errcode = 'check_violation';
  end if;

  -- had_trial: one-way latch. Allow false→true and same. Reject true→false.
  if old.had_trial = true and new.had_trial = false then
    raise exception
      'cannot reset/refill freemium gating field: had_trial (true -> false is forbidden)'
      using errcode = 'check_violation';
  end if;

  return new;
end
$$;

drop trigger if exists guard_user_profiles_freemium_fields on public.user_profiles;
create trigger guard_user_profiles_freemium_fields
  before update on public.user_profiles
  for each row
  execute function public.guard_user_profiles_freemium_fields();

-- ---------------------------------------------------------------------------
-- user_daily_usage guard
-- ---------------------------------------------------------------------------

create or replace function public.guard_user_daily_usage_freemium_fields()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  if current_user in ('service_role', 'postgres', 'supabase_admin') then
    return new;
  end if;

  if new.reflect_uses < old.reflect_uses then
    raise exception
      'cannot reset/refill freemium gating field: reflect_uses (% -> %)',
      old.reflect_uses, new.reflect_uses
      using errcode = 'check_violation';
  end if;

  if new.built_dua_uses < old.built_dua_uses then
    raise exception
      'cannot reset/refill freemium gating field: built_dua_uses (% -> %)',
      old.built_dua_uses, new.built_dua_uses
      using errcode = 'check_violation';
  end if;

  if new.discover_name_uses < old.discover_name_uses then
    raise exception
      'cannot reset/refill freemium gating field: discover_name_uses (% -> %)',
      old.discover_name_uses, new.discover_name_uses
      using errcode = 'check_violation';
  end if;

  return new;
end
$$;

drop trigger if exists guard_user_daily_usage_freemium_fields on public.user_daily_usage;
create trigger guard_user_daily_usage_freemium_fields
  before update on public.user_daily_usage
  for each row
  execute function public.guard_user_daily_usage_freemium_fields();
