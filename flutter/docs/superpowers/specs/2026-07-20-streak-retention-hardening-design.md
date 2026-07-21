# Streak Retention Hardening — Design Spec

**Date:** 2026-07-20 · **Branch (target):** `feat/streaks-companion` (or a follow-up)
**Status:** Design-reviewed (see review report at end) · **Author:** Ibrahim + Claude

---

## 1. Context & goal

The streak + lantern companion is built. Omnipresence is already solved: the
**Home tab (`/` → `ProgressScreen`)** renders the live lantern hero at 130px plus
a streak-count pill, and the resolver (`companion_state_mapper.dart`) already
surfaces `pendingUnlit` / `atRiskUnlit` / `dormant` at the decision moment.

A retention audit (research in §12) found the engine is present but
under-leveraged, and the highest-ROI notification (the evening streak-saver) is
gain-framed and sprayed at everyone. This spec hardens the loss-aversion /
sunk-cost / anticipation loop **without** punitive dark patterns, which the
research shows *cause* churn in emotionally-loaded wellness categories.

## 2. Guardrails (non-negotiable)

- **Reverent, never guilt.** Copy gamifies *istiqāmah*; the `dormant` state stays
  "resting, not shamed."
- **Locked lantern vocabulary:** `lit` (reflected today) → `waiting` (not yet
  today) → `resting` (lapsed). **Banned words everywhere: dark, dies, lost,
  broken, failed.**
- **No post-expiry "you lost it" push.** Never over the Name reveal.
- **Gold is a non-text accent only** (~2.5:1 on emerald — fails WCAG for text).
  Functional text is emerald/cream. Gold = flame glyph + progress-bar fill only.
- **Economy integrity via RPC.** Tokens/XP/streaks/freeze/**milestone claims** flow
  through server-authoritative RPCs, never direct writes / never local-only.

## 3. Non-goals

- No new avatar art / brightness states (the 8-state ladder is fixed).
- No social/leaderboard streaks.
- No change to the **UTC** day-boundary streak accrual in `streak_service.dart`.
  (Only the *push-suppression* check reads local day — see S1.)
- **First-week grace: CUT** (decided in review — keep the hard reset; preserve
  streak-mechanic purity).
- **Freeze token buy-path: deferred** past v1 (visibility first, sink later).

## 4. Locked design decisions (from the 2026-07-20 review)

| # | Decision | Rationale |
|---|---|---|
| D1 | **Chain = collapsed summary → tap-expand.** Hero shows one line ("12 days lit this month ›"); full month grid on tap. | Protects the Name reveal; fixes day-0 empty-grid; resolves the week-vs-month contradiction. |
| D2 | **One merged streak line** replaces the pill+subtitle+sliver. Shield folds into the medallion. | One primary streak signal; kills duplicate numeric signals cluttering the hero. |
| D3 | **CTA label stays "Begin Muḥāsabah"** always; relight framing lives in the subtitle above it. | Preserves the single CTA mental model the tour teaches (`tour-coach-banner-direction`). |
| D4 | **Freeze-burn = a card, reunion-first copy.** "Welcome back — your 12-day streak is intact." | A card can be dwelt on; reunion-first avoids the "you almost failed" whisper. |
| D5 | **Lock the lantern metaphor** (§2); saver push becomes "Your lantern rests tonight — one reflection keeps it lit." | Consistent voice; compassion not dread. |
| D6 | **Suppress the morning win-back** if the evening saver fired and wasn't converted. | Avoids the "you blew it" sandwich around one lapse; win-back only on real dormancy (day 2–3). |
| D7 | **Milestone-approaching push: 1 day out only** in v1. | Protects an already-full notification budget; higher-intent moment. |
| D8 | **Saver eligibility uses LOCAL-day reflection**, not UTC. | The saver fires at local 7–8pm; a UTC check would false-fire "rests tonight" at users who reflected in their local evening. |
| D9 | **365+ sliver shows a maintained state** ("Day 400 · every day lit"), never disappears. | A vanished sliver punishes your most loyal users. |
| D10 | **Milestone claims — VERIFY ONLY, already shipped.** `claim_streak_milestone` (idempotent `ON CONFLICT DO NOTHING`, returns `newly_claimed`) exists in `20260719000000_streaks_defense.sql`; the client grants only on `newly_claimed`. | Eng review found the double-grant was already fixed. Task downgraded from build to a 15-min verify (confirm no caller grants economy off the local `getClaimedMilestones()` set). |
| D11 | **Unified streak-notification decision model.** Compute ONE decision per user per day (`saver \| milestone \| win-back \| none`), persist one `last_streak_family_sent_at` + `last_streak_family_kind`. | Cron runs `0,30 * * * *`; `pushedUserIds` is a per-invocation in-memory Set → useless across :00/:30, and per-type sent-columns let saver+milestone+win-back stack. One decision + one dedup column collapses mutual-exclusion, kills the double-fire, and makes D6 a trivial state transition. |
| D12 | **S1 ships LAST, no kill-switch.** Client surfaces (hero line, chain, burn card) ship first; the shared-RPC notification change ships last with the most testing. | S1 touches the RPC every push type (daily/dua/weekly) depends on — a regression takes them all down. It is the highest-blast-radius change, not "isolated." (User declined per-segment feature flags.) |
| D13 | **Chain calendar = month-scoped server query + shared UTC→local date normalization.** Not the 14-record client cache. Frozen/excused days derived from streak history, not only the net-new burn marker. | `checkin_history_service.dart:6` caps the local cache at 14 records (can't feed a 31-day grid); `checked_in_at` is UTC-dated (calendar would disagree with the saver about "lit" days); un-backfilled freeze burns would render as "missed" gaps, violating the §6 no-gap guardrail. |
| D14 | **Freeze-burn marker is server-side + dismissal-tracked** (`last_freeze_burn_at` + dismissed), written in/adjacent to `consume_streak_freeze`. | A local marker re-shows on cache-clear / second device (the D10 class of bug). Consume-before-upsert ordering (`streak_service.dart:435`) can lose a marker written next to the streak upsert. |

---

## 5. Workstreams

### S1 — Notification segmentation (P0)

Replace the single gain-framed streak push with a segmented ladder. All copy uses
the locked vocabulary (D5).

| Segment | Condition | When | Framing | Copy |
|---|---|---|---|---|
| **(suppress)** | reflected today (local day, D8) | — | — | *no push* |
| **Streak-saver** | streak ≥1, not reflected this **local** day | ~7–8pm local | loss, invitational | title "A quiet moment awaits" · body "Your lantern rests tonight — one reflection keeps it lit." |
| **Milestone (1-day, D7)** | exactly 1 day before 7/14/30/60/90/180/365 | evening | anticipation | "Tomorrow is your {tier}-day flame — one reflection away." |
| **Win-back** | dormant ≥ ~2 days AND **not** suppressed by D6 | morning | warm | "Your lantern is resting. Relight it whenever you're ready." |

**Implementation (unified model, D11 — reframed by eng review).** Do NOT bolt three
segments onto the shared RPC. Instead compute ONE streak-notification decision per
user per day:

```
decide(user) at their local evening tick:
  reflected this LOCAL day (last_reflected_local = local_today, D8/A1)   -> none
  streak lapsed >= 2 local days (dormant)                                -> win-back
  exactly 1 day before a milestone threshold                             -> milestone
  streak >= 1, not reflected this local day                              -> saver
  else                                                                    -> none
persist: last_streak_family_sent_at (date) + last_streak_family_kind (text)
dedup:   skip if last_streak_family_sent_at = local_today  (kills the :00/:30 double-fire)
```

- **A1 (D8):** add a client-written `last_reflected_local date` column (see A1 decision);
  the decision reads it, never the UTC `last_active`. NULL = eligible (no backfill).
- **D6 falls out for free:** win-back only fires at dormancy ≥2 local days, so it
  cannot overlap the evening-of-lapse saver — no conversion signal, no suppression
  flag needed.
- Keep `targetHour: 20`. The three segments become mutually exclusive by construction.
- **Blast-radius (D12):** this replaces the `streak` branch of the shared machinery —
  regression-test daily/dua/weekly/reengagement. Ships LAST.

### S2 — Home hero: merged streak line + relight framing (P1)

Per D2/D3. One state-driven line directly under the lantern; shield folded in.

| Companion state | Streak line (emerald text) | CTA subtitle | CTA label |
|---|---|---|---|
| lit, streak N, next tier T, d days away | **Day N · {d} to your {T}-day flame** | "Day N · glowing" | Begin Muḥāsabah (disabled ✓ "Reflected today") |
| lit, streak ≥365 (D9) | **Day N · every day lit** | "Day N · every day lit" | Reflected today ✓ |
| endowed-dim (no history) | **Your light is lit** | — | Begin Muḥāsabah |
| pending/at-risk unlit | **Your lantern is waiting** | "Your lantern is waiting" (+ lantern icon) | Begin Muḥāsabah |
| dormant (resting) | **Your lantern is resting** | "Relight it whenever you're ready" | Begin Muḥāsabah |

The next-milestone bar (6px, gold fill on emerald-tint track) sits under the line,
**merged with it** — not a separate sliver. Fixed-height slot; pre-hydration shows a
dimmed track, no copy (never a "0 to your 7-day flame" flash). **Acceptance: on the
smallest supported device (iPhone SE), with a lit streak + active milestone, the
Name-of-Allah reveal must be at least partially visible above the fold.**

### S3 — "Month of light" chain calendar (P1)

Per D1. **Collapsed:** one hero line — `"{lit} days lit this month ›"`; day-0 shows
`"Your month begins today ›"` (never a wall of empty cells). **Expanded (on tap):**
full current-month grid on its own surface.

**Data source (D13 — reframed by eng review).** NOT the 14-record client cache
(`checkin_history_service.dart:6` `_maxHistory=14` truncates a 31-day grid). Add a
**month-scoped Supabase read** (`user_checkin_history where checked_in_at >=
month_start`) with its own loading/error states. Normalize `checked_in_at` (UTC date)
to the user's **local** day using the same helper as A1 so the calendar and the saver
agree about which day was "lit." **Frozen/excused cells derive from streak history**
(`user_streak_excused_dates` + freeze burns), not only the net-new burn marker — else
pre-existing freeze burns render as "missed" gaps and break the §6 no-gap guardrail.
Read-only; no new writes.

### S4 — Freeze visibility + burn moment (P1)

- **Shield ring** = a **forward-looking overlay from freeze ownership**
  (`companion.protected`), NOT a backward-looking "was protected" state — freeze is a
  consumable bool with no persistent protected signal. ~2px emerald @55% composited
  on the medallion; quiet, not a badge.
- **Burn card (D4):** on next Home load after an auto-consumed freeze, a dismissible
  card leads with reunion: title "Welcome back" · body "Your {N}-day streak is
  intact." (optional secondary line: "A freeze held it while you were away.").
  Requires a **server-side, dismissal-tracked marker (D14)** — `last_freeze_burn_at`
  + a dismissed flag, written in/adjacent to `consume_streak_freeze` (NOT next to the
  client streak upsert, which can fail and lose it; NOT local SharedPrefs, which
  re-shows on cache-clear / second device). Fires exactly once across devices.
  **Latent bug to fix while here:** concurrent `markActiveToday` calls can double-call
  `consume_streak_freeze` → one gets `false` → falls through to EXPIRED, burning the
  streak the freeze should have saved. Guard the consume path (idempotent per local day).
- **Acquisition:** freeze visibly earnable in the daily-reward path. (Buy-path deferred.)

### S5 — Token wager experiment (P2)

"Stake N tokens on a 7-day streak, win 2N." Rides the token economy. Build only
after S1–S4 land. (First-week grace: **cut**, per D-review.)

---

## 6. Visual spec — state matrix

**Chain cells** — 36px cell, 9px radius, gold flame glyph ✦ where lit.

| State | Light (cream) | Dark (warm charcoal) | Screen-reader |
|---|---|---|---|
| lit | bg `#EAF1EC` · glyph gold `#C8985E` | bg `rgba(200,152,94,.14)` · glyph `#D9AE72` | "Reflected" |
| missed | 1px dashed `#DDD3C4`, no glyph | 1px dashed `#3A342C` | "Missed" |
| frozen | bg `#E4EEF0` · shield `#3E7F86` | bg `rgba(62,127,134,.18)` · `#6FB7BE` | "Freeze protected" |
| excused | bg `#F3EEE6` · soft dot `#B7AC99` (filled — reads "gently held", NOT a gap) | bg `rgba(255,255,255,.05)` · `#8C8478` | "Rest day — gently held" |
| today-pending | 2px emerald `#1B6B4A` ring | 2px emerald `#3E9A6E` ring | "Today — not yet reflected" |
| future | faint `#EFE8DC` (expanded grid only) | `rgba(255,255,255,.03)` | (not announced) |

**Milestone bar:** track `#EAF1EC` (light) / `rgba(255,255,255,.08)` (dark); fill
gold gradient `#D9AE72→#C8985E`; 6px h, 999 radius. **Loading:** dimmed track, no copy.
**Excused-run guard:** a run of excused days must never render as a visual gap/failure.

## 7. Responsive & accessibility

- **iPhone SE fold:** Name reveal partially visible above fold with lit streak +
  milestone (S2 acceptance). Chain is collapsed by default, so it costs one line.
- **Touch targets:** collapsed summary row ≥44px tap height; expanded grid cells
  36px inside a ≥44px hit area (the tap-to-expand model resolves the "44px month
  grid is huge" tension — the grid lives on its own surface, not the hero).
- **Contrast:** all functional text emerald/cream ≥4.5:1; gold used only as
  non-text accent. Dark-mode values specified per state (§6).
- **Screen readers:** lantern medallion gets a semantic label per state
  ("Lantern lit, day 12" / "Lantern waiting" / "Lantern resting, protected by a
  freeze"); chain cells announce per §6; the collapsed summary is a button
  ("12 days lit this month, opens calendar").
- **Reduced motion:** milestone bar fill + burn-card entrance respect
  `MediaQuery.disableAnimations`.

## 8. Instrumentation

New names in `analytics_event_names.dart`, emitted via the `onAnalyticsEvent`
static hook; segment by existing flag super-properties (one funnel):
`streak_notif_sent {segment, streak, hour}`, `streak_notif_opened {segment}`,
`streak_saver_converted`, `milestone_sliver_shown {next_tier, days_remaining}`,
`freeze_burn_ack_shown {streak}`, `chain_calendar_expanded`,
`streak_wager_started|won|lost`.

## 9. Rollout order

Reordered by eng review (D12 — client surfaces first; the shared-RPC notification
change ships LAST, most-tested):

1. **S2** merged hero line + relight framing (cheap client edit).
2. **S4** freeze burn card (server marker D14 + concurrent-consume guard) + shield overlay.
3. **S3-chain** collapsed summary + tap-expand grid (month server query + local-date normalization, D13).
4. **T3-verify** confirm milestone claims key on server `newly_claimed`, not the local set (~15 min).
5. **S1** unified streak-notification decision model (D11) — highest blast radius, ships last with full regression on daily/dua/weekly.
6. **S5** wager experiment (last).

## 10. NOT in scope (deferred, with rationale)

- **First-week grace** — cut; keep hard reset (mechanic purity).
- **Freeze token buy-path** — deferred; ship visibility first, measure comprehension.
- **2-days-out milestone push** — v1 is 1-day only; revisit for 90/180/365.
- **Inline chain grid** — rejected; collapsed summary protects the hero.
- **State-driven CTA label** — rejected; subtitle carries the frame, button stays stable.

## 11. What already exists (reuse, don't reinvent)

`CompanionMedallion` + `LanternPainter` (shield-ring supported), the `streakPill`
+ hero slot on `ProgressScreen`, `companion_state_mapper.dart` resolver,
`AppColors`/`AppTypography`, `AdjustedArabicDisplay`, the milestone Lottie overlay,
the rescue-sheet visual language, and `send-scheduled-notifications` +
`get_eligible_notification_users`. The chain calendar and the burn card are the
only genuinely new widgets.

## 12. Research basis

Freeze → +48% streak length past day 7; loss aversion takes over ~day 7
([Apptitude](https://apptitude.io/blog/how-duolingos-streak-mechanic-actually-works/)).
Evening saver ~7pm = highest-ROI reminder
([Trophy](https://trophy.so/blog/streak-reminder-emails)). Streak calendars → ~3.2×
consistency ([Trophy](https://trophy.so/blog/when-your-app-needs-streak-feature)).
Punitive streaks churn distressed users; compassion retains
([Holly Lau](https://hollylau.com/designing-with-compassion-rethinking-wellness-apps-beyond-streaks-and-checklists/),
[Smashing](https://www.smashingmagazine.com/2026/07/designing-distressed-users-mental-health-apps-ui/)).
Anticipation/status ladders + wager ([Duolingo Wiki](https://duolingo.fandom.com/wiki/Streak)).

## Approved Mockups

| Screen/Section | Mockup Path | Direction | Notes |
|---|---|---|---|
| Home hero (lit + unlit/relight) & chain + burn card | `~/.gstack/projects/SamieBelal-Sakina/designs/streak-retention-20260720/wireframe.html` | Hand-coded HTML wireframe in real tokens (PNG generator blocked on OpenAI org verification) | Merged streak line, collapsed chain to be applied per D1/D2; wireframe shows pre-consolidation layout for reference |

## 13. Test coverage & failure modes (eng review)

```
CODE / DATA PATHS                                     TEST TYPE / STATUS
[+] nextMilestone(streak) shared helper               [GAP] unit — thresholds, 365-max
[+] merged hero line state map (S2)                   [GAP] widget — each companion state, loading, SE-fold
[+] month_of_light query + UTC→local normalize (S3)   [GAP] unit + widget — no-gap guardrail
[+] unified decide(user) selection (S1)               [GAP] [→pgtap] saver|milestone|winback|none
[+] D8 east-of-UTC local-morning reflection           [GAP] [→pgtap] excluded from saver (regression)
[+] :00/:30 double-fire dedup (last_streak_family_*)  [GAP] [→pgtap] one decision per day
[+] freeze-burn server marker single-fire (D14)       [GAP] cache-clear + 2nd device don't re-show
[+] concurrent markActiveToday consume guard          [GAP] [CRITICAL regression] no double-consume→EXPIRED
[+] milestone claim idempotency (already shipped)     [VERIFY] grant keys on newly_claimed not local set
[+] shared RPC regression: daily/dua/weekly/reengage  [GAP] [→pgtap] unchanged after S1

COVERAGE: 0/10 planned paths have tests today — full suite to be written with the feature.
```

**Failure modes (new codepaths):**
- Concurrent `markActiveToday` double-consume → **EXPIRED** despite owned freeze. No test, no guard today, **silent** → **CRITICAL GAP** (fix in S4/D14).
- Shared notification RPC regression → daily/dua/weekly silently stop for all users. No kill-switch (per D12). Mitigate with the pgtap regression suite + ship-last ordering.
- `last_reflected_local` NULL after migration → saver stops until next reflection (fail-safe: no false push). Acceptable; document.
- Long excused run > 8/30d cap (`streaks_defense.sql:62`) → days past the cap render as "missed" gaps in the chain, breaking §6. **Documented limitation**, not fixable client-side.
- Local-only mode (no `userId`): freeze burn has no server trace → burn card + frozen cells unreconstructable. Blind spot; acceptable for anonymous sessions.

## Implementation Tasks
Reconciled with the eng review. Ship order = rollout §9 (client first, S1 last).

- [ ] **T1 (P1, human ~4h / CC ~40min)** — Home hero — merge pill+subtitle+milestone into one state-driven line; fold shield into medallion; 365-maxed + loading states
  - Surfaced by: Design Pass 1 + D2/D9. Files: `progress_screen.dart`, `companion_medallion.dart`. Verify: SE-fold; no pre-hydration flash; widget tests per state.
- [ ] **T2 (P1, human ~5h / CC ~45min)** — Freeze burn — server-side `last_freeze_burn_at` + dismissed marker (D14) + reunion-first card + **concurrent-consume guard**
  - Surfaced by: Arch A3 + outside-voice T5. Files: `streak_service.dart`, `consume_streak_freeze` migration, `progress_screen.dart`. Verify: single-fire across cache-clear/2nd device; **CRITICAL regression** no double-consume→EXPIRED.
- [ ] **T3 (P1, human ~1d / CC ~2h)** — Chain calendar — collapsed summary + tap-expand month grid; **month-scoped server query + shared UTC→local normalization**; frozen/excused from history (D13)
  - Surfaced by: Design Pass 2 + outside-voice chain. Files: new `month_of_light.dart`, `progress_screen.dart`, `checkin_history_service.dart` (month query). Verify: day-0 copy; frozen/excused run never a gap; calendar agrees with saver on "lit".
- [ ] **T4 (P3-verify, human ~15min)** — Milestone claims — confirm economy grants key on server `newly_claimed`, local set is optimization-only (already shipped, D10)
  - Surfaced by: Step 0. Files: `streak_service.dart:87-118`, `daily_loop_provider.dart:432`. Verify: cache-clear cannot re-grant.
- [ ] **T5 (P1, human ~1.5d / CC ~3h)** — Notifications — **unified streak-decision model** (D11): `last_reflected_local` col (A1/D8), one `last_streak_family_sent_at`+`kind`, decide() per user/day; ships LAST (D12)
  - Surfaced by: Arch A1/A2 + outside-voice P1×2. Files: `send-scheduled-notifications/index.ts`, new migration (col + RPC rewrite). Verify: pgtap — one decision/day, east-of-UTC excluded, no :00/:30 double-fire, **full regression on daily/dua/weekly/reengagement**.
- [ ] **T6 (P2, human ~2h / CC ~20min)** — Freeze visibility — shield forward-looking overlay + earnable in daily-reward path
  - Surfaced by: S4. Files: `lantern_painter.dart`, `companion_medallion.dart`, daily-reward path.
- [ ] **T7 (P3, human ~2h / CC ~20min)** — Instrumentation — §8 events; **define `streak_saver_converted` source** (reflected-after-saver join; today undefined)
  - Surfaced by: §8 + outside-voice P3. Files: `analytics_event_names.dart`.
- [ ] **T8 (P3, human ~15min)** — Cleanup — delete committed `lib/features/progress/screens/progress_screen.dart.bak`
  - Surfaced by: Code Quality C2. Verify: `git rm` the stale `.bak`.
- [ ] **T9 (P3, human ~1d / CC ~2h)** — Token wager experiment (S5) — after all above
  - Surfaced by: §12 research. Files: TBD.

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | unavailable (binary ENOENT) | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | clean | 8 issues, 1 critical gap; 2 scope reductions; 6 decisions |
| Design Review | `/plan-design-review` | UI/UX gaps | 1 | clean | score 5/10 → 9/10, 11 decisions |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

Eng review: Step 0 cut 2 phantom items (T3 already shipped; S1 reflected-today filter already exists). Adopted the unified streak-decision model (D11), server-side burn marker (D14), month-scoped chain query (D13), S1 ships last (D12). 1 critical gap flagged (concurrent `markActiveToday` double-consume). Outside voice = Claude subagent (Codex ENOENT); its notification-substrate findings were absorbed into D11–D14, not left as tension.

- **CROSS-MODEL:** single-model (Codex unavailable). Claude subagent and the primary review agreed on T3-already-shipped and the A1 local-date fix; no unresolved tension.
- **VERDICT:** DESIGN + ENG CLEARED — ready to implement. Build order per §9 (client surfaces first, unified notification model last with full regression).

NO UNRESOLVED DECISIONS
