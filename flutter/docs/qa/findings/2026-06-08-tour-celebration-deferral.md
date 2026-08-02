# Finding: guided tour felt slow/stuck — celebration overlays interrupt it; deferred to after the tour

- **Found:** 2026-06-08 (user-reported "Collection step takes a very long time to show")
- **Severity:** Medium (onboarding UX — the forced tour stalls behind celebration modals)
- **Status:** Fixed
- **Component:** Guided tour × economy/quest/achievement celebrations
  (`lib/widgets/app_shell.dart`, `lib/services/achievement_checker.dart`,
  `lib/features/tour/providers/deferred_celebrations_provider.dart`)

## Root cause (corrected)

Instrumenting the reveal-settle on-device (release-like timing wasn't possible —
iOS sims only run debug) showed every tour coachmark reveals in **~415–500ms**.
The "Collection step took ~2.5s" was **not** the reveal gate. The slow step was
whichever one happened to coincide with a **blocking celebration overlay**:

- `LevelUpOverlay` (rank-up), pushed by `AppShell` on an `XpGranted{leveledUp}`.
- `FirstStepsOverlay` (bundle), quest-completion toasts, achievement toasts.

The tour route observer treats the modal celebrations as **blocking routes**, so
while one is up the next coachmark is correctly suppressed — but the user has to
dismiss the celebration first, which reads as the tour being stuck. During the
forced first-run tour the user earns a rank-up + several quest/achievement
unlocks, so these pile onto the coachmark flow. Proven in the instrumented run:
the one slow step (`returnHome`, ~2500ms) was blocked by the rank-up overlay
while it was on screen.

## Fix — defer during the tour, replay after

While the guided tour is **active**, celebrations are withheld into a queue
instead of shown, then replayed on the **first home arrival after the tour**
(the trailing hard paywall clears first; product decision 2026-06-08).

- `deferred_celebrations_provider.dart` — a `StateNotifier<List<DeferredCelebration>>`
  (`LevelUpCelebration` / `FirstStepsCelebration` / `QuestToastCelebration` /
  `AchievementToastCelebration`) + `shouldDeferCelebrations(ref)` (= tour active).
- Each push site (`AppShell`: level-up, bundle, standard + beginner quest toasts;
  `achievement_checker.checkAchievements`) now: **if tour active → enqueue; else →
  show immediately, exactly as before.** Analytics still fire during the tour;
  only the visual celebration is withheld.
- **Drain:** `AppShell._maybeDrainDeferredCelebrations` runs from `build` (post-
  frame). `AppShell` only builds for tab routes, and at tour-completion it
  transitions to the paywall **without** an `AppShell` rebuild — so the queue
  naturally drains on the next build, i.e. the post-paywall home remount, never
  prematurely. Guards: tour resolved, no blocking route on top, a `_draining`
  re-entry latch, and atomic `takeAll()`.

### Sequential replay UX

Modals (`LevelUpOverlay`, `FirstStepsOverlay`) replay **one at a time, awaited**
so the headline rewards lead and never overlap; then the ambient toasts flush
through the **existing** `_toastQueue` (achievement_toast.dart), which already
sequences them FIFO with auto-dismiss + dedup. No new toast sequencing invented.

### Kept inline (intentionally NOT deferred)

- The muhāsabah **card reveal** (`NameRevealOverlay`) — it's the primary result
  of the muhāsabah the tour is literally guiding; deferring it would mean doing a
  muhāsabah and not seeing your Name.
- Gates (`DailyLaunchOverlay`, `LapsedTrialSheet`) — not celebrations.

## Also fixed

`onboarding_tour_overlay_host.dart`: the F-12 max-settle ceiling timer is now
cancelled when the normal settle wins, so it no longer fires a redundant (and,
in logs, misleading) late "reveal" on every step. Temporary timing
instrumentation removed.

## Tests

- `test/features/tour/deferred_celebrations_provider_test.dart` — queue FIFO +
  `takeAll` clears + no double-drain.
- `test/widgets/app_shell_deferred_celebrations_test.dart` — (1) a level-up is
  withheld + queued while the tour is active; (2) it replays on the first
  post-tour `AppShell` build and the queue drains exactly once.
- Regression-checked: existing `app_shell_level_up_overlay_test` (non-tour path
  still shows celebrations immediately) + full tour/daily/quests suites — 213
  pass, analyzer clean.

## Not yet verified on-device

Covered by tests; an on-device re-run of the full fresh-tour would confirm the
end-to-end replay (deferred until the post-paywall home). Deferred to avoid
another full onboarding drive unless requested.
