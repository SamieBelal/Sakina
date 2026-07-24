---
status: pending
priority: p2
issue_id: "010"
tags: [code-review, quality, maintainability, animation]
dependencies: []
---

# Extract named phase constants for the interlocking _seg() timeline windows

## Problem Statement
The choreography's real source of truth is ~25 hardcoded `_seg(t, a, b)` windows scattered across `build`/`_buildLantern`/`_buildCard`/`_buildCaption`. Several must stay equal to each other or a silent one-frame gap opens (e.g. the lantern→card swap `t<0.46` must match the card `appear` window start `0.46`; the caption gate `t>0.85` must sit inside the badge stagger `0.85`). The top-of-file comment says these are meant to be "tunable live" — but tuning one number can desync an interlocking pair with no signal.

## Findings
- `_seg` sites: `build` (`:269-374`), `_buildLantern` (`:391-396`), `_buildCard` (`:455-508`), `_buildCaption` (`:523-525`).
- Interlocks: `_kCardSwap` (lantern↔card, build `:368` + appear `:455`), caption gate `:374` vs badge stagger `:523`, halo/motes gate `:339/:353` vs opacity windows `0.82/0.84`.
- The 4 `HapticProfile` beat fractions (`:174-209`) are a *second* independent set of timeline anchors that must loosely track the visual windows.

## Proposed Solutions
1. **Extract interlocking boundaries as named constants** (`_kIgniteEnd`, `_kBurstPeak`, `_kCardSwap`, `_kSettle`, `_kCaptionIn`) and reference them from the paired sites. Even partial extraction (`_kCardSwap`, `_kCaptionIn`, `_kSettle`) removes the "two magic numbers must stay equal" foot-guns. Effort: Small–Medium.
2. **Cross-reference haptic beats to visual phases** (comment or shared constants) so a visual retune doesn't silently desync haptics. Effort: Small.

## Recommended Action
_(blank — triage)_

## Technical Details
- `lib/features/daily/widgets/card_reveal_overlay.dart`. Coordinate with #006 (a `reveal_geometry.dart` is the natural home).

## Acceptance Criteria
- [ ] Paired timeline boundaries reference one shared named constant (no duplicated literal that must stay equal).
- [ ] Haptic beats reference or comment their corresponding visual phase.

## Work Log
- 2026-07-23: Found via /code-review (pattern-recognition P2-2, P3-7).
- 2026-07-23: DONE (partial extraction, as recommended). Added named phase constants in `reveal/reveal_geometry.dart` for the genuine interlocks: `kCardSwap = 0.46` (lantern↔card swap gate in build + card `appear` window start + lantern dissolve end), `kCaptionIn = 0.85` (caption mount gate + badge-stagger first window), `kSpinSettle = 0.86` (spin easing window END must equal the overshoot-wobble window START). Referenced from both paired sites. Left purely-local one-off windows (0.84 pop/settle, 0.34/0.58 etc.) as literals to avoid noise — values unchanged. Haptic beat fractions left as-is (separate follow-up if desired). `flutter analyze` clean; tests green.

## Resources
- —
