import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/paywall/widgets/lapsed_trial_sheet.dart';
import 'package:sakina/features/tour/providers/tour_route_observer.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('LapsedTrialSheet', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(
        _wrap(
          LapsedTrialSheet(
            momentsDuringTrial: 7,
            daysActiveDuringTrial: 3,
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );
      expect(find.byType(LapsedTrialSheet), findsOneWidget);
    });

    testWidgets('headline is always Welcome back to one a day', (tester) async {
      await tester.pumpWidget(
        _wrap(
          LapsedTrialSheet(
            momentsDuringTrial: 7,
            daysActiveDuringTrial: 3,
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );
      expect(find.text('Welcome back to one a day'), findsOneWidget);
    });

    testWidgets('falls back to generic copy when momentsDuringTrial is 0',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          LapsedTrialSheet(
            momentsDuringTrial: 0,
            daysActiveDuringTrial: 0,
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );
      expect(
        find.text(
          "You've explored what Premium feels like. One reflection a day "
          'is yours forever — or unlock unlimited again.',
        ),
        findsOneWidget,
      );
      // The interpolation form must NOT show in the fallback case.
      expect(find.textContaining('In your 3-day trial'), findsNothing);
    });

    testWidgets('falls back when moments is 0 but days is non-zero',
        (tester) async {
      // Even if days happens to be non-zero, zero moments means we
      // couldn't resolve activity meaningfully — still fall back.
      await tester.pumpWidget(
        _wrap(
          LapsedTrialSheet(
            momentsDuringTrial: 0,
            daysActiveDuringTrial: 3,
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );
      expect(find.textContaining("You've explored what Premium feels like"),
          findsOneWidget);
    });

    testWidgets('singular grammar at moments=1, days=1 (1 time, 1 day)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          LapsedTrialSheet(
            momentsDuringTrial: 1,
            daysActiveDuringTrial: 1,
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );
      expect(
        find.text(
          'In your 3-day trial, you showed up 1 time across 1 day. '
          'Premium keeps that pace going.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('plural grammar at moments=5, days=2 (5 times, 2 days)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          LapsedTrialSheet(
            momentsDuringTrial: 5,
            daysActiveDuringTrial: 2,
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );
      expect(
        find.text(
          'In your 3-day trial, you showed up 5 times across 2 days. '
          'Premium keeps that pace going.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'body never contains the word "reflected" '
        '(regression — was the bug)', (tester) async {
      // Pump several representative cases — fallback, singular, plural —
      // and assert no rendered Text contains "reflected". Locks in the
      // fix for the P3 bug where building duas / discovering names was
      // reported as "you reflected N times" in the lapsed-trial copy.
      final cases = <(int, int)>[
        (0, 0),
        (1, 1),
        (5, 2),
        (12, 3),
      ];
      for (final (moments, days) in cases) {
        await tester.pumpWidget(
          _wrap(
            LapsedTrialSheet(
              momentsDuringTrial: moments,
              daysActiveDuringTrial: days,
              onUpgrade: () {},
              onDismiss: () {},
            ),
          ),
        );
        expect(
          find.textContaining('reflected'),
          findsNothing,
          reason:
              'moments=$moments days=$days: copy must not say "reflected" — '
              'the displayed count includes built duas + discovered names too',
        );
      }
    });

    testWidgets('tapping primary invokes onUpgrade', (tester) async {
      var upgraded = 0;
      await tester.pumpWidget(
        _wrap(
          LapsedTrialSheet(
            momentsDuringTrial: 4,
            daysActiveDuringTrial: 2,
            onUpgrade: () => upgraded++,
            onDismiss: () {},
          ),
        ),
      );
      await tester.tap(find.text('Unlock unlimited'));
      await tester.pump();
      expect(upgraded, 1);
    });

    testWidgets('tapping secondary invokes onDismiss', (tester) async {
      var dismissed = 0;
      await tester.pumpWidget(
        _wrap(
          LapsedTrialSheet(
            momentsDuringTrial: 4,
            daysActiveDuringTrial: 2,
            onUpgrade: () {},
            onDismiss: () => dismissed++,
          ),
        ),
      );
      await tester.tap(find.text('Maybe later'));
      await tester.pump();
      expect(dismissed, 1);
    });

    testWidgets('show() forwards onDismiss to the caller AND pops the sheet',
        (tester) async {
      // Pins the reverse-trial fix: the static show() now accepts an onDismiss
      // hook (so the caller can fire soft_gate_dismissed) and still closes the
      // modal. Regression for F2 — the sheet must dismiss on "Maybe later".
      var dismissed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => LapsedTrialSheet.show(
                context,
                momentsDuringTrial: 4,
                daysActiveDuringTrial: 2,
                onUpgrade: () {},
                onDismiss: () => dismissed++,
              ),
              child: const Text('Show sheet'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Show sheet'));
      await tester.pumpAndSettle();
      expect(find.byType(LapsedTrialSheet), findsOneWidget);

      await tester.tap(find.text('Maybe later'));
      await tester.pumpAndSettle();
      expect(dismissed, 1, reason: 'caller onDismiss must fire');
      expect(find.byType(LapsedTrialSheet), findsNothing,
          reason: 'sheet must be popped after dismiss');
    });

    testWidgets('show names its route so the guided tour is suppressed',
        (tester) async {
      final observer = TourRouteObserver();
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => LapsedTrialSheet.show(
                context,
                momentsDuringTrial: 4,
                daysActiveDuringTrial: 2,
                onUpgrade: () {},
              ),
              child: const Text('Show sheet'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show sheet'));
      await tester.pumpAndSettle();

      expect(observer.topRouteName.value, 'LapsedTrialSheet');
      expect(observer.isBlockingRouteOnTop, true);
    });
  });
}
