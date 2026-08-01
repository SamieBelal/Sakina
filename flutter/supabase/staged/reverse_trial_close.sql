-- Reverse-trial close-out — W5 Wave A, the server half.
-- STAGED: two steps, run days apart. See README.md.
--
-- Context: the reverse-trial experiment is retired (control 2.44% vs treatment
-- 1.68%, n=768). The client half — deleting `reverse_trial_onboarding.dart`,
-- `paywall_experiment.dart`, `trial_expiry_service.dart` and the orphaned
-- bucketing — ships with the T0 build. This file is only the `app_config` key.
--
-- WHY THE FLIP COMES FIRST, AND WHY IT IS URGENT:
--   The live App Store build still reads `reverse_trial_experiment_enabled` at
--   onboarding-complete and calls `activate_trial(3)` for the treatment half of
--   every new signup. Each such signup pushes "the last in-flight trial" out
--   another 72h, so the close-out date slides indefinitely while the flag is
--   true. Step 1 freezes that horizon at (flip + 3 days + <=6h of config-cache
--   staleness); nothing else does.
--
-- WHAT STEP 1 DOES NOT DO — deliberately:
--   It does NOT touch `user_profiles.trial_premium_until`, and it does NOT
--   revoke anything. An in-flight trial is honored to its natural expiry: the
--   window is a server column OR'd into `PurchaseService.isPremium()`, and that
--   read never consults this flag. No clawback is part of this close-out; a
--   faith audience punishes them, and the ADR forbids it.

-- ===========================================================================
-- STEP 1 — stop minting new trials.  RUN NOW.
-- ===========================================================================
-- Effect on a new signup, on the CURRENTLY LIVE build:
--   `resolveAndApplyPaywallExperiment` returns at its first line. No arm is
--   assigned, no `experiment_assigned`, no `activate_trial`, and
--   `paywall_exp_arm` resolves to `unassigned`. Every new user gets the control
--   experience (soft paywall after onboarding, free tier) — the better-
--   converting arm, and the one the retirement decision picked.
--   Side benefit: they are no longer stamped `had_trial = true`, so they keep
--   the warmup budget instead of dropping to the lapsed-trialer 1/day cap.
--
-- Reversible: set the value back to 'true' and the live build resumes minting
-- within one config-cache TTL (6h stale-while-revalidate).
--
-- The row is SET, not deleted. `getBool(..., fallback: false)` means a missing
-- key and an explicit false are behaviorally identical to every build — but an
-- explicit false is the record of WHEN the experiment closed, and a missing key
-- is indistinguishable from "never existed". Step 2 handles the deletion.

do $$
begin
  if current_user not in ('postgres', 'service_role', 'supabase_admin') then
    raise exception
      'reverse_trial_close step 1 must run as an exempt role (got %); app_config is not client-writable',
      current_user;
  end if;
end $$;

update public.app_config
   set value = 'false'::jsonb
 where key = 'reverse_trial_experiment_enabled';

-- Sanity: expect exactly one row, value false.
select key, value
  from public.app_config
 where key = 'reverse_trial_experiment_enabled';


-- ===========================================================================
-- STEP 2 — verification gate, then delete the key.  RUN AFTER THE LAST EXPIRY.
-- ===========================================================================
-- Do NOT run step 2 in the same session as step 1.
--
-- 2a. THE GATE. This must return 0 before any build shipping the client-side
--     deletion goes out. Re-query it — do not trust a previously recorded
--     timestamp, the horizon moved once already because new trials kept
--     starting.

select count(*) as active_trials_remaining,
       max(trial_premium_until) as last_expiry
  from public.user_profiles
 where trial_premium_until > now();

-- 2b. Only once 2a returns 0 AND the build that stopped reading the key is
--     effectively fully rolled out. Deleting earlier is not dangerous (the
--     fallback is false, so old builds behave identically) — it just erases the
--     record. There is no rush; a retired key costs nothing.

-- delete from public.app_config
--  where key = 'reverse_trial_experiment_enabled';

-- ---------------------------------------------------------------------------
-- NOT part of this close-out, and left standing on purpose:
--   * `user_profiles.trial_premium_until` — the column, the freemium-guard
--     clause protecting it, and `activate_trial()` itself. Dropping any of them
--     would revoke an in-flight trial and would break the guard re-emitted in
--     20260727100200. They are inert once nothing calls the RPC.
--   * `had_trial = true` on the 457 accounts that ever held an app-granted
--     trial. The guard forbids true -> false, and `GatingService` reads the
--     latch as "skip warmup, apply the cap" — so those accounts carry a
--     permanent free-tier penalty from a retired experiment. Leaving it is a
--     DECISION, not an oversight; reversing it needs a SECURITY DEFINER one-off
--     that re-grants their warmup. Tracked, not done here.
