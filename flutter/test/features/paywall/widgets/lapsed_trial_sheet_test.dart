import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/paywall/widgets/lapsed_trial_sheet.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('LapsedTrialSheet', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(
        _wrap(
          LapsedTrialSheet(
            reflectsDuringTrial: 7,
            daysActiveDuringTrial: 3,
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );
      expect(find.byType(LapsedTrialSheet), findsOneWidget);
    });

    testWidgets('headline is always Welcome back to one a day',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          LapsedTrialSheet(
            reflectsDuringTrial: 7,
            daysActiveDuringTrial: 3,
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );
      expect(find.text('Welcome back to one a day'), findsOneWidget);
    });

    testWidgets('interpolates non-zero counts into body', (tester) async {
      await tester.pumpWidget(
        _wrap(
          LapsedTrialSheet(
            reflectsDuringTrial: 7,
            daysActiveDuringTrial: 3,
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );
      expect(
        find.text(
          'In your 3-day trial, you reflected 7 times across 3 days. '
          'Premium keeps that pace going.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('falls back to generic copy when reflectsDuringTrial is 0',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          LapsedTrialSheet(
            reflectsDuringTrial: 0,
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

    testWidgets('falls back when reflects is 0 but days is non-zero',
        (tester) async {
      // Even if days happens to be non-zero, zero reflects means we
      // couldn't resolve activity meaningfully — still fall back.
      await tester.pumpWidget(
        _wrap(
          LapsedTrialSheet(
            reflectsDuringTrial: 0,
            daysActiveDuringTrial: 3,
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );
      expect(find.textContaining("You've explored what Premium feels like"),
          findsOneWidget);
    });

    testWidgets('tapping primary invokes onUpgrade', (tester) async {
      var upgraded = 0;
      await tester.pumpWidget(
        _wrap(
          LapsedTrialSheet(
            reflectsDuringTrial: 4,
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
            reflectsDuringTrial: 4,
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
  });
}
