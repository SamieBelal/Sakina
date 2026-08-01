import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/paywall/widgets/warmup_exhausted_sheet.dart';
import 'package:sakina/services/gating_service.dart' show GatingService;
import 'package:shared_preferences/shared_preferences.dart';

// Cohort-branched warm-up-exhaustion copy (One Ship W5 Wave D.5).
//
// The shipped body — "From tomorrow you'll get one a day." — describes what a
// LEGACY user falls through to. A `reel_v1` user falls through to something
// else entirely: Reflect and Build-a-Dua land in a combined Monday-reset
// weekly pool, and discoverName lands on a permanently-free once-a-day
// reveal. Neither is "one a day" for the feature in hand.

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

Future<void> _pump(
  WidgetTester tester,
  GatedFeature feature, {
  required bool isNewCohort,
}) {
  return tester.pumpWidget(
    _wrap(
      WarmupExhaustedSheet(
        feature: feature,
        isNewCohort: isNewCohort,
        onUpgrade: () {},
        onDismiss: () {},
      ),
    ),
  );
}

/// A gating service whose cohort read fails, to prove the sheet still shows.
class _ThrowingGatingService extends GatingService {
  _ThrowingGatingService() : super.test();

  @override
  Future<bool> isNewCohort() async => throw StateError('cohort unreadable');
}

void main() {
  // `show` awaits a SharedPreferences-backed cohort read, and
  // `getInstance()` never completes under flutter_test without a mock store.
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  const legacyBody =
      "From tomorrow you'll get one a day. Or unlock unlimited now.";
  const pooledBody =
      'From here, your free reflections and duʿās return together each '
      'Monday. Or unlock unlimited now.';
  const discoverBody =
      'Your Name for each day stays free, always. Or unlock unlimited now.';

  group('WarmupExhaustedSheet — legacy keeps the shipped daily copy', () {
    for (final feature in GatedFeature.values) {
      testWidgets('$feature renders the shipped body', (tester) async {
        await _pump(tester, feature, isNewCohort: false);
        expect(find.text(legacyBody), findsOneWidget);
      });
    }

    testWidgets('isNewCohort defaults to false', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WarmupExhaustedSheet(
            feature: GatedFeature.reflect,
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );
      expect(find.text(legacyBody), findsOneWidget);
    });
  });

  group('WarmupExhaustedSheet — reel_v1 names the real fall-through', () {
    testWidgets('reflect falls through to the weekly pool', (tester) async {
      await _pump(tester, GatedFeature.reflect, isNewCohort: true);
      expect(find.text(pooledBody), findsOneWidget);
      expect(find.text(legacyBody), findsNothing);
    });

    testWidgets('builtDua falls through to the same pool, and the copy says '
        'so', (tester) async {
      await _pump(tester, GatedFeature.builtDua, isNewCohort: true);
      expect(find.text(pooledBody), findsOneWidget);
      expect(find.textContaining('reflections and duʿās'), findsOneWidget,
          reason: 'both features must be named on the pooled line');
      // Same load-bearing word as the cap sheet — see that test for why.
      expect(find.textContaining('return together'), findsOneWidget,
          reason: 'the shared-pool signal must survive any reword');
    });

    testWidgets('discoverName falls through to the free daily reveal, not a '
        'pool', (tester) async {
      // discover_name is rejected outright by consume_weekly_allowance — it
      // is never pooled. Its once-a-day reveal consults no gate (D10②), so
      // "free, always" is the honest statement, not a Monday promise.
      await _pump(tester, GatedFeature.discoverName, isNewCohort: true);
      expect(find.text(discoverBody), findsOneWidget);
      expect(find.textContaining('Monday'), findsNothing);
    });

    testWidgets('no reel_v1 body claims "one a day" for a pooled feature',
        (tester) async {
      for (final feature in [GatedFeature.reflect, GatedFeature.builtDua]) {
        await _pump(tester, feature, isNewCohort: true);
        expect(find.textContaining('one a day'), findsNothing);
        expect(find.textContaining('omorrow'), findsNothing);
      }
    });

    testWidgets('the pooled body quotes no pool SIZE', (tester) async {
      await _pump(tester, GatedFeature.reflect, isNewCohort: true);
      final body = tester.widget<Text>(find.text(pooledBody)).data!;
      expect(RegExp(r'\d').hasMatch(body), isFalse,
          reason: 'must survive any weekly_pool_size dial value');
    });

    testWidgets('headlines stay cohort-neutral — they report what just '
        'finished, which is true either way', (tester) async {
      const headlines = <GatedFeature, String>{
        GatedFeature.reflect: "You've completed your free reflections",
        GatedFeature.builtDua: "You've built your free duʿās",
        GatedFeature.discoverName: "You've discovered your free Names",
      };
      for (final entry in headlines.entries) {
        await _pump(tester, entry.key, isNewCohort: true);
        expect(find.text(entry.value), findsOneWidget);
        await _pump(tester, entry.key, isNewCohort: false);
        expect(find.text(entry.value), findsOneWidget);
      }
    });

    testWidgets('both cohorts keep the same two CTAs', (tester) async {
      for (final cohort in [true, false]) {
        await _pump(tester, GatedFeature.reflect, isNewCohort: cohort);
        expect(find.text('Unlock unlimited'), findsOneWidget);
        expect(find.text('Maybe later'), findsOneWidget);
      }
    });
  });

  group('WarmupExhaustedSheet — the duʿā spelling holds', () {
    testWidgets('every feature x cohort renders no bare "dua"',
        (tester) async {
      for (final feature in GatedFeature.values) {
        for (final cohort in [true, false]) {
          await _pump(tester, feature, isNewCohort: cohort);
          final texts = tester
              .widgetList<Text>(find.byType(Text))
              .map((t) => t.data)
              .whereType<String>();
          for (final text in texts) {
            expect(RegExp(r'\bduas?\b').hasMatch(text), isFalse,
                reason: '$feature/$cohort rendered bare "dua": "$text"');
          }
        }
      }
    });

    testWidgets('the headline and the pooled body both use the ʿayn',
        (tester) async {
      await _pump(tester, GatedFeature.builtDua, isNewCohort: true);
      expect(find.text("You've built your free duʿās"), findsOneWidget);
      expect(find.textContaining('reflections and duʿās'), findsOneWidget);
    });
  });

  group('WarmupExhaustedSheet.show — cohort resolution', () {
    testWidgets('a cohort read that THROWS still presents the sheet, on the '
        'legacy copy', (tester) async {
      // The cohort read must fail to the generous tier WITHOUT abandoning the
      // sheet. This sheet is the one moment the free tier explains itself;
      // dropping it silently is the failure mode muhasabah_screen's
      // mount-time read exists to prevent.
      GatingService.debugSetOverride(_ThrowingGatingService());
      addTearDown(GatingService.debugClearOverride);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => WarmupExhaustedSheet.show(
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

      expect(find.byType(WarmupExhaustedSheet), findsOneWidget);
      expect(find.text(legacyBody), findsOneWidget);
    });

    testWidgets('show() still completes so callers can clear the pending flag',
        (tester) async {
      // muhasabah_screen chains .whenComplete(dismissWarmupExhausted); if the
      // added await swallowed the future the flag would stay stuck set and
      // the sheet would re-present on every visit to that route.
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
      expect(completed, isFalse);

      await tester.tap(find.text('Maybe later'));
      await tester.pumpAndSettle();
      expect(completed, isTrue);
    });
  });
}
