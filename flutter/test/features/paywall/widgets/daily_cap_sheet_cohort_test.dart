import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/paywall/widgets/daily_cap_sheet.dart';
import 'package:sakina/features/paywall/widgets/warmup_exhausted_sheet.dart'
    show GatedFeature;
import 'package:sakina/services/gating_service.dart'
    show GateReason, GatingService;
import 'package:shared_preferences/shared_preferences.dart';

// Cohort-branched cap-sheet copy + bypass removal.
//
// One Ship W5 Wave D.4 (UI half) and D.5. Two shipped strings promised a DAILY
// reset — "Tomorrow's reflection is on us" — which the `reel_v1` weekly pool
// makes false: under a Monday-reset combined allowance, tomorrow is NOT on us.
// The app breaking a promise on the surface where it asks for money is the
// thing these tests exist to stop recurring, so they pin the literal strings
// rather than a shape.

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

Future<void> _pump(
  WidgetTester tester,
  GatedFeature feature, {
  required bool isNewCohort,
  GateReason? gateReason,
  int? tokenBalance,
  int? bypassesUsedToday,
  ValueChanged<GatedFeature>? onBypassRequested,
  bool firstBypassAvailable = false,
  ValueChanged<GatedFeature>? onFirstBypassRequested,
  bool isPremium = false,
}) {
  return tester.pumpWidget(
    _wrap(
      DailyCapSheet(
        feature: feature,
        isNewCohort: isNewCohort,
        gateReason: gateReason,
        tokenBalance: tokenBalance,
        bypassesUsedToday: bypassesUsedToday,
        onBypassRequested: onBypassRequested,
        firstBypassAvailable: firstBypassAvailable,
        onFirstBypassRequested: onFirstBypassRequested,
        isPremium: isPremium,
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

/// A gating service that reports the tightened cohort.
///
/// Overriding the service is the only way to drive this from a widget test:
/// `GatingService.debugSetCohort` writes through
/// `supabaseSyncService.scopedKey`, which asserts on an initialized Supabase
/// instance and throws under `flutter_test`.
class _NewCohortGatingService extends GatingService {
  _NewCohortGatingService() : super.test();

  @override
  Future<bool> isNewCohort() async => true;
}

void main() {
  // `show` awaits a SharedPreferences-backed cohort read, and
  // `getInstance()` never completes under flutter_test without a mock store —
  // it hangs rather than throwing, so the sheet would simply never appear.
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('DailyCapSheet — legacy cohort keeps the daily copy verbatim', () {
    const headlines = <GatedFeature, String>{
      GatedFeature.reflect: "You've reflected today",
      GatedFeature.builtDua: "You've built today's duʿā",
      GatedFeature.discoverName: "You've discovered today's Name",
    };
    const bodies = <GatedFeature, String>{
      GatedFeature.reflect:
          "Tomorrow's reflection is on us. Or unlock unlimited now.",
      GatedFeature.builtDua:
          "Tomorrow's duʿā is on us. Or unlock unlimited now.",
      GatedFeature.discoverName:
          "Tomorrow's discovery is on us. Or unlock unlimited now.",
    };

    for (final feature in GatedFeature.values) {
      testWidgets('$feature renders the shipped daily copy', (tester) async {
        await _pump(tester, feature, isNewCohort: false);
        expect(find.text(headlines[feature]!), findsOneWidget);
        expect(find.text(bodies[feature]!), findsOneWidget);
      });
    }

    testWidgets('isNewCohort defaults to false — an untaught caller renders '
        'the generous tier, never the tightened one', (tester) async {
      await tester.pumpWidget(
        _wrap(
          DailyCapSheet(
            feature: GatedFeature.reflect,
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );
      expect(
        find.text("Tomorrow's reflection is on us. Or unlock unlimited now."),
        findsOneWidget,
      );
    });
  });

  group('DailyCapSheet — reel_v1 states the real weekly reset', () {
    const pooledBody =
        'Your free reflections and duʿās return together on Monday. '
        'Or unlock unlimited now.';

    testWidgets('reflect: headline drops "today", body names Monday',
        (tester) async {
      await _pump(tester, GatedFeature.reflect, isNewCohort: true);
      expect(find.text('Your reflections for this week are used'),
          findsOneWidget);
      expect(find.text(pooledBody), findsOneWidget);
    });

    testWidgets('builtDua: headline drops "today", body names Monday',
        (tester) async {
      await _pump(tester, GatedFeature.builtDua, isNewCohort: true);
      expect(find.text('Your duʿās for this week are used'), findsOneWidget);
      expect(find.text(pooledBody), findsOneWidget);
    });

    testWidgets('the pooled body names BOTH features, because the pool is '
        'combined', (tester) async {
      // consume_weekly_allowance charges ONE counter for reflect and
      // built_dua alike. A user told only that their reflections return on
      // Monday, who then finds Build-a-Dua closed too, has been misled by
      // omission — the same broken promise, one step later.
      for (final feature in [GatedFeature.reflect, GatedFeature.builtDua]) {
        await _pump(tester, feature, isNewCohort: true);
        expect(
          find.textContaining('reflections and duʿās'),
          findsOneWidget,
          reason: 'both features must be named on the pooled line',
        );
        // "together" is the ONLY thing left saying the two draw on one pool,
        // now that "share a free allowance" is gone. Without it, a user who
        // spent the week on reflections reads "Your duʿās for this week are
        // used" — having built zero duas — as two separate buckets.
        expect(
          find.textContaining('return together'),
          findsOneWidget,
          reason: 'the shared-pool signal must survive any reword',
        );
      }
    });

    testWidgets('the pooled copy quotes no pool SIZE', (tester) async {
      // `weekly_pool_size` is a server dial nothing client-side reads. A
      // number here would rebuild the trap documented at
      // GatingService.bypassTokenCost: ops tunes the dial, the sheet keeps
      // quoting the old figure, and the copy is false again.
      for (final feature in [GatedFeature.reflect, GatedFeature.builtDua]) {
        await _pump(tester, feature, isNewCohort: true);
        final body = tester.widget<Text>(find.text(pooledBody)).data!;
        expect(
          RegExp(r'\d').hasMatch(body),
          isFalse,
          reason: 'pooled body must survive any weekly_pool_size',
        );
        expect(body.toLowerCase(), isNot(contains('three')));
      }
    });

    testWidgets('discoverName is NOT pooled — it keeps a true daily promise',
        (tester) async {
      // D10②: the day-open reveal consults no gate and is free permanently.
      // Only a SECOND Name in a day is premium, which is the only thing the
      // upgrade CTA is selling on this sheet.
      await _pump(tester, GatedFeature.discoverName, isNewCohort: true);
      expect(find.text("You've discovered today's Name"), findsOneWidget);
      expect(
        find.text('One Name a day stays free, always. '
            'Or unlock unlimited to meet another today.'),
        findsOneWidget,
      );
    });

    testWidgets('no reel_v1 sheet promises anything about "tomorrow" for a '
        'pooled feature (the D10③ regression)', (tester) async {
      for (final feature in [GatedFeature.reflect, GatedFeature.builtDua]) {
        await _pump(tester, feature, isNewCohort: true);
        expect(
          find.textContaining('omorrow'),
          findsNothing,
          reason: 'under a Monday-reset pool, tomorrow is not on us',
        );
      }
    });
  });

  group('DailyCapSheet — the bypass slot is gone for reel_v1 (D.4)', () {
    testWidgets('full STATE A props render NO bypass button', (tester) async {
      var bypassed = 0;
      await _pump(
        tester,
        GatedFeature.reflect,
        isNewCohort: true,
        tokenBalance: 87,
        bypassesUsedToday: 0,
        onBypassRequested: (_) => bypassed++,
      );

      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.textContaining('Use 25 tokens'), findsNothing);
      expect(bypassed, 0);
    });

    testWidgets('STATE B renders no dead-end disabled button either',
        (tester) async {
      // Under 25 tokens the legacy slot went dead with a hint and offered no
      // route to buying tokens. reel_v1 removes the dead end, not just the
      // button (D10④) — so neither the button nor its hint may appear.
      await _pump(
        tester,
        GatedFeature.builtDua,
        isNewCohort: true,
        tokenBalance: 10,
        bypassesUsedToday: 0,
        onBypassRequested: (_) {},
      );
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.textContaining('Need 25'), findsNothing);
    });

    testWidgets('STATE D (the Day-1 freebie) is suppressed too', (tester) async {
      // D.4: "Remove the bypass for reel_v1 — claimFirstBypass included."
      var claimed = 0;
      await _pump(
        tester,
        GatedFeature.reflect,
        isNewCohort: true,
        firstBypassAvailable: true,
        onFirstBypassRequested: (_) => claimed++,
        tokenBalance: 87,
        bypassesUsedToday: 0,
        onBypassRequested: (_) {},
      );

      expect(find.text('One more on us'), findsNothing);
      expect(find.text('Reflect one more time, free'), findsNothing);
      expect(claimed, 0);
      // Falls back to the standard reel_v1 sheet.
      expect(find.text('Your reflections for this week are used'),
          findsOneWidget);
      expect(find.text('Unlock unlimited'), findsOneWidget);
    });

    testWidgets('the sheet collapses to exactly headline + Unlock unlimited '
        '+ Maybe later', (tester) async {
      await _pump(
        tester,
        GatedFeature.reflect,
        isNewCohort: true,
        tokenBalance: 500,
        bypassesUsedToday: 0,
        onBypassRequested: (_) {},
      );
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Unlock unlimited'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(TextButton), findsOneWidget);
      expect(find.text('Maybe later'), findsOneWidget);
    });

    testWidgets('premium on reel_v1 still never sees a bypass path',
        (tester) async {
      // Belt and braces on the rule pinned in CLAUDE.md: premium must never
      // reach reserveBypass. Both suppressors are independent, so neither
      // one relies on the other being set.
      await _pump(
        tester,
        GatedFeature.discoverName,
        isNewCohort: true,
        isPremium: true,
        firstBypassAvailable: true,
        onFirstBypassRequested: (_) {},
        tokenBalance: 500,
        bypassesUsedToday: 0,
        onBypassRequested: (_) {},
      );
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.textContaining('Use 25 tokens'), findsNothing);
      expect(find.text('One more on us'), findsNothing);
    });

    testWidgets('LEGACY keeps the bypass — reel_v1 removal must not leak',
        (tester) async {
      await _pump(
        tester,
        GatedFeature.reflect,
        isNewCohort: false,
        tokenBalance: 87,
        bypassesUsedToday: 0,
        onBypassRequested: (_) {},
      );
      expect(
        find.text('Use 25 tokens for one more (you have 87)'),
        findsOneWidget,
      );
    });

    testWidgets('LEGACY keeps STATE D', (tester) async {
      await _pump(
        tester,
        GatedFeature.reflect,
        isNewCohort: false,
        firstBypassAvailable: true,
        onFirstBypassRequested: (_) {},
      );
      expect(find.text('One more on us'), findsOneWidget);
      expect(find.text('Reflect one more time, free'), findsOneWidget);
    });
  });

  group('DailyCapSheet — the duʿā spelling holds on every variant', () {
    // Founder ruling 2026-07-31: the ʿayn form is the house register (33 files
    // in lib/) and purchase surfaces follow it. The failure this guards is
    // subtler than the paywall case that prompted the ruling — there, two
    // spellings sat inches apart on one screen; here the headline and the body
    // of the SAME sheet are one line apart, so a partial application would
    // read worse than not doing it at all.
    Future<void> expectNoBareDua(WidgetTester tester) async {
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>();
      for (final text in texts) {
        expect(RegExp(r'\bduas?\b').hasMatch(text), isFalse,
            reason: 'bare "dua" rendered: "$text"');
      }
    }

    testWidgets('legacy builtDua sheet', (tester) async {
      await _pump(tester, GatedFeature.builtDua, isNewCohort: false);
      expect(find.text("You've built today's duʿā"), findsOneWidget);
      await expectNoBareDua(tester);
    });

    testWidgets('reel_v1 builtDua sheet — headline AND body agree',
        (tester) async {
      await _pump(tester, GatedFeature.builtDua, isNewCohort: true);
      expect(find.text('Your duʿās for this week are used'), findsOneWidget);
      expect(
        find.text('Your free reflections and duʿās return together on '
            'Monday. Or unlock unlimited now.'),
        findsOneWidget,
      );
      await expectNoBareDua(tester);
    });

    testWidgets('the STATE D freebie variant too', (tester) async {
      await _pump(
        tester,
        GatedFeature.builtDua,
        isNewCohort: false,
        firstBypassAvailable: true,
        onFirstBypassRequested: (_) {},
      );
      expect(find.text('Build one more duʿā, free'), findsOneWidget);
      await expectNoBareDua(tester);
    });

    testWidgets('every feature x cohort renders no bare "dua"',
        (tester) async {
      for (final feature in GatedFeature.values) {
        for (final cohort in [true, false]) {
          await _pump(tester, feature, isNewCohort: cohort);
          await expectNoBareDua(tester);
        }
      }
    });
  });

  group('DailyCapSheet — the gate REASON outranks the cohort flag', () {
    const pooledBody =
        'Your free reflections and duʿās return together on Monday. '
        'Or unlock unlimited now.';

    testWidgets('weeklyPool forces weekly copy even when the cohort read says '
        'legacy', (tester) async {
      // The property that makes the reason the better input: the copy can
      // never contradict the gate that produced the sheet. If the cohort
      // cache were stale or wrong, a user who genuinely hit the weekly pool
      // would otherwise be promised a reset tomorrow that is not coming.
      await _pump(
        tester,
        GatedFeature.reflect,
        isNewCohort: false,
        gateReason: GateReason.weeklyPool,
      );
      expect(find.text('Your reflections for this week are used'),
          findsOneWidget);
      expect(find.text(pooledBody), findsOneWidget);
      expect(find.textContaining('omorrow'), findsNothing);
    });

    testWidgets('rerollPremium forces the discoverName new-tier copy',
        (tester) async {
      await _pump(
        tester,
        GatedFeature.discoverName,
        isNewCohort: false,
        gateReason: GateReason.rerollPremium,
      );
      expect(
        find.text('One Name a day stays free, always. '
            'Or unlock unlimited to meet another today.'),
        findsOneWidget,
      );
    });

    testWidgets('weeklyPool also kills the bypass slot on a legacy flag',
        (tester) async {
      await _pump(
        tester,
        GatedFeature.reflect,
        isNewCohort: false,
        gateReason: GateReason.weeklyPool,
        tokenBalance: 500,
        bypassesUsedToday: 0,
        onBypassRequested: (_) {},
      );
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.textContaining('Use 25 tokens'), findsNothing);
    });

    testWidgets('the combination is one-way: a NON-tightened reason never '
        'downgrades a reel_v1 user to legacy copy', (tester) async {
      // The reason this is an OR and not a switch. If `canUse` ever hands
      // this sheet `dailyCap` for a reel_v1 account, mapping that back to
      // "legacy" would promise a daily reset the pool will not honour. The
      // cohort must still win in that direction.
      for (final reason in [
        GateReason.dailyCap,
        GateReason.hadTrialNoBudget,
        GateReason.premiumFairUse,
      ]) {
        await _pump(
          tester,
          GatedFeature.reflect,
          isNewCohort: true,
          gateReason: reason,
        );
        expect(find.text(pooledBody), findsOneWidget,
            reason: '$reason must not downgrade a reel_v1 user');
      }
    });

    testWidgets('PREMIUM is never described as being on the free tier, '
        'whatever the cohort says', (tester) async {
      // `free_tier_cohort` is stamped at signup and never cleared when the
      // account subscribes, so a paying user created after the flip reports
      // isNewCohort == true forever. The only limit they can hit is the
      // premium fair-use ceiling, which is DAILY and never touches the pool —
      // canUse returns premiumFairUse from its premium branch and never
      // reaches _applyPostWarmupCap. Weekly copy here is false in every
      // clause: no weekly allowance, nothing returns Monday, and they already
      // have unlimited.
      await _pump(
        tester,
        GatedFeature.reflect,
        isNewCohort: true,
        gateReason: GateReason.premiumFairUse,
        isPremium: true,
      );
      expect(find.text("Tomorrow's reflection is on us. "
          'Or unlock unlimited now.'), findsOneWidget);
      expect(find.textContaining('Monday'), findsNothing);
      expect(find.text('Your reflections for this week are used'), findsNothing);
    });

    testWidgets('the premium veto outranks even a weekly-pool reason',
        (tester) async {
      // Defence in depth: keyed off isPremium rather than off the reason, so
      // it holds if a caller ever hands this sheet a reason that disagrees
      // with the account's actual entitlement.
      await _pump(
        tester,
        GatedFeature.builtDua,
        isNewCohort: true,
        gateReason: GateReason.weeklyPool,
        isPremium: true,
      );
      expect(find.textContaining('Monday'), findsNothing);
      expect(find.text("Tomorrow's duʿā is on us. Or unlock unlimited now."),
          findsOneWidget);
    });

    testWidgets('a null reason changes nothing — today\'s four call sites',
        (tester) async {
      await _pump(
        tester,
        GatedFeature.reflect,
        isNewCohort: false,
      );
      expect(
        find.text("Tomorrow's reflection is on us. Or unlock unlimited now."),
        findsOneWidget,
      );
    });
  });

  group('DailyCapSheet.show — cohort resolution', () {
    testWidgets('show(gateReason: weeklyPool) renders weekly copy without '
        'consulting the cohort at all', (tester) async {
      // No prefs mock and a throwing gating service: if `show` still reached
      // the cohort read on this path it would resolve to legacy and the
      // assertion below would fail.
      GatingService.debugSetOverride(_ThrowingGatingService());
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

      expect(
        find.text('Your free reflections and duʿās return together on Monday. '
            'Or unlock unlimited now.'),
        findsOneWidget,
      );
    });

    testWidgets('show(gateReason: dailyCap) still consults the cohort',
        (tester) async {
      // dailyCap occurs in BOTH tiers, so it settles nothing on its own and
      // must not short-circuit the read. The override reports reel_v1, so the
      // tightened copy below can only appear if the read actually happened.
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
                  gateReason: GateReason.dailyCap,
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

      expect(find.text('Your reflections for this week are used'),
          findsOneWidget);
    });

    testWidgets('a cached reel_v1 cohort renders the tightened sheet',
        (tester) async {
      // The ordinary production path today: no reason passed, cohort decides.
      GatingService.debugSetOverride(_NewCohortGatingService());
      addTearDown(GatingService.debugClearOverride);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => DailyCapSheet.show(
                  context,
                  feature: GatedFeature.builtDua,
                  onUpgrade: () {},
                  tokenBalance: 500,
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

      expect(find.text('Your duʿās for this week are used'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('a cohort read that THROWS still presents the sheet, on the '
        'legacy copy', (tester) async {
      // The fail-safe that matters. An uncaught error here would abandon
      // showModalBottomSheet and leave a capped user tapping a CTA that
      // produces nothing — turning a gate into a dead end. And it must fail
      // to LEGACY: never hand someone the tightened tier on a guess.
      GatingService.debugSetOverride(_ThrowingGatingService());
      addTearDown(GatingService.debugClearOverride);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
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

      expect(find.byType(DailyCapSheet), findsOneWidget);
      expect(
        find.text("Tomorrow's reflection is on us. Or unlock unlimited now."),
        findsOneWidget,
      );
    });

    testWidgets('no cached cohort → the LEGACY sheet', (tester) async {
      // The ordinary unknown-cohort case: a fresh install before the first
      // batch sync, or a sync that timed out. Same posture as a throw — the
      // more generous tier, per isNewCohort's documented fail-to-false.
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
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

      expect(find.byType(DailyCapSheet), findsOneWidget);
      expect(
        find.text("Tomorrow's reflection is on us. Or unlock unlimited now."),
        findsOneWidget,
      );
    });

    testWidgets('show() still completes its future so the caller can clear '
        'its gate flag', (tester) async {
      // Every caller chains .whenComplete(dismissGate). If the added await
      // ever swallowed the future, the gate flag would stay set and the user
      // could never re-enter the feature.
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
      expect(completed, isFalse, reason: 'sheet is still up');

      await tester.tap(find.text('Maybe later'));
      await tester.pumpAndSettle();
      expect(completed, isTrue);
    });
  });
}
