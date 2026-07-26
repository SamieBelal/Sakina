-- Align the streak-milestone day set on 90 (the client is canonical).
--
-- THE BUG: three sources disagreed on the milestone days.
--   * lib/services/streak_service.dart  streakMilestones = {7,14,30,60,90,180,365}
--   * claim_streak_milestone recognized set              = {7,14,30,60,100,180,365}
--   * award_noor case arms                               = {7,14,30,60,100}
-- streak_service.dart is the ONLY caller of claim_streak_milestone and it can
-- only ever send a day drawn from streakMilestones. So a user who actually
-- reached a 90-day streak hit `raise 'unrecognized milestone day 90'`;
-- SupabaseSyncService.callRpc swallows the raise, so the claim was silently
-- never recorded server-side (the local XP/title grant still fired, and the
-- milestone Noor was never minted). Meanwhile day 100 was unreachable dead
-- code — no client has ever been able to send it.
--
-- THE FIX: swap 100 → 90 in both server-side day sets so all three sources
-- agree on the client's list.
--
-- DECISION — 100 is FULLY REMOVED, not kept as a legacy no-op.
--   Rationale: 100 was never a milestone any client could reach. The only
--   caller derives p_day from streakMilestones, which has never contained 100
--   (it has had 90 since the streak system shipped), so no user_streak_milestones_claimed
--   row and no noor_grants 'milestone:100' row can exist from the app. A local
--   DB check confirmed zero rows in both tables. Keeping 100 recognized would
--   preserve a claim path that nothing calls while leaving a second, wrong
--   milestone day in the guard — exactly the drift this migration exists to
--   remove. Prod-safety: even if a day-100 claim row somehow existed, it is a
--   historical record; this guard only gates NEW claims and does not read,
--   rewrite, or invalidate stored rows.
--
-- Both functions are CREATE OR REPLACE at the SAME signature, so they replace
-- in place and existing EXECUTE grants are preserved. Everything other than
-- the day sets / the one case arm is carried over VERBATIM: the auth check,
-- the recognized-day guard shape, the reached-check guard, SECURITY DEFINER,
-- the pinned search_path, the 'newly_claimed' + 'noor_awarded' return keys and
-- the atomic in-transaction `public.award_noor(...)` mint.

-- ── claim_streak_milestone: recognized {…,90,…}, mint guard {7,14,30,60,90} ──
-- (body from 20260726000700_claim_milestone_atomic_award.sql — the live
--  definition — with ONLY the two day sets changed.)
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
begin
  if uid is null then raise exception 'Not authenticated'; end if;

  -- Guard 1: recognized milestone day only. Matches streakMilestones in
  -- lib/services/streak_service.dart exactly (90, never 100).
  if p_day not in (7,14,30,60,90,180,365) then
    raise exception 'unrecognized milestone day %', p_day;
  end if;
  -- Guard 2: user must have actually reached it.
  if coalesce((select current_streak from public.user_streaks where user_id = uid), 0) < p_day then
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

-- ── award_noor: the 'milestone:100' arm becomes 'milestone:90' ───────────────
-- (body from 20260726000000_cosmetics_economy.sql — no later migration
--  redefines it — with ONLY that one case arm changed. Amount unchanged at 400.)
create or replace function public.award_noor(p_reason text, p_reason_key text)
returns integer
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_amount integer;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  v_amount := case
    when p_reason = 'daily'          then 10
    when p_reason = 'milestone:7'    then 40
    when p_reason = 'milestone:14'   then 75
    when p_reason = 'milestone:30'   then 150
    when p_reason = 'milestone:60'   then 250
    when p_reason = 'milestone:90'   then 400
    when p_reason = 'quest'          then 15
    else null end;
  if v_amount is null then raise exception 'unknown noor reason: %', p_reason; end if;

  insert into public.noor_grants(user_id, reason_key, amount)
    values (v_uid, p_reason_key, v_amount)
    on conflict (user_id, reason_key) do nothing;
  if not found then return 0; end if;

  perform set_config('app.cosmetics_rpc','on', true);
  update public.user_profiles
     set noor_balance = noor_balance + v_amount,
         noor_total_earned = noor_total_earned + v_amount
   where id = v_uid;
  return v_amount;
end $$;

revoke execute on function public.award_noor(text,text) from public, anon;
grant  execute on function public.award_noor(text,text) to authenticated;
