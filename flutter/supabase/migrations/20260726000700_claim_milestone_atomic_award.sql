-- Make streak-milestone claim + its Noor award ATOMIC (P1 follow-up).
--
-- BEFORE: the client called claim_streak_milestone(p_day) THEN award_noor() as
-- two separate RPCs (two transactions). If the claim committed but the second
-- call failed, the retry saw newly_claimed=false and the (idempotent) Noor
-- grant was never re-attempted → a one-time milestone grant was permanently
-- lost. A wrapper / second-RPC does NOT fix this: whichever caller claims first
-- (the streak flow OR the cosmetics flow) records the claim, and the other then
-- sees already-claimed and skips the award. The ONLY robust fix is to mint the
-- milestone Noor INSIDE claim_streak_milestone, in the same transaction — a
-- single RPC call is one tx, so the claim record and the award commit-or-roll
-- back together.
--
-- This is a CREATE OR REPLACE of the SHIPPED function with the SAME signature
-- (p_day integer → jsonb), so it replaces in place: all existing callers keep
-- working and EXECUTE grants are preserved. The ENTIRE prior body + guards
-- (from 20260726000200_fix_claim_streak_milestone.sql) are preserved verbatim;
-- the ONLY additions are:
--   * after a NEWLY-claimed row, and ONLY for the mintable milestone days
--     {7,14,30,60,100}, perform public.award_noor('milestone:N','milestone:N')
--     in the same transaction. award_noor is SECURITY DEFINER, idempotent on
--     reason_key, binds to auth.uid(), and manages its own guard GUC + amount,
--     so we reuse its audited logic rather than duplicating it.
--   * 180 / 365 are recognized-but-NON-mintable (award_noor has no arm and
--     would raise 'unknown noor reason') → the perform is guarded to the five
--     mintable days so those claims succeed WITHOUT a raise.
--   * a purely-additive 'noor_awarded' jsonb key (the minted amount, or 0).
--     Existing keys ('newly_claimed') are untouched → backward-compatible.
--
-- SECURITY DEFINER, search_path, return type (jsonb) and grants are unchanged
-- (create or replace preserves the existing EXECUTE grants).
--
-- NOTE for callers: the streak flow (streak_service.dart) ALSO calls
-- claim_streak_milestone; it will now additionally mint milestone Noor for
-- days 7/14/30/60 as a side effect. That is the intended/correct behavior (a
-- milestone reward) and, because the mint is idempotent per (user,reason_key),
-- it can only ever grant once regardless of which flow claims first.

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

  -- Guard 1: recognized milestone day only.
  if p_day not in (7,14,30,60,100,180,365) then
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
  -- award_noor actually mints (7,14,30,60,100). 180/365 are recognized but have
  -- no award_noor arm — guarding them here avoids the 'unknown noor reason'
  -- raise while still recording the claim. award_noor is idempotent per
  -- (user, reason_key='milestone:N'), so a streak rebuild can never re-mint.
  -- Same transaction as the claim → both commit or both roll back.
  if v_new and p_day in (7,14,30,60,100) then
    v_noor := public.award_noor('milestone:' || p_day, 'milestone:' || p_day);
  end if;

  return jsonb_build_object('newly_claimed', v_new, 'noor_awarded', v_noor);
end;
$function$;
