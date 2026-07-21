// Regression guard: StreakMilestoneOverlay must cancel pending phase timers
// on dispose so a dismissed overlay can't fire HapticFeedback.heavyImpact()
// or setState() on a dead State.
//
// Background:
//   The original `_runSequence` used three bare `await Future.delayed(...)` calls
//   (lines 93, 100, 105 of the pre-fix file). These schedule internal Dart Timers
//   with no handle to cancel. If the overlay is popped while any delay is
//   pending, the continuation runs after disposal:
//     - `HapticFeedback.heavyImpact()` fires on a dead route.
//     - `setState(() => _phase = N)` is called on a disposed State, triggering
//       the Flutter framework error "setState() called after dispose()".
//
//   `LevelUpOverlay` already solves this with a `List<Timer> _pendingTimers`
//   cancelled in `dispose()` (see `level_up_overlay.dart` lines 69–120).
//
// Fix contract tested here (structural assertions, same approach as
// `level_up_overlay_phase_gate_test.dart` and `name_reveal_overlay_phase_gate_test.dart`
// — full widget-pump is not viable because Lottie.asset + google_fonts +
// flutter_animate continuous loops can't be drained by pumpAndSettle):
//
//   A. `_pendingTimers` list is declared on the State.
//   B. `_schedulePhase` helper adds to `_pendingTimers`.
//   C. `dispose()` cancels every timer in `_pendingTimers`.
//   D. Each scheduled callback guards with `if (!mounted) return;`.
//   E. No bare `await Future.delayed(...)` remain in `_runSequence`.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File(
    'lib/features/daily/widgets/streak_milestone_overlay.dart',
  ).readAsStringSync();

  test(
    'A: _pendingTimers list is declared on _StreakMilestoneOverlayState '
    '(cancelable timer registry — absent before fix)',
    () {
      // Must declare a List<Timer> field named _pendingTimers.
      final pattern = RegExp(r'List<Timer>\s+_pendingTimers\s*=\s*\[\]');
      expect(pattern.hasMatch(source), isTrue,
          reason:
              '`_pendingTimers` field not found. The fix requires a '
              '`final List<Timer> _pendingTimers = [];` field on '
              '_StreakMilestoneOverlayState so dispose() can cancel any '
              'timer that has not yet fired.');
    },
  );

  test(
    'B: _schedulePhase helper adds Timer to _pendingTimers '
    '(mirrors level_up_overlay.dart pattern)',
    () {
      // Must have a _schedulePhase method that calls Timer() and adds to list.
      final pattern = RegExp(r'void\s+_schedulePhase\s*\(');
      expect(pattern.hasMatch(source), isTrue,
          reason:
              '`_schedulePhase` helper not found. The fix requires a helper '
              'that wraps `Timer(offset, callback)` and appends to '
              '_pendingTimers — mirroring LevelUpOverlay._schedulePhase.');

      // The timer must be added to _pendingTimers.
      final addsToList = source.contains('_pendingTimers.add(Timer(');
      expect(addsToList, isTrue,
          reason:
              '`_pendingTimers.add(Timer(...)` not found. _schedulePhase must '
              'append the Timer to _pendingTimers so dispose() can cancel it.');
    },
  );

  test(
    'C: dispose() cancels all timers in _pendingTimers '
    '(prevents post-dispose setState / haptic after overlay is popped)',
    () {
      // dispose must iterate _pendingTimers and cancel each.
      final cancelPattern = RegExp(
        r'for\s*\(.*_pendingTimers\s*\)[\s\S]*?\.cancel\(\)',
      );
      final hasCancel =
          cancelPattern.hasMatch(source) || source.contains('.cancel()');
      expect(hasCancel, isTrue,
          reason:
              'dispose() does not cancel pending timers. Without timer '
              'cancellation, if the overlay is popped before a phase fires, '
              'the callback runs on a disposed State and triggers '
              '`setState() called after dispose()`.');

      // Belt-and-braces: the cancel must be inside dispose().
      final disposeCancels = RegExp(
        r'void\s+dispose\(\)\s*\{[\s\S]*?cancel\(\)[\s\S]*?super\.dispose\(\)',
      ).hasMatch(source);
      expect(disposeCancels, isTrue,
          reason:
              'Timer.cancel() must appear inside the dispose() override, '
              'before super.dispose(), so the callback guard on `mounted` '
              'has consistent semantics.');
    },
  );

  test(
    'D: each scheduled callback guards with `if (!mounted) return;` '
    '(defence-in-depth against stale callbacks)',
    () {
      // The `mounted` guard inside _schedulePhase callback mirrors level_up_overlay.
      final pattern = RegExp(r'if\s*\(!mounted\)\s*return\s*;');
      expect(pattern.hasMatch(source), isTrue,
          reason:
              '`if (!mounted) return;` guard not found. Even with timer '
              'cancellation, the guard is defence-in-depth: if a callback '
              'races with dispose() it exits before calling setState().');
    },
  );

  test(
    'E: no bare `await Future.delayed` in _runSequence '
    '(the original bug — uncancelable Timers)',
    () {
      final bareDelayed = RegExp(r'await\s+Future\.delayed\s*\(');
      expect(bareDelayed.hasMatch(source), isFalse,
          reason:
              'Found `await Future.delayed(...)` — this is the pre-fix '
              'pattern that schedules uncancelable Timers. Replace all '
              'phase delays with `_schedulePhase(offset, callback)` so '
              'dispose() can cancel them.');
    },
  );
}
