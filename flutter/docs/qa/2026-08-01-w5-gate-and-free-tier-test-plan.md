# W5 — the gate and the free tier: device/sim test plan

**Branch:** `feat/reel-first-w2-onboarding` · **Written:** 2026-08-01 · **Covers:** the 20
W5 commits from `195a113` to `c9c8d74`

This plan exists because W5 changed **who gets what for free**, and every defect in it is
either invisible (an analytics event that lies) or irreversible (a server counter clamped
down by a guard that only goes one way). Reading a screen is not enough — most of §4 is
about state you have to seed before the screen can tell you anything.

---

## 1. What is applied RIGHT NOW, and what is not

Verified against production 2026-08-01, not assumed.

### Applied (server)

| Thing | State |
|---|---|
| `20260801015832_warmup_discover_name_size` | **applied** |
| `20260801015850_handle_new_user_stamps_discover_warmup` | **applied** |
| `consume_weekly_allowance(p_feature)` | exists, SECURITY DEFINER |
| `app_config.warmup_reflect_size` / `warmup_built_dua_size` / `warmup_discover_name_size` | **3 / 3 / 3** |
| `app_config.weekly_pool_size` | **3** |
| `app_config.post_tour_paywall_mode` | `soft` |
| `guard_user_profiles_freemium_fields` | covers cohort + all pool columns; exempts `service_role` / `postgres` / `supabase_admin` |

### NOT applied — and this shapes the whole test pass

| Thing | State | Consequence for testing |
|---|---|---|
| `app_config.new_signup_cohort` | **`'legacy'`** | **Every account you create today is LEGACY.** `reel_v1` must be seeded by hand (§3.1). |
| `free_tier_cohort` on real rows | **0 `reel_v1`**, 103 `legacy`, **1,262 NULL** | NULL reads as legacy. The tightened tier is currently reaching nobody. |
| `supabase/staged/t0_flip_all_to_reel_v1.sql` | **not run** | The T0 flip. Do not run it to test — seed one account instead. |
| App Store Connect trial | still **`P3D`** | Every trial string renders "3 days". The 7-day copy cannot be verified until ASC changes. |
| Wave A (reverse-trial deletion) | blocked to **2026-08-04** | `assignPaywallArm`, `tourBucket`, `trial_expiry_service` still live. |

---

## 2. What you CANNOT test on a simulator — read before starting

This is the honest boundary. Ignoring it produces false failures.

**2.1 — There is no StoreKit configuration in the repo** (`find ios -name "*.storekit"` is
empty), and RevenueCat resolves product metadata through StoreKit. On a simulator the
offerings fetch returns nothing, so:

- `_annualPackage` / `_weeklyPackage` are **null**
- `_trialFor(...)` therefore returns **null for every plan**
- **the paywall always renders its NO-TRIAL variant**: CTA reads "Subscribe", the terms
  line reads "$49.99 a year. Cancel anytime.", and the ceremony collapses to **2 pages**
  (the trial timeline is dropped by design)
- the paywall renders its explicit unavailable state: no fabricated prices, billing terms,
  or purchase CTA are shown

**So the sim gives you preview #5 — the ineligible user — and nothing else.** That is a
real and important state (every lapsed trialer lands there), but it is not the default one.

**Device-only, no exceptions:**

- trial copy anywhere (CTA, terms, timeline page, exit offer)
- the trial timeline page existing at all
- purchase, restore, `trial_started` vs `subscription_started_no_trial`
- per-user intro eligibility (the thing that decides which of the two you see)
- the hard gate's offerings-failure safety valve behaving as a *failure* path rather than
  the normal one

**Sim is fine for:** every gating decision, every cap/warmup sheet, cohort branching, the
weekly pool, warmup arithmetic, navigation and placement, the always-free card, and all
layout.

**2.2 — Dev Tools has no gating controls.** `/dev-tools` (Settings → Developer, `kDebugMode`
only) covers streaks, rewards, quests, achievements and freezes. Nothing for warmup, cohort
or the pool. Seed those in SQL (§3).

**2.3 — Daily usage counters are local-only.** `daily_usage_*` lives in SharedPreferences
and is never mirrored from the server, so a daily cap can only be exhausted by *actually
using the feature* (each use is a real OpenAI call) or by reinstalling. Everything else —
warmup, cohort, pool, `had_trial` — IS mirrored and can be seeded.

**2.4 — Do NOT use Settings → Danger Zone to reset counters.** It is not debug-gated and
must never clear `daily_free_reveal_*` / `daily_usage_*`.

---

## 3. Seeding recipes (Supabase MCP)

MCP runs privileged, so it is exempt from `guard_user_profiles_freemium_fields` — these
writes succeed where the app's own would raise.

**The hydration rule, and it governs every recipe below:** `GatingService.hydrateFromProfile`
copies `warmup_*_remaining`, `free_tier_cohort`, `weekly_pool_used`, `weekly_pool_week_start`,
`had_trial` and `first_bypass_consumed` out of the `sync_all_user_data` payload into
SharedPreferences on each sync. So the loop is always:

> **SQL → force-quit the app → relaunch → sign in.** A hot reload will NOT pick these up.

### 3.1 A `reel_v1` free user (the W5 tier)

```sql
update public.user_profiles set
  free_tier_cohort               = 'reel_v1',
  warmup_reflect_remaining       = 3,
  warmup_built_dua_remaining     = 3,
  warmup_discover_name_remaining = 3,
  weekly_pool_used               = 0,
  weekly_pool_week_start         = null,
  weekly_pool_reset_at           = null,
  had_trial                      = false
where id = '<uid>';
```

### 3.2 Warmup already spent, pool untouched

```sql
update public.user_profiles set
  warmup_reflect_remaining = 0, warmup_built_dua_remaining = 0
where id = '<uid>';
```

### 3.3 Weekly pool exhausted

`weekly_pool_week_start` is **required** — without it `weeklyPoolRemaining()` returns the
full pool and you will see no cap.

```sql
update public.user_profiles set
  weekly_pool_used       = 3,
  weekly_pool_week_start = (date_trunc('week', now() at time zone
                             public.safe_user_tz('<uid>')))::date
where id = '<uid>';
```

### 3.4 Premium WITHOUT StoreKit

`PurchaseService.isPremium()` ORs gift → RevenueCat → referral → trial. `referral_premium_until`
is the cheapest lever, and `AppSessionNotifier` refreshes its cache at boot.

```sql
update public.user_profiles
set referral_premium_until = now() + interval '30 days'
where id = '<uid>';
```

To undo: set it back to `null`, then relaunch.

### 3.5 A lapsed trialer (for the LapsedTrialSheet)

Server side only sets the latch; the sheet also needs `hadTrial()` from RevenueCat and a
cleared one-shot flag, so **this one is device-only in practice**:

```sql
update public.user_profiles set had_trial = true where id = '<uid>';
```

### 3.6 A pre-onboarded account from scratch

Use the recipe in the `qa-preonboarded-test-account` memory (auth.users + auth.identities,
**token varchar columns set to `''` not NULL**, then `onboarding_completed = true`,
`onboarding_paywall_cleared = true`). Existing usable accounts:
`qatester1@sakina-test.dev`, `beat-qa@sakina-test.dev` (both `testpass123`).

### 3.7 Reading state back

```sql
select free_tier_cohort, warmup_reflect_remaining, warmup_built_dua_remaining,
       warmup_discover_name_remaining, weekly_pool_used, weekly_pool_week_start,
       had_trial, referral_premium_until
from public.user_profiles where id = '<uid>';
```

---

## 4. The test matrix

Ordered by **what breaks worst**, not by feature. P0 items are the defects found and fixed
during this wave — they are the highest-probability regressions and several are silent.

### P0-1 · A failed sync must not destroy a legacy user's warmup ⚠️ irreversible

The bug: provenance was re-derived from "does a local counter exist", but the no-push path
*writes* that counter — so the second use pushed a guessed `1` over a server `10`, and the
decrement-only guard made it permanent.

| | |
|---|---|
| **Seed** | legacy account, `warmup_reflect_remaining = 10`, `free_tier_cohort = 'legacy'` |
| **Set up the failure** | The local counter must be ABSENT while the server value exists. Easiest: delete the app from the sim and reinstall, then sign in **with networking disabled** (Settings → Airplane-ish, or kill the Supabase host) so `hydrateFromProfile` never runs. |
| **Do** | Reflect **twice**. |
| **Expect** | Both allowed. |
| **Verify (this is the test)** | `select warmup_reflect_remaining from user_profiles where id='<uid>'` → still **10**. |
| **Fails if** | it reads 1, 2, or anything below 10. |

Then re-enable networking, relaunch, and confirm the counter hydrates back to 10 and
subsequent uses **do** decrement the server.

### P0-2 · Warmup exhaustion must not spend the weekly pool

| | |
|---|---|
| **Seed** | §3.1, then `warmup_reflect_remaining = 1` |
| **Do** | Reflect once (the 1 → 0 transition). |
| **Expect** | `WarmupExhaustedSheet` appears with the Monday copy. |
| **Verify** | `weekly_pool_used` is still **0**. |
| **Fails if** | it is 1 — the user reaches the post-warmup tier with 2 of 3 uses after being promised 3. |

### P0-3 · The stale-week probe is bounded (no unlimited pool)

The original bug burned a real OpenAI call per iteration and survived restarts.

| | |
|---|---|
| **Seed** | §3.1 + §3.3 (pool exhausted), then set the sim's clock forward past your local Monday **without** changing the server. |
| **Do** | Attempt Reflect repeatedly. |
| **Expect** | **At most one** pass-through, then the weekly-pool cap sheet for the rest of the day. |
| **Fails if** | every attempt is allowed. |

### P0-4 · Premium is never sold to a payer

| | |
|---|---|
| **Seed** | §3.4 |
| **Do** | Exhaust the premium fair-use ceiling (30/day) — or force it by seeding a non-premium account, hitting the cap, then granting premium and relaunching. |
| **Expect** | The sheet reads **"You've done a lot today" / "Reflections open again tomorrow."** with a single **outlined Close** and **no** "Unlock unlimited", **no** token bypass. |
| **Also** | `WarmupExhaustedSheet.show()` must return without presenting anything for a premium user. |

### P0-5 · The ✕ on a cap sheet actually dismisses

Regression for the dead-✕ bug (an await that threw before the exit callback).

Open each cap/warmup sheet and dismiss it **four ways**: the ✕/secondary button, a scrim
tap, a swipe-down, and Android back. All four must close the sheet *and* leave the app
usable — no frozen gate.

### P0-6 · Placement survives a router refresh

| | |
|---|---|
| **Do** | Open the paywall from a **cap sheet** (not the settings card). While it is open, trigger an auth-token refresh (background the app ~60s and return, or force a sync). |
| **Expect** | Still the condensed in-app paywall with its trigger-specific value line. |
| **Fails if** | it reverts to the generic soft-in-app line — the `extra` was dropped by GoRouter's re-parse. |

### P1-1 · The `reel_v1` weekly pool

| Step | Expect |
|---|---|
| Seed §3.1. Reflect ×3 | all allowed, warmup consumed |
| Reflect ×3 more | allowed, `weekly_pool_used` climbs 1→2→3 |
| Reflect again | **weekly-pool cap sheet**: "Your reflections for this week are used" / "Your free reflections and duʿās return together on Monday." |
| Now Build-a-Duʿā | **also capped** — the pool is shared. This is the single most important assertion in this section. |

### P1-2 · `discoverName` on `reel_v1`

| Step | Expect |
|---|---|
| Day-open reveal | **always free, no gate consulted** — verify it works even with warmup at 0 and the pool exhausted |
| Re-roll ×3 | allowed (the lifetime warmup) |
| Re-roll again | cap sheet with `GateReason.rerollPremium` — "One Name a day stays free, always. Or unlock unlimited to meet another today." |
| **Critical** | the day-open reveal must NEVER be answerable with a cap sheet |

### P1-3 · Legacy is byte-for-byte unchanged

Seed a `legacy` account (or leave one at NULL cohort) and confirm: 1/day cap, "Tomorrow's
reflection is on us", the **token bypass slot present**, and `discoverName` at an effective
2/day. Nothing in W5 may have moved for this cohort — this is the guarantee that protects
the existing base until T0.

### P1-4 · Cohort resolution fails to LEGACY

Sign in with networking down so no cohort ever hydrates. The user must get the **generous**
legacy tier, never the tightened one.

### P1-5 · The dials are live

Change `app_config.warmup_reflect_size` to `1`, relaunch, and confirm a fresh account gets
one warmup use. **Set it back to 3.** This proves the client reads the dial rather than its
fallback constant.

### P2-1 · The 15 surfaces in situ

All were reviewed in isolation on 2026-08-01 and approved. Re-check only what a harness
could not show: real data (a real awarded card on ceremony page 1), real prices, and that
the condensed paywall **fits without scrolling** — it truncates the benefit list by screen
class (5/4/3/2), so check an SE-class sim as well as your device.

### P2-2 · Trial timeline dates (device only)

Dates are computed local-calendar, not UTC and not `Duration(days:)`. Check at **23:50
local** that "Today" still shows today's date. Five unit tests already cover month rollover
and the US spring-forward.

### P3 · Analytics

With the Mixpanel test-id exclusion applied, confirm on a real purchase (device):
`trial_started` fires **only** when a trial was granted, and `subscription_started_no_trial`
fires otherwise. Both carry `placement`. This is the pair that decides whether W5 is kept,
and it was wrong until this wave.

---

## 5. Cleanup

After testing, reset any account you seeded — especially `referral_premium_until` (a live
premium grant) and any dial you changed. Add every test uid to
`docs/qa/mixpanel-orphaned-distinct-ids.json` so it is excluded from funnel queries.

**Do not** run `t0_flip_all_to_reel_v1.sql` as part of testing. It is the launch-day
operation, its warmup clamp is **lossy** (`least()` discards the surplus), and rolling the
cohort back does not restore the counters.
