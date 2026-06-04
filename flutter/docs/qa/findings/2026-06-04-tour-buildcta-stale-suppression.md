# Finding: guided-tour `duas.buildCta` coachmark intermittently never shows

- **Found:** 2026-06-04 (user-reported, flaky during guided-tour drive-throughs)
- **Severity:** Medium (UX reliability — the "type your need, then Build" coachmark silently fails to appear)
- **Status:** Fixed
- **Component:** Duas build screen × guided tour overlay (`lib/features/duas/screens/duas_screen.dart`, `lib/features/tour/`)

## Symptom

While driving through the guided onboarding tour, when reaching the **Duas** step the
coachmark that highlights the text box ("Type what's on your heart, then tap Build" —
step `duas.buildCta`, index 8) **sometimes does not appear**. The workaround that
reliably brings it back: navigate to the previous step (tap **Collection**), then tap
**Duas** again. Flaky — not every run.

## Root cause

`tourSuppressedProvider` (a top-level `StateProvider<bool>`) is the flag the overlay
host uses to hide the tour while the multi-screen **Build-a-Dua** flow is on screen
(loader + the four reader beats), because the *next* step's anchor (`firstRelatedHeart`)
only mounts on the result view. While the flag is `true`, the overlay host both
early-returns in `_updateRevealReadiness` and forces `hidden = true` in `_buildOverlay`,
so an anchored step's coachmark **never reveals**.

`DuasScreen` is the only writer of that flag. It sets it:
- **true/false** via an **edge-triggered** `ref.listen<DuasState>` — fires only on
  `duasProvider` *changes*; and
- **false** in `dispose()`.

There was **no reconciliation on mount**. So a stale `true` left over from an earlier
Duas visit (most easily reproduced by replaying the tour, which developers do
repeatedly) survives a fresh mount when `duasProvider` doesn't happen to change — and
the `buildCta` coachmark stays hidden forever. Leaving the tab runs `DuasScreen.dispose()`,
whose only overlay-relevant side effect is resetting the flag to `false`; re-entering
then reveals the coachmark. That exactly matches the user's workaround.

### Why this is `buildCta`-specific and not a timeout

Mixpanel (project 4013350, 30d) `tour_anchor_timeout` by `step_id`: every other step
(`muhasabah.*`, `appShell.tabCollection`, `duas.firstRelatedHeart`) shows timeouts, but
**`duas.buildCta` shows ZERO** across **25 `tour_step_viewed`**. The `buildCta` anchor is
always mounted (the build *input* is the default view), so the 60s anchor-timeout never
arms — the step can't auto-skip and can't fire a timeout. It just sits with no visible
coachmark. `buildCta` → `firstRelatedHeart` drops 25 → 17 (~32%), consistent with users
stuck without guidance.

### Relationship to F-06

This is the **same stale-suppression bug class** documented for the centered final step
in `2026-06-01-tour-step13-saved-dua-no-banner.md` and pinned by the
`onboarding_tour_overlay_host_test.dart` F-06 test ("stale suppression … kept
`_revealReady` false forever"). The F-06 fix only patched **centered** steps (a dedicated
settle timer that bypasses the suppression gate). **Anchored** steps like `buildCta`
remained exposed.

## Fix

Reconcile `tourSuppressedProvider` to the **actual** current build-flow state when
`DuasScreen` mounts (post-frame callback in `initState`), so a stale leftover is always
corrected. The existing `ref.listen` (changes while mounted) and `dispose()` reset now
have their gap closed. The build-flow predicate is shared via `_tourBlockedFor`.

At the `buildCta` step the build input is showing (`buildResult == null`,
`!buildLoading`), so reconcile resolves to `false` — clearing any stale `true` and
letting the coachmark reveal.

## Regression test

`test/features/duas/duas_screen_tour_suppression_test.dart` — mounts `DuasScreen` with
`tourSuppressedProvider` overridden to `true` (stale) and `duasProvider` in build-input
state; asserts the flag is reconciled to `false` on mount. Verified to **fail** without
the fix and **pass** with it.

## Possible follow-up (not done here)

Defense-in-depth in the overlay host: treat suppression as bogus for the current step
when that step's anchor is already resolvable (legitimate suppression always coincides
with the current step's anchor being *absent*). Would harden against any future stale
writer without a per-screen reconcile. Deferred to avoid bundling changes into the tour
render/advance logic.
