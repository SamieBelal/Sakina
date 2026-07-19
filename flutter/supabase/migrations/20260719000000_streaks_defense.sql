-- Streaks defense (Phase 2 of the streaks + companion plan, 2026-07-19).
--
-- Adds the soft-decay lapse fields, the excused-days side-table, and the two
-- server-authoritative repair RPCs. The day-to-day streak increment + free
-- soft-decay/repair stays client-computed (consistent with the existing
-- markActiveToday model); ONLY the paid buy-back is a SECURITY DEFINER RPC,
-- because it debits tokens and MUST be atomic + server-priced (CLAUDE.md:
-- never write economy tables from Flutter).
--
-- NOT YET APPLIED to the live DB at authoring time — review first.

-- ── 1. Lapse + repair bookkeeping on user_streaks ────────────────────────────
alter table public.user_streaks
  add column if not exists pre_lapse_streak int,          -- streak value saved at lapse, for buy-back
  add column if not exists lapsed_at timestamptz,          -- computed first-missed-day 00:00 UTC
  add column if not exists last_paid_repair_at timestamptz,-- paid-repair rate-limit (≤1 / 30d)
  add column if not exists premium_free_repair_at timestamptz; -- premium free-repair meter (1 / 30d)

-- ── 2. Excused days (menstruation / travel-illness) — capped, server-side ────
create table if not exists public.user_streak_excused_dates (
  user_id uuid not null references auth.users(id) on delete cascade,
  excused_date date not null,
  created_at timestamptz not null default now(),
  primary key (user_id, excused_date)
);

alter table public.user_streak_excused_dates enable row level security;

drop policy if exists "Users can view own excused dates" on public.user_streak_excused_dates;
create policy "Users can view own excused dates" on public.user_streak_excused_dates
  for select to authenticated using ((select auth.uid()) = user_id);
-- No direct INSERT policy: writes go through add_excused_date() (cap-enforced).

-- ── 3. Excused-day add (bounded ≤8 per rolling 30 days) ──────────────────────
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

-- ── 4. Paid streak buy-back (post-expiry rescue) ─────────────────────────────
-- Atomic: debits tokens AND restores the streak in one transaction, or neither.
-- Server-priced by the pre-lapse band (client cannot under-pay). Rate-limited
-- to 1 / 30d. Premium gets one free repair / 30d before tokens are charged
-- (RC premium isn't in the DB, so the client asserts p_is_premium; the server
-- still meters the free credit via premium_free_repair_at so it can't repeat).
create or replace function public.repair_streak_paid(p_is_premium boolean default false)
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
  v_premium_free boolean := false;
begin
  if uid is null then raise exception 'Not authenticated'; end if;

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

  -- Server-authoritative tier price (mirrors the token packs).
  v_cost := case
    when s.pre_lapse_streak between 7 and 29 then 100
    when s.pre_lapse_streak between 30 and 89 then 250
    else 500  -- 90+
  end;

  -- Restore the lost streak on top of whatever's been rebuilt since (incl. today).
  v_restored := s.pre_lapse_streak + s.current_streak;

  -- Premium free-monthly credit takes precedence over charging tokens.
  if p_is_premium and (s.premium_free_repair_at is null
      or now_ts >= s.premium_free_repair_at + interval '30 days') then
    v_premium_free := true;
  end if;

  if not v_premium_free then
    -- Rate-limit only the PAID path (premium free path has its own meter).
    if s.last_paid_repair_at is not null
       and now_ts < s.last_paid_repair_at + interval '30 days' then
      raise exception 'Repair rate-limited';
    end if;

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

  update public.user_streaks
    set current_streak = v_restored,
        longest_streak = greatest(longest_streak, v_restored),
        pre_lapse_streak = null,
        lapsed_at = null,
        last_paid_repair_at = case when v_premium_free then last_paid_repair_at else now_ts end,
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

-- ── 5. Server-authoritative milestone claimed-set (§2f, T3) ──────────────────
-- Today `checkStreakMilestones` claims in local prefs → on cache-clear / new
-- device the set is empty and every milestone re-fires + re-grants. Move the
-- CLAIM server-side (idempotent by PK) so the client only grants when the
-- server confirms a milestone is newly claimed. Additive — does NOT touch
-- sync_all_user_data; grants stay client-triggered but gated on this.
create table if not exists public.user_streak_milestones_claimed (
  user_id uuid not null references auth.users(id) on delete cascade,
  milestone_day int not null,
  claimed_at timestamptz not null default now(),
  primary key (user_id, milestone_day)
);

alter table public.user_streak_milestones_claimed enable row level security;

drop policy if exists "Users can view own milestone claims" on public.user_streak_milestones_claimed;
create policy "Users can view own milestone claims" on public.user_streak_milestones_claimed
  for select to authenticated using ((select auth.uid()) = user_id);

create or replace function public.claim_streak_milestone(p_day int)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  v_new boolean;
begin
  if uid is null then raise exception 'Not authenticated'; end if;

  insert into public.user_streak_milestones_claimed (user_id, milestone_day)
    values (uid, p_day)
    on conflict (user_id, milestone_day) do nothing;

  -- FOUND is true iff a row was actually inserted (false on conflict-skip),
  -- i.e. this is the first time the user has claimed this milestone anywhere.
  v_new := found;
  return jsonb_build_object('newly_claimed', v_new);
end;
$$;

-- ── 6. Grants (match the reconcile pattern: authenticated only) ──────────────
revoke execute on function public.add_excused_date(date) from public, anon;
revoke execute on function public.repair_streak_paid(boolean) from public, anon;
revoke execute on function public.claim_streak_milestone(int) from public, anon;
grant execute on function public.add_excused_date(date) to authenticated;
grant execute on function public.repair_streak_paid(boolean) to authenticated;
grant execute on function public.claim_streak_milestone(int) to authenticated;
