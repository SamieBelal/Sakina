-- Fix: repair_streak_paid() shared 30-day rate-limit meter.
--
-- BUG (20260719000000_streaks_defense.sql, line 167):
--   last_paid_repair_at = case when v_premium_free then last_paid_repair_at else now_ts end
-- When the premium-free path runs, last_paid_repair_at stays NULL.  The paid
-- rate-limit guard only fires when last_paid_repair_at IS NOT NULL, so a user
-- who takes a free repair (leaving it NULL) and then loses premium can take a
-- second paid repair in the same 30-day window — violating the 1-repair/30d
-- intent.
--
-- FIX: always stamp last_paid_repair_at = now_ts on a successful repair,
-- regardless of whether it was free or paid.  The paid guard
-- ("last_paid_repair_at IS NOT NULL AND < +30d") then blocks both types.
-- premium_free_repair_at continues to be stamped on the free path as before
-- (it gates the once-per-30d free credit, unchanged).
-- The rate-limit check is also moved before the free/paid branch so it blocks
-- BOTH paths identically (the free credit does not bypass the shared meter).
--
-- All other behaviour (pricing, restore math, premium detection, window check,
-- atomicity, grants) is preserved verbatim.

create or replace function public.repair_streak_paid()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  s record;
  now_ts timestamptz := now();
  v_cost int;
  v_restored int;
  v_balance int;
  v_is_premium boolean;
  v_premium_free boolean := false;
begin
  if uid is null then raise exception 'Not authenticated'; end if;

  -- Server-authoritative premium (RC entitlement via webhook OR granted premium).
  v_is_premium := public.has_active_premium_entitlement(uid)
    or exists (
      select 1 from public.user_profiles p
      where p.id = uid
        and (p.referral_premium_until > now_ts
             or p.gift_premium_until > now_ts
             or p.trial_premium_until > now_ts)
    );

  select current_streak, longest_streak, pre_lapse_streak, lapsed_at,
         last_paid_repair_at, premium_free_repair_at
    into s
    from public.user_streaks
    where user_id = uid
    for update;
  if not found then raise exception 'No streak row'; end if;

  -- Must be a restorable, expired streak worth buying back.
  if coalesce(s.pre_lapse_streak, 0) < 7
     or coalesce(s.pre_lapse_streak, 0) <= s.current_streak then
    raise exception 'Nothing to restore';
  end if;

  -- Buy-back window: within 30 days of the lapse.
  if s.lapsed_at is null or now_ts > s.lapsed_at + interval '30 days' then
    raise exception 'Repair window passed';
  end if;

  -- Shared 30-day rate-limit: blocks BOTH paid AND premium-free paths.
  -- last_paid_repair_at is stamped on every successful repair (see UPDATE
  -- below), so this guard fires regardless of how the previous repair was paid.
  if s.last_paid_repair_at is not null
     and now_ts < s.last_paid_repair_at + interval '30 days' then
    raise exception 'Repair rate-limited';
  end if;

  -- Server-authoritative tier price (mirrors the token packs).
  v_cost := case
    when s.pre_lapse_streak between 7 and 29 then 100
    when s.pre_lapse_streak between 30 and 89 then 250
    else 500  -- 90+
  end;

  -- Restore the lost streak on top of whatever's been rebuilt since (incl. today).
  v_restored := s.pre_lapse_streak + s.current_streak;

  -- Premium free-monthly credit takes precedence over charging tokens.
  if v_is_premium and (s.premium_free_repair_at is null
      or now_ts >= s.premium_free_repair_at + interval '30 days') then
    v_premium_free := true;
  end if;

  if not v_premium_free then
    update public.user_tokens
      set balance = balance - v_cost,
          total_spent = total_spent + v_cost
      where user_id = uid and balance >= v_cost
      returning balance into v_balance;
    if not found then
      raise exception 'Insufficient tokens';
    end if;
  else
    select balance into v_balance from public.user_tokens where user_id = uid;
  end if;

  -- FIX: always stamp last_paid_repair_at so the shared 30-day meter is set
  -- regardless of whether this was a free or paid repair.
  update public.user_streaks
    set current_streak = v_restored,
        longest_streak = greatest(longest_streak, v_restored),
        pre_lapse_streak = null,
        lapsed_at = null,
        last_paid_repair_at = now_ts,
        premium_free_repair_at = case when v_premium_free then now_ts else premium_free_repair_at end,
        last_active = timezone('utc', now_ts)::date
    where user_id = uid;

  return jsonb_build_object(
    'restored', true,
    'method', case when v_premium_free then 'premium_free' else 'paid' end,
    'current_streak', v_restored,
    'balance', coalesce(v_balance, 0),
    'cost', case when v_premium_free then 0 else v_cost end
  );
end;
$$;

-- Re-grant (idempotent — matches the original migration).
revoke execute on function public.repair_streak_paid() from public, anon;
grant execute on function public.repair_streak_paid() to authenticated;
