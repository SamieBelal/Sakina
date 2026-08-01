// W6 Wave C, S2 — the cap-sheet blackout. `warmup_exhausted_sheet.dart`
// emitted ZERO analytics and `daily_cap_sheet.dart` emitted only the two
// bypass-offer events, both on the token-bypass slot W5 removes for
// `reel_v1`. So the single most important monetization surface in the ship
// fired nothing on impression and nothing on dismissal for the cohort it was
// built for. This pins the added `cap_sheet_shown` / `cap_sheet_dismissed`
// pair on BOTH sheets, and the `fireDismissOnce` reconciliation transplanted
// from `LapsedTrialSheet.show` (test technique for the non-button routes
// copied from `lapsed_trial_sheet_test.dart` too: a direct `maybePop()`
// stands in for barrier tap / swipe-down / Android back, which are
// mechanically identical from outside `showModalBottomSheet`'s public API).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/paywall/widgets/daily_cap_sheet.dart';
import 'package:sakina/features/paywall/widgets/warmup_exhausted_sheet.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/gating_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('DailyCapSheet — cap_sheet_shown', () {
    testWidgets('fires {feature, reason, sheet} when gateReason is known',
        (tester) async {
      final events = <(String, Map<String, dynamic>)>[];
      DailyCapSheet.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => DailyCapSheet.onAnalyticsEvent = null);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => DailyCapSheet.show(
                context,
                feature: GatedFeature.reflect,
                gateReason: GateReason.dailyCap,
                onUpgrade: () {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final shown = events.where((e) => e.$1 == AnalyticsEvents.capSheetShown);
      expect(shown, hasLength(1));
      expect(shown.first.$2, {
        AnalyticsEvents.propFeature: 'reflect',
        AnalyticsEvents.propReason: AnalyticsEvents.gateReasonDailyCap,
        AnalyticsEvents.propSheet: AnalyticsEvents.sheetDailyCap,
      });
    });

    testWidgets('omits reason (does not fabricate one) when gateReason is null',
        (tester) async {
      // Narrative-trigger call sites (post-streak-milestone, post-card-
      // collected) have no GateReason at all.
      final events = <(String, Map<String, dynamic>)>[];
      DailyCapSheet.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => DailyCapSheet.onAnalyticsEvent = null);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => DailyCapSheet.show(
                context,
                feature: GatedFeature.builtDua,
                headlineOverride: 'Beautiful work on your streak',
                onUpgrade: () {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final shown = events.where((e) => e.$1 == AnalyticsEvents.capSheetShown);
      expect(shown, hasLength(1));
      expect(shown.first.$2.containsKey(AnalyticsEvents.propReason), isFalse);
    });

    testWidgets('does NOT fire for isPremium: true', (tester) async {
      final events = <(String, Map<String, dynamic>)>[];
      DailyCapSheet.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => DailyCapSheet.onAnalyticsEvent = null);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => DailyCapSheet.show(
                context,
                feature: GatedFeature.reflect,
                isPremium: true,
                onUpgrade: () {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(events, isEmpty,
          reason: 'a subscriber is not part of the free-tier funnel this '
              'event measures');
    });

    testWidgets(
        'does NOT fire when isPremium=false but gateReason=premiumFairUse — '
        'the reason alone settles it, matching _isPremiumFairUse on the '
        'widget', (tester) async {
      final events = <(String, Map<String, dynamic>)>[];
      DailyCapSheet.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => DailyCapSheet.onAnalyticsEvent = null);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => DailyCapSheet.show(
                context,
                feature: GatedFeature.reflect,
                isPremium: false,
                gateReason: GateReason.premiumFairUse,
                onUpgrade: () {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(events, isEmpty);
    });
  });

  group('DailyCapSheet — cap_sheet_dismissed (fires exactly once)', () {
    Widget subject(void Function(String, Map<String, dynamic>) onEvent, {
      bool isPremium = false,
      GateReason? gateReason,
      ValueChanged<GatedFeature>? onBypassRequested,
      int? tokenBalance,
      int? bypassesUsedToday,
      bool firstBypassAvailable = false,
      ValueChanged<GatedFeature>? onFirstBypassRequested,
      required VoidCallback onUpgrade,
    }) {
      DailyCapSheet.onAnalyticsEvent = onEvent;
      return MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => DailyCapSheet.show(
              context,
              feature: GatedFeature.reflect,
              isPremium: isPremium,
              gateReason: gateReason,
              onBypassRequested: onBypassRequested,
              tokenBalance: tokenBalance,
              bypassesUsedToday: bypassesUsedToday,
              firstBypassAvailable: firstBypassAvailable,
              onFirstBypassRequested: onFirstBypassRequested,
              userDisplayName: 'Aisha',
              onUpgrade: onUpgrade,
            ),
            child: const Text('open'),
          ),
        ),
      );
    }

    testWidgets('the secondary button path fires method=button once',
        (tester) async {
      final events = <(String, Map<String, dynamic>)>[];
      addTearDown(() => DailyCapSheet.onAnalyticsEvent = null);
      await tester.pumpWidget(subject(
        (e, p) => events.add((e, p)),
        onUpgrade: () {},
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Maybe later'));
      await tester.pumpAndSettle();

      final dismissed =
          events.where((e) => e.$1 == AnalyticsEvents.capSheetDismissed);
      expect(dismissed, hasLength(1));
      expect(dismissed.first.$2[AnalyticsEvents.propSheet],
          AnalyticsEvents.sheetDailyCap);
      expect(dismissed.first.$2[AnalyticsEvents.propMethod], 'button');
    });

    testWidgets(
        'a non-button dismissal (barrier / swipe / back all pop the route '
        'identically) fires exactly once too', (tester) async {
      final events = <(String, Map<String, dynamic>)>[];
      DailyCapSheet.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => DailyCapSheet.onAnalyticsEvent = null);
      late BuildContext rootContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              rootContext = context;
              return ElevatedButton(
                onPressed: () => DailyCapSheet.show(
                  context,
                  feature: GatedFeature.reflect,
                  onUpgrade: () {},
                ),
                child: const Text('open'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      Navigator.of(rootContext, rootNavigator: true).maybePop();
      await tester.pumpAndSettle();

      final dismissed =
          events.where((e) => e.$1 == AnalyticsEvents.capSheetDismissed);
      expect(dismissed, hasLength(1));
      expect(dismissed.first.$2[AnalyticsEvents.propMethod], 'dismissed');
    });

    testWidgets('taking the upgrade path fires NO dismissal', (tester) async {
      final events = <(String, Map<String, dynamic>)>[];
      addTearDown(() => DailyCapSheet.onAnalyticsEvent = null);
      var upgraded = 0;
      await tester.pumpWidget(subject(
        (e, p) => events.add((e, p)),
        onUpgrade: () => upgraded++,
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Unlock unlimited'));
      await tester.pumpAndSettle();

      expect(upgraded, 1);
      expect(
        events.where((e) => e.$1 == AnalyticsEvents.capSheetDismissed),
        isEmpty,
      );
    });

    testWidgets('taking the token bypass fires NO dismissal', (tester) async {
      final events = <(String, Map<String, dynamic>)>[];
      addTearDown(() => DailyCapSheet.onAnalyticsEvent = null);
      var bypassed = 0;
      await tester.pumpWidget(subject(
        (e, p) => events.add((e, p)),
        onUpgrade: () {},
        onBypassRequested: (_) => bypassed++,
        tokenBalance: 87,
        bypassesUsedToday: 0,
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Use 25 tokens'));
      await tester.pumpAndSettle();

      expect(bypassed, 1);
      expect(
        events.where((e) => e.$1 == AnalyticsEvents.capSheetDismissed),
        isEmpty,
      );
    });

    testWidgets('claiming the Day-1 freebie (STATE D) fires NO dismissal',
        (tester) async {
      final events = <(String, Map<String, dynamic>)>[];
      addTearDown(() => DailyCapSheet.onAnalyticsEvent = null);
      var claimed = 0;
      await tester.pumpWidget(subject(
        (e, p) => events.add((e, p)),
        onUpgrade: () {},
        firstBypassAvailable: true,
        onFirstBypassRequested: (_) => claimed++,
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reflect one more time, free'));
      await tester.pumpAndSettle();

      expect(claimed, 1);
      expect(
        events.where((e) => e.$1 == AnalyticsEvents.capSheetDismissed),
        isEmpty,
      );
    });

    testWidgets('premium never fires a dismissal, even via its sole "Close"',
        (tester) async {
      final events = <(String, Map<String, dynamic>)>[];
      addTearDown(() => DailyCapSheet.onAnalyticsEvent = null);
      await tester.pumpWidget(subject(
        (e, p) => events.add((e, p)),
        isPremium: true,
        onUpgrade: () {},
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(events, isEmpty);
    });
  });

  group('WarmupExhaustedSheet — cap_sheet_shown / cap_sheet_dismissed', () {
    testWidgets('shown fires {feature, sheet} with no reason property',
        (tester) async {
      final events = <(String, Map<String, dynamic>)>[];
      GatingService.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => GatingService.onAnalyticsEvent = null);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => WarmupExhaustedSheet.show(
                context,
                feature: GatedFeature.discoverName,
                onUpgrade: () {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final shown = events.where((e) => e.$1 == AnalyticsEvents.capSheetShown);
      expect(shown, hasLength(1));
      expect(shown.first.$2, {
        AnalyticsEvents.propFeature: 'discover_name',
        AnalyticsEvents.propSheet: AnalyticsEvents.sheetWarmupExhausted,
      });
    });

    testWidgets('dismissal fires exactly once on the button path',
        (tester) async {
      final events = <(String, Map<String, dynamic>)>[];
      GatingService.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => GatingService.onAnalyticsEvent = null);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => WarmupExhaustedSheet.show(
                context,
                feature: GatedFeature.reflect,
                onUpgrade: () {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Maybe later'));
      await tester.pumpAndSettle();

      final dismissed =
          events.where((e) => e.$1 == AnalyticsEvents.capSheetDismissed);
      expect(dismissed, hasLength(1));
      expect(dismissed.first.$2[AnalyticsEvents.propMethod], 'button');
      expect(dismissed.first.$2[AnalyticsEvents.propSheet],
          AnalyticsEvents.sheetWarmupExhausted);
    });

    testWidgets(
        'a non-button dismissal (barrier / swipe / back) also fires exactly '
        'once', (tester) async {
      final events = <(String, Map<String, dynamic>)>[];
      GatingService.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => GatingService.onAnalyticsEvent = null);
      late BuildContext rootContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              rootContext = context;
              return ElevatedButton(
                onPressed: () => WarmupExhaustedSheet.show(
                  context,
                  feature: GatedFeature.reflect,
                  onUpgrade: () {},
                ),
                child: const Text('open'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      Navigator.of(rootContext, rootNavigator: true).maybePop();
      await tester.pumpAndSettle();

      final dismissed =
          events.where((e) => e.$1 == AnalyticsEvents.capSheetDismissed);
      expect(dismissed, hasLength(1));
      expect(dismissed.first.$2[AnalyticsEvents.propMethod], 'dismissed');
    });

    testWidgets('taking the upgrade path fires NO dismissal', (tester) async {
      final events = <(String, Map<String, dynamic>)>[];
      GatingService.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => GatingService.onAnalyticsEvent = null);
      var upgraded = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => WarmupExhaustedSheet.show(
                context,
                feature: GatedFeature.reflect,
                onUpgrade: () => upgraded++,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Unlock unlimited'));
      await tester.pumpAndSettle();

      expect(upgraded, 1);
      expect(
        events.where((e) => e.$1 == AnalyticsEvents.capSheetDismissed),
        isEmpty,
      );
    });
  });
}
