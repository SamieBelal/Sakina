-- Harden claim_streak_milestone against arbitrary-day claims.
--
-- The original function (20260719000000_streaks_defense.sql) inserted a claim
-- row for ANY p_day the caller passed, with no check that the day is a real
-- milestone or that the user actually reached it. Since we're about to hang
-- valuable Noor / cosmetic grants off milestone claims, an authenticated user
-- could otherwise farm grants for arbitrary days.
--
-- This preserves the original body EXACTLY and only prepends two guard checks
-- at the top of the executable body:
--   1. p_day must be a recognized milestone day (7,14,30,60,100,180,365).
--   2. The caller's current_streak must be >= p_day (they actually reached it).
--
-- SECURITY DEFINER, search_path, return type (jsonb) and grants are all
-- unchanged (create or replace preserves the existing EXECUTE grants).

create or replace function public.claim_streak_milestone(p_day integer)
  returns jsonb
  language plpgsql
  security definer
  set search_path to 'public'
as $function$
declare
  uid uuid := auth.uid();
  v_new boolean;
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
  return jsonb_build_object('newly_claimed', v_new);
end;
$function$;
