# Reverse-trial paywall experiment — readout & decision guide

> ## ⚠️ CLOSED 2026-07-31 — WITHOUT A DECISION
> **This experiment is over and no arm won.** It was closed by **supersession**: the One Ship
> (W5) replaces the paywall and onboarding surfaces the arms were testing. Everything between
> here and the addendum describes a decision read that **was never taken and never will be** —
> it is preserved as the experiment's design record, **not** as live instructions. Do not run
> the queries below expecting a verdict, and do not treat any number in this doc as one.
> **→ [Addendum — 2026-07-31: closed without a decision](#addendum--2026-07-31--closed-without-a-decision)**

**Audience:** anyone (human or AI agent) reading out the reverse-trial A/B test in Mixpanel and deciding which arm to ship.
**Companion doc:** [`funnel-flags-and-querying.md`](./funnel-flags-and-querying.md) — the general funnel/super-property model. Read it first; this doc is the experiment-specific layer on top.
**ADR / plan of record:** [`docs/decisions/2026-06-14-onboarding-paywall-reverse-trial.md`](../decisions/2026-06-14-onboarding-paywall-reverse-trial.md).
**Mixpanel project:** `4013350`. **RevenueCat project:** `proje6681c8c`.
**Ships in:** app build **`1.2.0+4`** (the build carrying PRs #44 + #45). Record the exact `app_version` of the first store release that contains the experiment — every query below filters to it.

---

## TL;DR — the one rule for THIS test

There is **ONE funnel**, segmented by the **`paywall_exp_arm`** super property. Two arms:

| `paywall_exp_arm` value | Arm | Experience |
|---|---|---|
| `control_no_trial` | **Control** | onboarding → tour → **soft paywall immediately** at tour exit |
| `treatment_reverse_trial` | **Treatment** | onboarding → tour → **straight into the app** with a silent 3-day app-granted premium → the **same soft paywall surfaces on Day 3** when it lapses |
| `unassigned` | (neither) | assigned before the experiment was active — **exclude from the read** |

The paywall is **soft (dismissible) in both arms by design** — the *only* variable is the 3-day trial. Never look for arm-specific event names; there are none. Build the funnel once, break down by `paywall_exp_arm`.

---

## When to re-query (timeline anchored to store-release day = **T0**)

> **Why you can't read early:** every experiment event ships *inside the binary* and has **zero history before `1.2.0+4` is live**. And the treatment arm's conversion is structurally delayed — a treatment user cannot convert until their 3-day trial lapses (Day 3) *plus* however long they take to decide. So the earliest a treatment paid conversion can even exist is ~T0 + 3 days, and a fair read needs a full conversion window after that.

| Checkpoint | What it's for | Decision-grade? |
|---|---|---|
| **T0 (release day)** | **Instrumentation sanity only.** Confirm `experiment_assigned` is firing, the split is ~50/50 across the two arms, `trial_activated` fires for treatment, and both `placement` values (`post_tour_soft`, `post_trial_soft`) appear. | ❌ No |
| **T0 + 3–4 days** | Health check: `trial_activated` count ≈ treatment `experiment_assigned` count (trials are actually being granted); `trial_expired` starting to fire; no anomalous `daily_cap_hit` spike. | ❌ No |
| **T0 + 10 days** | **First directional read.** Earliest point treatment conversions can exist (3-day trial + ~1 week decide). Look at the trend, not significance. Do NOT call the test here. | ⚠️ Directional only |
| **T0 + 21 days AND min-N met** | **Decision read.** 3 weeks covers 3 weekly cycles (weekend vs weekday signup behaviour) and gives both arms a full conversion window. | ✅ Yes — if min-N met |

**Minimum sample (both must hold before deciding):**
- **≥ 21 calendar days** of `1.2.0+4` exposure, **and**
- **≥ ~1,500 `experiment_assigned` users per arm** (≈3,000 total). At ~50–100 signups/day on a 50/50 split that's roughly the 3–5 week mark. If conversion is rarer than expected, extend rather than call it underpowered.

If 21 days passes but min-N isn't met, **keep running** — do not decide on an underpowered sample. Re-query weekly until both gates clear.

> **Do NOT change flags mid-run.** Don't flip `reverse_trial_experiment_enabled`, `post_tour_paywall_mode`, or `tour_ab_enabled` while the test is live — arm assignment is a stable per-user hash *only while the flag stays on*. Toggling reassigns in-flight users and corrupts the read. Set once at T0, leave untouched until the decision read.

---

## What to pull — the metrics

All events carry the `paywall_exp_arm` super property. Build each as a funnel/ratio, **broken down by `paywall_exp_arm`**, filtered to `app_version = 1.2.0+4` (or later), with the test IDs excluded (see Gotchas).

### Primary metric — paid conversion per assigned user
**Definition:** `experiment_assigned` (denominator, shared by both arms) → `subscription_started` (RevenueCat webhook, the true paid signal) **OR** client `trial_started` if you prefer surface-attributed RC-trial starts.

- Funnel: `experiment_assigned` → `trial_started` → `subscription_started`.
- Break down by `paywall_exp_arm`.
- **This is the number the decision hinges on:** *of everyone assigned to the arm, what fraction became a paying RC subscriber?*

> ⚠️ **Do not confuse the app-granted trial with an RC trial.** `trial_activated` (treatment's 3-day app-granted premium) is **not** a RevenueCat trial and never converts to RC on its own. Real revenue = `subscription_started` / `trial_started` (RevenueCat). The reverse trial is a *funnel-warming* mechanic, not a billing event.

### Secondary / supporting metrics (break down by `paywall_exp_arm`)
| Metric | Events | Reads |
|---|---|---|
| Trial grant integrity | `trial_activated{days:3, source:reverse_trial}` | treatment only; count ≈ treatment assignments |
| Trial lapse | `trial_expired` | treatment only (carries no `arm` prop — relies on the super property; only treatment users have a `trial_premium_until`) |
| Day-3 gate view | `trial_paywall_surfaced{placement:post_trial_soft}` | treatment's post-trial wall impressions |
| Soft-gate dismissal | `soft_gate_dismissed{placement, arm}` | how many *walk away* from the wall (split by `post_tour_soft` vs `post_trial_soft`) |
| Free-tier friction | `daily_cap_hit{feature, arm}` | does control (no trial) hit caps sooner and harder? proxy for "wishes they had premium" |

### Guardrail metrics (must NOT regress) — break down by `paywall_exp_arm`
- **D1 / D7 retention:** funnel `experiment_assigned` → `check_in_completed` at day-1 and day-7 windows. The reverse trial should *help or hold* retention; if treatment retention drops materially, that's a veto even if conversion is up.
- **Engagement during trial:** `check_in_completed`, `dua_built`, `journal_entry_created` in the first 3 days — confirms treatment users actually *experience* premium (if they don't engage, the trial isn't doing its job).

---

## How to decide which arm wins

Apply in order. A win requires the primary to clear **and** no guardrail to be vetoed.

1. **Primary (paid conversion per assigned user):** treatment must beat control with **P(treatment > control) ≥ 95%** (Bayesian; Mixpanel's experiment/“compare” view reports this) — or, frequentist, the **95% CI on the absolute lift excludes 0**. A raw point-estimate lift with overlapping intervals is **not** a win.
2. **Guardrail — retention:** treatment D7 retention must not be significantly *worse* than control. If it is, treatment loses regardless of conversion.
3. **Tie / inconclusive (intervals overlap at min-N + 21 days):** prefer **control** — it's simpler, has no give-away-premium mechanic, and is the lower-risk default. Don't ship added complexity for an unproven lift.

**Worked read (the exact Mixpanel steps):**
1. Insights/Funnels → events `experiment_assigned` → `subscription_started`.
2. Breakdown: `paywall_exp_arm`.
3. Filter: `app_version` is `1.2.0+4` (or `≥`); exclude the test distinct_ids.
4. Date range: T0 → today (≥21 days).
5. Read the two conversion rates + the significance/lift the compare view reports.
6. Repeat steps 1–5 swapping the final step for the D7 retention funnel (the guardrail).

---

## Which build/config to keep after the decision

The arms are runtime `app_config` states, so "shipping the winner" is mostly a flag flip — **except** rolling treatment to 100%, which needs a small code change (see below).

| Outcome | What to set | Notes |
|---|---|---|
| **Control wins** (no trial, soft wall) | `reverse_trial_experiment_enabled = false`, `post_tour_paywall_mode = soft` | Everyone gets the immediate soft wall, no trial. Pure flag flip, no deploy. |
| **Treatment wins** (reverse trial) | `reverse_trial_experiment_enabled` stays on **but** bucketing must go 100% treatment | The current `assignPaywallArm` is a 50/50 split — leaving the flag on keeps *half* of users in control forever. Rolling the winner to everyone is a **code change** (make `assignPaywallArm` return treatment unconditionally, or add an "always-on" config), then deploy. Flag-only is NOT enough here. |
| **Inconclusive** | `reverse_trial_experiment_enabled = false`, `post_tour_paywall_mode = soft` | Fall back to the simpler control experience; revisit later. |

**Keep the legacy `hard_paywall_after_tour_enabled` flag** regardless — older installed binaries (pre-`1.2.0`) read only that boolean and have never heard of `post_tour_paywall_mode`. Don't retire it until that build is fully sunset.

---

## Gotchas (read before trusting a number)

- **Exclude the 54 test distinct_ids** in [`docs/qa/mixpanel-orphaned-distinct-ids.json`](../qa/mixpanel-orphaned-distinct-ids.json) on *every* query.
- **No history before `1.2.0+4` ships.** `experiment_assigned`, `trial_activated`, `trial_expired`, `trial_paywall_surfaced`, `daily_cap_hit`, `soft_gate_dismissed`, the `post_tour_soft`/`post_trial_soft` placements, and the `paywall_exp_arm` / `flag_reverse_trial_exp` super properties all populate **only from that build forward**. Always filter `app_version`.
- **`unassigned` is not an arm** — it's the pre-experiment / pre-flag default. Filter it out of the comparison.
- **`trial_expired` carries no `arm` event prop** — it fires on a later session (Day 3+, app-resume) where the arm isn't in scope. It relies entirely on the durable `paywall_exp_arm` super property, which is re-applied at boot and survives sign-out. Only treatment users can have a `trial_premium_until`, so the super property already attributes it correctly — but if you ever break funnels by the *event* `arm` prop, this event won't have one.
- **App-granted trial ≠ RC trial** (restated because it's the #1 misread): `trial_activated` is not revenue. Conversion = `subscription_started` / `trial_started`.
- **Identity is Simplified ID Merge** — anonymous→signed-up stitches by `distinct_id` automatically (verified 2026-06-15). Re-verify if Mixpanel's identity setting ever changes.
- **Super properties don't backfill** — they attach going forward from when they're set (arm at onboarding-complete, flags at boot). The very earliest events of a brand-new session may predate the arm property.
- **Don't decide on raw event totals** — `experiment_assigned` should be ~once per user, but always count **unique users** as the denominator, not raw events.

---
---

# Addendum — 2026-07-31 — closed without a decision

**Status:** CLOSED. **Superseded, not decided.** No winning arm. Nothing ships from this test.
**Written:** 2026-07-31, as One Ship **W5 Wave A** ([`docs/superpowers/plans/2026-07-31-one-ship-05-gate-and-free-tier.md`](../superpowers/plans/2026-07-31-one-ship-05-gate-and-free-tier.md) §4.A).
**Prod state verified:** 2026-07-31 22:18 UTC.

## A1. Why it closed — supersession, not failure, and not a result

The One Ship replaces **the surface under test**. The arms differed in exactly one thing: whether
a user got a 3-day app-granted premium before meeting **the post-tour soft paywall**. W5 deletes
that paywall (a single 1,741-line page becomes an approved 3-page gate), and the One Ship's
onboarding replaces the flow that fed it. The forced tour that sat between them is being killed
too.

So there is no arm to "ship as the winner." Shipping control would mean shipping the old soft
gate — which is being deleted. Shipping treatment would mean keeping a giveaway mechanic in
front of a paywall that no longer exists.

The rollout decision compounds this. Per **§V6.9** (founder, 2026-07-23) the One Ship goes to
**100% of new signups at release — no A/B, no control arm, no holdout**; the read is pre/post
against the trailing-90-day baseline. A concurrent arm-based experiment on the surface being
replaced cannot survive that, and was not meant to.

> **Be precise about the category of this ending.** The experiment did not fail, did not error,
> and did not produce a negative result. It was **stopped early because the thing it measured
> is being removed.** That is supersession. An experiment that is superseded has no finding —
> it has a stopping reason.

**The min-N rule is explicitly overridden, not met.** The design above required **≥1,500
`experiment_assigned` users per arm (≈3,000 total) AND ≥21 days**. Actual exposure was roughly
**768 users across both arms**. At ~21 signups/day, reaching 3,000 assigned would have taken on
the order of **five more months** — during which the surface under test would not have existed.
Power here was not merely unmet; it was **unreachable**. This addendum overrides the min-N gate
by closing the test, not by declaring it satisfied.

## A2. The honesty clause, restated (the #1 misread, and it survives the close-out)

> ### ⚠️ The app-granted `trial_activated` is **NOT** a RevenueCat trial and **never** counted as revenue.
>
> The treatment arm's 3-day premium was granted by **our own server** by writing
> `user_profiles.trial_premium_until`. It involved **no store transaction, no RevenueCat
> entitlement, no billing relationship, and no payment instrument.** It could never convert to a
> paid subscription on its own — it simply lapsed.
>
> **457 accounts ever held one.** That number is a count of **give-aways**, not conversions,
> not trials in the store sense, and not revenue of any kind. The same goes for every
> `trial_activated` event in Mixpanel.
>
> Real revenue in this test was, and remains, **`subscription_started` / `trial_started` from
> RevenueCat** — nothing else.

This matters more *after* the close-out than during it. A future reader skimming for "how did
the trial do" will find a large, inviting `trial_activated` / 457-row count sitting next to a
tiny paid-conversion count. **Those are not two measurements of the same funnel.** The reverse
trial was a funnel-warming mechanic. Do not put it in a numerator or a denominator with revenue.

Note also that W5 introduces a **real 7-day RevenueCat store trial**. From that build forward,
"trial" in this codebase means a genuine StoreKit introductory offer. The app-granted kind
described in this doc is being deleted and must never be conflated with it.

## A3. What we saw — descriptive only, and **not** a result

The last read, taken **2026-07-23** from **production subscription records** (not Mixpanel), over
signups since **2026-06-18**:

| Arm | Assigned | Subscribed | Rate |
|---|---:|---:|---:|
| `control_no_trial` (no trial, post-tour soft gate) | 410 | 10 | **2.44%** |
| `treatment_reverse_trial` (3-day reverse trial → soft gate) | 358 | 6 | **1.68%** |
| **Total** | **768** | **16** | 2.08% |

**Sixteen conversions decided nothing.** Ten versus six. Moving two or three users between the
columns reorders the arms. No significance test is reported here because the sample cannot
support one, and none should be computed from these figures later — a point estimate is not a
finding, and a confidence interval on n=16 would be a decoration, not evidence.

Read the table as **exposure and raw counts under a stopped test**, nothing more.

**What the founder actually acted on.** The One Ship's rationale (§V6.3.5 / §V5.3) cites a
*hypothesis*, not a finding: **both soft arms sat at roughly the freemium median (~2.1%), which
suggested the ceiling was the gate model rather than the arm** — a toothless gate makes trial
expiry a non-event. That reasoning, plus dedicated hard-vs-soft research and the reel-first
strategy, drove the decision to replace the gate. **The experiment did not establish it.** It is
recorded here so the causal chain is honest: the direction came from research and product
conviction, and this test was too small to confirm or refute it.

**No fresh Mixpanel pull was taken for this close-out, deliberately.** The enshrined read above
comes from production subscription rows; a Mixpanel funnel would produce a second, differently
denominated number over the *same ~16 conversions* — adding no power while creating two competing
figures in a close-out document. (Separately: the standing test-ID exclusion cannot be expressed
cleanly in the current query schema — string filters are single-value with no "not in" operator —
so a compliant one-shot query was not available either.) A number that cannot change the outcome
was not worth the ambiguity.

## A4. In-flight position and the deletion unblock date

Verified against production **2026-07-31 22:18 UTC**:

| | |
|---|---:|
| Accounts holding an **active** `trial_premium_until` | **24** |
| Accounts that **ever** held one | **457** |
| **Last in-flight trial expires** | **2026-08-03 20:45:36 UTC** |

> **All in-flight trials are honored to their natural expiry. There is no early revocation, no
> clawback, and no shortening.** A faith audience punishes taking something back far more than it
> rewards a tidy migration, and 24 people are not worth that. They keep what they were given until
> it lapses on its own.

**Therefore code deletion cannot begin before 2026-08-04.** The gate is not the calendar date by
itself — it is the condition in A5.1 — but 2026-08-04 is the earliest date that condition can hold.

## A5. Deletion checklist

Run in order. **Do not start before 2026-08-04**, and do not skip step 1.

1. **Precondition — verify, don't assume.** Confirm **zero** rows satisfy the condition:
   ```sql
   select count(*) from public.user_profiles where trial_premium_until > now();
   -- must return 0
   ```
   A non-zero count means someone is still holding a granted trial. **Stop and wait.** Re-check;
   do not proceed on the calendar date alone.

2. **Delete the client code.** Symbols and files verified 2026-07-31.

   > **Grep, don't trust line numbers.** W5 is actively rewriting `app_session.dart`,
   > `main.dart`, `onboarding_screen.dart` and the paywall tree, and this checklist does not
   > run until 2026-08-04 at the earliest. Line numbers below are as-of-2026-07-31 hints and
   > **will** have drifted. The **symbol and file names are the contract**; locate each with
   > `grep -rn '<symbol>' lib/ test/`.

   | Symbol / thing | File | Note |
   |---|---|---|
   | `TrialExpiryService` | `lib/services/trial_expiry_service.dart` | imported by `lib/core/app_lifecycle_observer.dart`; named in a doc comment in `lib/services/purchase_service.dart` (~`:99`); test at `test/services/trial_expiry_service_test.dart` |
   | `assignPaywallArm`, `PaywallArm` enum, `analyticsValue` | `lib/features/paywall/paywall_experiment.dart` (~`:47`) | the whole file goes |
   | `_defaultPaywallArm` (the arm **reader**) | `lib/core/app_session.dart` (~`:699-709`) | calls `assignPaywallArm`; supplies the soft-paywall `arm` event prop. Also wired as the default `_paywallArmReader` in the `AppSession` constructor (~`:79`) — remove **both** |
   | `resolveAndApplyPaywallExperiment` + the `paywall_experiment_assigned` dedup key (`paywallExperimentAssignedBaseKey`, ~`:14`) | `lib/features/paywall/reverse_trial_onboarding.dart` | ⚠️ **this file still exists** — see the correction note below |
   | Experiment hook call site | `lib/features/onboarding/screens/onboarding_screen.dart` (~`:555-572`) | flag read + `resolveAndApplyPaywallExperiment` |
   | `reverse_trial_experiment_enabled` reads | `lib/main.dart` (~`:368`, registers the `flag_reverse_trial_exp` super property) · `onboarding_screen.dart` (~`:563`) | retire the super property with the flag |
   | Dependency note to drop | `lib/features/tour/models/onboarding_tour_step.dart` (~`:39`) | "load-bearing for `assignPaywallArm` until the reverse-trial close-out" |

3. **Then retire `reverse_trial_experiment_enabled` from `app_config`.** It is **`true` in
   production as of 2026-07-31** — so delete the key **only after** the build that stops reading
   it is live, or older installed binaries will fall back to their `fallback: false` default
   mid-session. Flag deletion follows code deletion, never leads it.

4. **Sweep the now-orphaned tour-A/B hash.** Removing `assignPaywallArm` removes the last
   consumer of `tourBucket` / `assignTourVariant`
   (`lib/features/tour/models/onboarding_tour_step.dart:445-455` — "kept because `tourBucket`
   backs `assignPaywallArm` and tests pin the hash"). The slim-vs-full tour A/B already concluded
   2026-07-25. Once this close-out lands, **both** experiments' bucketing machinery is dead code.

5. **Done when:** `grep -r assignPaywallArm lib` returns nothing and the suite is green.

> **Correction to the W5 plan's stated baseline:** §2 of the W5 plan says
> `reverse_trial_onboarding.dart` **is already deleted**. As of 2026-07-31 on
> `feat/reel-first-w2-onboarding` it is **still present** at
> `lib/features/paywall/reverse_trial_onboarding.dart` (6,071 bytes) and still declares the
> `paywall_experiment_assigned` dedup key. The plan also locates `assignPaywallArm` at
> `app_session.dart:694-707`; that range is `_defaultPaywallArm`, the **reader**. The function
> itself lives in `lib/features/paywall/paywall_experiment.dart`. Trust the table above.

## A6. `paywall_exp_arm` is frozen as history

**The super property is retired. It is valid as a filter on historical events only. It is never
re-added, and no shipped code reads it again.**

- Events carrying it exist only from build **`1.2.0+4`** forward through the close-out window.
  Outside that window the property is absent or `unassigned` — which **is not an arm**.
- Do not register it on new installs. Do not add it to any new instrumentation. Do not reuse the
  name for a future paywall experiment; a recycled property name silently merges two populations
  that were never comparable.
- The One Ship's equivalent dimension is a **different property**: `onboarding_flow`
  (`'reel_v1' | 'legacy'`), because a kill-switch flip makes flow non-inferable from
  `app_version`. It is not a continuation of `paywall_exp_arm` and must never be unioned with it.

**Precedent — this is the second one, handled identically:** `flag_tour_ab` was retired
**2026-07-25** when the slim-vs-full tour A/B concluded. Its `tour_ab_enabled` key was deleted
from `app_config` (confirmed absent in prod 2026-07-31), the super property was unregistered from
installs, and it remains valid on pre-2026-07-25 events only. See
[`funnel-flags-and-querying.md`](./funnel-flags-and-querying.md) — the retired row stays in the
flag table on purpose, so nobody re-adds it. `paywall_exp_arm` gets the same treatment.

## A7. What a future reader must NOT conclude from this data

Stated plainly, because each of these is an easy and wrong inference:

1. **Not that control won.** 2.44% vs 1.68% over 16 conversions is noise. Control's higher point
   estimate is not evidence, and this addendum is not a quiet vote for it.
2. **Not that reverse trials don't work.** The mechanic was never tested at power, and it was
   tested *only* in front of a dismissible soft gate — the one configuration where a lapse costs
   the user nothing. Nothing here generalizes to a reverse trial in front of a real gate.
3. **Not that giving away premium hurts conversion.** Same reason. Direction and magnitude are
   both unresolved.
4. **Not that the 457 app-granted trials represent trial volume, trial starts, or revenue.**
   See A2. They are give-aways, and they are not comparable to the real 7-day store trial W5 ships.
5. **Not that the One Ship's gate change is validated by this test.** It is not. The One Ship
   rests on hard-vs-soft research and a founder decision (§V6.9), explicitly traded a causal read
   for speed, and carries its own declared honesty clause: **no causal attribution; seasonality
   and reel-mix shifts are declared confounds.** Do not retroactively promote this test into
   supporting evidence.
6. **Not that "we ran a paywall experiment and here's what we learned."** We ran one, stopped it
   early for a structural reason, and learned nothing decision-grade about the arms. The honest
   one-line summary is: *the surface was replaced before the test could answer anything.*

## A8. What this addendum supersedes above it

| Section above | Status |
|---|---|
| "When to re-query" (T0 / +3-4d / +10d / +21d timeline) | **Dead.** No further checkpoint will be run. |
| Minimum sample (≥1,500/arm, ≥21 days) | **Overridden by closure**, not met — see A1. |
| "Do NOT change flags mid-run" | **Moot.** `reverse_trial_experiment_enabled` is being deleted; sequencing is now A5.3. |
| "What to pull — the metrics" (primary, secondary, guardrails) | **Dead as instructions.** Preserved as the design record. |
| "How to decide which arm wins" (P ≥ 95%, retention veto, tie → control) | **Never applied and never will be.** No arm was chosen by this rule. |
| "Which build/config to keep after the decision" | **Superseded by W5.** Both the "control wins" flag flip and the "treatment wins" code change are void — the paywall those rows describe is being replaced. `hard_paywall_after_tour_enabled` (still `true` in prod) and `post_tour_paywall_mode` (`soft`) are now W5's business, not this experiment's. |
| Gotchas | **Still accurate** for querying historical events, with two fixes: (a) the test-ID list is now **64** distinct_ids, not 54 — always read the current [`docs/qa/mixpanel-orphaned-distinct-ids.json`](../qa/mixpanel-orphaned-distinct-ids.json) rather than the count quoted in prose; (b) `paywall_exp_arm` is now historical-only per A6. |
