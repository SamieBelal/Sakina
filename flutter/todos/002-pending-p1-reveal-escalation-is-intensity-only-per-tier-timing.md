---
status: pending
priority: p1
issue_id: "002"
tags: [code-review, design, animation, motion, impeccable]
dependencies: []
---

# Tier escalation is intensity-only; give each tier its own timing + signature gesture

## Problem Statement
All four tiers share ONE normalized `_seg(t,a,b)` timeline; escalation is delivered almost entirely through intensity multipliers, not timing or distinct gestures. Consequences: (a) the anticipation/ignite phase scales linearly with total duration, so Bronze's ignite is starved (~960ms — below the ~600–800ms floor to read a build, and it feels *clipped* not *quick*) while Emerald's ~2800ms ignite is near dragging; (b) Bronze and Silver are hard to tell apart — the only strong differentiator is "does it flip once." The ladder reads as "one reveal at four brightnesses," not four kinds of moment. This is the headline design finding for the user's "polish all tiers, keep Emerald nicest" ask.

## Findings
- `reveal_spec.dart` durations 2400/3600/5000/7000ms × fixed windows in `card_reveal_overlay.dart:368` (lantern↔card swap `t=0.46`), `:391` (swell 0–0.30), `:466` (spin 0.49–0.86). Ignite phase `t∈[0,~0.40]` → Bronze 960ms vs Emerald 2800ms, linear.
- Bronze spec (spin 0, aurora 0, foil 0, shafts 0, **shineSweep false**) vs Silver (spin 1, aurora 0.25, foil 0, shafts 0): aurora 0.25 is barely perceptible; adjacent tiers too close.

## Proposed Solutions
1. **Per-tier phase proportions (recommended).** Add `igniteBias`/`settleBias` (or a phase-remap curve) to `RevealSpec`; remap `t` before it hits `_seg` windows so lower tiers spend proportionally less on ignite/rest and more on burst+land, while Emerald spends more on ignite (luxurious build). Minimum viable: Bronze compresses [0,0.40]→[0,0.30]. Effort: Medium.
2. **Signature gesture per tier.** Bronze = restraint but crisp: turn `shineSweep` ON for Bronze (its one confident flourish). Silver = the single flip is the hero (commit aurora ~0.4 or drop to 0). Gold = foil+shafts arrive (already). Emerald = halo + full foil + forge + sustained aurora. Effort: Small (spec tweaks) + Medium (validation).
3. **Raise Bronze floor only (cheap partial).** Bump Bronze to ~2.8s and shorten its ignite fraction. Doesn't fix Bronze/Silver similarity. Effort: Small.

## Recommended Action
_(blank — triage)_

## Technical Details
- `lib/features/daily/models/reveal_spec.dart` (new bias fields + Bronze `shineSweep: true`), `lib/features/daily/widgets/card_reveal_overlay.dart` (t-remap before `_seg`).
- Requires on-device visual QA per tier via Dev Tools → Reveal Previews.

## Acceptance Criteria
- [ ] Bronze reads as *deliberately quick/calm*, not clipped; has one confident shine.
- [ ] Bronze vs Silver are distinguishable at a glance (distinct gesture, not just brightness).
- [ ] Emerald unchanged/still the richest.
- [ ] Each tier's ignite has a readable anticipation beat regardless of total duration.

## Work Log
- 2026-07-23: Found via /code-review (impeccable animation pass P1-1, P2-1).
- 2026-07-23: Implemented Solution 1 (per-tier burst point) + part of Solution 2 (Bronze signature gesture, see #004 log). Added `RevealSpec.burstAt` (Bronze 0.34, Silver 0.42, Gold 0.46, Emerald 0.46 — Emerald unchanged). All swap-pivoted timeline windows in `card_reveal_overlay.dart` (lantern rays fade, burst rings/flash/shafts, sparks, lantern flare, vessel↔card swap gate) and in `revealCardMotion` (card `appear` `[burstAt, burstAt+0.12]`, spin start `burstAt+0.03`) are now RELATIVE to `spec.burstAt`. Verified Emerald's numbers come out equal to the pre-change literals. Lower tiers now ignite earlier so more of their short runtime lands on burst+land+rest. Relaxed one over-fit boundary assertion in `reveal_motion_test.dart` (exact appear value at the window edge, now float-rounded). `flutter analyze` clean; `flutter test test/features/daily/` green (branch `feat/tiered-card-reveal`).

## Resources
- impeccable:critique / impeccable:animate lenses. Reference: Clash Royale / CS:GO case reveals for escalation-by-timing.
