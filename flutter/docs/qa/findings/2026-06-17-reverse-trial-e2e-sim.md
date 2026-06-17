# Reverse-trial experiment — end-to-end simulator QA

**Date:** 2026-06-17
**Build:** 1.2.0+4 (debug), iPhone 16 Pro simulator, prod Supabase (`smhvsqrxqoehqncphjrq`) + prod Mixpanel (`4013350`).
**Scope:** Validate the reverse-trial experiment shipped in PRs #44/#45 — analytics decision-readiness, the 3-day trial lifecycle, and that `app_config` flags drive behavior without breaking the app.
**Test account:** `rt.qa.j17.01@example.com` → uid `bd5fe274-a2df-49ba-ad22-1388153f40e3` (bucket 85 → **treatment_reverse_trial**). Added to `mixpanel-orphaned-distinct-ids.json` for readout exclusion.

## Setup performed (prod, via Supabase MCP)
- Applied migration `reverse_trial_backend` — verified backward-compatible first: diffed the live `sync_all_user_data` against the re-emitted version (only `trial_premium_until` added to the profile read-back; everything else byte-identical). `trial_premium_until timestamptz` + `activate_trial(p_days int)` SECURITY DEFINER (granted to `authenticated` only) + extended freemium guard. Zero impact on current users.
- Seeded `post_tour_paywall_mode` (jsonb string) + `reverse_trial_experiment_enabled` (jsonb bool) in `app_config`.
- **Restored to dormant/safe after testing:** `post_tour_paywall_mode="hard"`, `reverse_trial_experiment_enabled=false` (so shipping 1.2.0+4 = today's behavior until launch flip).

## PASS — validated end-to-end on device
| Area | Result |
|---|---|
| Logic/static | `flutter analyze` clean; 87 reverse-trial unit/widget tests green |
| Onboarding (15 pp) + email signup | Answers persisted correctly (`display_name`, commitment, intention); no breakage |
| Arm assignment | uid bucket 85 → treatment; `assignPaywallArm` salt verified offline matches |
| Trial activation | At onboarding-complete: `activate_trial(3)` fired → `trial_premium_until` = now+3d (exact), `had_trial=true`; onboarding paywall correctly skipped (premium) |
| Guided tour | Runs fully for the premium-via-trial user (Muhāsabah → story → dua → Build-a-Dua `buildComplete`). **No tour confound** — premium does NOT skip the guided tour. Real Islamic content, correctly sourced (not fabricated) |
| Trial expiry | Force-expired server-side → cold relaunch → `isPremium` drops → dismissible soft upsell with post-trial copy ("In your 3-day trial, you showed up 1 time…") |
| Analytics (Mixpanel) | `experiment_assigned`=1, `trial_activated`=1, `trial_expired`=1, `dua_built`=1. **All carry `paywall_exp_arm=treatment_reverse_trial`** incl. `trial_expired` (which has no event-level arm — relies on the super property, exactly as designed). The 2-arm decision funnel is segmentable. |

## FINDINGS — need a closer look (not blockers for the decision metrics)

### F1 (P2) — Post-trial surface is the in-app Home sheet, NOT the routing soft paywall
On trial expiry the user routes to **Home** and sees the in-app "Welcome back to one a day" bottom sheet (Scrim + nav tabs visible), **not** the full-screen routing soft paywall (`/onboarding-soft-paywall`). Consequence: **`trial_paywall_surfaced{post_trial_soft}` did NOT fire** (0 in Mixpanel), and `soft_gate_dismissed` did not fire on dismiss.
- Likely cause: `AppSession._isPremiumCached` is set true while the trial is active and is **not re-hydrated to false** when the trial lapses mid-session (resume invalidates `premiumStateProvider`, but the routing gate reads the stale session cache), so `resolveOnboardingStage` returns `app` → Home, where a separate re-engagement sheet renders.
- Impact: **The decision-critical events are unaffected** (`experiment_assigned`/`trial_activated`/`trial_expired` all fire + segment correctly; primary metric = paid conversion per assigned user via `subscription_started`). But the readout doc's secondary `trial_paywall_surfaced` instrument will **not populate** as documented for the Day-3 view. Either re-point the readout to the actual surface's event, or fix the routing so the soft PaywallScreen shows post-expiry.

### F2 (P3) — Post-trial sheet "Maybe later" did not dismiss across taps
On the in-app post-trial sheet, tapping "Maybe later" twice did not close it and `onboarding_paywall_cleared` stayed `false`; `soft_gate_dismissed` did not fire. Could be an interaction miss on the sim or a real dismiss-handler gap on this surface — verify.

### F3 (informational) — 2-launch latency was a TEST ARTIFACT, not a bug
The first post-expiry cold launch landed on Home (boot read the still-cached now+3d window); the home-load refreshed the cache + fired `trial_expired`; the second launch showed the soft surface. **In production this is a single open** — the cache stores the true expiry timestamp, so `isPremium()` flips false at boot on the first open after the 3-day mark. The 2-launch effect only happened because we force-expired the *server* value while the device cache still held the real +3d.

## NOT device-verified (covered by unit tests)
- Control arm (no-trial → immediate soft wall after tour): see "Control-arm device test" below.
- `hard`/`off` post-tour modes on device: the app demonstrably reads the flags (treatment used soft semantics + experiment ran), and `onboarding_stage_test` covers all mode branches. A clean device test of hard/off needs a fresh non-premium account (full onboarding walk).

---

## RESOLUTION (2026-06-17) — F1 + F2 fixed & verified on device

### Root causes
- **Overlap + F2 (one bug):** `LapsedTrialSheet.show` called `showModalBottomSheet` WITHOUT `useRootNavigator: true`. Under the GoRouter shell the sheet pushed on the nested shell navigator, so the root-attached singleton `tourRouteObserver` never saw the `LapsedTrialSheet` route → the `blockingRouteNames` guard never fired → an in-flight guided tour overlapped the sheet AND its gesture layer intercepted the sheet's buttons (so "Maybe later" did nothing).
- **F1 (analytics):** the lapsed reverse-trialer's Day-3 surface is the in-app `LapsedTrialSheet` (gated on `hadTrial()`), NOT the routing `PaywallScreen`. `LapsedTrialSheet` fired no analytics, so `trial_paywall_surfaced`/`soft_gate_dismissed` never populated for reverse-trial expiry.
- **Tour re-appearance (test artifact):** the tour marks "seen" only on reaching its LAST step; the test cut the Build-a-Dua reader short, so the seen flag was never written and the tour restarted on relaunch. (Exposes a real edge: a user who abandons the dua-build mid-reader gets the tour re-shown next launch.)

### Fixes (PR #45 / feat/reverse-trial-backend)
- `lapsed_trial_sheet.dart`: added `useRootNavigator: true`; added an `onDismiss` callback to `show()`.
- `progress_screen.dart`: fire `trial_paywall_surfaced{placement:post_trial_soft, hard_gate:false}` on show and `soft_gate_dismissed{placement:post_trial_soft}` on dismiss.
- Test: `lapsed_trial_sheet_test.dart` pins `show()` forwards `onDismiss` AND pops.

### Device + Mixpanel verification
- Reproduced the overlap (reset the one-shot `lapsed_trial_sheet_shown` pref). With the fix the tour overlay is **suppressed** while the sheet is up — no overlap.
- "Maybe later" now **dismisses** the sheet → free tier; the tour correctly re-appears after the sheet pops.
- Mixpanel (project 4013350): `trial_paywall_surfaced{post_trial_soft}` = 1 and `soft_gate_dismissed{post_trial_soft}` = 1, both carrying `paywall_exp_arm=treatment_reverse_trial`.

## Control-arm device test (attempted, not completed — logic unit-tested)
Two fresh signups both randomly bucketed treatment (buckets 85, 88); a pre-created control-bucket account (0a8ba8db) could not cleanly reach `_completeOnboarding` because re-onboarding an already-authenticated account hits the save-progress auth wall. The control arm's distinguishing logic — `experiment_assigned{arm:control_no_trial}` + NO `activate_trial` + immediate post-tour soft paywall — is covered by `reverse_trial_onboarding_test` and `onboarding_soft_paywall_redirect_test`. A deterministic device proof would require either more signup attempts (≈50%/try) or putting the pre-created control account at the gate via prefs surgery. Open follow-up.

## Side observation (minor, separate)
`flutter.onboarding_completed` is a GLOBAL (non-uid-scoped) SharedPreferences flag, so on a shared/QA device a second user signing in can inherit the previous user's "onboarded" state and skip onboarding. Low real-world impact (one account per device normally); worth uid-scoping.
