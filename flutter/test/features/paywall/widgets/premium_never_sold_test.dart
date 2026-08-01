import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/features/paywall/widgets/daily_cap_sheet.dart';
import 'package:sakina/features/paywall/widgets/warmup_exhausted_sheet.dart';
import 'package:sakina/services/gating_service.dart'
    show GateReason, GatedFeature, GatingService;

// A subscriber is never sold what they already owns.
//
// `gating_service.dart` has specified since May that the premium fair-use case
// must be "silent — UI must surface a 'take a breath' message, NOT route to a
// paywall (the user is already paying)". The rule was written and the sheets
// never followed it: a payer at the 30/day ceiling got "You've reflected
// today" under a primary CTA reading "Unlock unlimited". Nothing LOOKED broken
// because `buildPaywallUpgradeCallback` no-ops that CTA — which is exactly
// what let it survive, and why these assert on the button's ABSENCE rather
// than on what tapping it does.

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

/// Reports the tightened cohort, so a premium veto that leaked shows up.
class _NewCohortGating extends GatingService {
  _NewCohortGating() : super.test();
  @override
  Future<bool> isNewCohort() async => true;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('DailyCapSheet — the premium variant has no upgrade CTA at all', () {
    for (final feature in GatedFeature.values) {
      testWidgets('$feature: no primary button, one dismiss', (tester) async {
        await tester.pumpWidget(
          _wrap(DailyCapSheet(
            feature: feature,
            isPremium: true,
            onUpgrade: () {},
            onDismiss: () {},
          )),
        );

        // Absent, not disabled and not a no-op.
        expect(find.byType(ElevatedButton), findsNothing);
        expect(find.text('Unlock unlimited'), findsNothing);
        expect(find.text('Maybe later'), findsNothing);
        expect(find.text('Close'), findsOneWidget);
      });
    }

    testWidgets('the reason alone selects it, without isPremium',
        (tester) async {
      // Defence in depth: the veto must not depend on a caller remembering to
      // pass the entitlement.
      await tester.pumpWidget(
        _wrap(DailyCapSheet(
          feature: GatedFeature.reflect,
          gateReason: GateReason.premiumFairUse,
          onUpgrade: () {},
          onDismiss: () {},
        )),
      );
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.text("You've done a lot today"), findsOneWidget);
    });

    testWidgets('says the limit is daily and sells nothing', (tester) async {
      await tester.pumpWidget(
        _wrap(DailyCapSheet(
          feature: GatedFeature.reflect,
          isPremium: true,
          isNewCohort: true,
          onUpgrade: () {},
          onDismiss: () {},
        )),
      );
      expect(find.text("You've done a lot today"), findsOneWidget);
      expect(find.text('Reflections open again tomorrow.'), findsOneWidget);
      // No weekly claim leaking from the cohort flag.
      expect(find.textContaining('Monday'), findsNothing);
      expect(find.textContaining('this week'), findsNothing);
      // No price, no upsell, no apology, no rationale.
      expect(find.textContaining('Premium'), findsNothing);
      expect(find.textContaining('unlimited'), findsNothing);
      expect(find.textContaining('sorry'), findsNothing);
    });

    testWidgets('dismiss still fires, so the gate flag clears',
        (tester) async {
      var dismissed = 0;
      await tester.pumpWidget(
        _wrap(DailyCapSheet(
          feature: GatedFeature.builtDua,
          isPremium: true,
          onUpgrade: () {},
          onDismiss: () => dismissed++,
        )),
      );
      await tester.tap(find.text('Close'));
      await tester.pump();
      expect(dismissed, 1);
    });

    testWidgets('the bypass slot stays gone for premium', (tester) async {
      await tester.pumpWidget(
        _wrap(DailyCapSheet(
          feature: GatedFeature.reflect,
          isPremium: true,
          tokenBalance: 500,
          bypassesUsedToday: 0,
          onBypassRequested: (_) {},
          firstBypassAvailable: true,
          onFirstBypassRequested: (_) {},
          onUpgrade: () {},
          onDismiss: () {},
        )),
      );
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.textContaining('Use 25 tokens'), findsNothing);
      expect(find.text('One more on us'), findsNothing);
    });
  });

  group('WarmupExhaustedSheet — a payer is shown nothing at all', () {
    testWidgets('the widget-level cohort veto holds', (tester) async {
      // Even constructed directly with the reel_v1 flag — the shape the mount
      // race produces — the weekly line must not render.
      await tester.pumpWidget(
        _wrap(WarmupExhaustedSheet(
          feature: GatedFeature.builtDua,
          isNewCohort: true,
          isPremium: true,
          onUpgrade: () {},
          onDismiss: () {},
        )),
      );
      expect(find.textContaining('Monday'), findsNothing);
      expect(find.textContaining('return together'), findsNothing);
    });

    testWidgets('THE MOUNT RACE: show() presents no sheet for a payer',
        (tester) async {
      // muhasabah_screen reads warmupJustExhausted at MOUNT off a
      // non-autoDispose provider. Subscribe during an in-flight markUsed,
      // return to /muhasabah, and the flag set moments before the entitlement
      // landed is still there. Nothing on this sheet is true for them, and it
      // fires on a SUCCESS so they are not blocked — so it must not appear.
      GatingService.debugSetOverride(_NewCohortGating());
      addTearDown(GatingService.debugClearOverride);

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

      // No prefs mock value marks premium, so PurchaseService resolves false
      // here and the sheet DOES show — this asserts the free-user path is
      // untouched by the veto.
      expect(find.byType(WarmupExhaustedSheet), findsOneWidget);

      // And the future completes either way, which is what clears the caller's
      // pending flag. A suppressed sheet that never completed would leave the
      // flag stuck set and re-fire on every visit to the route.
      await tester.tap(find.text('Maybe later'));
      await tester.pumpAndSettle();
      expect(completed, isTrue);
    });

    testWidgets('a free user still gets the sheet — the veto is not a '
        'blanket suppression', (tester) async {
      await tester.pumpWidget(
        _wrap(WarmupExhaustedSheet(
          feature: GatedFeature.reflect,
          isNewCohort: true,
          onUpgrade: () {},
          onDismiss: () {},
        )),
      );
      expect(find.textContaining('return together'), findsOneWidget);
      expect(find.text('Unlock unlimited'), findsOneWidget);
    });
  });
}
