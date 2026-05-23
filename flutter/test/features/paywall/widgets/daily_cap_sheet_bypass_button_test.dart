import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/paywall/widgets/daily_cap_sheet.dart';
import 'package:sakina/features/paywall/widgets/warmup_exhausted_sheet.dart'
    show GatedFeature;
import 'package:sakina/services/analytics_events.dart';

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

    testWidgets(
        'show() fires ai_bypass_offered when bypass slot will render '
        '(PR 3 plan 2026-05-23)',
        (tester) async {
      final events = <(String, Map<String, dynamic>)>[];
      DailyCapSheet.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => DailyCapSheet.onAnalyticsEvent = null);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => DailyCapSheet.show(
                  context,
                  feature: GatedFeature.builtDua,
                  onUpgrade: () {},
                  onBypassRequested: (_) {},
                  tokenBalance: 87,
                  bypassesUsedToday: 0,
                  isPremium: false,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(events, hasLength(1));
      expect(events.first.$1, AnalyticsEvents.aiBypassOffered);
      expect(events.first.$2, {
        'feature': 'built_dua',
        'token_balance': 87,
        'bypasses_used_today': 0,
      });
    });

    testWidgets('show() does NOT fire ai_bypass_offered for premium users',
        (tester) async {
      final events = <(String, Map<String, dynamic>)>[];
      DailyCapSheet.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => DailyCapSheet.onAnalyticsEvent = null);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => DailyCapSheet.show(
                  context,
                  feature: GatedFeature.reflect,
                  onUpgrade: () {},
                  onBypassRequested: (_) {},
                  tokenBalance: 500,
                  bypassesUsedToday: 0,
                  isPremium: true,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(events, isEmpty,
          reason: 'Premium sheets never render the bypass slot');
    });

    testWidgets(
        'show() does NOT fire ai_bypass_offered when onBypassRequested is null',
        (tester) async {
      final events = <(String, Map<String, dynamic>)>[];
      DailyCapSheet.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => DailyCapSheet.onAnalyticsEvent = null);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => DailyCapSheet.show(
                  context,
                  feature: GatedFeature.reflect,
                  onUpgrade: () {},
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(events, isEmpty);
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
