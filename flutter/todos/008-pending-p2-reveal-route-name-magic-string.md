---
status: pending
priority: p2
issue_id: "008"
tags: [code-review, architecture, coupling]
dependencies: []
---

# Replace the 'CardRevealOverlay' route-name magic string with a shared const

## Problem Statement
The guided-tour blocking guard matches the literal `'CardRevealOverlay'`, and the muḥāsabah push must set the exact same literal in `RouteSettings(name: ...)`. Two independent string literals in two features that must stay in lockstep — a rename/typo silently breaks the tour's "don't punch coachmarks through the reveal" guard with no compile error and no test. This branch already carries the risk (a two-name window with `'NameRevealOverlay'` kept for collection/onboarding).

## Findings
- `tour_route_observer.dart:24` — `blockingRouteNames` contains `'CardRevealOverlay'`.
- `muhasabah_screen.dart` — `RouteSettings(name: 'CardRevealOverlay')` at the push site.
- The regression this class of bug causes was literally hit once already this branch (fixed in commit `2c65dd8`).

## Proposed Solutions
1. **Shared const (recommended).** `static const String routeName = 'CardRevealOverlay';` on `CardRevealOverlay`; reference from both the push (`RouteSettings(name: CardRevealOverlay.routeName)`) and the observer set. Compile-checked coupling. Effort: Small.
2. **Add a guard test.** Assert the pushed route's `settings.name` ∈ `TourRouteObserver.blockingRouteNames`. Effort: Small.

## Recommended Action
_(blank — triage)_

## Technical Details
- `lib/features/daily/widgets/card_reveal_overlay.dart`, `lib/features/daily/screens/muhasabah_screen.dart`, `lib/features/tour/providers/tour_route_observer.dart`.

## Acceptance Criteria
- [ ] The route name exists as one shared const referenced by both push site and observer.
- [ ] (Optional) a test pins the push name is in the blocking set.

## Work Log
- 2026-07-23: Found via /code-review (architecture-strategist P2). Related live fix: commit `2c65dd8`.
- 2026-07-23: Implemented Solution 1 (shared const). Added `static const String routeName = 'CardRevealOverlay';` to `CardRevealOverlay`; muhasabah_screen push now uses `CardRevealOverlay.routeName`; tour_route_observer `blockingRouteNames` now references `CardRevealOverlay.routeName` (import added), `'NameRevealOverlay'` literal kept. Const-in-const-set compiles. `flutter analyze` on the 3 files clean; `flutter test test/features/daily/` all pass.

## Resources
- —
