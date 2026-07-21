// Regression test: streak-milestone celebration must not be silently dropped
// when the user backs out of BeatRevealFlow without completing (taps the left
// zone at beat 0 → onReturnHome → context.go('/')) before tapping "Ameen".
//
// Background:
//   `_markStreakAndHandleMilestones` fires during `discoverName()` (the gacha /
//   checkin phase) and sets `state.streakMilestoneReached = true`. The
//   `ref.listen` in `muhasabah_screen.dart` only fires the celebration when
//   `currentStep` transitions to `completed` (after the user taps "Ameen" →
//   `completeDeeper()`). If the user backs out before Ameen, `completeDeeper()`
//   is never called, the `completed` transition never fires, and the milestone
//   overlay is silently dropped — the milestone was already claimed server-side
//   (XP + scrolls awarded, `checkStreakMilestones` idempotency guard consumed)
//   but the user never sees the celebration.
//
// Fix contract tested here:
//   1. When streakMilestoneReached is set and back-out occurs without
//      completeDeeper(), the flag stays true — proving the undrained bug.
//   2. clearStreakMilestone() drains the flag atomically.
//   3. completeDeeper() advances to `completed` while leaving
//      streakMilestoneReached set (for the ref.listen listener), then
//      clearStreakMilestone() from the overlay onContinue clears it exactly once.
//   4. StreakMilestoneCelebration enqueues and drains exactly once from
//      deferredCelebrationsProvider.
//   5. Source: muhasabah_screen onReturnHome checks streakMilestoneReached
//      and enqueues StreakMilestoneCelebration.
//   6. Source: app_shell drains StreakMilestoneCelebration.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/tour/providers/deferred_celebrations_provider.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(
      FakeSupabaseSyncService(userId: 'user-A'),
    );
  });

  tearDown(SupabaseSyncService.debugReset);

  // ─────────────────────────────────────────────────────────────────────────
  // 1. State invariant — the flag stays set until explicitly cleared
  // ─────────────────────────────────────────────────────────────────────────

  test(
    'streakMilestoneReached stays true on back-out (no implicit drain exists)',
    () {
      final notifier = DailyLoopNotifier(skipInitForTests: true);

      notifier.debugSetStreakMilestone(streak: 7, xp: 100, scrolls: 1);

      expect(notifier.state.streakMilestoneReached, isTrue,
          reason: 'flag must be set after debugSetStreakMilestone');
      expect(notifier.state.streakMilestoneCount, 7);
      expect(notifier.state.streakMilestoneXp, 100);
      expect(notifier.state.streakMilestoneScrolls, 1);

      // Back-out: currentStep never becomes completed.
      expect(notifier.state.currentStep, isNot(DailyLoopStep.completed),
          reason: 'back-out does not complete the loop');

      // BUG (pre-fix): the flag stays true with no mechanism to surface it.
      expect(notifier.state.streakMilestoneReached, isTrue,
          reason:
              'streakMilestoneReached is still true after back-out — '
              'nothing consumed it without the fix');

      notifier.dispose();
    },
  );

  // ─────────────────────────────────────────────────────────────────────────
  // 2. clearStreakMilestone atomically clears all milestone fields
  // ─────────────────────────────────────────────────────────────────────────

  test('clearStreakMilestone resets all milestone fields to defaults', () {
    final notifier = DailyLoopNotifier(skipInitForTests: true);

    notifier.debugSetStreakMilestone(streak: 7, xp: 100, scrolls: 1);
    notifier.clearStreakMilestone();

    expect(notifier.state.streakMilestoneReached, isFalse);
    expect(notifier.state.streakMilestoneCount, 0);
    expect(notifier.state.streakMilestoneXp, 0);
    expect(notifier.state.streakMilestoneScrolls, 0);

    notifier.dispose();
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 3. Normal completion path: completeDeeper preserves the flag for listener
  // ─────────────────────────────────────────────────────────────────────────

  test(
    'completeDeeper → currentStep=completed while streakMilestoneReached stays '
    'true (ref.listen fires overlay; clearStreakMilestone runs on dismiss)',
    () async {
      final notifier = DailyLoopNotifier(skipInitForTests: true);

      notifier.debugSetStreakMilestone(streak: 14, xp: 200, scrolls: 2);
      notifier.debugSetCheckinDoneForReset(
        checkinName: 'Ar-Rahman',
        checkinNameArabic: 'الرَّحْمَن',
      );

      expect(notifier.state.streakMilestoneReached, isTrue);

      await notifier.completeDeeper();

      expect(notifier.state.currentStep, DailyLoopStep.completed,
          reason: 'completeDeeper advances to completed');
      expect(notifier.state.streakMilestoneReached, isTrue,
          reason:
              'completeDeeper must NOT clear the milestone — the ref.listen '
              'listener reads it on the completed-step edge and the overlay '
              'onContinue calls clearStreakMilestone exactly once');

      // Overlay dismissed → clearStreakMilestone called.
      notifier.clearStreakMilestone();
      expect(notifier.state.streakMilestoneReached, isFalse,
          reason: 'flag cleared exactly once after overlay dismiss');

      notifier.dispose();
    },
  );

  // ─────────────────────────────────────────────────────────────────────────
  // 4. Deferred queue: StreakMilestoneCelebration round-trip
  // ─────────────────────────────────────────────────────────────────────────

  test(
    'StreakMilestoneCelebration enqueues, drains exactly once, no double-drain',
    () {
      final queue = DeferredCelebrationsNotifier();

      queue.enqueue(
        const StreakMilestoneCelebration(streak: 7, xp: 100, scrolls: 1),
      );

      expect(queue.state, hasLength(1));
      final item = queue.state.first;
      expect(item, isA<StreakMilestoneCelebration>());
      final milestone = item as StreakMilestoneCelebration;
      expect(milestone.streak, 7);
      expect(milestone.xp, 100);
      expect(milestone.scrolls, 1);

      final drained = queue.takeAll();
      expect(drained, hasLength(1));
      expect(queue.state, isEmpty, reason: 'queue is empty after first drain');

      final second = queue.takeAll();
      expect(second, isEmpty, reason: 'idempotent: second drain returns empty');
    },
  );

  // ─────────────────────────────────────────────────────────────────────────
  // 5. Source: onReturnHome checks streakMilestoneReached and enqueues
  // ─────────────────────────────────────────────────────────────────────────

  test(
    'muhasabah_screen onReturnHome reads streakMilestoneReached and enqueues '
    'StreakMilestoneCelebration before navigating home',
    () {
      final source =
          File('lib/features/daily/screens/muhasabah_screen.dart')
              .readAsStringSync();

      // The onReturnHome closure must contain a check for streakMilestoneReached.
      final hasCheckInCallback = RegExp(
        r'onReturnHome\s*:\s*\(\)\s*\{[\s\S]*?streakMilestoneReached[\s\S]*?\}',
      ).hasMatch(source);
      expect(hasCheckInCallback, isTrue,
          reason:
              'onReturnHome callback must check state.streakMilestoneReached '
              'to handle the back-out case (BeatRevealFlow exit without Ameen). '
              'Without this check the milestone celebration is silently dropped.');

      expect(source.contains('StreakMilestoneCelebration'), isTrue,
          reason:
              'muhasabah_screen must reference StreakMilestoneCelebration to '
              'enqueue it on back-out so Home can drain and display it.');
    },
  );

  // ─────────────────────────────────────────────────────────────────────────
  // 6. Source: app_shell drains StreakMilestoneCelebration
  // ─────────────────────────────────────────────────────────────────────────

  test(
    'app_shell._maybeDrainDeferredCelebrations handles StreakMilestoneCelebration',
    () {
      final source = File('lib/widgets/app_shell.dart').readAsStringSync();

      expect(source.contains('StreakMilestoneCelebration'), isTrue,
          reason:
              'app_shell must handle StreakMilestoneCelebration in its '
              'deferred-celebration drain loop, otherwise enqueued milestones '
              'from the back-out path are silently discarded.');
    },
  );
}
