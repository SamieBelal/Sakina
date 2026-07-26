# Lantern Cosmetics — Skins & Backdrops (Design Spec)

**Date:** 2026-07-25
**Status:** Design approved (brainstorm); spike validated. Pending user spec review → implementation plan.
**Author:** Ibrahim + Claude

## 1. Summary

Add a two-axis cosmetic system for the lantern companion:

- **Lantern skins** — swappable material/geometry variants of the code-drawn `LanternPainter`.
- **Backdrops** — a code-drawn scene behind the lantern on a new full-screen **Companion stage**.

Both are **pure `CustomPainter` parameters** (~0 KB assets), so they animate live in-app and (skins only) export to the iOS widget as static PNGs. Monetized via an **earn-first model with subscriber perks**: everyone earns a cosmetic currency (**Noor**) to unlock any catalog item; premium adds a rotating monthly-exclusive skin, guaranteed seasonal skins, 2× Noor, and early access. Specific skins are also buyable outright with real money (à-la-carte, named IAP). **No gacha / loot boxes ever** (Shariah: maysir/gharar) — every unlock is named and direct.

### Why this shape (from research + spike)

- **Finch soft-paywall** (single-avatar self-care app, ~$30M ARR) is the closest analog: earned currency, cosmetics never fully paywalled, subscription widens access. Protects the sub and the warm brand.
- **Duolingo dead-end economy** is the risk to avoid (thin catalog → currency feels pointless). Mitigated by **two collectible axes** (skin × backdrop = combinatorial looks) + rotation + seasonal drops.
- **Spike proved quality end-to-end** — recolor skins, sculpted skins, and composed skin+backdrop stages all render premium (see `docs/superpowers/specs/skin-previews/`).

## 2. Prototype artifacts (already built, non-breaking)

These exist in-tree as the validated spike. All additive; production rendering is byte-identical when no skin/backdrop is supplied.

- `lib/features/streaks/models/lantern_skin.dart` — `LanternSkin` (palette) + `LanternForm` (geometry/ornament: `DomeShape`, `FinialType`, arched window, lattice, tassel). 6 recolor skins + 3 sculpted heroes. `classicGold` == the original hardcoded palette.
- `lib/features/streaks/widgets/lantern_painter.dart` — parameterized by `skin`; `LanternPainter()` with no `skin` renders as before.
- `lib/features/streaks/models/backdrop.dart` + `widgets/backdrop_painter.dart` — `Backdrop` + `BackdropPainter` (themes: `laylatNight`, `emeraldSanctuary`).
- `test/widgets/gen_skin_showcase_test.dart`, `test/widgets/gen_stage_spike_test.dart` — render harnesses → preview PNGs.

## 3. Economy & earning

### Currency: Noor (earn-only, never sold)

| Source | Grant (indicative, to tune) |
|---|---|
| Daily muḥāsabah completion | +10 |
| Streak milestones (7/14/30/60/100…) | +40 / +75 / +150 / … |
| Achievements / quests / first-time actions | one-off |
| **Premium multiplier** | **~2×** all earning |

Prices tuned so a recolor skin ≈ **1–2 weeks** of daily use (goal-gradient pull without grind). Sculpted heroes cost more Noor **or** are bought outright via IAP.

### Acquisition paths (never fully paywalled)

1. **Save Noor → buy any recolor skin** (everyday loop).
2. **Milestone unlocks** — specific skins awarded free at streak milestones (the streak-coupling; strongest retention lever). Visible-but-locked in the wardrobe ("Unlock at a 30-day streak") to drive motivation.
3. **À-la-carte IAP** — buy a specific named skin outright with real money.
4. **Sculpted heroes** — IAP **or** a high Noor price (aspirational grind).

### Premium subscriber perks (protect the sub)

- **Monthly exclusive skin** (rotates; kept forever, even after cancel).
- **All seasonal skins auto-granted** (Ramadan/Eid) while subscribed.
- **2× Noor** earning + **early access** to new drops.
- One **subscriber-only backdrop**.

### Guardrails

- **Cosmetics are named, direct purchases only.** No cosmetic currency packs, no random cosmetic draws. Every cosmetic buy shows the exact item + price. Noor is **never** sold.
- **Shariah boundary (maintainer ruling, 2026-07-25).** The acceptable line is *guaranteed-beneficial-outcome*, not *no-randomness*. The existing purchasable-token → 25-token `discoverName` → random-but-guaranteed-card flow is considered **acceptable**: the user always receives a beneficial card, there is no wager where they can pay and receive nothing (no maysir loss leg). This supersedes the earlier draft invariant that framed any real-money→random path as prohibited. Cosmetics still keep the stricter named/direct model. A formal scholarly ruling may be sought later but is **not** a blocker. (Raised by the CEO-review outside voice; ruled acceptable by the maintainer.)
- **Premium must never reach `GatingService.reserveBypass`** — respect the existing short-circuit.

## 4. Data model & backend

All economic state is **server-authoritative**, reusing the `card_collection` list-section pattern + the freemium-guard triggers. Flutter never writes balances/ownership directly.

### New tables

- **`user_cosmetics`** — inventory. `(user_id, item_type, item_id, acquired_via, acquired_at)`, PK `(user_id, item_type, item_id)`.
  - `item_type ∈ {lantern_skin, backdrop}`
  - `acquired_via ∈ {default, noor, iap, milestone, seasonal, premium}`
- **`cosmetic_catalog`** — economic source of truth (never trust client price): `(item_type, item_id, noor_price nullable, iap_product_id nullable, is_premium_exclusive bool, is_seasonal bool, season_key nullable, drop_month nullable, sort int, active bool)`. The **visual** definition stays client-side (`LanternSkin`/`Backdrop` keyed by `item_id`); this table governs price/availability/gating so sales/seasonal toggles need no app release.

### New `user_profiles` columns

- `noor_balance int default 0`, `noor_total_earned int default 0`, `noor_total_spent int default 0`
- `equipped_lantern_skin text default 'classic_gold'`
- `equipped_backdrop text default 'default'`

### New SECURITY DEFINER RPCs (only mutation path)

- `award_noor(amount, reason)` — called by daily/milestone/quest hooks.
- `unlock_cosmetic(item_type, item_id)` — reads price from `cosmetic_catalog`, atomically checks + deducts Noor, inserts inventory (`ON CONFLICT DO NOTHING`). Rejects if insufficient or item inactive.
- `equip_cosmetic(item_type, item_id)` — verifies ownership, sets the equipped column.
- `grant_cosmetic_iap(item_id, …)` — grants after a RevenueCat receipt check; reuses the `ConsumableGrantsService` dedup + orphan-recovery approach. **Skins are non-consumable IAP products.**
- Premium grants (monthly-exclusive + seasonal) — granted on sync when premium is active and `drop_month` / active `islamic_occasions` window matches; `ON CONFLICT DO NOTHING`.

### Guard / RLS

- Extend freemium-guard triggers so `noor_balance` and `user_cosmetics` are writable **only** by these RPCs.
- RLS: user may `SELECT` own rows; direct `INSERT/UPDATE` blocked. Same posture as token/entitlement columns.

### Sync

Extend `sync_all_user_data()` to return three new sections, hydrated in `user_data_batch_sync_service.dart`:

- `noor` — balance / total_earned / total_spent
- `cosmetics` — owned list `[{item_type, item_id, acquired_via}]`
- `equipped` — `{lantern_skin, backdrop}`

## 5. Rendering & assets

### Lantern skins

- `LanternSkin` = palette (metal gradient, highlight, glow, ember, glass, dusty) + `LanternForm` (dome, finial, arched window, lattice, tassel), fed into the one `LanternPainter`. ~0 KB.
- **Arched-window fix (do in P0):** make the glass window itself arch-topped rather than the current additive cap (the one rough edge in the prototype). Touches the panel clip path + the code that references `panel` as an `RRect` — refactor those call sites.
- `equip_cosmetic` resolves which `LanternSkin` the medallion renders.

### Backdrops

- New `Backdrop` descriptor + `BackdropPainter` (layered: sky gradient → sky khatam wash (≤5% opacity, per the design rule) → stars → moon+halo → backlit skyline → warm floor glow → vignette). ~0 KB. Renders **behind** `CompanionMedallion` on the Companion stage + wardrobe preview **only** — never Home surfaces or the widget.
- **Spike learnings to apply:**
  - **Composition tuning:** avoid lantern/skyline overlap — lower/shrink the central dome or lift the lantern so it stands in a gap. Parameterize the lantern anchor per backdrop.
  - **Default pairing guidance:** contrast varies (brass-on-emerald pops; jade-on-emerald is tonal). Shop should suggest flattering pairings; both remain user-selectable.

### iOS widget (the bundle-size constraint)

- Widget can't run the painter → loads a pre-rendered PNG per **skin × brightness state** (7 states). Backdrops excluded (widget stays the cream container + lantern skin), which bounds the matrix.
- **Export widget frames at ~360px + PNG-crush** (in-app avatar stays full-res since it's code-drawn). ~10 skins × 7 ≈ 70 PNGs ≈ ~5–7 MB.
  - **Fallback if the built bundle is too heavy:** cap widget-enabled skins to a curated subset; others fall back to Classic on the widget only.
- Frame generator loops skins; Swift `TimelineProvider` reads equipped skin from the App-Group payload → loads `companion_<skin>_<state>.png`.

## 6. UI

### Companion screen (new stage)

- Reached by tapping the Home medallion (Home keeps today's small medallion unchanged).
- Composes: `BackdropPainter` (equipped backdrop) → `CompanionMedallion` (equipped skin, live-animated) → streak/status line → **Customize** button.
- A new daily reason to visit ("go see your lantern").

### Wardrobe (browse + preview + acquire)

- Opened from Customize. **Two tabs: Lanterns · Backdrops.** Grid of tiles (reuse `collection_screen` `_GridEntry` + card teaser-tile patterns) showing owned / equipped / locked.
- **Tap tile → live preview on the stage** + the right action: **Equip** (owned) · **Unlock — N Noor** (affordable) · **Get — $X.XX** (IAP) · or a **locked teaser** ("Unlock at 30-day streak" / "Ramadan · Premium" / "This month's Premium skin").
- **Noor balance** in header; premium/seasonal/milestone badges.
- **Buy-then-equip** (no equip-on-purchase surprise); saved via `equipped_*` columns.

### Store integration

- Real-money cosmetic buys live **inside the Wardrobe** (preview + purchase together). The existing Store gets a small **cross-link banner** ("Personalize your lantern →"); cosmetics do not clutter the tokens/scrolls tabs.

### Reuse tally

`CompanionMedallion` (as-is), `collection_screen` grid/teaser patterns, `PurchaseService` for IAP, analytics `onAnalyticsEvent` hook. New: `CompanionScreen`, `WardrobeScreen` (+ preview sheet), `BackdropPainter`.

## 7. Analytics

Via the `onAnalyticsEvent` hook; constants in `analytics_event_names.dart` (per `docs/analytics/funnel-flags-and-querying.md`).

- Events: `companion_screen_opened`, `wardrobe_opened{tab}`, `cosmetic_previewed{item_type,item_id}`, `cosmetic_equipped{…}`, `noor_earned{amount,reason}`, `cosmetic_unlocked{via:noor}`, `cosmetic_iap_purchased{item_id,price}`, `milestone_skin_unlocked`, `premium_exclusive_granted`, `seasonal_granted`.
- User super-props: `cosmetics_owned_count`, `equipped_lantern_skin`.

## 8. Testing

- **pgTAP:** `unlock_cosmetic` price read + atomic Noor deduct + `ON CONFLICT` idempotency; guard triggers **reject** direct client writes; `equip_cosmetic` ownership check.
- **Service tests:** Noor earn/spend, equip, IAP grant dedup via orphan-recovery path.
- **Widget tests:** Companion screen renders; wardrobe owned/locked/premium states; preview.
- **Golden set:** extend the showcase harness so every skin × key state is a committed golden (visual-regression guard).
- Pre-release tripwire (`check_no_fake_strings.sh`) unaffected.

## 9. Phasing (ship the free loop first, layer money after)

- **P0** Productionize skin param (spike done) + arched-window fix + finalize skin catalog + widget frame regen at 360px.
- **P1** DB (tables/columns/RPCs/guards) + sync extension + Noor earning hooks.
- **P2** Companion screen + Wardrobe + equip + Noor-unlock → **end-to-end free loop, no money.**
- **P3** Backdrops (painter + 2nd axis) + composition tuning.
- **P4** IAP (à-la-carte non-consumable) + premium perks (monthly exclusive, seasonal auto-grant, 2× Noor) + Store cross-link.
- **P5** Milestone unlocks + seasonal automation + analytics polish.

## 10. Risks & mitigations

| Risk | Mitigation |
|---|---|
| Widget bundle size | 360px + crush; subset fallback |
| Dead-end economy | 2 axes + rotation + seasonal + roadmap |
| Backdrop clash with existing UI | Contained to Companion stage + preview only |
| Premium hitting `reserveBypass` | Respect existing short-circuit |
| Shariah (gambling) | Named/direct unlocks only; no gacha; no real-money→random |
| Composition overlap (spike) | Per-backdrop lantern anchor tuning |

## 11. Out of scope (v1)

- Backdrops on the iOS widget (in-app only).
- More than two collectible axes.
- Trading/gifting cosmetics.
- User-authored/custom skins.

## 12. Accepted expansions (CEO review 2026-07-25, SELECTIVE EXPANSION)

Scope held at the full two-axis build; three expansions accepted (share hook answers the review's "does nothing for the funnel" premise concern):

- **E1 — Share-your-lantern growth hook.** A Share action on the Companion screen exports the composed stage (skin + backdrop + streak) as an image/story card + referral link, via the existing share-export + referral systems. Turns a retention feature into an acquisition loop.
- **E2 — Unlock reveal reuses `CardRevealOverlay`.** Skin/backdrop unlocks play the just-shipped tiered reveal for a real "earned it" moment.
- **E3 — Name your lantern.** One optional profile field (profanity/length/unicode guard); personalizes the share card. Endowment lever.

## 13. Review-mandated corrections (CEO review 2026-07-25)

Full scope held, so these correctness gaps (Claude review + Codex outside voice) are **required build tasks**, not optional:

1. **`award_noor` server-authoritative + ledger.** Amount is **server-derived from `reason`**, never client-supplied. Add a `noor_grants` ledger keyed `(user_id, reason_key)` with `ON CONFLICT DO NOTHING` → milestone/daily grants idempotent, retry-safe, auditable, reversible. Kills streak-rebuild farming.
2. **`unlock_cosmetic` transactional.** Conditional balance update / `SELECT … FOR UPDATE` so deduct + insert are atomic under concurrency; `ON CONFLICT` alone is not idempotent if deduct precedes insert.
3. **Fix the exploitable `claim_streak_milestone(p_day)`** (`20260719000000_streaks_defense.sql`) — it verifies neither that the day is recognized nor reached; any authed user can claim any day. **Prerequisite** before hanging Noor/skins on milestones.
4. **Non-consumable IAP infra must be built, not reused.** `ConsumableGrantsService` dedups in SharedPreferences (not cross-device); the RevenueCat webhook (`revenuecat-webhook/handler.ts`) has **no** non-consumable/non-renewing grant path — no refund, restore, original-transaction, environment, or product→item verification. This is net-new work.
5. **Supersede the monetization ADR.** À-la-carte skins reintroduce the `NON_RENEWING_PURCHASE` path `docs/decisions/monetization-model.md` deleted. **RESOLVED 2026-07-25 — maintainer chose to keep direct skin IAP; superseding ADR written: [`docs/decisions/2026-07-25-cosmetics-non-consumable-iap.md`](../../decisions/2026-07-25-cosmetics-non-consumable-iap.md)** (clarifies premium-entitlement is still subscription-only; sanctions non-consumable *cosmetic* IAP; skin refunds revoke a cosmetic entitlement, not consumables). Must land before shipping IAP to users.
6. **One server-authoritative `premium` definition.** Client counts subs/trials/gifts/referrals; server helper counts subs only. **RULED 2026-07-25:** premium-exclusive (subscriber-perk) skins are equippable **only while a premium source is active** and are **NEVER converted to permanent ownership** — trial/gift/referral users do not keep the monthly exclusive after premium lapses (equipped slot falls back to an owned default). À-la-carte purchases (distinct) are permanent. Enforce server-side.
7. **Entitlement-period reconciliation for grants.** "Grant on sync while active" misses subscribers who don't open during the month/window. Reconcile over the entitlement period, not current-state-at-launch.
8. **Catalog fields.** `cosmetic_catalog` needs milestone_day, early-access/general-release timestamps, availability intervals, `min_app_version`, platform-specific product ids, and grant-retention policy; plus explicit RLS/read access + client fetch path.
9. **Widget plumbing before widget work.** Add a skin field to the App-Group payload (`widget_data_service.dart`), write it on sync, replace the hardcoded `companion_<brightness>.png` lookup (`SakinaCompanionWidget.swift`), and define immediate refresh on equip. Only skins whose PNGs are bundled in the installed build are widget-eligible (`min_app_version`).
10. **Backdrop performance test.** Full-screen animated backdrop repaints gradients + 64 stars + blurs + blend modes every `pulse`. Add low-end device frame-time + battery measurement, `RepaintBoundary`, and raster-cache/static-layer separation (animate only what must move).
11. **Real golden coverage.** The spike writes 4 cherry-picked lit PNGs. Replace with goldens over skin × backdrop × representative states.
12. **Fix `Backdrop.none`** — it currently maps to `emeraldSanctuary` (renders the emerald scene); make it a genuinely plain surface.

13. **[Lane B client gating — from Lane A code review]** `award_noor('milestone:N', …)` is idempotent but does NOT itself verify the milestone was reached — that authority lives in `claim_streak_milestone(N)`. The client MUST call `award_noor('milestone:N')` ONLY after a successful `claim_streak_milestone(N)`, with a server-shaped `reason_key` (e.g. `milestone:N`), never a client-arbitrary one. Consider folding the Noor grant directly into `claim_streak_milestone` in a later migration so it cannot be invoked independently. (Lane A hardening already gated `unlock_cosmetic` on availability + premium-exclusive, and added amount/price CHECKs — migration `20260726000400`.)

**Separate, pre-existing (NOT this feature's scope):**
- **Shariah boundary** ruled acceptable by the maintainer (see §3) — documented, no fix required.
- **Guard is UPDATE-only** (accepted posture, mirrors `guard_user_profiles_freemium_fields`) — safe because the profile row is created once server-side; a client INSERT never wins post-signup.

## 15. Implementation parallelization

Five workstreams; A + C launch in parallel, B follows A's RPC contracts, D/E integrate last.

| Lane | Modules | Depends on |
|------|---------|-----------|
| A — Backend/economy | `supabase/migrations`, `supabase/tests`, `supabase/functions` (tables, RPCs, guards, catalog, milestone fix, IAP webhook, sync sections) | — |
| B — Client services | `lib/services` (premium unification, Noor/cosmetics services, IAP grant, sync hydration) | A (RPC contracts) |
| C — Render | `lib/features/streaks/widgets` (skin/backdrop painters, arched-window fix, backdrop perf) | — |
| D — UI | `lib/features/streaks/screens` (Companion screen, wardrobe, preview, share, naming) | B + C |
| E — Widget | `ios/SakinaWidget`, `widget_data_service.dart` (skin payload, Swift lookup, frame gen) | C (PNGs) + B (equip field) |

Execution: **Launch A + C in parallel worktrees.** Then B (after A). Then D and E in parallel (after B + C). Conflict flag: B and E both read the equip contract from A — coordinate the payload/schema shape once in A before splitting.

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 1 | issues_open | SELECTIVE EXPANSION; 3 expansions accepted; 12 correctness gaps mandated |
| Outside Voice (Codex) | auto | Independent 2nd opinion | 1 | issues_found | 16 findings; 5 net-new (pre-existing Shariah flow, ADR reversal, non-existent IAP infra, exploitable milestone RPC, untested backdrop perf) |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | issues_open | No new arch findings; §13 hardening confirmed; 0/20 test coverage (new feature), 6 critical economy-integrity tests required |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | — | recommended before wardrobe build |

- **CODEX:** ran in the CEO review on this exact artifact (<30 min prior); same-artifact re-run deduped in eng review. 5 grounded findings folded into §13.
- **CROSS-MODEL:** strong agreement — both reviewers flagged strategic miscalibration (cohort barely exists per retention data). Maintainer held full scope with the data on the table (informed decision).
- **VERDICT:** CEO + ENG reviewed. Full scope held; §13 correctness gaps + the pgTAP economy-integrity suite (6 critical) are mandatory build tasks. Architecture confirmed (no rework). **Ready to implement**; design review recommended (optional, not a gate) for the wardrobe/Companion screen.

NO UNRESOLVED DECISIONS

## 14. Reversibility & rollout posture

- **Reversibility 4/5** — feature-flagged (like `onboarding_trim_enabled`), additive tables/columns.
- **Rollout order:** migrate (tables/columns/RPCs/guards) → backfill (existing users get `classic_gold`/`default` equipped, `noor_balance` 0) → deploy client behind the flag. Equip columns default so old clients ignore them. Zero-downtime.
- **Observability (add):** Noor mint/burn rate, insufficient-funds/negative-balance attempts, unlock/IAP-grant failure counts, and a farming alert on anomalous Noor mint.
