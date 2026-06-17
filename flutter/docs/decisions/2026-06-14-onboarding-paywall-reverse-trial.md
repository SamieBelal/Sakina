# Onboarding → Reverse Trial → Soft Gate

**Decision:** Fix retention first — **(1) slim the 13-step guided tour to ~4–5 steps (Muḥāsabah → Duas → Streak)**, **(2) turn off the hard post-tour paywall** (server flag), then **(3) layer a 3-day reverse trial** that downgrades to the existing limited free tier behind a **soft (dismissible) paywall**. Keep the soft onboarding paywall.
**Date:** 2026-06-14 (updated 2026-06-15 with post-release cohort data — tour bleed is the primary bottleneck, see below).
**Status:** Accepted (direction). Implementation phased — see below. **Reassessment checkpoint: ~2026-06-19** (4 days), re-pull post-release cohort + retention deltas before/after any change.
**Amended 2026-06-16 — see [Addendum: experiment scope](#addendum-2026-06-16--experiment-scope-corrected-4-arms--one-single-variable-2-arm-test).** The Phase-4 multi-arm idea (four flows: hard / soft / trial→hard / trial→soft) is **superseded**. Per low-traffic experimentation research + our own funnel data, the test is collapsed to **one single-variable 2-arm test — reverse-trial vs. no-trial — with the paywall held *soft* in both arms**. Paywall *hardness* is decided (soft), not tested; the trial→hard arm is dropped. The addendum specifies the flags, separate per-arm analytics, and code changes.
**Builds on:** [`monetization-model.md`](./monetization-model.md) (subscription-only; server entitlement is source of truth). This decision does **not** change *what* we sell — only *when and how* we gate it.

---

## Context: what we have today

The founder's model was "onboarding → guided onboarding → hard paywall." The code is actually a **two-paywall** flow:

| Stage | Mechanism | Hard/soft |
|---|---|---|
| Onboarding (pages ~16–19) | Personalized plan → onboarding paywall | **Soft** (X to dismiss) |
| Guided tour | Post-signup walkthrough | Skippable |
| **Post-tour gate** | `OnboardingStage.hardPaywall`, router-enforced redirect (`hard_paywall_after_tour_enabled` flag) | **Hard** (no X, blocks navigation; exits only via trial/purchase) |

A limited **free tier already exists** in `GatingService`: one-time warmup (10 reflections / 10 duas / 5 name-discovers), then **1 use/day**. Time-based premium already drives `isPremium()` via `referral_premium_until` and `gift_premium_until` (server columns set by SECURITY DEFINER RPCs). **The infrastructure for a timed trial is ~70% built.**

## The data that drove this (2026-06-14)

**Mixpanel (90d, test IDs excluded):**
- Onboarding completion ~71–76% (healthy).
- Hard paywall: 183 viewed → **87 tapped CTA (48%)** over 90d. Intent is high.
- **Instrumentation VALIDATED (correction, 2026-06-14):** an earlier pass mis-read `trial_started`/`subscription_started` as "broken/dropping" because they showed ~6–7 vs RC's 22 trials. That was a window artifact — `trial_started` only shipped 2026-06-03 (commit b3b5c11). Matched-window reconciliation (Jun 3–14): RC new trials **5** vs Mixpanel `trial_started` **7** / `subscription_started` **6** → Mixpanel ≥ RC, **not under-counting** (the +2 is likely sandbox/TestFlight purchases the client counts but RC production excludes). Clean-window CTA→trial ≈ 15% (event-level), a normal StoreKit-completion range, not a "92% collapse." Conversion data from 1.1.0 onward is trustworthy.
- Retention: D1 36% → **D3 18%** → D7 13%. Notification opt-in **70%**. Tour: ~50% start, 46% complete. <10 paid of ~350 signups.

**RevenueCat:**
- 6 active subs, 3 active trials, $41 MRR, $285 lifetime revenue (all iOS).
- New-user→paid 1.07%; initial conversion (incl. trial) 4.55%.
- **Trial→paid 36% (up to 47% on the larger cohort) — healthy.**
- Only **22 trials in 90d (~4% of new users)** → the real bottleneck is trial *starts*, not conversion.
- A **3-day trial is already configured** on `sakina_sub_weekly` ($4.99/wk) and `sakina_sub_annual` ($49.99/yr). Annual wins (5 of 6 subs). **Zero experiments ever run.** 33% set-to-cancel, 8% refund (one refund).

**External benchmarks (cited in appendix):**
- Hard paywall ≈ 10.7% D35 trial→paid, $3.09 RPI, LTV ~$42; freemium ≈ 2.1%, $0.38 RPI, ~1.7% free→paid (needs tens of millions of users — we don't have that).
- Soft paywall converts ~50% better on paywall-view→pay (warmer audience), ~21% lower LTV.
- Onboarding-with-trial = best-converting placement (1.35%); ~90% of trial starts happen Day 0.
- 3-day trial: best LTV (weekly+3-day ≈ 1.5× LTV), but ~25% per-start conversion vs ~42% for 17–32-day trials.
- **Reverse trial** (full access → downgrade): highest conversion on record (7–21%) when PMF is strong; loss aversion does the selling.

## Post-release cohort analysis (2026-06-15) — the real bottleneck is the TOUR, not the paywall

v1.1.0 (hard paywall) went live ~2026-06-11. Analyzed the **165 signups since release** (122 of them a Jun 14 marketing/viral spike — fresh, lower-intent). Sources: Supabase `user_profiles` cohort + Mixpanel funnel (Jun 11–15) + RevenueCat.

**The hard paywall is barely reached — it is NOT the leak:**
- 165 signups → onboarding completed ~99% → tour_started 146 → **only 15 ever saw the paywall → 2 cleared it → 0 in-cohort trials** (RC: 3 trials total in window).
- Supabase confirms: of 165, `onboarding_paywall_cleared` = **2**, `had_trial` = **0**.

**The leak is mid-tour.** The guided tour is **13 steps** (muḥāsabah → streak → collection → duas → journal). Per-step unique users (Jun 11–15):

| # | step_id | users |  | # | step_id | users |
|---|---|---|---|---|---|---|
| 0 | home.beginMuhasabah | 148 | | 7 | appShell.tabDuasFromCollection | 96 (**−14%**) |
| 1 | muhasabah.goDeeper | 135 | | 8 | duas.buildCta | 94 |
| 2 | muhasabah.readStory | 132 | | 9 | duas.firstRelatedHeart | 85 |
| 3 | muhasabah.ameen | 128 | | 10 | appShell.tabJournalFromDuas | 72 (**−15%**) |
| 4 | muhasabah.returnHome | 119 | | 11 | journal.firstEntry | 69 |
| 5 | home.streakPill | 113 | | 12 | duaDetail.done (last, pre-wall) | **65** |
| 6 | appShell.tabCollection | 112 | | | tour_completed | 65 (~44%) |

- Front half (muḥāsabah aha, steps 0–5) holds **~76%**; back half (Collection→Duas→Journal tourism, steps 6–12) loses another **~42%**, worst at the tab-navigation steps. `tour_anchor_timeout` fired for 14 users (some drops may be UI-anchor bugs, not just fatigue).
- Net: only **~44% finish the tour**, and most who do don't return to even see the wall (only 61 started a 2nd session).

**Implications (reprioritization):**
1. **#1 lever = slim the tour**, not paywall placement. If the back half retained like the front half, ~113 (vs 65) would reach the app per cohort — ~75% more. Bigger than anything the paywall can do.
2. **Turning off the hard paywall barely affects retention** (almost nobody reaches it) — but it cleanly unblocks the ~150 trapped users and is the right direction anyway. It is a runtime `app_config` flag (`AppConfigService`, 6h stale-while-revalidate TTL) — **flipping it needs no app release**; new installs get it on boot, existing users after cache expiry + relaunch.
3. The **main issue is retention (first-session→second-session cliff)**, driven by tour length — monetization is downstream and premature until retention is fixed.

### Slim-tour spec (Muḥāsabah → Duas → Streak)

**Shipped 2026-06-15** as 7 steps (`kOnboardingTourSteps`), ending on the user's own built dua:

1. `home.beginMuhasabah` (tap)
2. `muhasabah.goDeeper` (tap)
3. `muhasabah.readStory` (tap)
4. `muhasabah.ameen` (tap)
5. `muhasabah.returnHome` (tap) → back on Home
6. `appShell.tabDuas` (navigate `/duas`) — the single tab hop, no Collection detour
7. `duas.buildCta` (tap Build) — **END**; tour completes when the user taps Build

Cut: `appShell.tabCollection`, `tabDuasFromCollection`, `duas.firstRelatedHeart`, `tabJournalFromDuas`, `journal.firstEntry`, `duaDetail.done`, **plus the in-tour streak beat (`home.streakPill`) and the return-home hop (`appShell.tabHome`) it required.** Surface Collection/Journal contextually in-app instead of force-touring.

**Design note — why no in-tour streak beat:** an interim 9-step version ended Muḥāsabah → Duas → *Streak* (return home, land on the streak pill). That required a *second* tab hop (Duas→Home), and tab-navigation is the least-reliable step type (`tour_anchor_timeout` clustered there, 14 fires). The streak pill's only job was the "come back tomorrow" return hook — which is already delivered by the evening **streak push** (`send-scheduled-notifications`: title "Protect your streak", body "Keep your N-day streak alive today.", 20:00, gated on `notify_streak` + push opt-in ~70%), plus the daily reminder and the 3-day re-engagement push. So the streak beat was dropped, which also removed the return-home hop → **one tab hop instead of two**, a shorter tour (better completion = the primary metric), and a warmer finish on the user's personal dua.

**Residual risk (acknowledged, now lower):** one tab hop remains (`appShell.tabDuas`, step 6) — still the least-reliable step type. Watch the per-step funnel at the 2026-06-19 checkpoint; if step 6 bleeds or times out, fall back to dropping the Duas beat entirely (end on the muḥāsabah aha after `muhasabah.returnHome` — zero tab hops).

**Instrumentation added 2026-06-15** so the checkpoint can actually evaluate the Duas beat (previously neither Duas nor Journal fired any event): `dua_built` (real, on-topic build only) and `journal_entry_created` (with `entry_type` ∈ {built_dua [auto], saved_dua, reflection}). Wired via `DuasNotifier`/`ReflectNotifier.onAnalyticsEvent` in `main.dart`. Engagement baseline that drove keeping Duas vs. cutting Collection/Journal: muḥāsabah `check_in_completed` 154 unique / 30d ≈ `card_revealed` 153 ≈ `streak_extended` 152 ≈ `quest_completed` 140 — cards/streak/quests ride the muḥāsabah loop automatically (so they need no tour step), while `store_viewed` was 6 (correctly never toured). Dua-build and Journal were unmeasured until now.

## Decision

### 1. Keep the soft onboarding paywall
It captures the Day-0 high-intent buyers (the 48% who tap CTA). The hard paywall's one virtue — grabbing the warm buyer immediately — is preserved here. Do **not** remove this revenue capture.

### 2. Replace the hard post-tour wall with a 3-day reverse trial
- **Days 0–3:** full premium access. Engagement mechanics (badges/collection, streak-with-gentle-freeze, daily rewards, capped notifications) build habit + sunk-cost investment.
- **Day 3+:** downgrade to the **existing** free floor. An engaged trial user will have burned the 10-reflection warmup, so they drop straight to **1/day** — going from unlimited → 1/day is a *felt loss*, which is the reverse-trial conversion engine.
- The paywall that appears on Day 3 is **soft/dismissible**; the gating is real because the free tier is genuinely limited.

**Trial length: 3 days** (already configured in RC, best LTV, maximizes Day-0 velocity). A/B vs 7 days later once volume supports significance.

### 3. The trial grant flows through the server, not a client grant
Add an `activate_trial(days)` **SECURITY DEFINER** RPC that sets a time-based column (e.g. `trial_premium_until`, mirroring the `gift_premium_until` pattern) and `had_trial = true`. `isPremium()` ORs this in alongside RC entitlement / referral / gift. **This preserves the monetization-model invariant: no client-side grants — premium status still comes from a server column / entitlement check.**

### 4. Instrumentation is validated — small enhancements only (NOT blocking)
Conversion events were confirmed healthy via matched-window reconciliation (see data section). Remaining optional work: (a) add `purchase_sheet_presented`/`dismissed` to *measure* StoreKit abandonment; (b) filter/tag sandbox purchases out of client conversion events so Mixpanel and RC reconcile exactly. Neither blocks the refactor. The real constraint on any hard-vs-soft experiment is **sample size** (single-digit conversions/month), not data quality.

## What we are NOT doing

- **Not** a hard Day-3 wall (yet). Reputationally risky for a faith app, and unmeasurable until instrumentation + volume improve. Revisit once we can A/B it honestly.
- **Not** open-ended freemium ("free forever"). Freemium economics need scale we don't have; the free floor stays limited (1/day).
- **Not** "notifs all the time." Evidence contradicts it (opt-out begins at 2–5/week, worse for devout/older users). See guardrails.

## Phased plan

**Phase 1 — Slim the tour + turn off hard paywall (HIGHEST PRIORITY, ~days)**
0a. ✅ **DONE 2026-06-15** — Trimmed `kOnboardingTourSteps` 13→7 to the slim-tour spec above (Muḥāsabah → Duas, ends on the dua build; in-tour streak beat dropped since the streak push carries the return hook). Anchors verified, all tour tests green, `flutter analyze` clean.
0b. ⏳ **PENDING founder confirmation** — Set `hard_paywall_after_tour_enabled = false` in `app_config` (runtime flag, no release; unblocks ~150 trapped users). Production change — do not apply without sign-off.
0c. ✅ **DONE 2026-06-15** — built the slim-vs-full A/B behind `app_config.tour_ab_enabled`. Both arms live in code (`kSlimOnboardingTourSteps` 7-step, `kFullOnboardingTourSteps` 13-step control). Off (default) → everyone slim; on → stable per-user 50/50 (`assignTourVariant`, FNV-1a bucket of the user id — no persistence, same arm every launch). The arm is set as a `tour_variant` USER property at tour start (+ `variant` prop on `tour_started`), so retention/conversion break down cleanly by arm. **Why this matters:** the current cohort is 68% a single-day Jun-14 viral spike and <4 days old — a naive before/after on retention is confounded; the A/B gives a clean within-period read once organic volume accrues.

**Operating the experiment (no app release needed once a build with this code ships):**
- Turn on: set `app_config.tour_ab_enabled = true` (jsonb `true`). 6h stale-while-revalidate TTL; primed at launch.
- Read: segment `session_started` / `check_in_completed` retention (and `tour_completed`, `dua_built`) by the `tour_variant` user property, **filtered to dates the flag was on**.
- Ship the winner: flag off → slim everywhere (if slim wins/neutral). If full wins, revert the code default (that outcome means the slim change was wrong, which warrants a release anyway).
- ⚠️ These events ship in the binary → the A/B only runs for users on the **next release build**; it cannot evaluate the current live cohort.
- ⚠️ At ~15–30 organic signups/day, a retention-powered read takes **weeks**. Don't call it early.

**Phase 1b — Instrumentation polish (OPTIONAL, parallel)**
1. `trial_started`/`subscription_started` already validated (Jun 3+). No fix needed.
2. ✅ **DONE 2026-06-15** — added `dua_built` + `journal_entry_created` (typed) so the two guided-tour features (Duas, Journal) are measurable at the checkpoint; they fired no events before.
3. Nice-to-have: add `app_install` + `purchase_sheet_presented` / `purchase_sheet_dismissed`; tag/exclude sandbox purchases so Mixpanel and RC reconcile exactly.

**Phase 2 — Reverse-trial refactor (~3–4 weeks)**
3. Migration: `trial_premium_until` (or `trial_activated_at` + `trial_duration_days`) on `user_profiles`.
4. `activate_trial(days)` SECURITY DEFINER RPC (mirror `claim_sakina_gift`); include trial fields in `sync_all_user_data`.
5. Onboarding complete → call `activate_trial(3)` instead of forcing `hardPaywall`; route to tour → app.
6. Integrate trial into `isPremium()` / `GatingService.canUse()` (trial = premium tier, 30/day).
7. Day-3 soft paywall + "trial ending" UX (countdown badge, expiry sheet — reuse `TrialExpired`/daily-cap sheet patterns in `lib/features/paywall/`).
8. Keep soft onboarding paywall as-is. Preserve backward compat: users with `onboarding_paywall_cleared = true` must not be re-walled (stage logic already handles this).

**Phase 3 — Engagement guardrails (parallel)**
9. Notifications: soft-ask the iOS prompt **after** first muḥāsabah (not first launch); cap ~1/day (2–5/week); trial-ending reminders day 2 + day 3; never go silent. **No "all the time."**
10. Route reward energy into badges/collection + streak-with-gentle-freeze; warm/encouraging copy; **no leaderboards/ranked competition** (cheapens a spiritual product).

**Phase 4 — Experiment (once volume allows)**
11. First-ever RC/Mixpanel experiment: 3-day vs 7-day trial; then soft vs hard Day-3 gate. **Primary metric: trial-start rate** (the bottleneck); secondary: trial→paid (already healthy).

## Risks & mitigations

- **D3 retention is only ~18%** — deferring the ask to day 3 asks a decayed cohort. Mitigation: keep the soft onboarding paywall for Day-0 capture; use the capped engagement push (70% opt-in is the lever) to lift D3.
- **Reverse trial needs real PMF.** 36–47% trial→paid suggests triers like it, but volume is tiny. Monitor as it scales.
- **Faith-tech "pay-to-pray" backlash + FTC dark-pattern enforcement.** Mitigation: soft/dismissible gate, one-tap cancellation, animations read as reverence not slot-machine.
- **Timezone correctness** for expiry (UTC everywhere — existing pattern).

## Reassessment checkpoint — ~2026-06-19 (4 days out)

Re-pull and compare against the 2026-06-15 baseline below, then confirm or pivot the plan:
- **Tour funnel:** `tour_step_viewed` by `step_index` + `tour_completed` rate. Baseline: 148 start → 65 finish (~44%); back-half steps 6–12 are the bleed. NEW slim tour is 7 steps — re-baseline the per-step drop, watch `tour_anchor_timeout` on the single `appShell.tabDuas` hop (step 6).
- **Duas + Journal engagement (NEW events, no pre-2026-06-15 baseline):** `dua_built` and `journal_entry_created` (break down by `entry_type`). Question to answer: does the tour's Duas beat translate into real dua-builds / journal saves, or should the Duas step be cut (fallback above)? Compare retained vs. churned cohorts.
- **First→second session retention:** D1/D3 for the post-release cohort, **split organic vs the Jun 14 spike** (spike traffic is lower-intent and drags the average). Baseline: ~37% started a 2nd session.
- **Paywall reach + conversion:** `paywall_viewed` / `trial_started`; Supabase `onboarding_paywall_cleared`, `had_trial`. Baseline (165 cohort): 15 saw paywall, 2 cleared, 0 trials; RC 3 trials.
- **Signups:** Supabase daily `auth.users` (baseline: 165 since Jun 11, 122 on Jun 14).
- **If any change shipped** (slim tour / flag off): compare before/after on the above. Decision: tour-slim confirmed if app-arrival/2nd-session rate rises; otherwise investigate `tour_anchor_timeout` (UI bug) vs fatigue.
- Always exclude the 54 test IDs (`docs/qa/mixpanel-orphaned-distinct-ids.json`); compare conversion events only from ≥2026-06-03.

## Revisit triggers

- After instrumentation fix, if the CTA→billing gap persists (i.e. it's genuine StoreKit abandonment, not tracking) → prioritize purchase-sheet UX over model changes.
- If reverse-trial trial→paid drops materially below the current 36% at higher volume → reconsider hard Day-3 gate via a real A/B.
- If notification opt-out / uninstall spikes after Phase 2 → cut cadence further.
- Per `monetization-model.md`: still subscription-only; this decision does not reopen the lifetime/one-time question.

## Appendix: key sources

- RevenueCat — State of Subscription Apps 2026: <https://www.revenuecat.com/state-of-subscription-apps/>
- RevenueCat — trial length: <https://www.revenuecat.com/blog/growth/7-day-trial-subscription-app/>
- Adapty — high-performing paywall 2026: <https://adapty.io/blog/high-performing-paywall-2026/>
- Superwall — Cal AI case study (onboarding-then-paywall): <https://superwall.com/case-studies/cal-ai>
- Growth Gems — should you have a hard paywall: <https://growthgems.substack.com/p/should-you-have-a-hard-paywall>
- Lenny's Newsletter — free-to-paid conversion / reverse trials: <https://www.lennysnewsletter.com/p/what-is-a-good-free-to-paid-conversion>
- Contrary Research — Hallow (faith-app model): <https://research.contrary.com/company/hallow>
- FTC — dark patterns in subscriptions (2024): <https://www.ftc.gov/news-events/news/press-releases/2024/07/ftc-icpen-gpen-announce-results-review-use-dark-patterns-affecting-subscription-services-privacy>

*Internal data: Mixpanel project 4013350 and RevenueCat project `proje6681c8c`, pulled 2026-06-14, test IDs from `docs/qa/mixpanel-orphaned-distinct-ids.json` excluded.*

---

# Addendum 2026-06-16 — experiment scope corrected: 4 arms → one single-variable 2-arm test

## What changed and why

The founder asked to run a **4-arm** A/B test of the post-tour monetization flow:

1. tour → **hard** paywall
2. tour → **soft** paywall → free tier
3. tour → **3-day trial** → **hard** paywall (day 3)
4. tour → **3-day trial** → **soft** paywall (day 3) → free tier

Research into multi-arm experimentation at low traffic (sources below) plus our own funnel data say this format is wrong for us, for three independent reasons:

1. **The four arms confound two variables.** They are a 2×2 of *timing* (immediate vs. 3-day trial) × *hardness* (hard vs. soft). Each arm changes **two** knobs at once, so a winner is un-attributable — *"every experiment should change exactly one thing… if you change [two things] simultaneously, you cannot isolate what drove the result"* (Airbridge / RevenueCat paywall-testing guidance). This holds **even at infinite traffic**.
2. **Low traffic forbids 4 arms.** Near-unanimous guidance for our volume (~20–50 signups/day, single-digit conversions/week): **≤2 variants**, larger MDE, **upstream/proxy metrics**, Bayesian reads. AB Tasty: *"Don't create more than two variations… [multivariate testing] is only designed for websites with very high traffic levels."* CXL's pro-multi-variant stance still assumes **500–1,000 conversions/month**; we have single digits. Four arms also quarter the sample and add a multiple-comparisons tax (Bonferroni/Holm ⇒ +30–40% N).
3. **Our data already answers the hardness question.** Of 165 post-release signups, **2 ever reached the hard wall**. Testing hard-vs-soft spends scarce experiment-weeks on a gate almost nobody hits, and a hard wall is reputationally risky for a faith app. Hardness is therefore **decided (soft), not tested.**

**Decision:** collapse to the **single comparison that isolates the lever the ADR already identified as the #1 bottleneck (trial *starts*)**, holding hardness constant at *soft*. This is old Arm 2 vs. old Arm 4. **Old Arm 1 and Arm 3 (hard variants) are dropped.**

## The test

| | **Control (arm `control_no_trial`)** | **Treatment (arm `treatment_reverse_trial`)** |
|---|---|---|
| Flow | onboarding → slim tour → **immediate soft paywall** → free tier (1/day) | onboarding → slim tour → **3-day reverse trial** (full premium) → **Day-3 soft paywall** → free tier (1/day) |
| Held constant (both arms) | post-tour gate is **soft/dismissible**; slim tour; soft onboarding paywall (Day-0 capture) | same |
| **The one variable tested** | trial **off** | trial **on (3 days)** |

50/50 split, stable per user, deterministic bucketing.

## Flags — `app_config` changes

`app_config` is `(key text PK, value jsonb)`, read via `AppConfigService` with a 6h stale-while-revalidate cache, primed at boot in `main.dart`. `AppConfigService.getBool` is **boolean-only today** — string/int flags need new accessors (below).

### Existing flags

| key | current DB value | action | rationale |
|---|---|---|---|
| `hard_paywall_after_tour_enabled` | `true` | **set `false`** (production change — needs founder sign-off, ADR step 0b) | retire the hard wall; new build no longer routes to `OnboardingStage.hardPaywall`. Kept only as a back-compat read for the live 1.1.x binary. |
| `tour_ab_enabled` | `false` | **leave unchanged** | tour-length A/B is an **orthogonal** dimension; do not entangle it with the paywall experiment. |
| `guided_tour_enabled` | `true` | leave | master tour kill-switch. |
| `onboarding_trim_enabled` | `true` | leave | slim onboarding stays on. |

### New flags

| key | type | default | controls |
|---|---|---|---|
| `post_tour_paywall_mode` | string (`off` \| `soft` \| `hard`) | `"soft"` | Replaces the boolean's overloaded semantics for the **new build**. The *hardness* knob — held at `soft` for the experiment. (`off` = straight to app = legacy rollback; `hard` reserved for a future, separately-powered hardness test.) |
| `reverse_trial_experiment_enabled` | bool | `false` → flip `true` when build ships + ready | **Master switch for the 2-arm test.** Off ⇒ everyone gets **control** (no trial); the unproven treatment never ships to 100% before it reads. On ⇒ users 50/50 bucketed. |

> **Cut from current scope (2026-06-16 eng review):** a `reverse_trial_duration_days` int flag + `AppConfigService.getInt` were considered for A/B-ing 3-vs-7-day trials. **Deferred** — the ADR itself defers 3-vs-7 to "later once volume supports significance," and shipping the accessor now is premature abstraction (YAGNI). The client **hardcodes 3 days**; revisit the flag when we actually run the duration test.

> **Why a flag, not just shipping the trial:** keeping `reverse_trial_experiment_enabled` off by default means the new binary ships **control behavior** (soft immediate paywall) to everyone, and we turn the experiment on server-side only when instrumentation is verified — no release needed to start/stop/ship-winner.

## Separate per-arm analytics — "which arm is working"

Architecture stays **one funnel, segmented by a super-property** (per `docs/analytics/funnel-flags-and-querying.md`) — NOT two event streams. The arm is the breakdown dimension; that is what makes the two arms separable on every step.

> **Baseline already merged — this is a DELTA, not a rebuild.** The funnel spine (boot super-property registration in `analytics_events.dart`, `placement` on paywall events, `resetForSignOut` durability, the slim-vs-full tour A/B with `tour_variant`/`assignTourVariant`/`tourBucket`/`_recordVariant`, and `funnel-flags-and-querying.md`) shipped in **PR #41 / `49bbded` (Jun 15), already in master.** Verified net-new (absent today): `paywall_exp_arm`, `flag_reverse_trial_exp`, `experiment_assigned`, `trial_activated`/`trial_expired`/`trial_paywall_surfaced`, `assignPaywallArm`. `daily_cap_hit` exists only in comments (`analytics_event_names.dart:156,176`) — promote to a real constant AND wire emission. T6 extends the merged machinery; it does not reinvent it. NB: because `49bbded` shipped `assignTourVariant`/`tourBucket`/`flag_tour_ab`, eng-review finding #2 (salt the paywall bucket) is a live de-correlation requirement, not hypothetical.

### Assignment / segmentation properties (the spine)

Registered at boot and re-applied at assignment (mirror `_recordVariant` for `tour_variant`, `onboarding_tour_controller.dart`); durable across sign-out via `AnalyticsService.resetForSignOut`:

- **`paywall_exp_arm`** ∈ `{control_no_trial, treatment_reverse_trial, unassigned}` — super-property **and** people property. The primary breakdown.
- **`flag_reverse_trial_exp`** (bool) — was the experiment active for this user (separates pre-experiment cohort from in-experiment).
- Keep existing: `flag_onboarding_trim`, `flag_tour_ab`, `tour_variant`, `app_version`, `is_premium`.

### Events — exact constants to add (most do not exist yet)

| event | props | status today | where it fires |
|---|---|---|---|
| `experiment_assigned` | `{experiment:'reverse_trial', arm}` | **new** | once, at arm assignment (onboarding complete) — the denominator for both arms |
| `trial_activated` | `{days, source:'reverse_trial', arm}` | **new** | treatment entry; on successful `activate_trial(3)` RPC |
| `trial_expired` | `{arm}` | **new** | first client detection of `trial_premium_until < now()`; wire into `lapsed_trial_service.dart` (it already detects lapse but fires **zero** events) |
| `trial_paywall_surfaced` | `{placement:'post_trial_soft', arm, hard_gate:false}` | **new** | treatment's Day-3 soft gate view (distinct from onboarding/in-app placements) |
| `daily_cap_hit` | `{feature, arm}` | **constant documented but NEVER emitted** (`analytics_event_names.dart:156,176`) | wire emission in `GatingService.canUse`/`reserveBypass` when a free/lapsed user is blocked — numerator for "cap-hit → upgrade" |
| `soft_gate_dismissed` | `{placement, arm}` | **new** (today `paywall_closed` carries no placement) | on X / dismiss of any soft paywall |
| `paywall_viewed` | `{placement, arm, hard_gate}` | exists; ensure `placement` populates (`post_tour_soft` for control) | both arms |
| `paywall_cta_tapped` | `{plan, arm}` | exists | both arms |
| `trial_started` (StoreKit) / `subscription_started` (RC webhook) | `{plan, arm}` | exist (validated Jun 3+) | both arms — the paid event |
| `tour_completed`, `dua_built`, `journal_entry_created`, `session_started`, `check_in_completed` | + `arm` via super-property | exist | retention/engagement guardrails |

> ⚠️ All new events only populate **after the build ships** (Mixpanel shows nothing for pre-release cohorts — empirically confirmed for the Phase-1 events). Do not read the experiment on the current live cohort.

### The two segmented funnels (read these side-by-side, broken down by `paywall_exp_arm`)

- **Control:** `experiment_assigned` → `tour_completed` → `paywall_viewed{post_tour_soft}` → `paywall_cta_tapped` → `subscription_started`. Loss path: `soft_gate_dismissed` → `daily_cap_hit` → (re-engage / upgrade).
- **Treatment:** `experiment_assigned` → `tour_completed` → `trial_activated` → [Day 0–3 `session_started`/`check_in_completed` retention] → `trial_expired` → `trial_paywall_surfaced` → `paywall_cta_tapped` → `subscription_started`. Loss path: `trial_expired` → `soft_gate_dismissed` → `daily_cap_hit`.

### Decision metrics (how we declare a winner)

| tier | metric | definition (segment by `paywall_exp_arm`) | reads in |
|---|---|---|---|
| **North-star (comparable across arms)** | new-paid rate | `tour_completed` → `subscription_started` within **14 days** | weeks–months |
| **Primary proxy (high base rate — what we actually call it on)** | purchase intent | control: `paywall_viewed` → `paywall_cta_tapped`; treatment: `trial_activated` → `paywall_cta_tapped` (post-expiry) | ~2–4 weeks |
| **Guardrail** | habit | **D1 / D7 retention** (`session_started` / `check_in_completed`) by arm — treatment *should* retain more; a paid-%-only read would falsely favor control | continuous |
| **Loss-loop** | recovery | `daily_cap_hit` → upgrade %, by arm | continuous |
| **Lagging confirmation** | quality of revenue | `trial_started`/`subscription_started` → renewal vs. churn, by arm | 4–8 weeks |

**Method:** Bayesian `P(treatment > control)` (low-N appropriate); **run 4–8 weeks** to cover ≥1 renewal cycle; **always exclude the 54 test IDs** (`docs/qa/mixpanel-orphaned-distinct-ids.json`) and count conversions only from **≥2026-06-03**. Do **not** early-stop on the first p<0.05 swing.

## Code changes (file-by-file)

**DB / `supabase/migrations/` (the critical path — arms differ only by the trial, which doesn't exist yet):**
1. `ALTER TABLE user_profiles ADD COLUMN trial_premium_until timestamptz;`
2. `activate_trial(p_days int)` **SECURITY DEFINER** RPC, mirroring `claim_sakina_gift`: assert `auth.uid()` = caller; `trial_premium_until = greatest(coalesce(trial_premium_until, now()), now() + (p_days || ' days')::interval)`; set `had_trial = true`; **idempotent** via `greatest()` (re-call cannot extend). Grant execute to `authenticated`.
3. **Extend `guard_user_profiles_freemium_fields()`** to forbid direct client mutation of `trial_premium_until` (mirror the existing `gift_premium_until` / `referral_premium_until` clauses) — otherwise a client self-grants infinite premium. `had_trial=true` is already irreversible per the guard.
4. Include `trial_premium_until` + `had_trial` in `sync_all_user_data()` so cross-device sign-in restores the trial.
5. pgtap: `activate_trial` idempotency + RLS; guard blocks direct write.
6. Seed `app_config`: `post_tour_paywall_mode='soft'`, `reverse_trial_experiment_enabled=false`, `reverse_trial_duration_days=3`; set `hard_paywall_after_tour_enabled=false` (sign-off gated).

**`lib/services/app_config_service.dart`:** add `getString(key, {fallback})` mirroring `getBool`'s SWR cache, for `post_tour_paywall_mode`. (No `getInt` — duration is hardcoded 3, see cut note above.)

**`lib/services/purchase_service.dart`** (`isPremium()` @ ~84–97): add `_isTrialPremium()` + `refreshTrialPremiumCache()` siblings to the referral pair, OR'd into `isPremium()` (scoped pref `trial_premium_until:<uid>`). Because every gate calls `isPremium()`, the whole app respects the trial with **zero per-feature changes**.

**`lib/features/onboarding/onboarding_stage.dart`:** add `OnboardingStage.softPaywall`; `resolveOnboardingStage` takes `paywallMode` + `arm` + `trialActive`: premium/cleared/trialActive → `app`; `!tourCompleted` → `tour`; else `mode==hard` → `hardPaywall`, `mode==soft` → `softPaywall`, `mode==off` → `app`.

**`lib/core/router.dart`:** route `softPaywall` → dismissible `PaywallScreen(hardGate:false)` (placement `post_tour_soft`); on dismiss → app + free tier (already wired). `hardPaywall` redirect stays for back-compat but is unreachable when `mode=soft`.

**New `lib/features/paywall/.../paywall_experiment.dart`:** `enum PaywallArm { controlNoTrial, treatmentReverseTrial }`, `assignPaywallArm(userId)` reusing the FNV-1a `tourBucket()` from `onboarding_tour_step.dart` (<50 control, ≥50 treatment). Resolve at onboarding-complete; record `paywall_exp_arm` super+people property; fire `experiment_assigned`.

**Onboarding-complete hook:** if `reverse_trial_experiment_enabled` && arm==treatment → `activate_trial(3)` (duration hardcoded; see cut note) + `refreshTrialPremiumCache()`, route tour → app (no immediate wall). Control → no trial → soft wall after tour.

**Day-3 UX:** trial-countdown badge + expiry sheet reusing `LapsedTrialSheet`/daily-cap patterns in `lib/features/paywall/`; fire `trial_expired` + `trial_paywall_surfaced`.

**`lib/services/gating_service.dart`:** emit `daily_cap_hit{feature, arm}` when a free/lapsed user is blocked (the constant exists, emission does not). Premium short-circuit unchanged.

**`lib/services/analytics_event_names.dart` + `analytics_events.dart`:** add the event/property constants above; register `paywall_exp_arm` + `flag_reverse_trial_exp` as super-properties at boot and re-apply at assignment; emit via the static `onAnalyticsEvent` hooks (no Riverpod in services).

**Tests:** bucketing determinism + ~50/50 split; `resolveOnboardingStage` soft/hard/trial routing matrix; `isPremium()` ORs `trial_premium_until`; `daily_cap_hit` emission; `experiment_assigned`/`trial_activated`/`trial_expired` fire once with `arm`; widget test for soft-gate dismiss → free tier.

## Sequence (two PRs — eng-review decision 2026-06-16)

**PR 1 = Phase A (routing seam, ~days).** **PR 2 = Phase B (trial + experiment, ~3-4 wks).** Land the seam first so the trial builds against it; nothing in Phase B blocks shipping Phase A.

1. **[PR 1] Decide & ship hardness = soft:** `getString` accessor + `post_tour_paywall_mode=soft` + `OnboardingStage.softPaywall` + router + `hard_paywall_after_tour_enabled=false` (founder sign-off). *(No experiment yet — this alone unblocks the ~150 trapped users.)*
2. **Build the trial backend + analytics** (ADR Phase 2, ~3–4 wks) — the only thing arms differ by.
3. **Verify instrumentation** (Mixpanel MCP: all new events fire with `arm`) on an internal build.
4. **Flip `reverse_trial_experiment_enabled=true`** → 50/50 starts, no release.
5. **Read at 4–8 wks** on the proxy + retention guardrail (Bayesian); ship winner by flag (treatment win → set arm default to treatment; control win → keep no-trial).
6. **Only then**, if warranted and traffic allows, a *separate* single-variable test of Day-3 gate hardness (soft vs hard).

## Eng-review hardening (2026-06-16) — decisions folded in

These came out of `/plan-eng-review` and are now part of the spec:

1. **Trial expiry = client-clock + resume re-check.** Keep the gift/referral client-trust posture (no new server round-trip on the hot gate path), but force `refreshTrialPremiumCache()` + an expiry evaluation on **app-resume and home-load** so the Day-3 soft gate reliably fires that session and `trial_expired` emits promptly. Clock-rollback abuse is tolerated (low stakes for a free 3-day trial; same risk gift/referral already accept).
2. **Salt the paywall bucket.** `assignPaywallArm(userId)` hashes `userId + ':paywall'`, NOT the raw `userId` — otherwise it would be perfectly correlated with `assignTourVariant`'s bucket and the tour A/B + paywall test could never run concurrently without confounding. Pinned by a de-correlation regression test (G2).
3. **Arm assignment is idempotent + flag-gated.** Persist the assigned arm server-side once per user; `experiment_assigned` dedupes on a stored flag (no double-count on reinstall/re-onboard); assign **only** when `reverse_trial_experiment_enabled` is on at onboarding-complete — pre-flag users stay `unassigned`.
4. **New build reads `post_tour_paywall_mode` only.** The legacy `hard_paywall_after_tour_enabled` boolean is read solely by old 1.1.x binaries; documented precedence, deprecate next release. Ship `post_tour_paywall_mode` as **`soft|off` only** — `hard` is YAGNI (already expressed by the legacy boolean + existing `PaywallScreen(hardGate:true)`); add it back when the future hardness test needs it.
5. **`sync_all_user_data()` reads `trial_premium_until` back only.** The sole writer is `activate_trial` (SECURITY DEFINER, exempt from the freemium guard). The sync RPC must NOT write the column from the client payload or it trips the guard / silently fails the whole UPDATE. Pinned by a pgtap round-trip test (G6).
6. **DRY:** extract one `_isTimedPremium(prefKey)` / `refreshTimedPremiumCache(prefKey, column)` helper; gift, referral, and trial all call it (no third copy).

**Required tests (folded — 100% of the new paths):** `getString` fallback (absent key / non-string jsonb) [G4]; `resolveOnboardingStage` full routing matrix incl. expired-trial→1/day [G5]; soft-gate dismiss→free-tier [E2E]; `activate_trial` idempotency + **RLS cross-uid block** [G-IRON, pgtap]; freemium-guard blocks direct write but `sync_all_user_data` round-trips the column [**G6 critical, pgtap**]; `assignPaywallArm` deterministic + ~50/50 + **de-correlated from `assignTourVariant`** [**G2 regression**]; `isPremium` ORs trial + expired→false + `had_trial` skips warmup [G5]; `experiment_assigned`/`trial_*` fire once with `arm`, **idempotent across reinstall** [G1]; app-resume on Day-3 → `trial_expired` + routes soft gate [G3, widget]; full treatment journey onboarding→tour→trial→app→Day-3→soft gate→free tier [G7, E2E].

## Research sources (2026-06-16)

- AB Tasty — A/B testing on low-traffic sites (≤2 variations; MVT only for high traffic): <https://www.abtasty.com/blog/six-techniques-for-getting-started-with-ab-testing-low-traffic/>
- CXL — How many A/B test variations (500–1,000 conversions/month floor; multiple-comparisons cost): <https://cxl.com/blog/how-many-ab-test-variations/>
- Airbridge — Paywall A/B testing ("change exactly one thing"; 2-wk min, 4–8 wk for renewal; ~200 paid conv/variant for 20% lift; 30k users/variant for 10% at 2%): <https://www.airbridge.io/en/blog/ab-test-paywall-setup-duration-results>
- RevenueCat — Experiments (max 4 variants; full-funnel read): <https://www.revenuecat.com/docs/tools/experiments-v1/experiments-overview-v1>
- Convert — A/B testing on low-traffic sites: <https://www.convert.com/blog/a-b-testing/i-dont-have-enough-traffic-to-a-b-test-now-what/>
- VWO — Low-traffic split testing: <https://vwo.com/blog/ab-split-testing-low-traffic-sites/>
- Analytics-Toolkit — running multiple concurrent A/B tests (don't peek/early-stop): <https://blog.analytics-toolkit.com/2017/running-multiple-concurrent-ab-tests/>
- SplitMetrics / CrazyEgg — multi-armed bandit vs A/B (bandits = optimization not causal; less traffic): <https://splitmetrics.com/blog/multi-armed-bandit-in-a-b-testing/> · <https://www.crazyegg.com/blog/multi-armed-bandit-vs-ab-testing/>

## Implementation Tasks
Synthesized from the 2026-06-16 eng review. P1 blocks ship; P2 lands same branch. PR1 = Phase A, PR2 = Phase B.

- [ ] **T1 (P1, human: ~1d / CC: ~45min)** — db-trial-backend [PR2] — `trial_premium_until` + `activate_trial` RPC + extend freemium guard + `sync_all_user_data` read-back
  - Surfaced by: Arch #4 + test G6 (guard vs sync collision)
  - Files: `supabase/migrations/`, `supabase/tests/`
  - Verify: pgtap — idempotency, RLS cross-uid block, guard blocks direct write but sync round-trips
- [ ] **T2 (P1, human: ~2d / CC: ~30min)** — phase-a-routing [PR1] — `getString` + `post_tour_paywall_mode(soft|off)` + `OnboardingStage.softPaywall` + router
  - Surfaced by: Step 0 phasing + Arch #3 (dual-flag precedence)
  - Files: `lib/services/app_config_service.dart`, `lib/features/onboarding/onboarding_stage.dart`, `lib/core/router.dart`
  - Verify: `flutter test` routing matrix incl. expired-trial→1/day; getString fallback
- [ ] **T3 (P1, human: ~0.5d / CC: ~25min)** — ispremium-trial [PR2] — extract `_isTimedPremium` helper, OR trial, refresh on resume/home
  - Surfaced by: Arch #1 (client-clock + resume) + CQ #6 (DRY)
  - Files: `lib/services/purchase_service.dart`
- [ ] **T4 (P1, human: ~0.5d / CC: ~20min)** — arm-assignment [PR2] — `assignPaywallArm` salted (`userId+':paywall'`), persisted, `experiment_assigned` idempotent + flag-gated
  - Surfaced by: CQ #5 (bucket confound) + Arch #2
  - Files: `lib/features/paywall/`
  - Verify: de-correlation regression test (G2)
- [ ] **T5 (P1, human: ~1.5d / CC: ~40min)** — day3-trial-ux [PR2] — Day-3 countdown + expiry sheet; `trial_activated`/`trial_expired`/`trial_paywall_surfaced`
  - Files: `lib/features/paywall/`
- [ ] **T6 (P2, human: ~0.5d / CC: ~25min)** — analytics-segmentation [PR2] — `paywall_exp_arm` + `flag_reverse_trial_exp` super-props; emit never-fired `daily_cap_hit` + `soft_gate_dismissed`
  - Files: `lib/services/analytics_event_names.dart`, `lib/services/analytics_events.dart`, `lib/services/gating_service.dart`
- [ ] **T7 (P1, human: ~1.5d / CC: ~50min)** — test-coverage [PR1+PR2] — pgtap + dart + widget + E2E per the folded test list (G1-G7)
  - Files: `test/`, `supabase/tests/`

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | CLEAR (PLAN) | 7 issues, 0 critical gaps (G6 closed by mandatory pgtap test) |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | — | — |

- **VERDICT:** ENG CLEARED — scope reduced (4-arm → 2-arm, phased PR1/PR2, duration flag cut), 7 findings all folded. Design review worth running before PR2 (Day-3 trial-ending UX is net-new user-facing surface).

NO UNRESOLVED DECISIONS
