# Launch overlay `_CheckInStep` widget is unreachable

**Severity:** Low (code cleanup + plan correction)
**File:** `lib/features/daily/screens/daily_launch_overlay.dart` (`_CheckInStep` widget at line 587, `answerCheckin` call at line 804)
**Found:** 2026-04-26 daily-loop edge run (B1, B3)

## Description

`DailyLaunchOverlay` has an internal `_step` field with three branches (0=streak greeting, 1=reward claim, 2=check-in questions). The `_advance()` method:

```dart
void _advance() {
  if (_step == 0 && _rewardClaimed) {
    _dismiss();
  } else if (_step == 0) {
    setState(() => _step = 1);
  } else {
    // After reward claim — dismiss overlay (Muhasabah is on its own screen now)
    _dismiss();
  }
}
```

The `else` branch dismisses the overlay after step 1 instead of advancing to step 2. There is no other code path that sets `_step = 2`. **The `_CheckInStep` widget (line 587, ~250 LOC) and its tap handlers — including the `answerCheckin(option)` call at line 804 — are unreachable in production.**

Comment at line 100 confirms the design change: "After reward claim — dismiss overlay (Muhasabah is on its own screen now)."

## Production muhasabah flow

The shipping flow is:

1. Cold launch → `DailyLaunchOverlay` shows step 0 (streak greeting) → tap Begin → step 1 (reward claim).
2. Tap Claim Reward → reward claimed inline → tap Continue → overlay dismisses.
3. Home → tap "Begin Muḥāsabah" → routes to `/muhasabah`.
4. `MuhasabahScreen` initState calls `discoverName()` (`daily_loop_provider.dart:402`) which **skips all questions**, picks an undiscovered/lowest-tier card, runs gacha animation.

There are no questions. There is no AI call. The `answerCheckin` multi-question path is not reachable through any UI surface.

## Doc impact

- **`docs/manual-test-plan.md` §5** documents "Path A — DailyLaunchOverlay (multi-question check-in): Tap → 4 check-in questions (`answerCheckin`)". This describes a UI that no longer exists. Path B (Home → /muhasabah → discoverName) is the only live path.
- Edge cases B1 (double-tap submit on final answer) and B3 (background during AI loading on Q4) target the dead path. Both are obsolete-by-design until the multi-question flow returns.

## Fix

1. **Delete `_CheckInStep`** widget and its `_buildQuestionStep` helper from `daily_launch_overlay.dart`. Remove the `_ => _CheckInStep(...)` fall-through in the `switch (_step)` block. Remove all imports that become unused (`HapticFeedback` may still be needed elsewhere — check).
2. **Update `daily_loop_provider.dart`** `answerCheckin` doc comment from "legacy — used by deeper reflection" to "DEPRECATED — multi-question flow removed; preserved only for the latent re-entry-guard concern (see finding 2026-04-26-answercheckin-no-reentry-guard.md). Delete with the next muhasabah refactor unless reintroducing multi-question UI."
3. **Patch `docs/manual-test-plan.md` §5**: drop the Path A description; merge the canonical flow into a single description matching the current shipping behavior; remove edge cases B1, B3 (or rewrite them against the discoverName path — note that discoverName has its own potential re-entry race that should be regression-checked).

## Status: FIXED (verified 2026-07-26)

`_CheckInStep` / `_buildQuestionStep` have been removed from `daily_launch_overlay.dart`; the `switch (_step)` block now only builds `_StreakGreetingStep` and `_RewardClaimStep` (no check-in branch).

- [x] Remove dead widget
- [ ] Update provider doc comment
- [ ] Patch manual-test-plan §5
