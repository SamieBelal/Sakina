# Finding: stale `tourSuppressed` can hang any anchored guided-tour step (host-level defense)

- **Found:** 2026-06-08 (audit follow-up to the `journal.firstEntry` reveal hang)
- **Severity:** Medium (UX reliability; HIGH in the mandatory gate tour where Skip
  is hidden and the user can't escape a hang)
- **Status:** Fixed
- **Component:** Guided tour overlay host
  (`lib/features/tour/widgets/onboarding_tour_overlay_host.dart`)

## Background

`tourSuppressedProvider` is a latch (written **only** by `DuasScreen`) that the
overlay host honors to keep the tour hidden while the multi-screen Build-a-Dua
flow is on screen — the next step's anchor (`firstRelatedHeart`) only mounts on
the result view. `b5ca75b` fixed the `buildCta` case of a **stale** latch by
reconciling it on `DuasScreen` mount, and the `2026-06-04` finding explicitly
**deferred** the general, host-level defense:

> *Defense-in-depth in the overlay host: treat suppression as bogus for the
> current step when that step's anchor is already resolvable (legitimate
> suppression always coincides with the current step's anchor being absent).
> Would harden against any future stale writer without a per-screen reconcile.*

This finding implements that deferred defense.

## The hang

When `tourSuppressed` is `true`, the host treats the step as legitimately
hidden across **three** sites, none of which has a recovery path:

1. `_buildOverlay` — hides the coachmark (`!isCentered && suppressed`).
2. `_maybeScheduleAnchorTimeout` — does **not** arm the 60s anchor-timeout.
3. `_updateRevealReadiness` — returns early, so the reveal-settle (and, after the
   F-12 fix, the max-settle ceiling) is **never even armed**.

So if the latch is ever `true` while an anchored step's anchor **is** on screen,
the coachmark is hidden, no timeout fires (the host thinks suppression is
intentional), and no settle is attempted — the step **hangs forever** with no
automatic recovery. In the **mandatory gate tour** `allowSkip` is false, so the
user can't even skip out: they're stranded at the onboarding wall.

Reachability today is low (only `DuasScreen` writes the latch and its
`dispose()` + `ref.listen` + mount reconcile keep it confined to the Duas
steps), but the host being undefended makes any future writer — or any timing
gap the per-screen reconcile misses — a silent hang. The F-12 max-settle does
**not** cover this case because it is deliberately not armed while suppressed.

## Fix

A single predicate decides whether suppression is effective:

```dart
bool _suppressionHides(OnboardingTourStepDef step) =>
    ref.read(tourSuppressedProvider) && !_anchorResolvable(step);
```

Suppression is honored **only while the current step's anchor is absent** (the
real Build-flow wait). Once the anchor is resolvable, a lingering flag is stale
and ignored, so the coachmark reveals normally instead of hanging. Applied at
all three sites. This also subsumes the old `!isCentered` guard — centered steps
are always "resolvable", so suppression never hides them (the F-06 case still
holds).

`_suppressionHides` replaces the bare `tourSuppressed` reads in
`_updateRevealReadiness`, `_maybeScheduleAnchorTimeout`, and `_buildOverlay`.

## Regression tests

`test/features/tour/onboarding_tour_overlay_host_test.dart`:
- *"tourSuppressed hides the coachmark while the anchor is ABSENT"* — suppression
  with an absent anchor still hides (and does not auto-advance); when the anchor
  later mounts, the now-stale flag is ignored and the coachmark reveals.
- *"stale tourSuppressed does NOT hide the coachmark when the anchor is already
  resolvable"* — the host-level defense: a flag set with the anchor on screen
  must not hide the coachmark (would hang — no timeout arms while present).

The pre-existing F-06 test (centered step reveals despite stuck suppression) and
the F-12 test (anchored max-settle) both still pass.

## Related

- `2026-06-04-tour-buildcta-stale-suppression.md` — the per-screen reconcile this
  generalizes.
- `2026-06-08-tour-journal-firstentry-reveal-hang.md` — the F-12 max-settle
  fail-open; together these close the known silent-hang classes for anchored
  steps (settle-stuck **and** suppression-stuck).
