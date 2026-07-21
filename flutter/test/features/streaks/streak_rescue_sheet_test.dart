// Widget test for the rate-limited (and related) branches of _StreakRescueSheet.
//
// Bug pinned: after Navigator.of(context).pop() the sheet's element is
// deactivated, so ScaffoldMessenger.of(context) would throw
// "Looking up a deactivated widget's ancestor is unsafe" on the rateLimited
// branch. The fix is to capture `messenger` BEFORE pop — this test drives
// that branch and asserts (a) no exception, and (b) the snackbar is shown.
//
// Injection seam: showStreakRescueSheetForTest accepts a repairFn so tests
// inject a stub without touching Supabase / SharedPreferences.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/daily/providers/daily_rewards_provider.dart';
import 'package:sakina/features/streaks/widgets/streak_rescue_sheet.dart';
import 'package:sakina/services/streak_service.dart';
import 'package:visibility_detector/visibility_detector.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Advance the clock enough to open/close the bottom sheet and let async
/// repair stubs complete, without waiting for repeating pulse animations.
/// [CompanionMedallion] uses a looping AnimationController so pumpAndSettle
/// never settles — we pump a fixed duration instead.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump(); // start futures
  await tester.pump(const Duration(milliseconds: 300)); // let animations start
  await tester.pump(const Duration(milliseconds: 300)); // let futures complete
}

/// Pumps a minimal app containing a Scaffold with a button. Pressing the
/// button opens the rescue sheet via the test-facing [showStreakRescueSheetForTest]
/// overload that accepts an injected [repairFn].
Widget _buildHarness({
  required int preLapseStreak,
  required Future<PaidRepairResult> Function({int preLapseStreak}) repairFn,
}) {
  return ProviderScope(
    overrides: [
      // Skip the real _initialize so pump doesn't time out waiting for
      // SharedPreferences / RevenueCat / Supabase.
      dailyLoopProvider.overrideWith(
        (ref) => DailyLoopNotifier(skipInitForTests: true),
      ),
      // Return non-premium immediately.
      premiumStateProvider.overrideWith(
        (ref) async => (isPremium: false, billingIssueAt: null),
      ),
      // Skip the reload() that hits SharedPrefs/Supabase.
      dailyRewardsProvider.overrideWith(
        (ref) => DailyRewardsNotifier.testOnly(),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(builder: (ctx) {
          return Center(
            child: ElevatedButton(
              key: const Key('open_sheet'),
              onPressed: () {
                showStreakRescueSheetForTest(
                  ctx,
                  preLapseStreak: preLapseStreak,
                  repairFn: repairFn,
                );
              },
              child: const Text('Open'),
            ),
          );
        }),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // CompanionMedallion wraps its content in a VisibilityDetector. By default
  // the controller batches callbacks with a 500ms timer, which leaves a
  // pending timer after each test and fails the invariant check. Setting
  // updateInterval to zero makes callbacks fire synchronously.
  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  // ---- rateLimited branch -------------------------------------------------

  testWidgets(
    'rateLimited: snackbar shown after sheet dismisses, no deactivated-widget exception',
    (tester) async {
      Future<PaidRepairResult> stub({int preLapseStreak = 0}) async {
        return const PaidRepairResult(
          success: false,
          reason: RepairFailReason.rateLimited,
        );
      }

      await tester.pumpWidget(_buildHarness(
        preLapseStreak: 10,
        repairFn: stub,
      ));

      // Open the sheet.
      await tester.tap(find.byKey(const Key('open_sheet')));
      await _settle(tester);

      // Tap the 'Restore' button inside the sheet.
      final restoreBtn = find.text('Restore for 100 tokens');
      expect(restoreBtn, findsOneWidget,
          reason: 'Sheet should be open with restore button visible');

      await tester.tap(restoreBtn);
      await _settle(tester);

      // The sheet should be gone.
      expect(find.text('Restore for 100 tokens'), findsNothing,
          reason: 'Sheet should have dismissed');

      // The rate-limit snackbar must appear.
      expect(
        find.text('You can restore a streak once a month.'),
        findsOneWidget,
        reason: 'Rate-limit snackbar must show after sheet dismisses',
      );
    },
  );

  // ---- windowPassed branch ------------------------------------------------

  testWidgets(
    'windowPassed: sheet dismisses quietly, no exception',
    (tester) async {
      Future<PaidRepairResult> stub({int preLapseStreak = 0}) async {
        return const PaidRepairResult(
          success: false,
          reason: RepairFailReason.windowPassed,
        );
      }

      await tester.pumpWidget(_buildHarness(
        preLapseStreak: 10,
        repairFn: stub,
      ));

      await tester.tap(find.byKey(const Key('open_sheet')));
      await _settle(tester);

      await tester.tap(find.text('Restore for 100 tokens'));
      await _settle(tester);

      // No snackbar expected (quiet dismiss).
      expect(find.byType(SnackBar), findsNothing);
    },
  );

  // ---- nothingToRestore branch --------------------------------------------

  testWidgets(
    'nothingToRestore: sheet dismisses quietly, no exception',
    (tester) async {
      Future<PaidRepairResult> stub({int preLapseStreak = 0}) async {
        return const PaidRepairResult(
          success: false,
          reason: RepairFailReason.nothingToRestore,
        );
      }

      await tester.pumpWidget(_buildHarness(
        preLapseStreak: 10,
        repairFn: stub,
      ));

      await tester.tap(find.byKey(const Key('open_sheet')));
      await _settle(tester);

      await tester.tap(find.text('Restore for 100 tokens'));
      await _settle(tester);

      expect(find.byType(SnackBar), findsNothing);
    },
  );

  // ---- unknown branch (no pop -> snackbar on live context) ----------------

  testWidgets(
    'unknown: snackbar shown on still-open sheet, no exception',
    (tester) async {
      Future<PaidRepairResult> stub({int preLapseStreak = 0}) async {
        return const PaidRepairResult(
          success: false,
          reason: RepairFailReason.unknown,
        );
      }

      await tester.pumpWidget(_buildHarness(
        preLapseStreak: 10,
        repairFn: stub,
      ));

      await tester.tap(find.byKey(const Key('open_sheet')));
      await _settle(tester);

      await tester.tap(find.text('Restore for 100 tokens'));
      await _settle(tester);

      // Sheet stays open (no pop on unknown/transient).
      expect(find.text('Restore for 100 tokens'), findsOneWidget,
          reason: 'Sheet must stay open for retry');

      expect(
        find.text('Couldn’t relight just now — try again.'),
        findsOneWidget,
        reason: 'Retry snackbar must show on live (open) sheet context',
      );

    },
  );

  // ---- dismissal-while-busy guard (new bug fix) ----------------------------

  testWidgets(
    'busy: sheet cannot be dismissed via back-pop while repairFn is in-flight',
    (tester) async {
      // A Completer we control — lets us keep the repairFn pending indefinitely.
      final completer = Completer<PaidRepairResult>();

      Future<PaidRepairResult> stub({int preLapseStreak = 0}) =>
          completer.future;

      await tester.pumpWidget(_buildHarness(
        preLapseStreak: 10,
        repairFn: stub,
      ));

      // Open the sheet.
      await tester.tap(find.byKey(const Key('open_sheet')));
      await _settle(tester);

      expect(find.text('Relight your lantern'), findsOneWidget,
          reason: 'Sheet must be open');

      // Tap Restore — this sets _busy = true (button text → spinner) and awaits
      // completer.future. We use the sheet TITLE as the "sheet present" indicator
      // since the Restore button text is replaced by a CircularProgressIndicator.
      await tester.tap(find.text('Restore for 100 tokens'));
      await tester.pump(); // let setState(_busy=true) run; do NOT complete completer

      // Simulate a system back / barrier-dismiss event via handlePopRoute.
      // PopScope(canPop: !_busy) should block this — canPop == false when _busy.
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // ASSERT: pop must be blocked — sheet still present (spinner visible).
      expect(find.text('Relight your lantern'), findsOneWidget,
          reason: 'Sheet must NOT dismiss while repairFn is in-flight');
      expect(find.byType(CircularProgressIndicator), findsOneWidget,
          reason: '_busy == true: spinner must be showing');

      // Complete the repair. We use windowPassed (a quiet-dismiss failure) rather
      // than success to avoid triggering dailyRewardsProvider.reload() which
      // needs Supabase — the harness stubs the notifier but not the underlying
      // service calls. The critical assertion was already made above; this just
      // confirms the sheet closes once the completer resolves.
      completer.complete(const PaidRepairResult(
        success: false,
        reason: RepairFailReason.windowPassed,
      ));
      await _settle(tester);

      // Sheet should be gone after the completer resolves.
      expect(find.text('Relight your lantern'), findsNothing,
          reason: 'Sheet must dismiss after repair completer resolves');
    },
  );

  testWidgets(
    'idle: sheet CAN be dismissed via back-pop when not busy',
    (tester) async {
      // A repairFn that never gets called in this test — we dismiss before tapping.
      Future<PaidRepairResult> stub({int preLapseStreak = 0}) async {
        return const PaidRepairResult(success: false, reason: RepairFailReason.unknown);
      }

      await tester.pumpWidget(_buildHarness(
        preLapseStreak: 10,
        repairFn: stub,
      ));

      // Open the sheet.
      await tester.tap(find.byKey(const Key('open_sheet')));
      await _settle(tester);

      expect(find.text('Relight your lantern'), findsOneWidget,
          reason: 'Sheet must be open');

      // While IDLE (not busy) canPop == true, so handlePopRoute should dismiss.
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Relight your lantern'), findsNothing,
          reason: 'Sheet must dismiss when idle and back-popped');
    },
  );
}
