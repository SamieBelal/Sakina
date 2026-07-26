-- Verify the milestone "reached" check server-side instead of trusting a
-- column the client can write.
--
-- ── THE EXPLOIT (reproduced on the local DB, rolled back) ───────────────────
-- `claim_streak_milestone(p_day)` decided whether the caller had reached day N
-- by reading `user_streaks.current_streak`. But `user_streaks` grants
-- `authenticated` direct INSERT/UPDATE/DELETE on its own row, and the UPDATE
-- policy carries no WITH CHECK. So the caller writes its own answer:
--
--     update user_streaks set current_streak = 365 where user_id = me;
--     claim_streak_milestone(7)  → 40
--     claim_streak_milestone(14) → 75
--     claim_streak_milestone(30) → 150
--     claim_streak_milestone(60) → 250
--     claim_streak_milestone(90) → 400
--     select noor_balance …      → 915          -- account created minutes ago
--
-- 915 Noor clears most of `cosmetic_catalog`, including à-la-carte skins that
-- also carry an `iap_product_id` (real-money SKUs) — the same revenue-loss
-- shape as the award_noor hole closed in 20260726200600, and repeatable on
-- every throwaway account at zero cost.
--
-- ── SCOPE: the streak WRITE PATH IS DELIBERATELY LEFT ALONE ─────────────────
-- `lib/services/streak_service.dart` upserts `user_streaks` directly
-- (markActiveToday) and that is the shipped, load-bearing retention mechanic.
-- Revoking those writes or moving streak advancement behind an RPC is a larger,
-- separate change. This migration changes ONLY the reached-check, and only by
-- ADDING a guard: the recognized-day set, the atomic award_noor mint, the
-- return keys, SECURITY DEFINER, the pinned search_path and the grants are
-- carried over verbatim from 20260726000800_align_milestone_day_90.sql (the
-- live definition — confirmed nothing between it and this file redefines the
-- function).
--
-- ── WHY NOT user_checkin_history ───────────────────────────────────────────
-- It was the obvious candidate — 20260726200600 already leans on it to gate
-- `award_daily_noor`. It does not work here, for two independent reasons.
--
-- (a) It is client-forgeable in the direction that matters. Its RLS is the same
--     open shape as `user_streaks` (`INSERT … WITH CHECK (auth.uid() = user_id)`,
--     plus UPDATE and DELETE), `checked_in_at` is an ordinary client-supplied
--     column with only a `now()` DEFAULT, and `lib/services/checkin_history_service.dart`
--     writes it by plain PostgREST insert. A caller can insert 365 backdated
--     rows as easily as it can write one integer. Basing the guard on it would
--     move the forgery one table over, not close it.
--
-- (b) Worse, it would FALSELY DENY real users, because in this app a streak day
--     is not the same thing as a check-in row. `markActiveToday()` — the only
--     thing that advances the streak — is called from
--     `reflect_provider.dart:797` as well as the daily loop, but a
--     `user_checkin_history` row is written ONLY by `daily_loop_provider.dart`.
--     So Reflect-only days advance the streak with no check-in row at all. On
--     top of that the repair ladder in `_markActiveTodayImpl` deliberately
--     carries a streak ACROSS days with no activity of any kind: the free
--     effort-repair window forgives a lapse outright, and a consumed freeze
--     covers the gap via `user_streak_excused_dates`. A legitimate
--     `current_streak = 90` can therefore sit on well under 90 check-in rows.
--
-- This also rules out the stricter "consecutive-day run" formulation: freezes
-- and effort-repair exist precisely to make a streak survive non-consecutive
-- days, so a consecutive-run check would deny the very users the feature was
-- built to keep. Neither a distinct-day count nor a run length is a sound
-- reconstruction of this app's streak.
--
-- ── THE SIGNAL ACTUALLY USED: auth.users.created_at ────────────────────────
-- Signup time is the one fact in this transaction the caller cannot author.
-- `authenticated` holds NO privilege on `auth.users` — verified on the live DB,
-- `has_table_privilege('authenticated','auth.users','select')` and `…,'update')`
-- are both false — and PostgREST does not expose the `auth` schema. There is no
-- RPC that writes it. It is set once by GoTrue at registration.
--
-- And it is a NECESSARY condition, which is what makes it safe: streak days are
-- distinct UTC dates (`_todayString()` in streak_service.dart is `.toUtc()`),
-- so reaching day N requires the account to have existed across N distinct UTC
-- dates. No user has ever legitimately reached day N on a younger account, so
-- this guard cannot deny a milestone anyone earned. That property is what
-- check-in evidence lacked.
--
-- Day 1 lands on the signup date itself, so day N needs only N-1 date
-- boundaries. The guard requires N-2 — one full extra day of slack, so that a
-- device clock running ahead, or a user near the international date line
-- crossing into their local day early, can never be refused at the boundary.
-- The cost of that slack is nil: the attacker's bill for the 400-Noor day-90
-- prize goes from zero to 88 real days of holding an account.
--
-- NULL `created_at` is treated as "age unknown", not as evidence of forgery,
-- and passes. The column is nullable and carries no default; the caller cannot
-- set it to NULL (no write privilege), so allowing NULL opens nothing, while
-- denying it would break any legacy row GoTrue left unstamped — and every other
-- pgTAP file in this repo seeds `auth.users` without it.
--
-- ── THE HONEST RESIDUAL ────────────────────────────────────────────────────
-- This makes the forgery cost the attacker the same WALL CLOCK an honest user
-- pays; it does not make it cost the same ATTENTION. A long-tenured account
-- that never actually streaked can still forge `current_streak` and claim the
-- ladder today, and a fresh account can do it after waiting out the milestone.
-- What it removes is the part that was actually worth exploiting: the instant
-- 915-Noor harvest on a throwaway account, repeatable without limit. Note the
-- payout is bounded at 915 per account forever regardless — `award_noor`
-- dedupes on `(user_id, reason_key='milestone:N')` — so what remained was
-- time-shifting, and time is now what it costs.
--
-- Closing the residual needs a server-authoritative record of daily activity,
-- which does not exist yet for historical users. One is now accumulating:
-- `award_daily_noor()` (20260726200600) writes `noor_grants` rows keyed
-- `'daily:' || <server UTC date>`, and `noor_grants` has RLS enabled with no
-- write policy for `authenticated`, so those rows are unforgeable and cannot be
-- backdated — the reason_key is stamped with the server's date at mint time.
-- Once that ledger is older than the longest milestone, this guard can be
-- tightened to `count(distinct daily: grants) >= p_day`. Requiring it today
-- would deny every existing user, since the function shipped this week.
-- Tracked as follow-up.

create or replace function public.claim_streak_milestone(p_day integer)
  returns jsonb
  language plpgsql
  security definer
  set search_path to 'public'
as $function$
declare
  uid uuid := auth.uid();
  v_new boolean;
  v_noor int := 0;
  v_signup_date date;
begin
  if uid is null then raise exception 'Not authenticated'; end if;

  -- Guard 1: recognized milestone day only. Matches streakMilestones in
  -- lib/services/streak_service.dart exactly (90, never 100). UNCHANGED.
  if p_day not in (7,14,30,60,90,180,365) then
    raise exception 'unrecognized milestone day %', p_day;
  end if;

  -- Guard 2: the client's own claim about its streak. UNCHANGED, but no longer
  -- sufficient on its own — guard 3 is what makes it cost something.
  if coalesce((select current_streak from public.user_streaks where user_id = uid), 0) < p_day then
    raise exception 'milestone % not reached', p_day;
  end if;

  -- Guard 3 (NEW): server-authoritative elapsed-time floor. `auth.users` is
  -- unreachable from the client, so this cannot be forged; and because it is a
  -- necessary condition for the streak, it cannot deny an earned milestone.
  -- Fully qualified because search_path is pinned to 'public'.
  select (u.created_at at time zone 'utc')::date
    into v_signup_date
    from auth.users u
   where u.id = uid;

  -- Same message as guard 2 on purpose: the client (streak_service.dart, via
  -- SupabaseSyncService.callRpc) only ever sees "the RPC raised", and keeping
  -- one string keeps that contract and the existing tests byte-compatible.
  if v_signup_date is not null
     and ((now() at time zone 'utc')::date - v_signup_date) < (p_day - 2) then
    raise exception 'milestone % not reached', p_day;
  end if;

  insert into public.user_streak_milestones_claimed (user_id, milestone_day)
    values (uid, p_day)
    on conflict (user_id, milestone_day) do nothing;

  -- FOUND is true iff a row was actually inserted (false on conflict-skip),
  -- i.e. this is the first time the user has claimed this milestone anywhere.
  v_new := found;

  -- ATOMIC milestone Noor: only on a fresh claim, and only for the days
  -- award_noor actually mints (7,14,30,60,90). 180/365 are recognized but have
  -- no award_noor arm — guarding them here avoids the 'unknown noor reason'
  -- raise while still recording the claim. award_noor is idempotent per
  -- (user, reason_key='milestone:N'), so a streak rebuild can never re-mint.
  -- Same transaction as the claim → both commit or both roll back.
  if v_new and p_day in (7,14,30,60,90) then
    v_noor := public.award_noor('milestone:' || p_day, 'milestone:' || p_day);
  end if;

  return jsonb_build_object('newly_claimed', v_new, 'noor_awarded', v_noor);
end;
$function$;

-- CREATE OR REPLACE at the same signature preserves existing grants; restated
-- for the same reason 20260726000800 restated award_noor's — so the intended
-- reachability is readable from this file alone.
revoke execute on function public.claim_streak_milestone(integer) from public, anon;
grant  execute on function public.claim_streak_milestone(integer) to authenticated;
