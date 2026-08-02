# Finding: guided-tour `journal.firstEntry` coachmark silently hangs (never shows)

- **Found:** 2026-06-08 (user-reported, fresh-run guided tour)
- **Severity:** Medium (UX reliability — the final-loop "Tap any entry" coachmark silently fails to appear and the tour hangs)
- **Status:** Fixed
- **Component:** Guided tour overlay host × Journal screen
  (`lib/features/tour/widgets/onboarding_tour_overlay_host.dart`,
  `lib/features/journal/screens/journal_screen.dart`)

## Symptom

Driving the guided onboarding tour: after hearting the related dua (step 9,
`duas.firstRelatedHeart`) and tapping the **Journal** tab (step 10), the
**Journal** step (step 11, `journal.firstEntry`, "Tap any entry to revisit it
anytime.") **never shows its coachmark** — no golden cutout, no tooltip. The
tour **hangs** on Journal: it neither reveals the coachmark nor auto-advances.
Reported on a **fresh first run** with the just-saved dua **already visible** in
the journal list.

This is the same *symptom class* the user reported for `duas.buildCta`
(fixed in `b5ca75b`, see `2026-06-04-tour-buildcta-stale-suppression.md`), but a
**different root cause** — see below.

## Why this is NOT the buildCta / suppression bug

`b5ca75b` fixed `buildCta` by reconciling the `tourSuppressedProvider` latch on
`DuasScreen` mount. That latch is **only written by `DuasScreen`** and is
provably **false** by the time the tour reaches Journal:

- At `firstRelatedHeart` the Duas result view is on screen
  (`buildCurrentSection == 4`) → `_tourBlockedFor` is false → `suppressed=false`.
  The user *saw and tapped* that heart coachmark, which only renders when
  `suppressed=false` — so suppression is confirmed false moments before Journal.
- Navigating `/duas`→`/journal` (a `ShellRoute` + `NoTransitionPage` swap)
  disposes `DuasScreen`, whose `dispose()` resets the latch to false anyway.
- `JournalScreen` never reads or writes the latch.

So the Journal hang is **not** stale suppression, and the per-screen reconcile in
`b5ca75b` has no Journal equivalent to "leave out."

## Root cause — fail-CLOSED anchored reveal-settle

The overlay host gates a coachmark behind a **reveal-settle**: it waits for a
minimum delay (`_kRevealMinSettle`, 400 ms) **and** for the anchor rect to stop
moving frame-to-frame before revealing (avoids popping in over a still-animating
screen). For an **anchored** step this stability wait had **no upper bound**.

Every other stuck state in the host has a recovery path:

| Stuck state | Recovery |
|---|---|
| Anchor absent | 60 s `tour_anchor_timeout` → auto-advance |
| Centered step (no anchor) | dedicated fixed settle timer (F-06 fix) |
| Blocking modal up | re-arms on route pop |
| **Anchor present but reveal-settle never completes** | **none — hangs forever** |

`journal.firstEntry`'s anchor is **essentially always resolvable** (an entry
exists by then, plus an empty-state fallback `TourAnchor` in `_buildAllFeed`).
So the 60 s timeout **never arms** (it only arms for an *unresolvable* anchor),
and if the stability wait never completes — sustained frame-to-frame jitter from
an async-driven rebuild storm (the `_journalStatsProvider` loader→content swap,
the empty→populated feed transition, staggered entry animations, auto-scroll),
or any device-timing hiccup — the coachmark stays hidden **forever** with nothing
to rescue it. That is the silent hang.

### Telemetry signature (Mixpanel, project 4013350, 30d)

`tour_anchor_timeout` by `step_id`: steps whose anchors are sometimes genuinely
absent DO time out (`muhasabah.*`, `appShell.tabCollection`,
`duas.firstRelatedHeart` ×4, `appShell.tabDuasFromCollection`). But
**`journal.firstEntry` shows ZERO timeouts** across **16 `tour_step_viewed`** —
identical to how `buildCta` looked: the anchor is always present, so the step
can neither auto-skip nor fire a timeout. It just sits with no visible coachmark.

## Fix

Add a **fail-open ceiling** to the anchored reveal-settle. When a step's anchor
first becomes drawable we already arm the 400 ms min-settle floor; we now also
arm a `_kRevealMaxSettle` (2500 ms) timer that force-reveals **regardless of
motion**. Measured from anchor-appearance (like the floor) so a late-mounting
anchor never force-reveals over an absent one. The `_buildOverlay` gates still
hide the coachmark if the anchor later vanishes or a modal/suppression
intervenes, so this only ever *unblocks* a stuck reveal — it never reveals over
a missing anchor. 2500 ms sits comfortably above realistic transition +
entry-animation + auto-scroll durations and far below the 60 s anchor-timeout;
bypassed under reduce-motion. This hardens **all** anchored steps, not just
Journal.

`lib/features/tour/widgets/onboarding_tour_overlay_host.dart`:
`_kRevealMaxSettle` + `_maxSettleTimer`, armed alongside the min-settle floor in
`_updateRevealReadiness`, reset on step change / inactivity / dispose.

## Regression test

`test/features/tour/onboarding_tour_overlay_host_test.dart` → **F-12**: mounts
the host at step 11 (`journal.firstEntry`) with an anchor that stays resolvable
but jitters > the 1 px epsilon every frame. Asserts the step does NOT
auto-advance (anchor present → no timeout) and that the coachmark **reveals**
after the max-settle window. Verified to **fail** without the fix (coachmark
never appears — the reproduction of the hang) and **pass** with it.
