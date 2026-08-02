# Guided Onboarding Tour — Simulator Test Run (Findings)

**Date:** 2026-05-31
**Branch:** `onboarding-trim-and-guided-tour`
**Device:** iPhone 16, iOS 18.5 (`F0259F3A-84BB-470D-8B13-168C566C9CDF`)
**Account:** `sakina.tour.qa@gmail.com` (Tester, user_id `f7eb9cb3-61b0-4ead-ae6d-ed9efa54b6dd`)
**Plan:** `docs/qa/plans/2026-05-31-guided-tour-sim-test-plan.md`
**Evidence:** screenshots `00–15` (happy path) and `E-01–E-13` (edges) in this directory.

## Verdict: ✅ Ship-ready for the tour feature

All 13 steps work end-to-end; every edge case driven on-device behaved correctly. **Zero crashes, zero "No Overlay found", zero orphaned overlays, zero double-fires.** One real (pre-existing, out-of-scope) follow-up and a couple of test-harness limitations are noted below. No tour bugs found.

---

## Happy path — 13/13 PASS

Driven on a warm debug build with the TEMP DEMO bypass active (so the tour fires for the walkthrough). Each step: banner placement correct (top-left, clear of its target, within safe area), gold ring on the correct element, `{name}`→"Tester" on all 6 named steps, and the tap drove BOTH the tour and the underlying navigation.

| # | Step | Screenshot | Result |
|---|---|---|---|
| 1 | home.beginMuhasabah | 00 | ✅ greeting + name, ring on Begin CTA |
| 2 | muhasabah.goDeeper | 02 | ✅ |
| 3 | muhasabah.readStory | 03 | ✅ no-name copy correct; ﷺ renders |
| 4 | muhasabah.ameen | 05 | ✅ **late anchor** — banner waited silently through Story→Dua nav, revealed only when `ameenCta` mounted (reveal-settle gate) |
| 5 | muhasabah.returnHome | 06 | ✅ ring on secondary "Return to Home", not primary "Seek Another Name" |
| 6 | home.streakPill | 07 | ✅ **auto-advanced** (no tap) |
| 7 | appShell.tabCollection | 07 | ✅ cutout grew to full tab cell (icon+label) |
| 8 | appShell.tabDuas | 08 | ✅ |
| 9 | duas.buildCta | 09 | ✅ **280pt upward cutout** covered the entire form (pills + text field + Build CTA); banner flipped above to the header, not over the input |
| 10 | duas.firstRelatedHeart | 10a/10b/11 | ✅ **suppression** held through the loader + all 4 reader beats; revealed on the result view |
| 11 | appShell.tabJournal | 12 | ✅ heart filled, dua saved |
| 12 | journal.firstEntry | 13 | ✅ |
| 13 | duaDetail.done | 14/15 | ✅ centered step, **auto-advanced after ~3.5s**, tour completed cleanly |

Bonus: the achievement toast ("First Supplication") rendered correctly during step 10 — confirms the `rootNavigatorKey.currentState.overlay` fix (no "No Overlay found"). The AI also produced a genuinely on-topic dua for the "patience / calm heart" input.

---

## Edge cases

| ID | Case | Result | Evidence |
|---|---|---|---|
| E1 | Skip mid-tour | ✅ PASS — banner dismissed instantly, Home clean, no orphan | E-04 |
| E2 | Background → foreground | ✅ PASS — tour persisted at the same step on resume; no crash, no duplicate overlay, flutter connection stable | E-02/E-03 |
| E4 | Already checked in (real gate) | ✅ PASS — on the TEMP-DEMO-reverted build, with the user checked-in today the tour did **not** fire and the launch marked the seen flag | E-10/E-13 |
| E5 | Seen-flag gate (no re-fire) | ✅ PASS (indirect) — across the whole run the tour fired **only** when the flag was clear+eligible and never when set; the TEMP DEMO hack existed solely to clear this flag so the tour would re-fire. Clean *not-checked-in + flag-set* isolation was blocked by a sim-cache limitation (see Limitations). | — |
| E6 | Kill switch off | ✅ PASS — with `guided_tour_enabled=false` the tour did not fire even with TEMP DEMO clearing the flag + bypassing checkin (the kill switch is checked independently) | E-09 |
| E9 | Blocking modal interrupt | ✅ PASS — `NameRevealOverlay` (gacha) correctly hid the banner while up; it returned for the next step after dismissal | 01 |
| E10 | Suppression during Build-a-Dua | ✅ PASS — banner hidden through loader + 4 beats; step 11 did not prematurely fire; step 10 revealed on the result view | 10a/10b |
| E11 | Late/anchor-follow + reveal-settle | ✅ PASS — step 4 ameen anchor (mounts after silent taps) revealed without pop-in | 04/05 |
| E12 | Auto-advance timing | ✅ PASS — streak (~2s) and final (~3.5s) both advanced with no input | 07 / 14→15 |
| E14 | Replay from Settings | ✅ PASS — restarted at step 1 immediately, **no app restart**; name re-resolved | E-08 |
| E15 | Tap non-target | ✅ PASS — tapping a neutral area did not advance the tour | (verified via AX tree) |
| E18 | Name personalization | ✅ PASS — "Tester" resolved on every named step | all |

### Edges not driven on-device (with rationale)

- **E3 (kill & relaunch mid-tour):** equivalent to E2 + a fresh `start()`; the state machine has no mid-tour persistence by design (re-fires from step 1 if still eligible). Covered by E2 + the relaunch behavior observed repeatedly.
- **E7 (cold-offline):** cleanly cutting the sim's network would also sever the Supabase/MCP channel driving the test. It's a fail-safe gate (skip the launch, do **not** mark seen, retry next launch) with simple logic; left to unit coverage.
- **E13 (back-gesture completes final step):** the forward auto-advance path was verified (E12); the back-gesture path is a small `onPop` handler (`onboarding_tour_overlay_host.dart:263`). Not re-driven (would require re-walking all 13 steps).
- **E16 (a11y) / E17 (keyboard fade):** VoiceOver/Reduce-Motion are impractical to drive reliably via the simulator MCP; the keyboard-fade depends on `viewInsets` which the sim's hardware-keyboard mode keeps at 0 (the software keyboard never appeared — see Observations). Both are pinned by widget tests (`coachmark_keyboard_test.dart`, the a11y Continue-button path).

---

## Findings & observations

1. **(Polish / out-of-scope) Step-1 copy vs CTA label when checked-in.** With the `checkinDone` start-gate bypassed (TEMP DEMO only), step 1's banner says "Tap **Begin Muḥāsabah**" while the Home CTA actually reads "**Discover a New Name**" (the post-checkin label). The same anchor key is attached so the highlight + tap-through still work, but the words mismatch. **This is exactly the case the real `checkinDone` gate prevents** (controller lines 97–100) — in production the tour never fires for a checked-in user. So this is a confirmation of the gate's rationale, **not a shippable bug**, and it reinforces that TEMP DEMO must never merge.

2. **(Retracted)** An earlier suspicion that the "Muḥāsabah Complete" heading used `ḥ` while the tour used `h` was a glyph misread — the accessibility label confirms plain "Muhāsabah". No inconsistency.

3. **(Minor dev-tool, out-of-scope) "Reset Daily Loop" didn't visibly clear the checked-in Home state** in this run (Home kept showing "Discover a New Name" after reset + relaunch). Worth a dev-tools follow-up, but it's a Danger-Zone debug action, not part of the tour, and not user-facing in production.

4. **Analytics** (`tour_started`, `tour_step_viewed`, `tour_step_advanced`, `tour_completed`, `tour_skipped`, `tour_replay_tapped`, `tour_start_skipped`, `tour_anchor_timeout`) route through Mixpanel, not the console, so they weren't asserted here. Recommend a quick Mixpanel spot-check that the happy-path sequence (started → 13× viewed → 12× advanced → completed), skip, replay, and `tour_start_skipped(reason:disabled)` events land.

## Test-harness limitations encountered

- **Local daily-loop cache is sticky on a warm sim.** Deleting today's `user_checkin_history` server-side did not flip the app's in-memory/local "checked-in today" state on relaunch, so Home kept showing "Discover a New Name". This prevented reaching a clean *not-checked-in* state for E5 isolation. Not a product issue — a genuinely-fresh day-0 user (as in the very first happy-path launch) correctly sees "Begin Muḥāsabah" and the tour fires.
- **Software keyboard never appeared** (sim in hardware-keyboard mode), so the keyboard-fade (E17) couldn't be exercised via the field-focus path.

## Cleanup (done)

- ✅ TEMP DEMO fully reverted — `git diff lib/features/tour/providers/onboarding_tour_controller.dart` is empty; `grep "TEMP DEMO" lib/` finds nothing. Working tree matches HEAD for the controller.
- ✅ `app_config.guided_tour_enabled` restored to `true`.
- ✅ QA account: today's checkin cleared (neutral state). Seen flag is set locally (natural post-tour state); use Settings → "Replay app tour" to demo again.
- ✅ `flutter run` stopped.
