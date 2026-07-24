---
status: pending
priority: p2
issue_id: "004"
tags: [code-review, design, animation, motion, impeccable]
dependencies: []
---

# Motion feel: spin easing, spring settle, and the lantern→card handoff

## Problem Statement
Three motion-craft issues undercut the "expensive object arriving" feel: the spin decel is front-loaded (feels computery), the settle "overshoot" is a symmetric sine wobble (reads as jelly, not weight), and the lantern→card transition is a hard widget swap hidden behind the burst flash (brittle, and it eats the "forged white-hot" birth moment).

## Findings
- Spin: `card_reveal_overlay.dart:466` `easeOutCubic` dumps decel early; premium gacha wants a longer high-speed body + hard terminal decel (the "will-it-land" tension lives in the tail).
- Settle: `:468-470` `sin(land*π*2.4)*(1-land)*0.11` — symmetric decaying sine rocks the card past front-face in *both* directions (uncanny for a rotation). Also `pop` (`:477`) window `0.84–0.94` can drift out of sync with the spin's face-arrival.
- Handoff: `:368-371` hard `if (t<0.46) lantern else card`; lantern opacity hits 0 exactly at 0.46, card `appear` starts at 0.46 — only works because the flash (`_bell(_seg(0.38,0.52))`, peak ~0.45) whites out the seam. The `birth` forge (`_seg(0.47,0.62)`) happens *inside* the whiteout, so it's largely invisible.
- `easeOutBack` on `appear` (`:455`) overshoots and stacks with `pop` (`:477`) and the angular `wobble` — three overshoot mechanisms in a narrow window → over-springy landing (#005/P2-5).

## Proposed Solutions
1. **Spin envelope → `Curves.easeOutQuart`/`easeOutQuint`** (sharper terminal decel, longer fast body). Keep cubic for calmer low tiers if desired. Effort: Small.
2. **Replace sine wobble with a single asymmetric spring** (`elasticOut` or critically-damped), overshoot once in the spin's direction, cycles ~1.3–1.5; sync the scale-`pop` peak to the moment rotation crosses front-face. Effort: Small–Medium.
3. **Overlap the handoff**: let the lantern's dissolving glow and the card's forge-birth co-exist ~0.44–0.50 (card emerges *from* where the lantern was), and shift `birth` to start ~0.50 so the white-hot cooling is visible against the darkening atmosphere. Effort: Medium.
4. **Pick one overshoot owner** for the landing (make `appear` monotonic `easeOut`; let the spring/`pop` own the bounce). Effort: Small.

## Recommended Action
_(blank — triage)_

## Technical Details
- `lib/features/daily/widgets/card_reveal_overlay.dart` `_buildCard` (`:445-520`), `_CardFace` birth timing.
- Device visual QA per tier.

## Acceptance Criteria
- [ ] The spin holds speed then lands with a decisive decel (not a coast).
- [ ] The settle reads as a weighted arrival (one overshoot), not a symmetric wobble.
- [ ] The "forged from light" birth is actually visible after the flash decays.
- [ ] No triple-overshoot springiness at landing.

## Work Log
- 2026-07-23: Found via /code-review (impeccable animation pass P1-2/3/4, P2-5).
- 2026-07-23: Implemented all four solutions in `revealCardMotion`/`_CardFace` (branch `feat/tiered-card-reveal`).
  - Solution 1 (spin envelope): `Curves.easeOutCubic` → `Curves.easeOutQuint` — longer high-speed body, hard terminal decel.
  - Solution 2 (settle spring + pop sync): replaced the symmetric `sin(land*π*2.4)*(1-land)*0.11` wobble with a SINGLE asymmetric damped overshoot `-sin(land*π)*exp(-3.2*land)*0.13` — one overshoot past the final angle in the spin direction (min ~-0.041 rad), no inner zero-crossing (not a jelly rock), decays to exactly 0 at land=1 (face-up preserved, angle≈0 at t=1.0). Synced the scale-`pop` bell to peak at `kSpinSettle` (`bell(seg(t, kSpinSettle-0.06, kSpinSettle+0.06))`) so it coincides with the face-arrival.
  - Solution 3 (handoff / forge visibility): shifted `_CardFace.birth` to start after the flash decays (`1 - seg(t, burstAt+0.01, burstAt+0.16)`, Emerald→[0.47,0.62]) and extended the lantern flare a hair past the swap (`seg(t, burstAt-0.12, burstAt+0.02)`) so the dissolving vessel glow overlaps the card's first fade-in frames.
  - Solution 4 (one overshoot owner): card `appear` curve `Curves.easeOutBack` → `Curves.easeOutCubic` (monotonic, no entrance bounce stacking on the settle spring + pop).
  - Also #002 Solution 2 signature-gesture: Bronze `shineSweep: false → true` (its one confident flourish).
  Emerald's spin/land feel changes slightly (the approved 004 polish) but still lands face-up. `flutter analyze` clean; `flutter test test/features/daily/` green.

## Resources
- Flutter `Curves` (easeOutQuint, elasticOut).
