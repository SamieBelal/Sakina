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

    testWidgets(
        'STATE D: firstBypassAvailable=true → gold freebie CTA, no '
        'Unlock unlimited (PR 4 plan 2026-05-23)',
        (tester) async {
      var claimed = 0;
      GatedFeature? receivedFeature;
      await tester.pumpWidget(
        _wrap(
          DailyCapSheet(
            feature: GatedFeature.reflect,
            firstBypassAvailable: true,
            userDisplayName: 'Aisha',
            onFirstBypassRequested: (f) {
              claimed++;
              receivedFeature = f;
            },
            // STATE A props also provided — STATE D must take precedence
            // and ignore them (otherwise we'd render the gold + the paid
            // bypass slot together, asking users to pay 1ms after offering
            // the same thing free).
            tokenBalance: 87,
            bypassesUsedToday: 0,
            isPremium: false,
            onBypassRequested: (_) {},
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );

      expect(find.text('One more on us, Aisha'), findsOneWidget);
      expect(find.text('Reflect one more time, free'), findsOneWidget);
      // Sub upsell is hidden in STATE D — the freebie's job is product
      // discovery, not monetization.
      expect(find.text('Unlock unlimited'), findsNothing);
      // Paid bypass slot hidden — see comment above.
      expect(find.textContaining('Use 25 tokens'), findsNothing);
      expect(find.text('Maybe later'), findsOneWidget);

      await tester.tap(find.text('Reflect one more time, free'));
      await tester.pump();
      expect(claimed, 1);
      expect(receivedFeature, GatedFeature.reflect);
    });

    testWidgets(
        'STATE D headline falls back to "One more on us" when name is '
        'default "Friend" placeholder', (tester) async {
      await tester.pumpWidget(
        _wrap(
          DailyCapSheet(
            feature: GatedFeature.builtDua,
            firstBypassAvailable: true,
            userDisplayName: 'Friend',
            onFirstBypassRequested: (_) {},
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );

      expect(find.text('One more on us'), findsOneWidget,
          reason: 'No awkward greeting when name == default placeholder');
      expect(find.text('One more on us, Friend'), findsNothing);
      expect(find.text('Build one more dua, free'), findsOneWidget);
    });

    testWidgets(
        'STATE D headline falls back when userDisplayName is null entirely',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          DailyCapSheet(
            feature: GatedFeature.discoverName,
            firstBypassAvailable: true,
            onFirstBypassRequested: (_) {},
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );
      expect(find.text('One more on us'), findsOneWidget);
      expect(find.text('Discover one more Name, free'), findsOneWidget);
    });

    testWidgets(
        'STATE D suppressed for premium users → falls back to standard sheet',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          DailyCapSheet(
            feature: GatedFeature.reflect,
            firstBypassAvailable: true,
            userDisplayName: 'Aisha',
            onFirstBypassRequested: (_) {},
            isPremium: true,
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );
      // Premium never sees DailyCapSheet for real, but defense-in-depth:
      // even if shown with firstBypassAvailable=true + isPremium=true,
      // STATE D must NOT render (no freebie for premium).
      expect(find.text('One more on us, Aisha'), findsNothing);
      expect(find.text("You've reflected today"), findsOneWidget);
      expect(find.text('Unlock unlimited'), findsOneWidget);
    });

    testWidgets(
        'show() fires first_bypass_offered when STATE D will render',
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
                  firstBypassAvailable: true,
                  userDisplayName: 'Aisha',
                  onFirstBypassRequested: (_) {},
                  // STATE A props also wired — show() must fire ONLY the
                  // first_bypass_offered event, not also ai_bypass_offered
                  // (would double-count in the funnel).
                  tokenBalance: 87,
                  bypassesUsedToday: 0,
                  onBypassRequested: (_) {},
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
      expect(events.first.$1, 'first_bypass_offered');
      expect(events.first.$2, {'feature': 'reflect'});
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
