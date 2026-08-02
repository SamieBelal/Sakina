# Guided Onboarding Tour — Simulator Test Plan

**Date:** 2026-05-31
**Branch:** `onboarding-trim-and-guided-tour`
**Feature under test:** 13-step interactive guided tour (`lib/features/tour/` + `lib/widgets/coachmark/`)
**Driver:** iOS Simulator MCP (`mcp__ios-simulator__*`) + Supabase MCP (state setup/reset) + Mixpanel MCP (analytics verification, optional)

---

## 0. What we're testing and why

The tour is an **interactive coach-banner walkthrough** that fires once per user after onboarding,
on the first Home view of the day **before** they've checked in. It drives the user through the core
loop: Home → Muḥāsabah → Collection → Duas → Journal. Most steps advance on a **real tap** that also
drives app navigation (tap-through). Two steps (streak, final wrap-up) auto-advance with no input.

The risk surface is not "does the happy path render" — it's the **state machine + lifecycle edges**:
what happens when the user leaves, backgrounds, kills the app, hits a modal mid-tour, scrolls the
anchor off-screen, has already checked in, has the kill switch off, or runs a screen reader. This
plan covers all of them.

### Implementation facts that shape the tests (verified in source)

| Fact | Location | Test implication |
|---|---|---|
| Tour `start()` fires from Home/Progress tab `initState`, **chained after `DailyLaunchOverlay` dismissal** | `progress_screen.dart:119-122` | Must land on Home with daily launch resolved before tour can fire |
| 6 start gates: auth user · status idle · seen-flag unset · `dailyLoopProvider.loaded` · **NOT checked in today** · `guided_tour_enabled` kill switch true | `onboarding_tour_controller.dart:70-119` | Each gate is its own negative test |
| **TEMP DEMO** in working tree force-clears the seen flag + bypasses the `checkinDone` gate every launch | `onboarding_tour_controller.dart:77-100` | Leave IN for happy-path; must be **reverted** to test the gates themselves |
| Seen flag key: `onboarding_tour_v1_seen_<userId>` (SharedPreferences) | `onboarding_tour_controller.dart:50-52` | Inspect/clear via app relaunch or plist |
| Blocking routes hide the overlay: `NameRevealOverlay`, `LevelUpOverlay`, `LapsedTrialSheet`, `FirstStepsOverlay`, `DailyLaunchOverlay` | `tour_route_observer.dart:21-27` | Modal-interrupt test |
| Suppression flag pauses the tour during the Duas "Build a Dua" inline flow | `duas_screen.dart:75-106`, `tourSuppressedProvider` | Step 10 (`firstRelatedHeart`) must wait for the result view |
| Anchor-timeout = **60s**, then `advance(via:'anchor_timeout')` | `onboarding_tour_overlay_host.dart:400` | Stuck-anchor fallback test |
| Reveal-settle: 400ms min + rect stability before banner shows | `onboarding_tour_overlay_host.dart:32` | No pop-in over animating screens |
| Auto-advance: **streak 2000ms**, **final 3500ms**; suppressed under `accessibleNavigation` (shows Continue) and while keyboard open | `onboarding_tour_step.dart:151,229`; `coachmark_overlay.dart` | Timing + a11y + keyboard tests |
| Back-gesture on `DuaDetailPage` completes the final step | `onboarding_tour_overlay_host.dart:263-267` | Back-swipe completion test |
| Replay from Settings clears flag → `context.go('/')` → `replay()` (no app restart) | `settings_screen.dart:133-146` | Replay test |
| `{name}` personalization; falls back to no-name copy if name missing | `onboarding_tour_overlay_host.dart:42-52` | Greeting/name test |
| Analytics: `tour_started`, `tour_step_viewed`, `tour_step_advanced`, `tour_completed`, `tour_skipped`, `tour_replay_tapped`, `tour_anchor_timeout`, `tour_start_skipped` | `analytics_events.dart:197-204` | Verify per scenario |

### The 13 steps (canonical order — `onboarding_tour_step.dart`)

| # | id | surface | anchor | interactive | notes |
|---|---|---|---|---|---|
| 1 | home.beginMuhasabah | home | beginMuhasabahCta | tap | Islamic greeting + `{name}` |
| 2 | muhasabah.goDeeper | muhasabah | goDeeperCta | tap | |
| 3 | muhasabah.readStory | muhasabah | readStoryCta | tap | "See the Dua" step intentionally omitted |
| 4 | muhasabah.ameen | muhasabah | ameenCta | tap | anchor mounts late (after silent Story→Dua taps) |
| 5 | muhasabah.returnHome | muhasabah | returnHomeCta | tap | |
| 6 | home.streakPill | home | streakPill | **auto (2s)** | read-only beat |
| 7 | appShell.tabCollection | appShell | tabCollection | tap | cutout grows to full tab cell |
| 8 | appShell.tabDuasFromCollection | appShell | tabDuas | tap | |
| 9 | duas.buildCta | duas | buildCta | tap | cutout extends 280pt up to cover text field |
| 10 | duas.firstRelatedHeart | duas | firstRelatedHeart | tap | **suppressed until Build result view** |
| 11 | appShell.tabJournalFromDuas | appShell | tabJournal | tap | |
| 12 | journal.firstEntry | journal | firstEntry | tap | |
| 13 | duaDetail.done | duaDetail | centered | **auto (3.5s)** | centered banner; back-gesture also completes |

---

## 1. Environment & preconditions

- **Simulator:** iPhone 16, UDID `F0259F3A-84BB-470D-8B13-168C566C9CDF` (boot via `mcp__ios-simulator__open_simulator` if not booted; confirm with `get_booted_sim_id`).
- **Build/run:** `flutter run -d F0259F3A-84BB-470D-8B13-168C566C9CDF --dart-define-from-file=env.json` (run in background; **never** omit `env.json`). Use hot-restart (`R`) between scenarios where a code toggle changes (e.g. TEMP DEMO revert).
- **Test account:** `sakina.tour.qa@gmail.com` / `abc123`, user_id `f7eb9cb3-61b0-4ead-ae6d-ed9efa54b6dd`, display_name "Tester".
- **Screenshots:** after every `mcp__ios-simulator__screenshot`, immediately `sips -Z 1600 <path>.png` (CLAUDE.md — native @3x trips the image cap). Capture per-step evidence into `docs/qa/runs/2026-05-31-guided-tour/`.
- **Driving:** prefer `mcp__ios-simulator__ui_describe_all` to locate anchors by accessibility frame, then `ui_tap` at the element center. Use `ui_swipe` for scroll tests. `ui_describe_point` to confirm what's under the banner / cutout.

### Per-scenario state reset (Supabase MCP, read-mostly)

Use `mcp__supabase__execute_sql` for the test user `f7eb9cb3-61b0-4ead-ae6d-ed9efa54b6dd`:

- **Reset to "fresh, not-checked-in-today, onboarded":** delete today's rows from `user_checkin_history`; keep onboarding/profile intact; keep starter card (name_id 6, bronze); `user_tokens.balance = 100`.
- **Force "already checked in today":** ensure a `user_checkin_history` row exists with today's date (for gate test #E4).
- The **local seen flag** lives in SharedPreferences (app sandbox plist), not Supabase. Clear it by relaunching with TEMP DEMO active, or `xcrun simctl` plist edit, or the Settings "Replay tour" path.

> All Supabase writes here are **test-data only** on the QA account. No production migrations, no schema changes.

---

## 2. Happy path — full 13-step walkthrough (P0)

**Setup:** TEMP DEMO active (tour fires every launch); test user reset to fresh + not-checked-in.

**Steps:** launch app → land on Home → tour fires at step 1. For each of the 13 steps:

1. Screenshot + `sips`. Record:
   - **Banner placement:** slides in from top-left, not off-screen, not clipping the notch/safe-area, width sane, does not cover the anchor it's pointing at.
   - **Cutout/ring accuracy:** gold ring highlights the *correct* element; for step 9 the 280pt upward extension covers the text field + Build CTA (banner flips to sit over the header, not the input).
   - **Copy:** correct message; `{name}` resolved to "Tester" (steps 1,2,5,8,11,13); Skip visible; no stray "Continue" on tap steps.
   - **Aesthetics:** cream gradient, emerald stripe, gold accent dot, padding generous, corner radius soft (design-system check).
2. Advance via the **real target tap** (tap-through). Confirm the tour advances AND the underlying navigation happens (e.g. tapping Begin Muḥāsabah both advances the tour and routes to `/muhasabah`).
3. For step 4 (`ameenCta`): navigate the silent Story → Dua taps, confirm the Ameen banner appears only once `ameenCta` mounts (reveal-settle gate, no pop-in mid-transition).
4. For step 9→10: type into the dua field, tap Build, confirm the tour is **suppressed** through the loader + 4 reader beats, then step 10 (`firstRelatedHeart`) reveals on the result view.
5. Step 6 (streak): do NOT tap — confirm it **auto-advances after ~2s**.
6. Step 13 (final): confirm centered banner, **auto-advances/dismisses after ~3.5s**, tour reaches `completed`.

**Expected:** all 13 render correctly, navigation drives correctly, tour ends in `completed`, seen flag set. Analytics: `tour_started` → 13× `tour_step_viewed` → 12× `tour_step_advanced` → `tour_completed`.

---

## 3. Edge cases

> For gate tests (E4–E7), **revert the TEMP DEMO first** (restore the real seen-flag check + `checkinDone` guard) and hot-restart — otherwise the demo bypass masks the gate.

### E1 — Skip mid-tour
Mid-tour (e.g. step 3), tap **Skip tour**. Expect: overlay disappears immediately, tour status `skipped`, seen flag set. Relaunch → tour does **not** re-fire. Analytics: `tour_skipped` with `at_step_id`, user property `tour_home_skipped_at` set.

### E2 — Background the app mid-tour (lifecycle)
Mid-tour, send app to background (`ui_swipe` up / home), wait, foreground. Expect: tour resumes at the same step, banner re-reveals (no crash, no duplicate overlay, no "No Overlay found"). Check the tracking ticker re-engages and the cutout re-locks onto the anchor.

### E3 — Kill & relaunch mid-tour
Mid-tour, **terminate** the app (`launch_app` after kill / simctl terminate), relaunch.
- With TEMP DEMO active: tour restarts at step 1 (flag cleared each launch — expected demo behavior).
- With TEMP DEMO reverted: seen flag is **not** set until completion/skip, so the tour fires again from step 1 on relaunch (state machine has no mid-tour persistence). Document this as the actual behavior; confirm no crash and a clean start.

### E4 — Already checked in today (gate)
Revert TEMP DEMO. Seed a `user_checkin_history` row for today. Relaunch. Expect: tour does **NOT** fire; seen flag is set (so it won't retry every launch). Confirms the day-0-only invariant from CLAUDE.md.

### E5 — Seen flag already set (gate)
Revert TEMP DEMO. Complete the tour once (flag set). Relaunch. Expect: tour does not fire. No analytics `tour_started`.

### E6 — Server kill switch off (gate)
Set `app_config.guided_tour_enabled = false` (Supabase MCP). Revert TEMP DEMO, reset user to eligible. Relaunch. Expect: tour does NOT fire; analytics `tour_start_skipped` with `reason: disabled`; seen flag **not** set (so flipping the switch back on later still lets it fire). Then flip back to `true`, relaunch → tour fires. **Restore `true` when done.**

### E7 — Cold-offline / daily loop never loads
Enable Airplane Mode on the sim before launch (or block network). Expect: `start()` waits up to ~1s for `dailyLoopProvider.loaded`; if it never loads, tour is skipped this launch and seen flag is **not** set (retries next launch). Re-enable network, relaunch → tour fires.

### E8 — Anchor never appears → 60s timeout
Force a step whose anchor can't mount (e.g. navigate away from the expected surface and stay). Expect: after 60s the step `advance(via:'anchor_timeout')`; analytics `tour_anchor_timeout` with `step_id`. (Optionally temporarily shorten the timer locally to avoid a 60s wait, then revert.)

### E9 — Blocking modal interrupts the tour
Trigger a blocking route while the tour is active (e.g. `NameRevealOverlay` / `LevelUpOverlay` on the muhasabah reveal, or `LapsedTrialSheet`). Expect: tour banner + ring **hide** (`SizedBox.shrink`) while the modal is on top, the achievement/level toast renders correctly, and when the modal pops the banner **re-appears** for the current step. Confirms the route-observer guard and that the anchor-timeout is paused while blocked.

### E10 — Suppression during Build-a-Dua flow
At step 9, type + tap Build. Through the loader and the 4 reader beats, confirm: banner is hidden (`tourSuppressedProvider == true`), step 11 (Journal tab) does **not** prematurely fire, and step 10 reveals only on the final result view (`buildCurrentSection == 4`). Leave the Duas screen and confirm suppression resets to false.

### E11 — Scroll: cutout follows anchor
On a scrollable surface (Collection / Journal / Duas result), scroll so the anchor would move. Expect: the per-frame tracking ticker keeps the gold ring locked onto the anchor; auto-scroll-into-view centers an off-fold anchor once per step activation; banner doesn't detach or jitter.

### E12 — Auto-advance timing
Step 6 streak: measure dwell ≈ 2.0s before auto-advance. Step 13 final: measure ≈ 3.5s. Neither should require a tap. (Use screenshots with timestamps or `record_video` to verify timing.)

### E13 — Back-gesture completes final step
At step 13 (`duaDetail.done`), instead of waiting for auto-advance, **swipe back** to pop `DuaDetailPage`. Expect: `advance(via:'back_gesture')`, tour completes cleanly, no orphaned overlay.

### E14 — Replay tour from Settings (no restart)
Complete or skip the tour. Go to Settings → **Replay app tour**. Expect: immediately (no app restart) routes to Home and restarts at step 1 with the banner showing; name re-resolves; analytics `tour_replay_tapped` + `tour_started` (`via: replay`). This pins commit `da01c47` (replay re-fires without restart).

### E15 — Tap a non-target element
While a tap step is active, tap somewhere that is **not** the highlighted target (and not Skip). Expect: tour does NOT advance; the tap either passes through harmlessly or is absorbed by the scrim; the highlighted target remains the only advance affordance (besides Skip).

### E16 — Accessibility
Enable **VoiceOver** (or set `accessibleNavigation`): expect auto-advance steps (6, 13) show a **Continue** button instead of timing out, and tap steps remain operable. Also spot-check **Reduce Motion** (reveal-settle gates bypassed, banner appears immediately, no slide), **Bold Text**, and **Larger Text** (Dynamic Type) — banner text must not clip or overflow.

### E17 — Keyboard open on Build step
At step 9, focus the dua text field so the keyboard opens. Expect: banner **fades out** (opacity 0, IgnorePointer ignoring) and auto-advance (if any) is suppressed while the keyboard is up; banner returns when keyboard dismisses. Pins `coachmark_keyboard_test.dart`.

### E18 — Name personalization fallback
Test with display_name present ("Tester") → greeting reads "Assalamu alaikum, Tester 👋". Then with name missing/empty (temporarily clear display_name or simulate `GatingService.displayName()` failure) → copy strips `{name}` cleanly ("Assalamu alaikum 👋"), no dangling comma.

---

## 4. Visual QA pass (per step, P1)

Across the happy path, evaluate against the design system (warm, premium, generous whitespace):
- No text truncation/overflow; banner respects notch + home indicator safe-areas.
- Ring/cutout corner radii soft; glow subtle; no harsh dim.
- Step 9 wide-cutout + step 13 centered banner are the two highest-risk layouts — verify width and placement explicitly.
- Arabic in "Muḥāsabah" / "Prophets ﷺ" renders without RTL bleed into the banner.

Record each as a labeled, `sips`-downscaled screenshot.

---

## 5. Analytics verification (P2, optional via Mixpanel MCP)

After the runs, confirm the event sequence per scenario:
- Happy path: `tour_started` → 13× `tour_step_viewed` → 12× `tour_step_advanced` (with `via` = `target_tap` mostly, `continue` for a11y) → `tour_completed`.
- Skip: `tour_skipped`. Disabled: `tour_start_skipped`. Timeout: `tour_anchor_timeout`. Replay: `tour_replay_tapped` + `tour_started(via:replay)`.
- `via` values are correct: `target_tap` | `continue` | `back_gesture` | `anchor_timeout`.

---

## 6. Cleanup (mandatory)

1. **Revert the TEMP DEMO** in `onboarding_tour_controller.dart` (restore real seen-flag check at line ~80, restore the `checkinDone` guard at ~97-100, remove `prefs.remove(flag)`). Confirm `git diff` is clean of "TEMP DEMO".
2. **Restore** `app_config.guided_tour_enabled = true` if E6 left it false.
3. **Reset** the QA user's test data (clear seeded checkin rows) to a known-good state.
4. Re-enable network / disable VoiceOver / Reduce Motion / Bold Text on the sim.
5. `flutter analyze` clean (expected baseline) and `flutter test` green.

---

## 7. Pass/fail criteria

**Pass** = happy path completes all 13 steps with correct nav + placement; E1–E18 each behave as specified above; no crashes, no "No Overlay found", no orphaned overlay, no double-fire; analytics sequences correct; visual QA shows no overflow/clipping; working tree clean of TEMP DEMO at end.

**Deliverable** = per-step + per-edge findings with screenshot evidence in `docs/qa/runs/2026-05-31-guided-tour/`, a severity-ranked bug list (Critical/High/Medium/Polish), and a ship-readiness verdict. No bug-fix commits unless explicitly requested after findings are reviewed.
