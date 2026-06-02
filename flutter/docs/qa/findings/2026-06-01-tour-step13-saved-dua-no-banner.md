# Finding: Tour step 13 — centered banner not shown on SAVED DUA journal detail

**Date:** 2026-06-01  
**Severity:** Medium  
**Lane:** A (new-user happy path)  
**Reporter:** Lane A QA agent  

---

## Summary

Tour step 13 (`duaDetail.done`) is supposed to show a centered banner on `DuaDetailPage` as the final step of the guided tour. In the test run, when the user navigated to a "SAVED DUA" journal entry (a public catalog dua saved from the Related Duas panel), the `DuaDetailPage` route was not matched by the tour's route observer and the centered banner did NOT appear.

The tour seen flag **was** set to true (confirmed via SharedPreferences plist), so the tour completed internally. However, the user did not see the final celebratory banner.

---

## Repro steps

1. Complete the guided tour through step 12 (journal.firstEntry)
2. From the journal list, tap the **SAVED DUA** entry (a public catalog dua that was heart-saved from Related Duas)
3. Observe: No tour banner on the dua detail view

**Expected:** Centered tour banner appears: "You've made it!" / final celebration copy, auto-advances after 3.5s  
**Actual:** No banner; tour quietly marks itself complete

---

## Root cause — UPDATED 2026-06-01 (investigation)

**The original route-name-mismatch hypothesis is WRONG.** Both dua-detail routes
share the SAME route name `'DuaDetailPage'`:
- `journal_screen.dart:840` → `RouteSettings(name: 'DuaDetailPage')` + `DuaDetailPage.fromBuiltDua` (personal built dua)
- `journal_screen.dart:901` → `RouteSettings(name: 'DuaDetailPage')` + `DuaDetailPage.fromRelatedDua` (saved catalog dua)

So `TourRouteObserver` sees `'DuaDetailPage'` for both — route matching is NOT the gap.

Real cause is most likely **premature step completion**: step 13 (`centered`, no
widget anchor) is auto-advanced/closed before the banner renders — via the
`anchor_timeout` path (overlapping **F-10**) or a nav race when the saved-dua
detail is pushed while the step is still arming. Seen-flag set + no banner is
consistent with an auto-skip, not a route miss.

**Recommended next step:** focused reproduce-and-trace — drive the tour to step 13
with a *saved catalog* dua on a sim, log the controller's `advance(via:)` reason
at step 13, and confirm whether `anchor_timeout` fires for a `centered`
(anchorless) step. A `centered` step should never arm an anchor timeout; if it
does, that is the fix. NOT fixed in this pass — a blind change to the tour
render/advance logic risks degrading the tour in the next build.

## Original hypothesis (superseded)

The two views may have different route paths — DISPROVEN above (same name).
The step 13 anchor is `centered` (no widget anchor); the banner is centered.

---

## Evidence

- Screenshot `A-85-tour-step13-final.png`: SAVED DUA detail page opened, no banner visible
- Screenshot `A-90-personal-dua-detail.png`: PERSONAL DUA detail page, also no banner (tour may have auto-completed via anchor_timeout or back-gesture during navigation)
- SharedPreferences: `flutter.onboarding_tour_v1_seen_7996f23a-6906-4484-96d9-93f9fc60774e = true` — tour did reach completion state

---

## Impact

New users who save a catalog dua (by tapping the heart in Related Duas) and then tap that saved dua in the journal miss the final tour celebration. The tour completes silently. If the tour is the first time they're in the journal, this is a sub-optimal experience.

---

## Suggested fix

Verify the tour route observer (`tour_route_observer.dart`) matches both:
- The built-personal-dua detail route
- The saved-catalog-dua detail route

OR ensure the tour navigates to the correct `DuaDetailPage` type in step 12 (Journal first entry), which should be the PERSONAL DUA built during step 9-10, not the SAVED DUA.
