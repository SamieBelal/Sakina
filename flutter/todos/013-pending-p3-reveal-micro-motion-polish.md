---
status: pending
priority: p3
issue_id: "013"
tags: [code-review, design, animation, polish, impeccable]
dependencies: []
---

# Micro motion polish: caption cadence, badge sheen, spark stagger, idle entrance, spin count

## Problem Statement
A batch of small, high-taste refinements that individually are minor but together sharpen the piece.

## Findings
- **Caption stagger too tight** (`:523-525`): badge `_seg(0.85,0.92)`, name `0.89–0.96`, meaning `0.93–1.0` — ~0.03 overlap = near-simultaneous, worse on short tiers. Widen gaps (badge 0.83 / name 0.88 / meaning 0.94, ~0.06 each) or use a fixed wall-clock stagger floor (~120ms/line).
- **Badge shimmer unsynced** (`:527` `shimmer = _ambient.value`): the sheen sweep runs on the free ambient loop, so it randomly misses the badge entrance. Fire one deterministic sweep off `_seg(0.85,0.95)` on entrance, then settle into ambient.
- **Sparks all launch together** (`_SparkPainter:1418`): uniform start → one expanding shell. Offset `progress` by `s.seed*0.08` for a spray, not a ring.
- **Idle hint has no entrance** (`_buildHint` `:604`): pops in with the route. Add a 300–400ms fade+rise on the hint + unlit lantern.
- **Emerald 3× spin borderline arcade** (`reveal_spec.dart:106`): consider 2.5 turns (lands facing front) for a more elegant, less loot-box feel; protect final-half-turn readability (pair with #004 quint easing).

## Proposed Solutions
1. Apply the five tweaks above; each is a small localized change. Effort: Small each. Visual-QA per tier.

## Recommended Action
_(blank — triage)_

## Technical Details
- `lib/features/daily/widgets/card_reveal_overlay.dart` (`_buildCaption`, `_ShimmerText` usage, `_SparkPainter`, `_buildHint`), `reveal_spec.dart` (spinTurns).

## Acceptance Criteria
- [ ] Caption reads badge → name → meaning as a cadence, even on Bronze.
- [ ] Badge sheen lands on the badge entrance.
- [ ] Sparks spray (staggered), idle hint fades in, Emerald spin count re-evaluated.

## Work Log
- 2026-07-23: Found via /code-review (impeccable animation pass P2-2, P3-1/2/3/4).
- 2026-07-23: Applied on `feat/reveal-everywhere` (4 of 5 items; spin-count SKIPPED):
  - Caption cadence widened (`_buildCaption`): badge `seg(t, kCaptionIn, 0.90)`,
    name `seg(t, 0.88, 0.95)`, meaning `seg(t, 0.93, 1.0)` — clear ~0.07 gaps.
    `kCaptionIn` lowered 0.85 → 0.83 (it gates `t > kCaptionIn` in build() AND is
    the badge stagger start) so the badge isn't clipped. No test asserts
    kCaptionIn's value; `reveal_motion_test.dart:96` uses 0.89 as a t input,
    unaffected.
  - One-shot badge sheen: `_ShimmerText.phase` on the tier badge now driven by
    `seg(t, 0.85, 1.0)` (one deterministic 0→1 left→right sweep as the badge
    rises) instead of the free-running `_ambient.value`.
  - Spark launch stagger (`SparkPainter.paint`): indexed loop, per-spark
    `delay = (i % 8) * 0.015`, `p = ((progress - delay) * s.speed).clamp(...)` —
    a subtle spray, not a ring. (Spark has no seed field, so delay is
    index-derived.)
  - Idle hint entrance (`_buildHint`): wrapped in a `TweenAnimationBuilder<double>`
    (0→1 over 350ms, easeOut) driving opacity + a 12px rise; existing breathing
    preserved.
  - SKIPPED (per batch instructions): Emerald 3× → 2.5× spin. `spinTurns` in
    reveal_spec.dart is unchanged — Emerald's spin feel is user-approved.
  - flutter analyze: 0 errors. flutter test test/features/daily/: 67 passed.

## Resources
- —
