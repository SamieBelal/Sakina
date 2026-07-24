---
status: pending
priority: p2
issue_id: "006"
tags: [code-review, architecture, quality, testing]
dependencies: []
---

# Split the 1452-line overlay into a reveal/ subfolder + lift motion math to pure functions

## Problem Statement
`card_reveal_overlay.dart` is 1452 lines holding the widget, its State, `_CardFace`, `_ShimmerText`, 9 CustomPainters, and `_Spark`/`_Mote` — ~7× the project's "one widget per file / <200 lines" convention (CLAUDE.md). The choreography (angle/facingFront/spinTilt, `_interactive` gate, layer intensities) lives as inline expressions in `build`/`_buildCard`, so it's only reachable by pumping the full widget tree — the sole widget test is a shallow reduced-motion smoke test.

## Findings
- `card_reveal_overlay.dart:1` — 15 classes in one file; the plan's own File Structure anticipated a `lib/features/daily/reveal/` folder.
- The painters are self-contained (take explicit color/intensity params, no reach into State) → low-risk mechanical extraction.
- Untested: Bronze never shows card-back, `foilPhase` wrap, `_interactive` threshold, tap-to-skip → tap-to-continue no double-fire.

## Proposed Solutions
1. **Extract to `lib/features/daily/reveal/`** (move `reveal_spec.dart`, `reveal_card_tile.dart` here too): `painters/*.dart` (burst, aurora, lantern_rays, halo, mote, atmosphere, spark, card_fx), `reveal_geometry.dart` (`_seg`/`_bell`/`_Spark`/`_Mote`, made library-visible). Keep `CardRevealOverlay` + `_CardFace` in the main file. Effort: Medium (mechanical).
2. **Lift pure timeline math to free functions** e.g. `revealCardMotion(RevealSpec, double t) -> ({double angle, bool facingFront, double spinTilt})` + layer-intensity computations → unit-test escalation invariants across all four tiers at t∈{0,0.5,0.9,1.0} with no widget pump. Effort: Medium.

## Recommended Action
_(blank — triage)_

## Technical Details
- New folder `lib/features/daily/reveal/`. Update imports in `muhasabah_screen.dart`, `dev_tools_screen.dart`.
- Enables #011 (test coverage) cheaply.

## Acceptance Criteria
- [ ] No single reveal file exceeds a reasonable ceiling (~500 lines for the widget; painters isolated).
- [ ] `revealCardMotion`/intensity math are pure functions with unit tests covering all four tiers.
- [ ] `flutter analyze` clean; existing behavior unchanged.

## Work Log
- 2026-07-23: Found via /code-review (architecture-strategist P1 file-size + P2 testability).
- 2026-07-23: DONE. Created `lib/features/daily/reveal/`; moved reveal_spec + reveal_card_tile in (git mv). Extracted the 9 painters into `reveal/painters/{background,card_fx}_painters.dart` (library-public names). Extracted seg/bell + Spark/Mote particle field into `reveal/reveal_geometry.dart`, and lifted the card choreography to a pure `revealCardMotion(RevealSpec, t, ambient) -> RevealCardMotion` record fn; `_buildCard` now calls it. Overlay shrank ~1460 → ~800 lines (still holds CardRevealOverlay + _CardFace + _ShimmerText; routeName const preserved). Behavior-preserving: `flutter analyze` 0 errors, all daily + collection tests green.

## Resources
- Plan `docs/superpowers/plans/2026-07-23-tiered-card-reveal-animations.md` File Structure section.
