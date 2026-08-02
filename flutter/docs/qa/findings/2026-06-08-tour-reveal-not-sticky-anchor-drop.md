# Finding: tour coachmark doesn't show on Collection→Duas / journal.firstEntry until you leave and re-enter

- **Found:** 2026-06-08 (user-reported, reproduced on physical device with rapid navigation)
- **Severity:** High (forced onboarding tour stalls — user can't see which control to tap next)
- **Status:** Fixed
- **Component:** Guided tour reveal-settle render gate
  (`lib/features/tour/widgets/onboarding_tour_overlay_host.dart`)

## Symptom

During the forced first-run tour, on the `appShell.tabDuasFromCollection` step
(coachmark should point at the Duas bottom-nav tab after the user taps
Collection) and on `journal.firstEntry`, the golden cutout + tooltip **did not
appear**. Navigating away from the screen and back — which the user did
instinctively — made it appear immediately. Only reproduced under **rapid**
navigation through the tour; a slower walk (or the iOS simulator) showed the
coachmark fine.

## Root cause

On-device `[STL]` instrumentation proved the reveal-settle **completed**:
`tabDuasFromCollection REVEAL@~408ms` and `journal.firstEntry REVEAL@~408ms`
both logged, with no subsequent motion / null-rect / max-settle ceiling. So
`_revealReady` flipped true — the settle decided to show the coachmark.

But the coachmark stayed hidden. The render gate in `_buildOverlay` was:

```dart
final hidden = blockingRouteUp || _suppressionHides(step) ||
    !_anchorResolvable(step) || !_revealReady;
```

The `_trackTicker` rebuilds this overlay **every frame**, re-evaluating
`_anchorResolvable(step)` (a live registry lookup → attached, sized RenderBox)
each time. At ~reveal time the host screen **rebuilds** — the deferred
quest-completion (`onCollectionVisited` / `onJournalVisited`) fires its state
update, plus rapid navigation churn — and the anchor's `TourAnchor` momentarily
**unregisters** (its `dispose` runs synchronously, a frame before the re-mount's
**post-frame** re-register). For that window `_anchorResolvable` returns false,
so `hidden` flips true and **re-hides an already-revealed coachmark**. Normally
the ticker would re-show it the next frame — but the registration drop persisted
(the re-register didn't land until a real re-navigation rebuilt the subtree
cleanly), so it stayed hidden until the user left and came back.

By elimination this was the only possible gate: `_revealReady` stays true once
set, the user was on a normal screen (no `blockingRouteUp`), and suppression
wasn't set on these steps — leaving `!_anchorResolvable` as the persistent
`true`. The widget was visibly **on screen** the whole time; the registry had
just lost the key — i.e. `_anchorResolvable` was a **false negative**.

## Fix — make the reveal sticky

`_anchorResolvable` is **redundant pre-reveal** (the `!_revealReady` term already
hides the coachmark until the settle completes, and the settle itself requires
the anchor to be drawable + stable before flipping `_revealReady`) and
**harmful post-reveal** (it re-couples persistent visibility to a per-frame
registry lookup that flickers during host rebuilds). Dropped it from the gate:

```dart
final hidden = blockingRouteUp || _suppressionHides(step) || !_revealReady;
```

Once the settle has decided to show the step, we trust `_revealReady`. The
`CoachmarkOverlay` degrades gracefully if the target rect is briefly null
(renders the banner without the ring), and the ticker re-draws the ring the
instant the key re-resolves — so a transient registration drop is invisible to
the user instead of hiding the whole coachmark. Navigation away from the step is
still handled by `blockingRouteUp` / the step changing / the tour going inactive.

## Tests

- `test/features/tour/onboarding_tour_overlay_host_test.dart` →
  *"reveal is sticky: an already-revealed coachmark survives a transient
  anchor-registration drop"*: reveals a step, then drops the anchor's
  registration (toggles the `TourAnchor` out of the tree) and asserts the
  coachmark **stays shown**. Fails before the fix (0 widgets — the exact bug),
  passes after.
- Full tour + deferred-celebration suites: 53 pass, analyzer clean.

## Relationship to the other reveal fixes (same session)

- **F-12** (`2026-06-08-tour-journal-firstentry-reveal-hang.md`) — fail-OPEN
  ceiling so a never-*settling* anchor can't hang the reveal. That gets
  `_revealReady` to flip. **This** finding is the next gate: keeping it shown
  once flipped.
- Suppression-stale defense (`2026-06-08-tour-suppression-stale-anchored-hang.md`)
  — same spirit (a stale gate must not hide a coachmark whose target is on
  screen), applied to `tourSuppressed` instead of `_anchorResolvable`.
