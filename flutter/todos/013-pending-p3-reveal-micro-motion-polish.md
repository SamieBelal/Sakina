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

## Resources
- —
