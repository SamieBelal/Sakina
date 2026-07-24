---
status: pending
priority: p2
issue_id: "005"
tags: [code-review, design, animation, on-brand, impeccable]
dependencies: ["001"]
---

# Rest state: one master breath, and retire the sci-fi tick-ring for Islamic geometry

## Problem Statement
Two on-brand/taste issues in the settled state: (1) six independent oscillators run at once (aurora breath, halo tick rotation, 14 motes twinkling at double-frequency, card bob, atmosphere pool breath, glow breath) → reads *fidgety*, not *serene*; (2) the halo's rotating radial tick-ring is a targeting-reticle / loading-spinner vocabulary — the single most "sci-fi HUD" element in the piece, undercutting the "beautifully typeset mushaf" tone on the prestige tier.

## Findings
- Rest oscillators: aurora `:299-305`, halo `_HaloPainter` `rotation*0.3` (`:1084-1095`), motes `:353-365` (twinkle `sin(phase*2π*2)` — double freq), card bob `:479` `sin(...)*4`, atmosphere pool breath `:1009`, card glow breath `_CardFace:750`.
- Halo tick-ring: `_HaloPainter:1084-1095` — 16 marching ticks on a rotating ring.

## Proposed Solutions
1. **One master breath.** Phase-lock glow/pool/aurora to a single slow cycle (slow `_ambient` rest to ~10–12s); drop mote twinkle to 1× (remove the `*2`); reduce rested mote count (~8 for Emerald, fewer down-tier). Pairs with #001 (which already freezes/throttles the loop). Effort: Small–Medium.
2. **Retire the tick-ring** → an Islamic-geometry motif at 5–8% opacity (8/16-point star rosette or thin double-rule ring with corner florons), non-rotating (or <0.05 rad/s). Keep the soft blurred outer ring (`:1066`) and the two concentric strokes; only the marching ticks go. Effort: Medium (new painter geometry).

## Recommended Action
_(blank — triage)_

## Technical Details
- `lib/features/daily/widgets/card_reveal_overlay.dart` `_HaloPainter`, `_MotePainter`, rest-state gating (coordinate with #001).
- DESIGN.md decorative-accent rule (5–8% opacity geometric patterns).

## Acceptance Criteria
- [ ] Rested Emerald reads as *quietly glowing* with one slow inhale, not orbited by instruments.
- [ ] No rotating tick/reticle motif remains; halo (if kept) is an Islamic-geometry accent within the opacity rule.

## Work Log
- 2026-07-23: Found via /code-review (impeccable animation pass P2-3, P2-4).
- 2026-07-23: Retired the halo tick-ring → static 8-point khatam star (two squares rotated 45°) + thin double-rule ring + 4 floral corner dots, all at ~6–18% opacity, non-rotating; dropped the `rotation` param from `HaloPainter` (call site updated). Added ONE 4000ms `_restBreath` controller (started at settle on the interactive path, skipped under reduced motion, disposed) driving ONLY the settled card's outer glow — split the breathing glow out of `_CardFace` into a `_CardGlow` sibling wrapped in its own `AnimatedBuilder(_restBreath)` + `RepaintBoundary`, so aurora/halo/motes stay frozen (Batch 1 perf win preserved). Also scaled the settled card up (width min(300, w*0.76), centre lifted −36 for caption clearance, +5% present-grow on land). `flutter analyze` 0 errors; `flutter test test/features/daily/` all pass.

## Resources
- DESIGN.md; CLAUDE.md design philosophy ("mushaf, not a tech product").
