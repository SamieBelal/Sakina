---
status: pending
priority: p1
issue_id: "001"
tags: [code-review, performance, animation, battery]
dependencies: []
---

# Reveal repaints the entire FX stack forever at rest (device battery/GPU drain)

## Problem Statement
`CardRevealOverlay` drives every layer off one `AnimatedBuilder(animation: Listenable.merge([_reveal, _ambient]))`, and `_ambient` is `..repeat()` for the widget's whole life. The overlay is a pushed full-screen route that stays mounted after the card settles (dismissed only on the "Tap to continue" tap). So after the reveal is visually "done," Atmosphere + Aurora (floored, never 0 for Emerald) + Halo + Motes + the foil-bearing CardFace all keep repainting full-screen blurred/additive fills at 60–120fps indefinitely. This is a real on-device battery/thermal cost (NOT just a simulator artifact) and is the direct cause of "lag while the card just sits there."

## Findings
- `card_reveal_overlay.dart:97-100` — `_ambient` started with `..repeat()` (8s loop), unconditionally.
- `card_reveal_overlay.dart:253-254` — single top-level `AnimatedBuilder` merges `_reveal` + `_ambient`, so the whole `Stack` rebuilds every ambient tick.
- Rest-state animated inputs: `breath` (atmosphere pool + card glow), aurora/halo rotation, mote drift, card `bob` (`:479`), foil phase, "Tap to continue" pulse (`:590`).
- Performance-oracle: this defeats every `RepaintBoundary` (inputs change every frame, so caches never hold) and is the single highest-value fix (~80–90% steady-state GPU reduction).

## Proposed Solutions
1. **Rest-state freeze (recommended).** When `_reveal.value >= 1.0` and not `autoStart`, `_ambient.stop()` and repaint one static settled frame. Optionally keep ONE cheap slow idle (a single breathing glow) via a *separate* small `AnimatedBuilder(animation: _ambient)` wrapping only that element. Pros: biggest win, simple. Cons: lose the busy rest ambiance (arguably a win — see #005). Effort: Small–Medium.
2. **Split builders by driver.** FX painters listen to `_reveal` only; a second small `AnimatedBuilder(_ambient)` wraps just rest-life (motes/halo/glow). Then stop `_ambient` at rest. Pros: clean separation, enables the RepaintBoundary caches to finally hold. Cons: more restructuring. Effort: Medium.
3. **Throttle `_ambient` at rest** to a low-frequency ticker (e.g. 10–12s cycle, fewer elements). Pros: keeps some life. Cons: still repaints; partial fix. Effort: Small.

## Recommended Action
_(blank — triage)_

## Technical Details
- Affected: `lib/features/daily/widgets/card_reveal_overlay.dart` (builder wiring, `dispose`, rest gating).
- Interacts with #005 (rest-state serenity) — resolve together.

## Acceptance Criteria
- [ ] With the reveal settled and left open 60s, "Highlight repaints" (DevTools) shows the FX stack NOT repainting each frame.
- [ ] Raster-thread time at rest is ~0 (profile mode, physical device).
- [ ] Normal (motion-enabled) Emerald reveal still plays identically up to settle.
- [ ] No regression in reduced-motion path.

## Work Log
- 2026-07-23: Found via /code-review (performance-oracle P1-A).
- 2026-07-23: Implemented Solution #1 (rest-state freeze) on `feat/tiered-card-reveal`.
  `_ambient` no longer `..repeat()` in initState; it's started in `_open()` only
  under normal motion, and a `_reveal` status listener (`_onRevealStatus`) stops it
  the moment the reveal reaches `completed`, freezing breath/rotation/motes at their
  settled values (calm frame). Interactive tap-to-skip (`_reveal.value = 1.0`) also
  trips `completed` → ambient stops. autoStart debug loop restarts BOTH controllers.
  Reduced motion never starts the ambient loop at all. Verified via unit tests +
  reasoning: at rest, non-autoStart path has `_ambient.isAnimating == false`, so the
  merged `AnimatedBuilder` gets no ticks and the FX stack stops repainting.

## Resources
- Branch `feat/tiered-card-reveal`. Measure: `flutter run --profile`, DevTools → Performance → raster thread; "Highlight repaints".
