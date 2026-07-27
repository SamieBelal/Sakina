-- Lock down award_noor: the client may no longer choose an amount or a dedupe key.
--
-- ── THE EXPLOIT (confirmed on the local DB, rolled back) ────────────────────
-- `public.award_noor(p_reason text, p_reason_key text)` shipped with
-- `grant execute … to authenticated`. It derives the AMOUNT from the
-- client-supplied `p_reason` and dedupes on the client-supplied `p_reason_key`.
-- A dedupe key the caller picks is not a dedupe key. As role `authenticated`:
--
--     award_noor('milestone:90','k1') → 400
--     award_noor('milestone:90','k2') → 400   -- any fresh key mints again
--     award_noor('milestone:90','k3') → 400
--     award_noor('milestone:90','k4') → 400
--     select noor_balance …           → 1600
--     unlock_cosmetic('lantern_skin','crystal_star') → t
--
-- `crystal_star` carries BOTH `noor_price = 300` AND
-- `iap_product_id = 'sakina.skin.crystal'` — an à-la-carte real-money SKU. So
-- forged Noor converts directly into paid content: this is revenue loss, not
-- just an economy imbalance. Every priced cosmetic in `cosmetic_catalog` is
-- reachable this way; the ceiling is unbounded because the attacker supplies a
-- fresh key each call.
--
-- ── THE FIX ────────────────────────────────────────────────────────────────
-- 1. Revoke EXECUTE on award_noor from authenticated/anon/public. It remains
--    callable by `service_role` and by SECURITY DEFINER functions, which
--    execute as the owner (postgres) and therefore keep their implicit grant —
--    `claim_streak_milestone` goes on minting the milestone Noor atomically
--    inside its own transaction, unchanged.
-- 2. Add ONE narrow, server-authoritative client earn path,
--    `award_daily_noor()`, which takes NO arguments: both the reason and the
--    dedupe key are derived server-side, and it mints only after verifying from
--    the server's own tables that the caller actually completed today's daily.
--
-- award_noor's body, amounts, ledger semantics and the milestone path are NOT
-- touched. `unlock_cosmetic` / `equip_cosmetic` are NOT touched.
--
-- ── WHY THERE IS NO award_quest_noor ───────────────────────────────────────
-- Quest completion has NO server-authoritative record to verify against.
-- `public.user_quest_progress` is written straight from Flutter by PostgREST
-- upsert (`quests_provider.dart` → `.upsert(..., onConflict:
-- 'user_id,quest_id,period_start')`), under an RLS policy that permits any
-- INSERT/UPDATE where `user_id = auth.uid()`. `quest_id` is free-form `text`
-- with no FK and no catalog table behind it, and `completed` is a plain boolean
-- the client sets. An `award_quest_noor(p_quest_id text)` that trusted
-- "completed = true for this quest_id" would therefore be exactly as forgeable
-- as the function it replaced: insert a row with an invented quest_id and
-- completed = true, mint 15, repeat with a new id, forever.
--
-- So the quest earn path is left DISABLED rather than reimplemented as a
-- forgeable RPC. Nothing regresses today: `awardNoor(reason:'quest', …)` has no
-- production call site in `lib/` (it was Lane B scaffolding, exercised only by
-- unit tests) — the quest→Noor hook was never wired up. Re-enabling it needs a
-- server-side quest ledger first: a `quest_catalog` table constraining
-- `quest_id`, plus completion recorded by a SECURITY DEFINER RPC that evaluates
-- the quest's own requirement from server data rather than accepting a
-- client-asserted `completed`.
--
-- ── HONEST LIMIT OF THE DAILY CHECK ────────────────────────────────────────
-- `user_checkin_history` is also client-written (same RLS shape), so a
-- determined client can insert a checkin row it did not earn. What the daily
-- path buys is a hard RATE CAP rather than proof of intent: the dedupe key is
-- `'daily:' || <server UTC date>`, derived inside the function, so the most any
-- account can extract is ONE 10-Noor grant per server day — precisely the rate
-- a user who simply opens the app earns anyway. That turns an unbounded mint
-- into a no-gain one. Making the daily grant genuinely unforgeable requires the
-- same fix as quests: the checkin write must move behind a SECURITY DEFINER RPC
-- so the client stops being the author of its own eligibility. Tracked as
-- follow-up; out of scope here, where the objective is closing the unbounded
-- mint.

-- ── 1. Revoke the client's direct access ───────────────────────────────────
revoke execute on function public.award_noor(text, text) from authenticated;
revoke execute on function public.award_noor(text, text) from anon;
revoke execute on function public.award_noor(text, text) from public;

-- ── 2. The one server-authoritative client earn path ───────────────────────
-- Returns the amount actually minted: 10 on the first call of the server day
-- for a caller who has completed today's daily, 0 on a replay, and 0 when the
-- caller has no checkin row for today. Never raises for the "not eligible"
-- case — a client that calls this speculatively after a loop it did not finish
-- gets a quiet 0, matching `awardNoor`'s old return contract.
--
-- The UTC day is used for BOTH the eligibility window and the dedupe key, so
-- the two can never disagree; a user far from UTC may see their grant land
-- against the adjacent UTC date, but still exactly one grant per UTC day.
create or replace function public.award_daily_noor()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid   uuid := auth.uid();
  v_today date := (now() at time zone 'utc')::date;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;

  -- Server-derived eligibility: the caller must have a checkin recorded for
  -- the server's current UTC date. The client asserts nothing here.
  if not exists (
    select 1
      from public.user_checkin_history c
     where c.user_id = v_uid
       and (c.checked_in_at at time zone 'utc')::date = v_today
  ) then
    return 0;
  end if;

  -- Reason AND dedupe key are both server-derived. award_noor's
  -- (user_id, reason_key) ledger makes this idempotent for the day.
  return public.award_noor('daily', 'daily:' || v_today::text);
end $$;

revoke execute on function public.award_daily_noor() from public, anon;
grant  execute on function public.award_daily_noor() to authenticated;
