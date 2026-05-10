# Free / Premium Tier Redesign

**Date:** 2026-05-09
**Status:** Design — pending user approval, then plan
**Owner:** Ibrahim
**Related:** `2026-05-05-paywall-flow-redesign-design.md` (paywall UI), `2026-05-07-quest-rewards-xp-feedback-design.md` (XP/token economy)

## Problem

Today's free tier leaks revenue and obscures the upgrade decision:

- **Reflect** and **Built Dua** allow 3 free uses per day, then cost 50 tokens per additional use (`lib/services/daily_usage_service.dart:12-13`, `lib/services/token_service.dart:12-13`).
- **Discover Name** has no daily quota — always costs 50 tokens (`lib/services/token_service.dart:14`).
- Daily login grants ~80 tokens / week (`lib/services/daily_rewards_service.dart:38-58`), so a token-grinding free user can quietly bypass caps without ever hitting the paywall.
- Premium has no usage caps at all, so a single rogue user could drive unbounded OpenAI cost.

The result: free users either get too much (loss of conversion pressure) or hit a 50-token soft wall that feels like a grind, not a clear "upgrade or wait" decision. There's no moment of friction big enough to drive a conversion at the moment the user is most hooked.

## Goal

Implement **value-first freemium with delayed gating**: every new free user gets an unrestricted "warm-up" of every AI feature, then transitions to a tight 1/day cap that can only be lifted by upgrading. Daily habit features (check-in, browsing, journal, streaks, quests) remain unlimited free forever.

The tier structure must:

1. Let a new free user feel the full product across every AI feature, repeatedly, before any cap appears.
2. Create one clear upgrade decision once habit forms, with no token-grind escape hatch.
3. Cap premium AI usage at a fair-use ceiling to bound OpenAI cost per user.
4. Preserve the existing 3-day RevenueCat trial as the conversion lever for high-intent users coming out of onboarding.
5. Keep the daily check-in / Muhasabah loop unlimited free — that IS the product's core habit.

## Non-goals

- No change to onboarding flow structure (pages 0–25 stay as defined in `CLAUDE.md`).
- No change to RevenueCat product configuration (annual + weekly with 3-day trial — unchanged).
- No change to streak milestones, level-up rewards, quest reward amounts, or scroll/card mechanics.
- No new subscription tier (no "Plus" / "Premium+" / family plan in this spec).
- No changes to public catalog access (Names, Duas, Quiz remain anonymous-readable).

## User states

The app distinguishes **three** user states. Trial vs paid is a RevenueCat detail, not a gating concern. Lapsed-trialer is a flag (`had_trial`) that causes a free user to skip the warm-up phase, not a separate state.

| State | Detection |
|---|---|
| **Premium** | `isPremium() == true` (covers active trial AND paid subscription) |
| **Free + budget** | not premium, AND `had_trial == false`, AND any feature's warm-up counter > 0 |
| **Free + capped** | not premium, AND (`had_trial == true` OR all warm-up counters == 0) |

`had_trial` is set to `true` the first time RevenueCat's `customerInfo.entitlements.all['premium']` shows a trial period (active or expired). Once true, it stays true forever — a one-way latch. This means the gating layer never has to reason about "is the trial currently active vs lapsed" — it only asks `isPremium()` for the current entitlement, and consults `had_trial` only to decide whether the warm-up budget applies.

## Gating matrix

| Feature | Premium | Free + budget | Free + capped |
|---|---|---|---|
| Daily check-in / Muhasabah | unlimited | unlimited | unlimited |
| Reflect | 30/day fair-use | 10 lifetime then cap | **1/day, hard** |
| Built Dua | 30/day fair-use | 10 lifetime then cap | **1/day, hard** |
| Discover Name | 30/day fair-use | 5 lifetime then cap | **1/day, hard** |
| Browse Names / Duas / Journal | unlimited | unlimited | unlimited |
| View collection | unlimited | unlimited | unlimited |
| Daily login rewards | 5x multiplier | 1x | 1x |
| Streak milestones | identical | identical | identical |
| Premium monthly grant | yes | no | no |
| Premium card store tab | unlocked | locked | locked |
| Save reflections to journal | unlimited | 5 lifetime cap (current) | 5 lifetime cap (current) |

### Warm-up budget (free users only)

Every brand-new free user (declined the trial offer at end of onboarding) is granted a **lifetime** warm-up budget of:

- **10 Reflects**
- **10 Built Duas**
- **5 Discover Names**

These accumulate across days — a user can reflect 10 times on Day 1, or once a week for 10 weeks. There is no time component to the warm-up.

Once any one budget is exhausted, that feature transitions to the **1/day hard cap** for that user. Each feature transitions independently.

### Daily caps (free users, post-warm-up)

After warm-up exhaustion (or immediately for lapsed trialers), each AI feature is limited to **1 use per calendar day**, resetting at local midnight (matches existing `daily_usage_service.dart` date-keying pattern).

These caps are **hard**: no token override, no "watch ad to unlock," no friend-invite bypass. The only way past the cap is `isPremium() == true`.

### Premium fair-use ceiling

Premium and trialer users are capped at **30 uses per AI feature per calendar day** (Reflect, Built Dua, Discover Name independently). This is a silent ceiling — 99.9% of users will never approach it, but it caps OpenAI cost at ~$0.30/user/day worst case.

When hit, the user sees: "You've reflected a lot today. Take a breath — your next reflection unlocks tomorrow." (No upgrade prompt; this is a fair-use message, not a paywall.)

**Invariant:** UI MUST NOT route `GateReason.premiumFairUse` to any paywall sheet. Premium users hitting fair-use see only the soft "take a breath" message. Routing them to a paywall is a bug because they're already paying.

## Token economy changes

Tokens lose their "buy past the cap" function and become a **collection currency only**.

- **Removed:** the 50-token cost path for Reflect / Built Dua / Discover Name beyond the free quota. The `tokenCostReflect`, `tokenCostBuiltDua`, `tokenCostDiscoverName` constants in `lib/services/token_service.dart:12-14` are deleted at their call sites; the constants themselves can be deleted or repurposed for store pricing.
- **Removed:** the `needsToken` flow in `lib/features/reflect/providers/reflect_provider.dart:319-334`. When `canReflectFree()` returns false, the provider sets a new `state.capReached = true` flag that the UI maps to the soft paywall sheet (see Paywall triggers below) instead of a token-spend confirmation.
- **Unchanged:** daily login cycle (~80 tokens/week + 1 freeze + 5 scrolls), level-up token rewards, streak milestone rewards, premium 5x daily reward multiplier, premium monthly grant.
- **Effect on premium:** premium tokens are now spent entirely on cosmetics (store cards). The 5x multiplier becomes "complete the collection 5x faster," which is a clean cosmetic upsell rather than a confusing reflect-budget multiplier.

## Trial interaction

The 3-day RevenueCat trial offered at the end of onboarding (paywall page 25) is unchanged. Its role in the new model:

- **Trial start:** `isPremium()` flips to true → user enters **Premium** state → unlimited (subject to 30/day fair-use). The first time `PurchaseService.hadTrial()` returns true, `had_trial` is latched to `true` in Supabase + SharedPreferences — done once, never undone. Warm-up counters are **not consumed** during trial because `GatingService.canUse()` short-circuits on `isPremium()` before reading them.
- **Trial conversion:** `isPremium()` stays true → user stays in **Premium** state → no behavior change.
- **Trial lapse (no conversion):** `isPremium()` flips to false. Because `had_trial == true`, `GatingService` resolves the user to **Free + capped** regardless of warm-up counter values. They drop directly to **1/day hard caps** from Day 4. The contrast between "yesterday unlimited" and "today 1" creates maximum conversion pressure exactly when they remember what they had.

Detection of lapsed trialer relies on RevenueCat's `customerInfo.entitlements.all['premium']`, where `periodType` was previously `trial` and is now expired. Implementation reads the historical entitlement once at app launch and writes a persistent `had_trial=true` flag to Supabase + SharedPreferences so we don't depend on RevenueCat history being available at every gating check.

## Paywall trigger points

The existing paywall (`lib/features/onboarding/screens/paywall_screen.dart`) is shown in five new contexts in addition to the onboarding flow:

1. **Warm-up exhaustion** — first time a feature's lifetime budget hits zero. Sheet copy: "You've completed your free reflections. From tomorrow you'll get one a day — or unlock unlimited now." Variant per feature (reflect / dua / discover).
2. **Daily cap hit (post-warm-up)** — user attempts a 2nd Reflect/Dua/Discover same day. Sheet copy: "You've reflected today. Tomorrow's is on us. Or unlock unlimited now." Frequency-capped to one prompt per feature per day so we don't badger.
3. **Lapsed-trial Day 1 in-app** — first app open after trial lapses. Special variant referencing trial activity ("In 3 days you reflected X times. Premium keeps that pace."). Shown once.
4. **Narrative high points** — after a high-resonance reflect result, after crossing a streak milestone, after collecting a card. Frequency-capped to once per week per user to avoid fatigue.
5. **Tap on locked premium card store tab** — current behavior, preserved.

All paywall surfaces use the existing `paywall_screen.dart` component (or a sheet wrapper around it) — no new paywall UI is in scope for this spec.

## Migration

No migration needed. The app has no existing users at the time of this change, so the new tier structure is the launch behavior. Schema changes are additive (new columns default to safe values: `warmup_*_remaining` to 10/10/5, `had_trial` to false). No backfill, no data shimming, no deprecation period. Test users created during dev will pick up the new structure on next app launch.

## Data model

New / changed fields:

- `user_daily_usage` (Supabase, existing): unchanged columns — `reflect_uses`, `built_dua_uses`. **Add** `discover_name_uses INT DEFAULT 0` (new column for the 1/day discover cap).
- `user_profiles` (Supabase, existing): **add** `warmup_reflect_remaining INT DEFAULT 10`, `warmup_built_dua_remaining INT DEFAULT 10`, `warmup_discover_remaining INT DEFAULT 5`, `had_trial BOOLEAN DEFAULT FALSE`. Each warmup column decrements on use; once at 0, cap logic takes over.
- SharedPreferences: mirror all four fields locally (`warmup_reflect_remaining`, `warmup_built_dua_remaining`, `warmup_discover_remaining`, `had_trial`) so gating works offline.

The warmup counters live alongside the existing daily-usage counters, not inside them, because they have different semantics (lifetime decrement vs daily reset).

## Service-layer changes

Single new service consolidates gating logic. Daily-usage storage stays where it is.

- New: `lib/services/gating_service.dart` — single source of truth for all gating decisions. Exposes one primary API:
  ```dart
  Future<GateResult> canUse(GatedFeature feature);
  // GateResult = { allowed: bool, reason: GateReason, remaining: int? }
  // GateReason = { ok, premiumFairUse, warmupRemaining, dailyCap, hadTrialNoBudget }
  ```
  Internally reads `PurchaseService.isPremium()`, `had_trial` flag, warm-up counters, and daily-usage counters. All Reflect / Built Dua / Discover Name flows call this instead of checking `isPremium()` directly. Returning a structured `GateResult` (not just bool) lets the UI render the right paywall variant from the `reason`.

- `lib/services/daily_usage_service.dart` — add `discoverName` parallel functions (`getDiscoverNameUsageToday`, `canDiscoverFree`, `incrementDiscoverNameUsage`, `discoverFreeRemaining`). Change `dailyFreeReflects` and `dailyFreeBuiltDuas` constants from `3` to `1`. Remains the storage layer for daily counters; `GatingService` is the policy layer that consults it.

- Warm-up counters live as columns on `user_profiles` (see Data model) and are read/written through new helpers in `gating_service.dart` itself — no separate service. The pattern is small enough to inline.

- `lib/services/token_service.dart` — **delete** `tokenCostReflect`, `tokenCostBuiltDua`, `tokenCostDiscoverName` (lines 12-14) along with the `spendTokensForReflect` / `spendTokensForBuiltDua` / `spendTokensForDiscoverName` methods. Token spending after this change happens only in store flows. Don't leave the constants behind "for future use" — that's dead code that confuses readers.

- `lib/services/purchase_service.dart` — add `hadTrial()` helper that reads `customerInfo.entitlements.all['premium']` and returns true if any trial period is present (active or expired). On first true detection, persist `had_trial = true` to Supabase + SharedPreferences (one-way latch). No changes to RevenueCat init or product fetches.

**Invariant:** `had_trial` is **per-user**, not global. Storage uses `supabaseSyncService.scopedKey('had_trial')` for SharedPreferences and the `had_trial` column on `user_profiles` (RLS-scoped to `user_id`). When a user signs out and a new user signs in on the same device, the new user's `had_trial` resolves independently. Never read or write a global `had_trial` flag.

**Idempotency:** `hadTrial()` checks the local SharedPreferences flag first. If it's already `true`, return immediately — no Supabase write, no RevenueCat re-read. Only a `false` local flag triggers the RevenueCat lookup. Prevents the write from firing on every app launch for trialer / paid users where RevenueCat will always report a trial period.

## UI changes (out of scope for this spec, listed for the implementation plan)

- Reflect screen: new "cap reached" state replacing the current "needsToken" state.
- Built Dua flow: same change.
- Discover Name flow: gain the cap state.
- Onboarding paywall: unchanged.
- Paywall sheet variants — **3 reusable widgets, 5 contexts via copy params**:
  - `WarmupExhaustedSheet(feature)` — used at trigger 2 (warm-up exhaustion). One widget, copy parameterized by feature (reflect / dua / discover).
  - `DailyCapSheet(feature)` — used at triggers 3, 5 (daily cap hit, narrative high points). One widget, parameterized by feature and optional headline override for narrative variants.
  - `LapsedTrialSheet(reflectsCount, daysActive)` — used at trigger 4 (lapsed-trial Day 1). One widget, parameterized by trial-period activity stats from RevenueCat + local counters.

  Trigger 1 (onboarding) keeps using the existing `paywall_screen.dart` page. Don't create a fourth widget for it.
- "Free uses remaining" badge somewhere on the home screen during warmup phase (so users know they have a budget).

These will be detailed in the implementation plan.

## Test plan

The implementation plan must include all of the following before marking complete. The gating layer is the entire revenue gate — it is the highest-stakes service in the app and gets ★★★ coverage (happy path + edge cases + error paths).

**Unit tests — `gating_service_test.dart` (new):**

- `canUse(reflect)` for Premium state: returns `allowed=true, reason=ok` for uses 1-29 today; returns `allowed=false, reason=premiumFairUse` for use 30+. Boundary tested at exactly 29, 30, 31.
- `canUse(reflect)` for Free + budget: returns `allowed=true, reason=warmupRemaining, remaining=N` for warm-up uses; correctly transitions to Free + capped when budget hits zero.
- `canUse(reflect)` for Free + capped: returns `allowed=true, reason=ok` for first daily use; returns `allowed=false, reason=dailyCap` for second daily use; counter resets correctly at local midnight (use a fake clock).
- **REGRESSION-PREVENTING:** `had_trial == true` causes `canUse` to resolve to capped phase **even when warm-up counters are still positive**. This test pins the lapsed-trialer skip rule against future refactors.
- Parity tests for `builtDua` and `discoverName` features (parametrized).
- `_markUsed(feature)` decrements warm-up counter when in budget phase, increments daily counter when in capped phase, never both.

**Unit tests — `purchase_service_test.dart` (extended):**

- `hadTrial()` returns false for fresh `CustomerInfo`, true for active trial, true for expired trial.
- First true detection writes `had_trial = true` to both SharedPreferences and Supabase.
- Subsequent calls do not re-write (idempotent latch).

**Unit tests — `daily_usage_service_test.dart` (modified):**

- **REGRESSION-CRITICAL:** any existing test asserting `dailyFreeReflects == 3` or `dailyFreeBuiltDuas == 3` must be updated to `1`. Search for those literals and update or the test suite green-passes against incorrect behavior.
- New `discoverName` functions mirror reflect/dua coverage.

**Widget tests:**

- `WarmupExhaustedSheet` renders feature-specific copy for reflect / dua / discover.
- `DailyCapSheet` renders correctly with and without narrative-variant headline.
- `LapsedTrialSheet` renders trial-activity counts from RevenueCat + local counters; degrades gracefully if counts are unavailable.

**Integration tests:**

- Reflect provider: removed `needsToken` state path. After this change, no free user (in any sub-state) should ever enter `needsToken`. Add an assertion-style test that confirms the state is unreachable.

**End-to-end tests:**

- E2E #1 — warm-up burn: free user reflects 10 times in one session, sees `WarmupExhaustedSheet`; 11th reflect attempt shows `DailyCapSheet`.
- E2E #2 — daily cap reset: free user uses 1/day reflect, blocked on attempt 2, advances clock to next day, succeeds again.
- E2E #3 — lapsed trial drop: mock RevenueCat trial-then-lapse; verify first reflect on Day 4 succeeds (1/day cap), second is blocked by `DailyCapSheet`, sheet copy references trial activity.

**Eval / non-applicable:** no LLM prompt changes in this spec, so no eval suite updates needed.

## Analytics

New Mixpanel events to instrument the funnel:

- `warmup_started` (on first free reflect/dua/discover, with feature param)
- `warmup_exhausted` (when a feature's warmup hits zero)
- `daily_cap_hit` (when a 1/day cap blocks an action; props: feature, user_tier, days_since_signup)
- `paywall_shown` (existing — extend with `trigger` prop: `onboarding | warmup_exhaustion | daily_cap | lapsed_trial_d1 | narrative_high | premium_store_tab`)
- `paywall_converted` (existing — extend with same `trigger` prop)
- `lapsed_trialer_resumed` (first open after trial lapse, before any action)

These let us A/B test the warmup budget sizes and see which paywall trigger contexts actually convert.

## Success criteria

- Trial-start rate from onboarding paywall: hold flat or improve (this design doesn't touch the onboarding paywall, so flat is the realistic target).
- Free-to-paid conversion within 14 days of signup: target 1.5x current baseline (per RevenueCat freemium benchmark, the value-first pattern lifts conversion 2-5x; we're targeting the conservative end).
- D7 retention for free users: hold flat or improve. The warmup budget is generous enough that the cap shouldn't accelerate churn.
- OpenAI cost per free user per day: drop ~70% (from current ~6 calls/day max with token-grinding to a hard 3 calls/day after warmup).
- OpenAI cost per premium user per day: capped at $0.30 worst case (30 reflects × ~$0.01).

## Open questions resolved

- **Q: What about users who haven't trialed but want to upgrade later?** They follow the standard subscription purchase flow, no second trial (Apple policy). The lapsed-trial paywall variant doesn't apply to them.
- **Q: Should the warmup be shared across features or per-feature?** Per-feature (10/10/5). Sharing creates weird incentive to over-use one feature.
- **Q: Should premium be truly unlimited?** No — 30/day fair-use cap, silent. Caps cost without affecting any real user.
- **Q: Should daily check-in ever be capped?** No, never. It's the core habit and must stay unlimited free.

## Risks

- **Risk:** existing free users notice the per-day cap and feel ripped off. **Mitigation:** the warmup budget gives them a generous transition; cap copy is warm ("Tomorrow's is on us") not punitive.
- **Risk:** lapsed trialers feel especially harsh treatment with no warmup. **Mitigation:** the special lapsed-trial paywall variant gives them an immediate, contextual upgrade path that references their actual trial activity.
- **Risk:** Mixpanel/Supabase schema changes need a migration. **Mitigation:** new columns default to safe values (10/10/5/false) so the migration is non-blocking.
- **Risk:** users discover the cap is per-Apple-ID and game it with multiple accounts. **Mitigation:** out of scope — same risk exists today with the trial.

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | CLEAR (PLAN) | 10 issues, 1 critical gap (decrement timing) |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | — | — |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

**UNRESOLVED:** 0 (all findings applied inline or explicitly deferred)
**VERDICT:** ENG CLEARED — 4 scope reductions accepted, 22 test cases identified, ready to convert to implementation plan via `superpowers:writing-plans`.
