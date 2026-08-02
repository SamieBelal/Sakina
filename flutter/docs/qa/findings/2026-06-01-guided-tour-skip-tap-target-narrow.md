# Finding: Guided Tour "Skip tour" tap target hard to hit on first-visit Home step

**Date:** 2026-06-01  
**Severity:** P3 (Low — usability; no data loss or security impact)  
**Reporter:** Lane C (automated sim regression)  
**Lane:** C · iPhone 17 simulator

## Summary
The "Skip tour" link inside the guided-tour coachmark bubble is difficult to tap reliably via automation (and likely by real users with large fingers or low-contrast displays). The hit target is ~25×18 pt and sits near the bottom of a 103-pt-tall banner, but the `_AbsorbTap` overlay strips block all taps OUTSIDE the anchor cutout zone including the region above and below the coachmark. Within the coachmark itself, "Skip tour" is rendered inside a GestureDetector with `horizontal: 2` padding, giving an effective tap width of ~80 pt but only ~18 pt height (vertical: 6 padding each side = 30 pt effective height). Empirical testing required 10+ attempts at different coordinates before landing on x=40, y=144.

## Repro Steps
1. Fresh install, tap Get Started → complete onboarding → skip paywall → reach Home.
2. Guided tour fires: coachmark anchored to "Begin Muhāsabah" card.
3. Attempt to tap "Skip tour" text at bottom of coachmark bubble.
4. Most tap coordinates in the lower coachmark area are absorbed by the `_AbsorbTap` strip (y < anchor cutout).

## Expected
"Skip tour" link is tappable reliably with a single tap. Per HIG, minimum 44pt touch target.

## Actual
- The "Skip tour" GestureDetector has `behavior: HitTestBehavior.opaque` — it should register — but is rendered very close to the `_AbsorbTap` bottom boundary.
- Working coordinates: x=40, y=144 (inside the coachmark at y=70–173). One pixel off and the tap hits the absorber.
- On a real device with slightly different safe-area insets, the exact y may vary.

## Root Cause
The tour coachmark widget (`_CoachBanner`) is the LAST child in the overlay Stack, so it renders above the absorbers. However the `_AbsorbTap` strip covers y=0 to padded_cutout.top (≈352 for the Begin Muhāsabah anchor), while the coachmark sits at y=70–173. The overlap means the coachmark IS above the absorber and SHOULD receive taps — but the 12px left padding between the coachmark edge (x=12) and the "Skip tour" text (x≈31) means taps at x<31 land outside the GestureDetector's subtree. The effective tap area for "Skip tour" is approximately x=31–120, y=131–155.

## Recommendation
- Expand the "Skip tour" GestureDetector padding to `symmetric(vertical: 10, horizontal: 8)` (from current vertical:6 horizontal:2) for a 44pt-minimum-equivalent touch area.
- Alternatively, promote "Skip tour" to a separate dedicated `IconButton` or `TextButton` widget with an explicit `minimumSize: Size(88, 44)` constraint so it always has a reachable touch target.

## Evidence
- Screenshots: C-41-skip-tour.png through C-55-reflect-tap2.png showing repeated failed navigation to Reflect tab due to tour overlay.
- Code: `lib/widgets/coachmark/coachmark_overlay.dart` line 466–480 (GestureDetector with HitTestBehavior.opaque, padding: symmetric(vertical: 6, horizontal: 2)).
