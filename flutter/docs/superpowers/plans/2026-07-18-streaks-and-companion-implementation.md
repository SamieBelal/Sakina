# Streaks + Companion (Lantern) — Implementation Plan

**Date:** 2026-07-18 · **Eng review:** 2026-07-19 (see `## GSTACK REVIEW REPORT` at bottom — 13 decisions folded in)
**Goal:** Ship the retention engine promised in the reel-first plan (`2026-07-03-reel-first-conversion-refactor.md` §C rows 4/5/7): a **reverent streak system with a forgiveness layer** and a **living lantern companion** whose light reflects the streak — across the home screen, the daily launch reveal, milestone moments, and the home-screen widget.
**Design inputs (read first):** [`docs/superpowers/specs/2026-07-18-streaks-and-companion-research.md`](../specs/2026-07-18-streaks-and-companion-research.md) — the sourced research that settled every strategy decision (streak defense = the strategy; non-figurative companion; code-drawn CustomPainter+shader; reverence guardrails). The companion visual is **built and approved** as the lantern (`lib/prototypes/lantern_companion_prototype.dart`, `khatam_companion_prototype.dart`).
**Scope decision (eng review):** **Full program, all 5 phases**, sequenced as separate PRs. The outside voice argued for deferring the defense backend until streak-reset churn is measured; founder held full-program (defense infra in place before the retention push). This is a deliberate bet that the Duolingo/Finch mechanism transfers to Sakina's secondary-streak model — the evidence is comparative, not yet Sakina-measured.

**What's already in the app (this plan *extends*, never rebuilds):**
- `StreakState{currentStreak, longestStreak, lastActive, todayActive}` + `markActiveToday()` + milestone ladder (7/14/30/60/90/180/365) — `lib/services/streak_service.dart`.
- Single-boolean streak freeze: `streak_freeze_owned` + `consume_streak_freeze` RPC — `lib/services/daily_rewards_service.dart:592`. **Consumed inline in `markActiveToday` on `_daysBetween > 1` (`streak_service.dart:295`); the commit is irreversible even if the streak upsert then fails.**
- Milestone claimed-set: **local SharedPreferences** (`_claimedMilestonesKey`), grants XP/scrolls/titles — `streak_service.dart:86`. ⚠ Economy state living in Flutter prefs (see Phase 2f).
- Widget state enum `{hidden, zero, done, pending, atRisk}` + payload with `streak`, live `streak` text in the chip — `ios/SakinaWidget/SakinaWidget.swift` (day boundary + 8pm cutoff computed in **local time**), pushed via `WidgetDataService.syncWidget()`. ⚠ The widget extension does **not build** until the Xcode target + App Group + fonts + catalog are added (see its header / SETUP.md) — a Phase 3 prerequisite.
- Streak surfaces: home hero (`lib/features/progress/screens/progress_screen.dart:~644`), daily launch reveal (`daily_launch_overlay.dart:~224`), milestone overlay (`streak_milestone_overlay.dart:~157`).
- `markActiveToday` has **three callers** (`reflect_provider`, `daily_question_provider`, `daily_loop_provider._markStreakAndHandleMilestones`) — any streak change must stay consistent across all three.

---

## 0. Locked decisions

**Strategy (from research):**
1. **Companion = the lantern** (code-drawn `CustomPainter` + `khatam_glow.frag`). Geometric/khatam, non-figurative. Garden/jannah collection axis is **out of scope** (deferred).
2. **Streak defense IS the retention strategy.** Forgiveness (soft-decay → free effort-repair → earned freeze → excused pause) is the core work; a **guarded paid buy-back** (§2g) is the *post-expiry* last resort only.
3. **Reverence is a hard constraint** (§3). Gamify showing up (istiqāmah), never the worship act.
4. **The daily muḥāsabah is the tend action.** Completing today's reflection **lights the lantern**. No new daily task.
5. **The widget cannot animate** — pre-rendered PNG frames per state, from the same painter.

**Architecture (from 2026-07-19 eng review — the load-bearing calls):**
6. `protected` is an **orthogonal shield-overlay modifier**, not a brightness state (§1).
7. The **lapse transition is an explicit state machine** with an ASCII diagram (§2a).
8. **Effort-repair fires before a freeze is consumed** (§2b).
9. `endowedDim` vs `dormant` derived from `lastActive==null && longestStreak==0` (§1).
10. **Thresholds live only in Dart**; the widget payload carries a precomputed 3-entry timeline (§3).
11. **No pixel goldens** — mapper unit tests + render-smoke (§5).
12. **Home-hero animation is bounded** — RepaintBoundary + pause offscreen/backgrounded (§4 perf).
13. **Milestone grants move server-side** so soft-decay + cache-clear can't double-grant (§2f).

---

## 1. The companion state machine (single source of truth)

`CompanionState` is **two orthogonal axes**, not a flat enum:

```
CompanionState = ( brightness : Brightness , protected : bool )

Brightness ∈ { endowedDim, dormant, pendingUnlit, atRiskUnlit, dim, glowing, fullyLit }
protected  = streak_freeze_owned == true   // forward-looking: "you're covered if you miss"
                                            // rendered as the painter's shield-halo bool,
                                            // composited OVER any brightness.
```

Pure mapper: `CompanionState resolveCompanionState({required StreakState streak, required bool freezeOwned, required DateTime now})`.

| Condition (evaluated in order) | Brightness | glow (illum pinned 1.0) | Reads as |
|---|---|---|---|
| `lastActive==null && longestStreak==0` (never acted) | `endowedDim` | 0.20 | "your light is lit" — never a cold Day 0 |
| `currentStreak==0` (has history: lastActive!=null OR longestStreak>0) | `dormant` | 0.0 | resting — *not lost* |
| done today, streak 1–3 | `dim` | 0.26 | just lit, faint |
| done today, 4–29 | `glowing` | 0.55 | warm |
| done today, 30+ | `fullyLit` | 0.95 + rays | radiant |
| not done, before 8pm | `pendingUnlit` | 0.10 | waiting to be lit |
| not done, ≥8pm | `atRiskUnlit` | 0.10 + gentle breath | still time — gentle, never panic |

`protected` (shield overlay) is applied on top of whichever brightness resolves, iff `freezeOwned`.

**Two hardening rules (from review):**
- **Snapshot read (finding #8).** The three inputs (`currentStreak` via `getStreak()`, `freezeOwned` via daily-rewards, `now`) must be read from a **single consistent snapshot**, not three independent provider watches — otherwise `protected` can render against a stale freeze while the streak is already post-consume. Provide one `companionInputsProvider` that composes the reads atomically; surfaces watch *that*.
- **Hydration guard (minor).** On cold launch `lastActive` is transiently `null` before `prepareStreakCacheForHydration` completes — a long-history user would flash `endowedDim`. The mapper's caller must gate on hydration-complete before first render (show a neutral placeholder until hydrated).

> **Clock note (P3):** the app's day boundary is **UTC** (`_todayString()` → `.toUtc()`, deliberate per the 2026-05-12 UTC migration); the widget's 8pm/at-risk is **local**. The mapper uses local `now` only for the 8pm pending/atRisk *copy* split (not brightness). The widget timeline (§3) must carry **absolute UTC instants**, and Swift localizes — never derive brightness from local time.

---

## 2. Phase breakdown

### Phase 0 — Extract the companion into the app *(S)*
- `lib/features/streaks/models/companion_state.dart` — `Brightness` enum + `CompanionState(brightness, protected)` + params resolver.
- `lib/features/streaks/companion_state_mapper.dart` — pure `resolveCompanionState(...)` (table §1).
- `lib/features/streaks/providers/companion_inputs_provider.dart` — the single-snapshot read (finding #8).
- `lib/features/streaks/widgets/companion_medallion.dart` — `CompanionMedallion(state, size)`: pulse controller + shader load + glow/illum lerp on state change, **wrapped in `RepaintBoundary`, pulse paused when offscreen/backgrounded** (finding #12).
- `lib/features/streaks/widgets/lantern_painter.dart` — production `LanternPainter` + geometry (moved out of `lib/prototypes/`).
- Confirm `shaders/khatam_glow.frag` ships in the real app build.

### Phase 1 — Place it in the 3 in-app surfaces *(S–M)*
1. **Home hero** — `progress_screen.dart:~644`, ~130px, ambient.
2. **Daily launch reveal** — `daily_launch_overlay.dart:~224`, replace the flame; arrives at yesterday's state, animates **unlit → lit** when today's reflection completes.
3. **Milestone overlay** — `streak_milestone_overlay.dart:~157`, `fullyLit` + rays.

### Phase 2 — Streak defense + endowed onboarding *(M, backend + client)*
All economy writes via existing RPC discipline — **never write streak/economy tables directly from Flutter.**

**2a. Lapse state machine (soft-decay, never hard-reset).** Explicit, not prose:

```
                 reflection (gap ≤1 day)
   ┌──────────────────────────────────────────────┐
   ▼                                                │
[ACTIVE]  current_streak = N, best = max, total++   │
   │  miss (a full day passes with no reflection)   │
   ▼                                                │
[LAPSED]  pre_lapse_streak = N (saved)              │
          current_streak → shown dormant            │
          lapsed_at = <first missed day, 00:00 UTC> │  reflection within 48h of lapsed_at
          best + total UNCHANGED  ──────────────────┘   → restore current_streak = pre_lapse+1  →[ACTIVE]
   │  48h passes with no reflection
   ▼
[EXPIRED]  current_streak = 0 (real)
           pre_lapse_streak cleared
           best + total PRESERVED FOREVER   → next reflection starts a fresh streak at 1
```

- Milestones read the **live** `current_streak`, so they pause during LAPSED and resume on repair. No milestone re-fires on restore (claimed-set, now server-side — 2f).
- **`lapsed_at` trigger fix (finding #4):** the miss day is not detected until the app next opens. Set `lapsed_at` to the **computed first-missed-day (00:00 UTC after `last_active`)**, NOT "now" — so a user who returns on day 5 is correctly past the 48h window, and one who returns within 48h of the actual miss is inside it. This makes the window measure real elapsed time, not app-open time.

**2b. The repair ladder (effort → freeze → paid, in that order).** Restructure `markActiveToday` so the **return reflection** decides, cheapest-and-most-reverent first:
1. **within 48h of `lapsed_at` → free effort-repair** (RPC `repair_streak`, gated purely on doing a reflection — **never tokens/money**). This is the primary, always-first path.
2. **else if `freeze_owned` → consume the earned freeze** (free — it was earned via daily rewards, never bought).
3. **else → EXPIRED.** From EXPIRED, the user may **optionally** buy back the streak with tokens (new **§2g**) — a rescue, never a block. If they decline, the streak starts fresh at 1 (best/total preserved forever).

Never auto-consume the freeze before the free effort-repair is attempted (reverse the current inline `consumeStreakFreeze` ordering at `streak_service.dart:296`). `repair_streak` is SECURITY DEFINER + idempotent.

**2c. Endowed start.** Brand-new users render `endowedDim` (never `dormant`), per §1 derivation. First reflection credits day 1 (already happens). Reveal copy frames it as *lit*, not *started from zero*.

**2d. Excused pause (capped + server-authoritative) (finding #5).** An excused day (menstruation/travel-illness) neither breaks the streak nor consumes a freeze. **Bounded** (e.g. ≤N excused days per rolling window — set the cap during build) and stored in a **server side-table with RLS** (`user_streak_excused_dates`), not a client toggle — otherwise it's unlimited free protection. `markActiveToday`'s gap check skips excused dates. Private, no reason required, but capped + audited.

**2e. Reverent loss framing (copy) + honest counters (finding #2).** Replace "streak broken/lost" with return-framed copy. **Gate "you've returned M of the last P days" behind sufficient `user_activity_log` history** — the log only started being written recently, so existing loyal users have a truncated log; showing the counter early would *understate* power users. Fall back to "best: N" until the log spans the window.

**2f. Milestone grants move server-side (finding #3).** Today `checkStreakMilestones` claims in local prefs and grants economy — on cache-clear/new-device the claimed-set is empty → **every milestone re-fires and re-grants XP/scrolls/titles**, and soft-decay makes streaks non-monotonic (the claimed-set assumed monotonic). Move the claim + grant into `sync_all_user_data()` / a dedicated SECURITY DEFINER RPC so the claimed-set is server-authoritative and idempotent. Aligns with the CLAUDE.md "no economy writes from Flutter" rule already enforced everywhere else.

**2g. Paid token repair (post-expiry rescue only) (founder decision 2026-07-19, overrides the original "no paid repair" rule — see §3).** Once a streak is **EXPIRED** (past the 48h free window AND no earned freeze), offer a one-tap **paid buy-back** with tokens. It is a *rescue*, surfaced only after the free paths are exhausted — never a gate on reflecting.
- **Price scales with the pre-lapse streak, mapped onto the existing token packs** (100=$1.99 / 250=$3.99 / 500=$6.99), so the cost equals ~one pack and exceeds a typical hoard (~10 tokens/day from daily rewards) — i.e. it realistically requires a purchase (the "strategical amount"):

  | Pre-lapse streak | Repair cost | Notes |
  |---|---|---|
  | **< 7 days** | **not offered** | trivial streak — just start fresh; never nickel-and-dime beginners |
  | 7–29 | **100 tokens** | ≈ $1.99 pack |
  | 30–89 | **250 tokens** | ≈ $3.99 pack |
  | 90+ | **500 tokens (cap)** | ≈ $6.99 pack |

- **Premium perk:** subscribers get **one free repair per rolling 30 days** (Duolingo-style) before tokens are charged — adds a paywall bullet and keeps the paid tier fair to payers.
- **Rate-limit:** ≤ **1 paid repair per rolling 30 days** (server-enforced) so it can't become a compulsive money sink.
- **Atomicity:** a single SECURITY DEFINER RPC (`repair_streak_paid`) **debits tokens AND restores `pre_lapse_streak`+1 in one transaction** — never a Flutter-side token debit (CLAUDE.md economy rule). Returns the new state; idempotent per lapse. Insufficient tokens → returns a "need N more" result that routes to the Store (reuse the `daily_cap_sheet` pattern).
- **Copy/UX (reverence):** calm and dismissible — "Relight your lantern" / "Restore your N-day journey", never "your streak died!". The free effort-repair is always shown first; the paid option only appears once the window has truly passed.

**2h. Streak notifications (reverent reframe + repair-window reminder).** Infra exists (`streak_risk` push, `notify_streak` pref, `last_streak_sent_at`, `send-scheduled-notifications` edge fn with quiet-hours dedup) but is not thorough for soft-decay:
- **Reframe `streak_risk` copy** away from mild-guilt ("keep your streak alive") toward reverent istiqāmah ("a quiet moment with Allah is waiting"). Keep the fixed-evening cadence + `notify_streak` opt-out + quiet-hours dedup.
- **New repair-window reminder** fired during the LAPSED grace (before `lapsed_at`+48h): "Your lamp is resting — return today to relight it." One push per lapse, deduped against the daily/streak/dua ticks, opt-out via `notify_streak`. Server-side in the edge fn (it already has `current_streak`; add lapse fields to the due-query).
- Never send an EXPIRED "you lost it" push — expiry is silent; the app surfaces the (optional) paid rescue in-context only.

**2i. Analytics (thorough instrumentation of every new codepath).** Through the existing `StreakAnalytics.onAnalyticsEvent` chokepoint (services have no Riverpod), documented in `docs/analytics/`. New events:
- `streak_lapsed` `{pre_lapse_streak}` — ACTIVE→LAPSED.
- `streak_repaired` `{method: 'effort'|'freeze'|'paid', pre_lapse_streak, tokens_spent, hours_since_lapse}` — the single success event across all three ladder rungs.
- `streak_expired` `{pre_lapse_streak}` — LAPSED→EXPIRED (window passed).
- `streak_repair_offer_shown` `{tier, cost_tokens, is_premium_free}` + `streak_repair_offer_dismissed` — paid-rescue funnel (offer→purchase or dismiss).
- `streak_excused_used` `{excused_count_in_window}`.
- `endowed_start` — first light on a brand-new lamp.
Add the name constants to `analytics_event_names.dart`; keep the emit-after-durable-commit discipline already used by `streak_extended`.

**Backend:** `user_streaks` (`20260407000000_initial_schema.sql:163`) — add `pre_lapse_streak`, `lapsed_at`, `last_paid_repair_at` (rate-limit + premium-free-monthly window); new `user_streak_excused_dates` table + RLS; `repair_streak` (free) + `repair_streak_paid` (atomic token debit + restore + rate-limit + premium-free-monthly) RPCs; server-side milestone claim/grant. New migration + pgtap.

### Phase 3 — Widget companion (pre-rendered frames) *(M)*
> **Prerequisite:** the Xcode widget target + App Group + fonts + catalog must be set up (the extension doesn't build yet — see its header). Do this first or Phase 3 can't ship.

- **Timeline payload (finding #10):** `WidgetDataService` writes a precomputed 3-entry timeline into the App-Group payload: `{state_now, state_evening, state_midnight}` where each is a resolved `CompanionState` **plus its absolute UTC instant**. Swift picks the frame per timeline entry and never re-derives thresholds (single source of truth in Dart).
- **Frames:** render the canonical brightness states to PNG (`pixelRatio:3`) from the Phase-0 painter, **per widget family** (Small vs Medium need different sizes — don't scale one). Composite the live `streak` number as SwiftUI text over the image (the number stays on the widget). Start with committed assets keyed by state; add live rasterization only if a state looks stale.
- **Lock Screen (finding #6):** `AccessoryView` is **OS-monochrome-tinted** — a colored lantern becomes a gray blob. Ship a **tint-safe monochrome/line-art lantern** (or keep the accessory text-only) so the "light reflects streak" idea survives the highest-frequency surface. Do NOT reuse the color PNG there.
- **Android:** same PNG-per-state via Glance→RemoteViews if/when an Android widget exists (follow-up if none today).

### Phase 4 — Milestone celebration polish (Lottie) *(S, optional)*
One-shot Lottie bloom around the `fullyLit` lantern at 7/30/100/365 + subtle haptic (reuse `~/lottie-lab`). Reverent — no slot-machine confetti.

---

## 3. Reverence guardrails (hard rules)
No leaderboards · no hasanat/reward count for worship · no guilt/"streak dies!" pushes (loss = reversible dormancy) · the number never eclipses the practice · copy oriented toward Allah/istiqāmah.

**Paid repair — guarded override (founder decision 2026-07-19).** The original "no paid streak repair (effort only)" rule is **relaxed** to allow a *post-expiry* token buy-back (§2g), under hard constraints that keep it from reading as selling indulgences: (a) the **free effort-repair is always offered first** and paid never gates reflecting; (b) paid appears **only after true expiry** (past 48h + no freeze); (c) **rate-limited** ≤1/30d + **premium gets one free/30d**; (d) **never** fear/guilt copy — calm, dismissible "relight your lantern"; (e) **not offered below a 7-day streak**. The worship act is never paywalled — only the *cosmetic streak counter* on an already-expired streak can be optionally restored.

---

## 4. Performance
- **Bounded animation (finding #12):** `CompanionMedallion` in a `RepaintBoundary`; pulse controller paused when offscreen (VisibilityDetector) or app backgrounded (lifecycle); keep the 2.6s breath. Prevents 60fps blur+bloom+shader repaint draining battery on the always-on home hero / in background.
- Widget frames are static PNGs — no runtime cost. Rasterization (if used) runs on streak-change, not per-frame.

## 5. Test plan
Framework: `flutter test` (unit + widget) + pgtap (per CLAUDE.md). **No pixel goldens** (finding #11 — shader/blur output is GPU-flaky).

- **[CRITICAL REGRESSION]** `markActiveToday` soft-decay: a 2-day gap with no freeze **preserves `longest_streak` + total-returned** (only current dims); a continued (≤1-day) streak still increments exactly as before. (Mandatory per the regression rule — the diff changes existing streak behavior.)
- **Mapper units** — every §1 row incl. boundaries (day 3/4, 29/30, 8pm), `endowedDim` vs `dormant`, `protected` overlay orthogonality, hydration-null guard.
- **Render-smoke** — each brightness state paints without throwing (existing `/tmp` harness).
- **`repair_streak` (free) pgtap** — idempotent within 48h; no-op after 48h (window measured from computed miss-day, not app-open); RLS can't repair another user.
- **`repair_streak_paid` pgtap** — restores `pre_lapse_streak`+1 **only** when EXPIRED; **atomic** (insufficient tokens → no debit, no restore); correct tier cost per streak band (7–29→100, 30–89→250, 90+→500, <7→refused); **rate-limit** ≤1/30d enforced; **premium free** consumes the monthly credit before tokens; RLS can't repair/charge another user; token debit routed through the RPC (never client-side).
- **Soft-decay/excused pgtap** — excused day skips gap; excused cap enforced; EXPIRED clears `pre_lapse_streak` but not best/total.
- **Milestone server-side pgtap** — claim idempotent across cache-clear (no double-grant); non-monotonic streak doesn't re-fire.
- **Notifications** — repair-window reminder fires once during the LAPSED grace and never after EXPIRED; deduped against daily/streak/dua ticks; suppressed when `notify_streak` is off.
- **Analytics** — each new event emits once, after durable commit; `streak_repaired` carries the correct `method`/`tokens_spent`; paid-offer funnel (`offer_shown`→`repaired{paid}`|`offer_dismissed`) is consistent.
- **[→E2E]** launch reveal `pending → complete muḥāsabah → lit`; lapse `→ reflect ≤48h → restored`; expiry `→ paid buy-back → restored` (+ insufficient-tokens → Store route).
- **Widget** — payload writes 3-entry UTC timeline; Swift picks correct frame per entry; Lock-Screen uses monochrome asset.

---

## What already exists (reuse audit)
Reused, not rebuilt: `StreakState`/`markActiveToday`/milestone ladder, `consume_streak_freeze` + freeze bool, widget state enum + `WidgetDataService`, the 3 streak surfaces. **Modified (regressions to test):** `markActiveToday` (soft-decay + repair-before-freeze ordering), milestone claim/grant (prefs → server). **Genuinely net-new:** the painter extraction, the mapper, `repair_streak` (free) + `repair_streak_paid` (paid rescue), excused-dates table, the repair-window notification, the new streak-defense analytics events, widget frames.

## NOT in scope (considered, deferred)
- **Garden/jannah collection** axis (organic art, Recraft/hybrid pipeline) — separate later plan.
- **Rive** — rejected (editor-first, not Claude-controllable/free).
- **Any new daily task** — tend action is the existing muḥāsabah.
- **Android widget frames** — follow-up if/when an Android widget exists.
- **Deferring the defense backend** — outside voice proposed it; founder held full-program (logged as cross-model tension).

## Failure modes (per new codepath)
| Codepath | Realistic failure | Test? | Error handling? | User sees |
|---|---|---|---|---|
| `repair_streak` RPC | server write fails mid-repair | pgtap idempotency | RPC atomic + returns state | stale streak, retries next reflection |
| `repair_streak_paid` RPC | tokens debited but streak not restored | pgtap atomicity | single txn: debit+restore together or neither | tokens safe; retry or refunded |
| paid-repair rate-limit | user spams buy-back / double-charge | pgtap (≤1/30d) | server-enforced window + `last_paid_repair_at` | offer hidden until window resets |
| `lapsed_at` compute | wrong instant → wrong 48h window | pgtap (miss-day math) | computed, not "now" | correct window (fixed) |
| milestone server grant | double-grant on cache-clear | pgtap | server-authoritative claimed-set | no double XP (fixed) |
| snapshot read | stale freeze vs post-consume streak | mapper test | single-snapshot provider | consistent shield (fixed) |
| widget timeline | UTC/local drift | widget test | absolute UTC instants | frame swaps at right wall-clock |
| Lock-Screen tint | color PNG → gray blob | widget test | monochrome asset | legible lantern (fixed) |
No remaining failure mode is silent + untested + unhandled → **no critical gaps open.**

## Worktree parallelization
| Step | Modules | Depends on |
|---|---|---|
| P0 extract | features/streaks/ | — |
| P1 surfaces | features/progress, features/daily | P0 |
| P2 defense | services/, supabase/migrations/ | — (mapper protected/endowed need P0) |
| P3 widget | ios/SakinaWidget, services/widget_data | P0 (painter), P2 (states) |

- **Lane A:** P0 → P1 (sequential, shared features/).
- **Lane B:** P2 backend (services/ + supabase/) — independent of P0/P1; can run in a parallel worktree.
- **Then:** P3 (needs P0 painter + P2 states). P4 after P1.
- **Conflict flag:** P1 and P2 both touch `streak_service.dart` region → coordinate or sequence.

## Implementation Tasks
Synthesized from findings. P1 blocks ship; P2 same branch; P3 follow-up.

- [ ] **T1 (P1, human: ~2h / CC: ~20min)** — streaks/mapper — Model `CompanionState` as `(brightness, protected)` + pure mapper with §1 derivations
  - Surfaced by: Arch 1 + 4 — protected orthogonal; endowed vs dormant from `lastActive==null && longestStreak==0`
  - Files: `lib/features/streaks/models/companion_state.dart`, `companion_state_mapper.dart`
  - Verify: mapper unit tests every §1 row + boundaries
- [ ] **T2 (P1, human: ~3h / CC: ~30min)** — streak_service/supabase — Lapse state machine: soft-decay, `pre_lapse_streak`/`lapsed_at` (computed miss-day), repair-before-freeze
  - Surfaced by: Arch 2 + 3, outside voice #4
  - Files: `lib/services/streak_service.dart`, new migration, `repair_streak` RPC
  - Verify: regression test + pgtap idempotency/window
- [ ] **T3 (P1, human: ~2h / CC: ~20min)** — supabase/economy — Move milestone claim+grant server-side (idempotent, cache-clear-safe)
  - Surfaced by: outside voice #3
  - Files: `streak_service.dart`, `sync_all_user_data`/new RPC, migration
  - Verify: pgtap no-double-grant across cleared claimed-set
- [ ] **T4 (P1, human: ~1.5h / CC: ~20min)** — widget/services — Timeline payload `{now,evening,midnight}` (UTC instants); Dart-only thresholds; monochrome Lock-Screen asset
  - Surfaced by: Code Quality 1, outside voice #6
  - Files: `lib/services/widget_data_service.dart`, `ios/SakinaWidget/SakinaWidget.swift`
  - Verify: widget test frame-per-entry + accessory tint
- [ ] **T5 (P2, human: ~1.5h / CC: ~15min)** — streaks/widgets — `CompanionMedallion` bounded animation (RepaintBoundary + pause offscreen/bg) + single-snapshot inputs provider
  - Surfaced by: Perf 1, outside voice #8
  - Files: `lib/features/streaks/widgets/companion_medallion.dart`, `providers/companion_inputs_provider.dart`
  - Verify: no repaint when offscreen; consistent protected/streak
- [ ] **T6 (P2, human: ~2h / CC: ~20min)** — streak_service/supabase — Excused-pause: capped + server side-table + RLS
  - Surfaced by: outside voice #5
  - Files: new `user_streak_excused_dates` migration + RLS, `streak_service.dart`
  - Verify: pgtap cap enforced + RLS isolation
- [ ] **T7 (P2, human: ~1h / CC: ~10min)** — daily/progress — Loss-reframe copy + gate "returned M of P" behind activity-log history
  - Surfaced by: outside voice #2
  - Files: `daily_launch_overlay.dart`, `progress_screen.dart`, notifications
  - Verify: copy audit; counter hidden until log spans window
- [ ] **T8 (P3, human: ~1h / CC: ~10min)** — daily — Milestone Lottie bloom around fullyLit lantern (Phase 4)
  - Surfaced by: plan Phase 4
  - Files: `streak_milestone_overlay.dart`, `assets/animations/`
  - Verify: one-shot plays; reverent
- [ ] **T9 (P1/P2, human: ~3h / CC: ~30min)** — supabase/economy/daily — Paid token repair (§2g): `repair_streak_paid` RPC (atomic debit+restore, tiered cost, ≤1/30d rate-limit, premium free-monthly) + post-expiry rescue sheet
  - Surfaced by: founder decision 2026-07-19 (overrides §3 no-paid-repair)
  - Files: new migration (`last_paid_repair_at` + RPC), `streak_service.dart`, new rescue widget under `features/daily/` or `features/streaks/`, Store route reuse (`daily_cap_sheet` pattern), pgtap
  - Verify: atomicity + tier cost + rate-limit + premium-free pgtap; insufficient-tokens → Store E2E; free effort-repair still offered first
- [ ] **T10 (P2, human: ~1.5h / CC: ~15min)** — notifications — Reverent `streak_risk` reframe + new repair-window reminder during the 48h grace
  - Surfaced by: gap review 2026-07-19 (§2h)
  - Files: `send-scheduled-notifications/index.ts` (due-query + copy), `notification_service.dart` (route/type), migration if a new notif type/sent-column is needed
  - Verify: fires once per lapse, never post-expiry; quiet-hours dedup; `notify_streak` opt-out honored
- [ ] **T11 (P2, human: ~1h / CC: ~10min)** — analytics — Instrument every new streak codepath (§2i)
  - Surfaced by: gap review 2026-07-19
  - Files: `analytics_event_names.dart`, `streak_service.dart` (StreakAnalytics emits), `docs/analytics/`
  - Verify: each event emits once after durable commit; `streak_repaired` method/tokens correct; paid funnel consistent

---

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | issues_found (all folded) | 7 review + 6 outside-voice findings, 13 decisions folded, 1 critical regression test added, 0 critical gaps open |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | — | — |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

- **CODEX:** Codex CLI errored on arg-parse (twice); outside voice ran via Claude subagent instead.
- **CROSS-MODEL:** One tension — outside voice recommended deferring the defense backend until streak-reset churn is measured; founder held full-program (a deliberate bet the mechanism transfers). Recorded, not applied.
- **VERDICT:** ENG CLEARED — ready to implement (full-program scope, phased PRs; start Phase 0).

NO UNRESOLVED DECISIONS
