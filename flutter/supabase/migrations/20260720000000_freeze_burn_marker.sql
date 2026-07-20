-- Freeze-burn reunion marker (spec S4 / D14).
--
-- When a streak freeze is auto-consumed to bridge a lapse, record the burn
-- SERVER-SIDE so the Home "Welcome back — your streak is intact" reunion card
-- fires exactly once across devices and survives a cache clear / reinstall.
-- The marker is set ATOMICALLY inside consume_streak_freeze (the same UPDATE as
-- the consume) so it can never be lost if the client's subsequent user_streaks
-- upsert fails — the failure mode the eng review flagged.

alter table public.user_daily_rewards
  add column if not exists last_freeze_burn_at timestamptz,
  -- Default true = "nothing to acknowledge". A real burn sets it false;
  -- ack_freeze_burn() sets it back to true when the user dismisses the card.
  add column if not exists freeze_burn_acked boolean not null default true;

create or replace function public.consume_streak_freeze()
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  consumed boolean := false;
begin
  if current_user_id is null then
    raise exception 'Not authenticated';
  end if;

  insert into public.user_daily_rewards (user_id)
  values (current_user_id)
  on conflict (user_id) do nothing;

  -- `and streak_freeze_owned = true` makes this idempotent under concurrency:
  -- a racing second call matches 0 rows and returns false. (The client-side
  -- markActiveToday in-flight guard is the primary defense; this is depth.)
  update public.user_daily_rewards
  set streak_freeze_owned = false,
      last_freeze_burn_at = now(),
      freeze_burn_acked = false
  where user_id = current_user_id
    and streak_freeze_owned = true
  returning true into consumed;

  return coalesce(consumed, false);
end;
$$;

-- Dismiss the reunion card. Idempotent; safe to call when nothing is pending.
create or replace function public.ack_freeze_burn()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'Not authenticated';
  end if;

  update public.user_daily_rewards
  set freeze_burn_acked = true
  where user_id = current_user_id;
end;
$$;

-- Re-creating consume_streak_freeze can reset its grants; re-apply the same
-- authenticated-only policy the reconcile migration established.
revoke execute on function public.consume_streak_freeze() from public, anon, authenticated;
grant  execute on function public.consume_streak_freeze() to authenticated;

revoke execute on function public.ack_freeze_burn() from public, anon;
grant  execute on function public.ack_freeze_burn() to authenticated;
