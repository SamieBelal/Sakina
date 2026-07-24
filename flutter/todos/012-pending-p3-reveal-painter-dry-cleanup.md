---
status: pending
priority: p3
issue_id: "012"
tags: [code-review, simplicity, dry]
dependencies: ["006"]
---

# DRY cleanup: shared ray-fan helper, redundant getters, trimmed shouldRepaint

## Problem Statement
Three net-simpler cleanups that preserve visual output exactly. The biggest is that three painters re-implement the identical "rotating triangular ray fan" idiom.

## Findings
- `_LanternRaysPainter` (`:1156`), `_AuroraPainter` (`:1241`), and the shafts loop in `_BurstPainter` (`:1336`) all do `save→translate→rotate→for i {rotate; build vertical LinearGradient triangle; drawPath plus; restore}` (~15 lines each).
- `_tColor`/`_tBright`/`_tGlow` getters (`:74-76`) are pure indirection over `spec.palette.{color,bright,glow}`.
- Every painter's `shouldRepaint` compares `bright`/`glow`/`color` — constant for a reveal's lifetime (from `spec.palette`), so those comparisons are dead branches.

## Proposed Solutions
1. Extract a free `_paintRayFan(canvas, center, {rays, baseRotation, lenFor, halfWidthFor, shaderFor, mask})` helper; the three painters supply only per-ray closures. Removes ~30 lines. Visual identical. Effort: Small.
2. Drop the `_tColor`/`_tBright`/`_tGlow` getters; use `spec.palette` (or one local `p`). Effort: Small.
3. Trim constant-color comparisons from each `shouldRepaint`. Effort: Small.

## Recommended Action
_(blank — triage)_

## Technical Details
- `lib/features/daily/widgets/card_reveal_overlay.dart` (or the extracted `reveal/` painters from #006).

## Acceptance Criteria
- [ ] One ray-fan helper used by all three ray painters; visual output unchanged.
- [ ] Redundant getters removed; `shouldRepaint` bodies compare only animated fields.

## Work Log
- 2026-07-23: Found via /code-review (code-simplicity P1.1, P1.2, P2.1).
- 2026-07-23: DONE. (1) Extracted `paintRayFan(canvas, center, {rays, baseRotation, lenFor, halfWidthFor, shaderFor, maskFor})` into `reveal/reveal_geometry.dart`; LanternRays, Aurora, and Burst-shafts now call it with per-ray closures — visual output identical (verified loop bodies match: same rotate/translate/triangle-path/BlendMode.plus; lantern keeps its trailing centre-glow circle, burst keeps flash+rings, both drawn in the same coord space as before). (2) Dropped `_tColor/_tBright/_tGlow` getters — overlay uses `spec.palette.{color,bright,glow}` directly. (3) Trimmed constant-color comparisons (`bright`/`glow`/`color`) from every painter's `shouldRepaint`; they only compare animated fields now. `flutter analyze` clean; daily + collection tests green.

## Resources
- Best done alongside #006 (painter extraction).
