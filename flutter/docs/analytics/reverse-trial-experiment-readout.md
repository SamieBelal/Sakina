# Reverse-trial paywall experiment — readout & decision guide

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
