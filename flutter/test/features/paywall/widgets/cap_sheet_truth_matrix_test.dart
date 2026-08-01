// Review hardening for the W5 cap-sheet commit (D10③ / D11).
//
// Three properties the existing suites assert by example; this file asserts
// them exhaustively, because the failure they guard is "the app said something
// untrue on the screen where it asks for money":
//
//  1. **The truth matrix.** Every (cohort × feature × GateReason × premium)
//     combination the widget can be constructed with — 84 of them — is rendered
//     and scanned. No sheet may mix the two reset stories: legacy copy may
//     never say "Monday"/"this week", pooled `reel_v1` copy may never say
//     "tomorrow"/"today"/"a day", and premium may never be told about a weekly
//     allowance it does not have. The named tests cover the interesting cells;
//     this covers the ones nobody thought of.
//  2. **Every dismissal route completes `show()`.** Both callers chain
//     `.whenComplete(dismissGate)`; a route that fails to complete the future
//     leaves the gate flag stuck set and the feature permanently unreachable.
//     The shipped tests only exercise "Maybe later".
//  3. **The compound route extra survives hostile copy.** The value line is
//     human-authored and travels as a JSON object string told apart from a bare
//     enum name by a leading `{`. Braces, quotes, backslashes, newlines, emoji
//     and a line that is itself valid JSON must all round-trip — and the
//     PLACEMENT must survive even when the line does not, because a dropped
//     placement is the worse bug (fixed in 2a4b3b6, re-risked by this codec).

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/paywall/paywall_navigation.dart';
import 'package:sakina/features/paywall/paywall_placement.dart';
import 'package:sakina/features/paywall/widgets/daily_cap_sheet.dart';
import 'package:sakina/features/paywall/widgets/warmup_exhausted_sheet.dart';
import 'package:sakina/services/gating_service.dart'
    show GateReason, GatedFeature, GatingService;

/// Reports the tightened cohort, so a premium veto that leaked would show up as
/// weekly copy rather than as a silent pass.
class _NewCohortGatingService extends GatingService {
  _NewCohortGatingService() : super.test();
  @override
  Future<bool> isNewCohort() async => true;
}

void main() {
  // `show` awaits a SharedPreferences-backed cohort read; `getInstance()` never
  // completes under flutter_test without a mock store.
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('the compound route extra survives hostile copy', () {
    const hostile = <String>[
      // A line that is itself a valid encoded extra.
      '{"placement":"softInApp"}',
      '{}',
      r'a \ backslash and "quotes"',
      'multi\nline\r\nvalue',
      'emoji 🕌 and the ʿayn in duʿās — em dash',
      '   {leading brace after spaces}',
      '',
    ];

    for (var i = 0; i < hostile.length; i++) {
      final line = hostile[i];
      test('round-trips ${json.encode(line)}', () {
        // postTrialSoft, not softInApp: the release-mode fallback IS softInApp,
        // so a dropped placement would be invisible against it.
        final extra = PaywallRouteExtra(
          placement: PaywallPlacement.postTrialSoft,
          valueLine: line,
        );
        final encoded = paywallPlacementExtraCodec.encode(extra);
        expect(encoded, isA<String>(),
            reason: 'every encoded extra stays one primitive');
        final decoded = paywallPlacementExtraCodec.decode(encoded);
        expect(placementFromRouteExtra(decoded), PaywallPlacement.postTrialSoft,
            reason: 'a dropped PLACEMENT is worse than a dropped line');
        expect(valueLineFromRouteExtra(decoded), line);
      });
    }

    test('no placement name could ever be read as a compound', () {
      // The whole discriminator is the leading `{`. Enum names are Dart
      // identifiers, so this can only break if someone adds a non-identifier
      // name — which the language forbids, but the assertion is free.
      for (final placement in PaywallPlacement.values) {
        expect(placement.name.startsWith('{'), isFalse, reason: placement.name);
      }
    });

    test('encoding is stable across repeated router round trips', () {
      // GoRouter re-reports route information after every re-parse, so the
      // decoded value is fed straight back into the encoder. Two encodings of
      // one logical value would make any future wire-form comparison wrong.
      const extra = PaywallRouteExtra(
        placement: PaywallPlacement.softInApp,
        valueLine: 'Your duʿās for this week are used — Premium is unlimited.',
      );
      final once = paywallPlacementExtraCodec.encode(extra);
      final twice = paywallPlacementExtraCodec
          .encode(paywallPlacementExtraCodec.decode(once));
      expect(twice, once);
    });
  });

  group('every dismissal route completes show()', () {
    Future<void> systemBack(WidgetTester tester) =>
        tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/navigation',
          const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
          (_) {},
        );

    Future<bool> openDailyCapThen(
      WidgetTester tester,
      Future<void> Function(WidgetTester) dismiss,
    ) async {
      var completed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => DailyCapSheet.show(
                  context,
                  feature: GatedFeature.reflect,
                  onUpgrade: () {},
                ).whenComplete(() => completed = true),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(DailyCapSheet), findsOneWidget);
      await dismiss(tester);
      await tester.pumpAndSettle();
      return completed;
    }

    testWidgets('DailyCapSheet — scrim tap', (tester) async {
      expect(
        await openDailyCapThen(tester, (t) => t.tapAt(const Offset(10, 10))),
        isTrue,
      );
    });

    testWidgets('DailyCapSheet — system back gesture', (tester) async {
      expect(await openDailyCapThen(tester, systemBack), isTrue);
    });

    testWidgets('DailyCapSheet — drag the sheet down', (tester) async {
      expect(
        await openDailyCapThen(
          tester,
          (t) => t.drag(find.byType(DailyCapSheet), const Offset(0, 600)),
        ),
        isTrue,
      );
    });

    testWidgets('DailyCapSheet — Unlock unlimited', (tester) async {
      expect(
        await openDailyCapThen(
          tester,
          (t) => t.tap(find.text('Unlock unlimited')),
        ),
        isTrue,
      );
    });

    testWidgets('WarmupExhaustedSheet — scrim tap and system back',
        (tester) async {
      for (final route in ['scrim', 'back']) {
        var completed = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => WarmupExhaustedSheet.show(
                    context,
                    feature: GatedFeature.reflect,
                    onUpgrade: () {},
                  ).whenComplete(() => completed = true),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(find.byType(WarmupExhaustedSheet), findsOneWidget);
        if (route == 'scrim') {
          await tester.tapAt(const Offset(10, 10));
        } else {
          await systemBack(tester);
        }
        await tester.pumpAndSettle();
        expect(completed, isTrue, reason: route);
      }
    });
  });

  group('cohort × feature × reason × premium', () {
    // Words that can only be true under one of the two allowances.
    const weeklyOnly = ['Monday', 'this week'];
    const dailyOnly = ['omorrow', 'today', 'a day'];

    testWidgets('no combination renders a claim from the other tier',
        (tester) async {
      for (final cohort in [true, false]) {
        for (final feature in GatedFeature.values) {
          for (final reason in <GateReason?>[null, ...GateReason.values]) {
            for (final premium in [true, false]) {
              await tester.pumpWidget(
                MaterialApp(
                  home: Scaffold(
                    body: DailyCapSheet(
                      feature: feature,
                      isNewCohort: cohort,
                      gateReason: reason,
                      isPremium: premium,
                      onUpgrade: () {},
                      onDismiss: () {},
                    ),
                  ),
                ),
              );
              final rendered = tester
                  .widgetList<Text>(find.byType(Text))
                  .map((t) => t.data)
                  .whereType<String>()
                  .join(' | ');
              final cell =
                  'cohort=$cohort feature=$feature reason=$reason premium=$premium';
              final newTier = DailyCapSheet.describesNewTier(
                gateReason: reason,
                isNewCohort: cohort,
                isPremium: premium,
              );

              if (premium) {
                // `free_tier_cohort` is never cleared on subscribe, so a payer
                // reports reel_v1 forever. Their only reachable limit is the
                // DAILY fair-use ceiling.
                for (final word in weeklyOnly) {
                  expect(rendered.contains(word), isFalse,
                      reason: 'premium was told "$word" — $cell :: $rendered');
                }
              }
              if (!newTier) {
                for (final word in weeklyOnly) {
                  expect(rendered.contains(word), isFalse,
                      reason: 'legacy copy said "$word" — $cell :: $rendered');
                }
              }
              if (newTier && feature != GatedFeature.discoverName) {
                // discoverName is exempt: it is never pooled and its reveal
                // really is once a day, so daily words are true for it.
                for (final word in dailyOnly) {
                  expect(rendered.contains(word), isFalse,
                      reason: 'pooled copy said "$word" — $cell :: $rendered');
                }
              }
            }
          }
        }
      }
    });
  });

  testWidgets('a weeklyPool REASON suppresses STATE D, whose body still '
      'promises "one a day"', (tester) async {
    // The cohort flag says legacy, so `firstBypassEligible()` would have
    // returned true (it short-circuits on isNewCohort) and STATE D is a live
    // candidate. Its body — "Tomorrow you'll get one a day" — is deliberately
    // left standing because it is true on the only cohort that can reach it, so
    // the reason-driven half of the veto has to hold here too, not just the
    // cohort-driven half.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DailyCapSheet(
            feature: GatedFeature.reflect,
            isNewCohort: false,
            gateReason: GateReason.weeklyPool,
            firstBypassAvailable: true,
            onFirstBypassRequested: (_) {},
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      ),
    );
    expect(find.text('One more on us'), findsNothing);
    expect(find.textContaining('one a day'), findsNothing);
    expect(find.textContaining('omorrow'), findsNothing);
    expect(find.text('Your reflections for this week are used'), findsOneWidget);
  });

  testWidgets('show() keeps the premium veto even when the cohort read says '
      'reel_v1 AND the reason says weeklyPool', (tester) async {
    // The end-to-end version of the veto: both inputs point at the new tier and
    // the entitlement still wins, all the way through the async cohort branch.
    GatingService.debugSetOverride(_NewCohortGatingService());
    addTearDown(GatingService.debugClearOverride);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => DailyCapSheet.show(
                context,
                feature: GatedFeature.reflect,
                gateReason: GateReason.weeklyPool,
                isPremium: true,
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

    expect(find.textContaining('Monday'), findsNothing);
    expect(
      find.text("Tomorrow's reflection is on us. Or unlock unlimited now."),
      findsOneWidget,
    );
  });
}
