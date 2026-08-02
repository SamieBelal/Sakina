# answerCheckin has no re-entry guard

**Severity:** P1 (latent — code path is currently unreachable in production UI; see F2)
**File:** `lib/features/daily/providers/daily_loop_provider.dart:465-624`
**Found:** 2026-04-26 daily-loop edge run (B1)

## Description

`DailyLoopNotifier.answerCheckin(String answer)` advances the muhasabah multi-question flow. On the final question (`currentIndex == 3`) it triggers an OpenAI call, persists the answer to `user_checkin_history`, marks the streak, and claims the daily reward. The function has **no protection against concurrent invocation**.

## Race trace

Two rapid invocations on the final question:

1. **Tap 1 (sync):** reads `state.checkinQuestionIndex == 3`, builds `updatedAnswers = [a,b,c,d]`, calls `state = state.copyWith(checkinAnswers: ..., checkinLoading: true)`, then awaits `getDailyResponse`.
2. **Tap 2 (during the await of Tap 1):** reads `state.checkinQuestionIndex == 3` (unchanged — the final-branch sets `checkinAnswers` and `checkinLoading` but not the index), builds `updatedAnswers = [a,b,c,d,d]`, calls `state.copyWith` again, also awaits `getDailyResponse`.

Both invocations run to completion. Both call `saveCheckinRecord(...)` → **two `user_checkin_history` rows for today**. Both call `_markStreakAndHandleMilestones()` → double streak mark, possibly double XP/scrolls grant if milestone fires. Both call `claimDailyReward()` (server-side idempotent — single grant — but still two RPC roundtrips).

## Why it doesn't bite users today

The launch overlay (`daily_launch_overlay.dart`) used to render a `_CheckInStep` widget with the question UI that called `answerCheckin`. The current overlay's `_advance()` only transitions `_step` 0 → 1, then dismisses on next tap. **The `_step == 2` branch is never entered**, so `_CheckInStep` (and its `answerCheckin` calls) is dead code. See finding `2026-04-26-launch-overlay-dead-checkinstep.md`.

The race is real. The trigger is gone. If the multi-question flow is ever reintroduced (the inventory of `answerCheckin` is preserved as "legacy — used by deeper reflection" per the in-file comment), the bug will surface immediately.

## Fix (one line)

```dart
Future<void> answerCheckin(String answer) async {
  if (state.checkinLoading) return;  // re-entry guard
  final currentIndex = state.checkinQuestionIndex;
  // ... existing logic
}
```

The early return covers both windows:
- Concurrent calls during the AI/persist await on the final question (the documented race).
- Concurrent calls during a synchronous index-advance (no-op race, but harmless to guard).

## Test

A widget test of the guard requires `DailyLoopNotifier` to accept service dependencies (currently constructs them via top-level imports — no DI seam). Two paths forward:
1. **Refactor `DailyLoopNotifier`** to take services as constructor params (estimated 30 min).
2. **Inject test-only static overrides** on `getDailyResponse`/`saveCheckinRecord` via a flag in `lib/services/`.

For now the guard ships without an automated test. Add the regression test when the multi-question flow is reintroduced (and DI is available), or as part of a separate refactor.

## Status: FIXED (verified 2026-07-26)

Re-entry guard `if (state.checkinLoading) return;` is present at the top of `answerCheckin` in `daily_loop_provider.dart` (line 659). The path also remains dormant (no live callers).

- [x] Apply guard to `answerCheckin`
- [ ] Capture in `docs/testing-plan.md` §4 as a known re-entry hazard requiring a guard pattern across daily-loop notifier methods
