import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/paywall/widgets/daily_cap_sheet.dart';
import 'package:sakina/features/paywall/widgets/warmup_exhausted_sheet.dart'
    show GatedFeature;

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('DailyCapSheet — bypass CTA states (plan 2026-05-23)', () {
    testWidgets('STATE A: balance >= 25 + bypasses < 2 → enabled "Use 25 tokens"',
        (tester) async {
      var bypassed = 0;
      await tester.pumpWidget(
        _wrap(
          DailyCapSheet(
            feature: GatedFeature.reflect,
            tokenBalance: 87,
            bypassesUsedToday: 0,
            isPremium: false,
            onBypassRequested: (_) => bypassed++,
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );

      final bypassLabel =
          find.text('Use 25 tokens for one more (you have 87)');
      expect(bypassLabel, findsOneWidget);

      // Disabled-state hints must NOT render in state A.
      expect(find.textContaining('cap reached'), findsNothing);
      expect(find.textContaining('Need 25'), findsNothing);

      final btn = tester.widget<OutlinedButton>(
        find.ancestor(of: bypassLabel, matching: find.byType(OutlinedButton)),
      );
      expect(btn.onPressed, isNotNull,
          reason: 'State A button must be tappable');

      await tester.tap(bypassLabel);
      await tester.pump();
      expect(bypassed, 1);
    });

    testWidgets('STATE B: balance < 25 → disabled with "Need 25" hint',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          DailyCapSheet(
            feature: GatedFeature.builtDua,
            tokenBalance: 10,
            bypassesUsedToday: 0,
            isPremium: false,
            onBypassRequested: (_) {},
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );

      final bypassLabel =
          find.text('Use 25 tokens for one more (you have 10)');
      expect(bypassLabel, findsOneWidget);
      expect(
        find.text('You have 10 tokens. Need 25.'),
        findsOneWidget,
      );

      final btn = tester.widget<OutlinedButton>(
        find.ancestor(of: bypassLabel, matching: find.byType(OutlinedButton)),
      );
      expect(btn.onPressed, isNull,
          reason: 'State B button must be disabled');
    });

    testWidgets('STATE C: bypasses_used >= 2 → disabled with cap-reached hint',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          DailyCapSheet(
            feature: GatedFeature.discoverName,
            tokenBalance: 200,
            bypassesUsedToday: 2,
            isPremium: false,
            onBypassRequested: (_) {},
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );

      final bypassLabel =
          find.text('Use 25 tokens for one more (you have 200)');
      expect(bypassLabel, findsOneWidget);
      expect(
        find.text("You've used today's bypasses. They reset tomorrow."),
        findsOneWidget,
      );

      final btn = tester.widget<OutlinedButton>(
        find.ancestor(of: bypassLabel, matching: find.byType(OutlinedButton)),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('isPremium=true → bypass CTA entirely hidden (defense-in-depth)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          DailyCapSheet(
            feature: GatedFeature.reflect,
            tokenBalance: 500,
            bypassesUsedToday: 0,
            isPremium: true,
            onBypassRequested: (_) {},
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );

      // Premium users should not see the outlined bypass button at all.
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.textContaining('Use 25 tokens'), findsNothing);

      // Primary + tertiary CTAs still render normally.
      expect(find.text('Unlock unlimited'), findsOneWidget);
      expect(find.text('Maybe later'), findsOneWidget);
    });

    testWidgets('onBypassRequested null → legacy 2-CTA layout (no regression)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          DailyCapSheet(
            feature: GatedFeature.reflect,
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );
      // No outlined button; only primary + tertiary.
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.text('Unlock unlimited'), findsOneWidget);
      expect(find.text('Maybe later'), findsOneWidget);
    });
  });
}
