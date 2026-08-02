-- T0 — put EVERY account on the reel_v1 free tier, immediately (D12).
-- STAGED: run once, on release day, after the T0 build is live. See README.md.
--
-- ⚠️ RUN THE WHOLE FILE IN ONE TRANSACTION. `psql -1 -f <this file>`, or paste
-- it with an explicit BEGIN/COMMIT around it. Without that, an error partway
-- through leaves the snapshot taken and the flip half-applied — and in a client
-- that does not set ON_ERROR_STOP, execution simply continues past the failure.
-- The individual UPDATE is atomic on its own; the FILE is not (review,
-- 2026-08-02).
--
-- Supersedes the softener wave's two-step notice→flip for the free tier.
-- D12 (founder, 2026-08-01) replaced "migrate existing users after a 30-day
-- notice" with "everyone tightens at T0, without notice". `softener_1_notice`
-- and `softener_2_flip` are dead for this purpose: the flip is gated on
-- `softener_notice_ends_at <= now()`, nothing stamps that column any more, so
-- it would match zero rows.
--
-- Three statements, and all three are load-bearing:
--
--  1. The cohort backfill is UNQUALIFIED on the cohort value. In production
--     `free_tier_cohort` is NULL on 1,262 of 1,365 accounts (the column was
--     added after they signed up); `where free_tier_cohort = 'legacy'` would
--     touch 103 rows and silently leave 92% of the base on the old tier.
--  2. The warmup counters are SERVER-authoritative — the client hydrates them
--     from `user_profiles` and deliberately never overwrites them with a
--     locally-derived guess. Existing rows still carry the legacy defaults
--     10 / 10 / 5, and 810 accounts sit at the full 25 uses. Flipping only the
--     cohort would leave the "tightened" tier untightened for weeks.
--  3. `least(...)`, never a bare assignment. A bare assignment would REFILL
--     someone who has already spent their warmup, and
--     `guard_user_profiles_freemium_fields` is decrement-only by design.
--
-- ROLLBACK IS PARTIAL, and that is a property of the decision, not a defect
-- in this script: setting `free_tier_cohort` back to 'legacy' restores the
-- legacy economy, but the clamped counters are NOT restored — `least()` threw
-- the surplus away. A user clamped 10 -> 3 stays at 3. Rolling back returns
-- them to the legacy 1/day cap with a smaller warmup than they started with.
-- If that matters, snapshot the three columns before running (see below).

do $$
begin
  if current_user not in ('postgres', 'service_role', 'supabase_admin') then
    raise exception 't0_flip_all_to_reel_v1 must run as an exempt role (got %); the freemium guard would half-block it', current_user;
  end if;
end $$;

-- NOT optional. This is the ONLY copy of the pre-clamp values — `least()` below
-- discards the surplus at the moment it runs, and no other record of it exists.
-- Drop it only once the keep decision is made, and understand that dropping it
-- makes the rollback below permanently impossible.
--
-- The weekly-pool columns are captured too (review, 2026-08-02). They are all
-- zero/NULL today because no account is on `reel_v1` yet — but the moment this
-- script runs, users start accruing pool state, and without these columns a
-- rollback would silently hand everyone a fresh week's allowance. Capturing a
-- column that is currently empty costs nothing; discovering it was needed after
-- a rollback costs a week of allowance per user.
create table if not exists public.warmup_pre_t0_snapshot as
select id,
       free_tier_cohort,
       warmup_reflect_remaining,
       warmup_built_dua_remaining,
       warmup_discover_name_remaining,
       weekly_pool_used,
       weekly_pool_week_start,
       weekly_pool_reset_at,
       now() as captured_at
from public.user_profiles;

-- The flip itself. One statement so a partial application is impossible: an
-- account cannot end up on the new cohort with un-clamped counters, which is
-- precisely the state that would hand it 25 free AI uses on the tight tier.
update public.user_profiles
set free_tier_cohort               = 'reel_v1',
    warmup_reflect_remaining       = least(
      warmup_reflect_remaining,
      coalesce((select (value::text)::int from public.app_config
                where key = 'warmup_reflect_size'), 3)),
    warmup_built_dua_remaining     = least(
      warmup_built_dua_remaining,
      coalesce((select (value::text)::int from public.app_config
                where key = 'warmup_built_dua_size'), 3)),
    warmup_discover_name_remaining = least(
      warmup_discover_name_remaining,
      coalesce((select (value::text)::int from public.app_config
                where key = 'warmup_discover_name_size'), 3)),
    -- Start everyone on a clean week rather than mid-pool. Leaving a stale
    -- week_start would make the client's first read look like a rollover it
    -- has to probe for.
    weekly_pool_used               = 0,
    weekly_pool_week_start         = null,
    weekly_pool_reset_at           = null
where free_tier_cohort is distinct from 'reel_v1';

-- New signups follow. Kept separate and LAST: if the statement above fails,
-- new accounts must not start landing on a tier the existing base has not
-- been moved to.
update public.app_config
set value = '"reel_v1"'::jsonb
where key = 'new_signup_cohort';

-- Verification — every row should read reel_v1, and no counter above its dial.
--   select free_tier_cohort, count(*) from public.user_profiles group by 1;
--   select count(*) from public.user_profiles
--    where warmup_reflect_remaining > 3
--       or warmup_built_dua_remaining > 3
--       or warmup_discover_name_remaining > 3;   -- expect 0
