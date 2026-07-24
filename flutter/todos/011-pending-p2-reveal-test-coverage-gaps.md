---
status: pending
priority: p2
issue_id: "011"
tags: [code-review, testing, quality]
dependencies: ["006"]
---

# Add tests for tap-to-skip, tier-gating, and analytics fire-once

## Problem Statement
Only reduced-motion (widget) and the spec-map escalation (unit) are tested. The most fragile logic — tap-to-skip → tap-to-continue, `_continue` idempotency, Bronze's no-card-back invariant, and analytics fire-once — has zero coverage. Regressions here (double-pop, coachmark bleed, double `card_reveal_completed`, Bronze flashing a card-back) would ship silently.

## Findings
- `card_reveal_overlay_test.dart` — only reduced-motion, and only via `autoStart: true` (not the production tap entry).
- Untested: `_handleTap` mid-reveal `stop()+value=1.0` snap then continue (`:214-229`); `_continue` `_dismissed` guard (`:231-233`); `card_reveal_shown`/`completed` fire once with correct `tier`/`auto`; Bronze `spinTurns==0` keeps `facingFront` true / never builds `RevealCardBack` (`:465-474`).

## Proposed Solutions
1. **Widget tests** (existing harness already handles the `VisibilityDetector` timer via `VisibilityDetectorController.instance.updateInterval = Duration.zero`):
   - Skip-then-continue: drive `_reveal.value` mid-flight, tap twice, assert exactly one `onContinue` and one `card_reveal_completed`.
   - Bronze: assert `RevealCardBack` never appears.
   - Reduced-motion via TAP entry (not autoStart) under `disableAnimations: true`.
   - Analytics: capture `onEvent` calls, assert shown-on-open + completed-once with props.
   Effort: Medium.
2. Prefer the pure-function motion math from #006 for the escalation invariants (no widget pump). Effort: Small once #006 lands.

## Recommended Action
_(blank — triage)_

## Technical Details
- `test/features/daily/card_reveal_overlay_test.dart`. Easier after #006.

## Acceptance Criteria
- [ ] Tests cover: tap-to-skip no double-fire, Bronze no card-back, reduced-motion tap-entry, analytics fire-once.
- [ ] `flutter test test/features/daily/` green.

## Work Log
- 2026-07-23: Found via /code-review (pattern-recognition P2-4; architecture P2).
- 2026-07-23: Added coverage. New pure-function file `test/features/daily/reveal_motion_test.dart` (Bronze never shows card back / never rotates; spinning tiers flip mid-reveal + land face-up ~0 angle at t=1.0; spinTurns 0/1/2/3 escalation; phase-constant interlock — appear gated at kCardSwap, pop/settleY settled at t=1.0). Extended `card_reveal_overlay_test.dart` with tap-entry widget tests: tap-to-skip→continue fires onContinue exactly once (+ _dismissed double-fire guard); analytics fire-once (card_reveal_shown on open, card_reveal_completed on continue, tier label + auto:false); reduced-motion via TAP entry. `flutter test test/features/daily/` → 68 pass; analyze clean. No product bug found. Harness note: normal-motion tests drain the mounted-guarded haptic `Future.delayed` timers with a final `pump(duration)` so none outlive the tree.

## Resources
- —
