---
status: pending
priority: p2
issue_id: "003"
tags: [code-review, performance, animation]
dependencies: ["001"]
---

# Trim burst-window paint cost (pre-rasterize ray fans; spec-drive counts; cache shaders)

## Problem Statement
During ignite/burst (worst case Emerald) the stack does ~48 shader-path draws + ~17 mask-blurs per frame, allocating new gradient shaders every frame. Most of this survives on a real device (unlike the rest-state issue #001 which the simulator over-reports). This is the frame-time spike users feel during the burst.

## Findings
- God-rays `card_reveal_overlay.dart:1178-1209`: 16 wedges, each a `LinearGradient` shader + `MaskFilter.blur(halfW*0.7)` (~14px) + 1 blurred radial. Static geometry; only `rotation`+scalar change.
- Aurora `:1257-1273`: 12 gradient path fills, all `BlendMode.plus`.
- Burst shafts `:1336-1367`: 20 gradient path fills, `BlendMode.plus`, heavy central overdraw.
- `createShader` allocated per-path-per-frame (`:1186, :1277, :1346`).
- Ray/shaft counts are hardcoded (`const rays = 16` `:1178`, `const n = 20` `:1340`) regardless of tier; motes fixed at 14 (`:91`).

## Proposed Solutions
1. **Pre-rasterize the static ray fans (god-rays, aurora) to a `ui.Picture`/`Image` once**, then each frame `drawImage` with a rotation transform + opacity `ColorFilter`. Eliminates ~28 path builds + ~17 blurs → 2 textured draws. Effort: Medium. (Biggest on-device win.)
2. **Make ray/shaft/mote/spark counts spec-driven** and cap on Bronze/Silver (e.g. rays 8, shafts 10). Low tiers fire far more often than Emerald. Effort: Small.
3. **Cache per-ray/aurora shaders** (they don't change within a reveal). Effort: Small.

## Recommended Action
_(blank — triage)_

## Technical Details
- `lib/features/daily/widgets/card_reveal_overlay.dart` painters `_LanternRaysPainter`, `_AuroraPainter`, `_BurstPainter`; `RevealSpec` (add count fields) if doing #2.
- Do #001 first (rest state) — measure, then decide how much burst trimming is needed on device.

## Acceptance Criteria
- [ ] Profile-mode raster time during the burst window holds under ~16ms on a mid device.
- [ ] Emerald burst looks unchanged; low tiers visibly lighter.

## Work Log
- 2026-07-23: Found via /code-review (performance-oracle P1-B/P1-C).
- 2026-07-23: Implemented Solution #2 (spec-driven counts) on `feat/tiered-card-reveal`.
  Added `godRayCount`/`shaftCount`/`moteCount` to `RevealSpec`. Counts:
  Bronze 8/10/6, Silver 10/12/8, Gold 14/16/12, **Emerald 16/20/14 (unchanged)**.
  `_LanternRaysPainter.rayCount`, `_BurstPainter.shaftCount`, and the `_motes` list
  (via `_buildMotes(spec.moteCount)`) are now spec-driven; sparks were already.
  DEFERRED: Solution #1 (ui.Picture pre-rasterization of the ray fans) and Solution #3
  (per-ray/aurora shader caching) — left for a device-profiling follow-up as too
  big/risky for this batch. Re-measure raster thread on device before attempting.

## Resources
- Measure raster thread in DevTools during the 0.38–0.66 window.
