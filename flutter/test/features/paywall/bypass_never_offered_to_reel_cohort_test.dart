// W6 Wave C, plan §4 test table row 4 — the `reel_v1` bypass assert.
// The bypass mechanic does not exist for `reel_v1` (W5 D.4): the sheet's
// middle CTA slot and STATE D freebie are both hidden for that cohort, so
// `ai_bypass_offered` / `first_bypass_offered` firing for it would inflate
// the top of a funnel whose remaining steps can never fire — the
// offer→purchase rate would sink and read as a conversion regression
// rather than a bypass that no longer exists.
//
// Two layers, both required:
//   1. Behavioural — `DailyCapSheet.show` with `free_tier_cohort=reel_v1`
//      never fires either offer event, however the bypass props are wired.
//   2. Source-level — every `onAnalyticsEvent?.call(AnalyticsEvents.
//      aiBypassOffered` / `firstBypassOffered` emit site sits behind a
//      `!newTier` (or equivalent) guard. This is what actually catches a
//      regression: the mutation that breaks row 1's behavioural tests is
//      "delete `!newTier` from the predicate" — the source-level test pins
//      that no OTHER, un-guarded emit site is ever added.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/paywall/widgets/daily_cap_sheet.dart';
import 'package:sakina/services/gating_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_supabase_sync_service.dart';

void main() {
  group('behavioural — reel_v1 offers neither bypass event', () {
    late FakeSupabaseSyncService fakeSync;
    late GatingService gating;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      fakeSync = FakeSupabaseSyncService(userId: 'user-1');
      SupabaseSyncService.debugSetInstance(fakeSync);
      gating = GatingService.test();
      await gating.debugSetCohort(GatingService.cohortReelV1);
      GatingService.debugSetOverride(gating);
    });

    tearDown(() {
      GatingService.debugClearOverride();
      SupabaseSyncService.debugReset();
    });

    testWidgets(
        'reel_v1 + full STATE A-C bypass props wired → neither offer event '
        'fires (mutation: dropping !newTier from willRenderBypassSlot)',
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
                feature: GatedFeature.builtDua,
                onUpgrade: () {},
                onBypassRequested: (_) {},
                tokenBalance: 500,
                bypassesUsedToday: 0,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
        events.where((e) =>
            e.$1 == 'ai_bypass_offered' || e.$1 == 'first_bypass_offered'),
        isEmpty,
      );
      // The bypass button itself must not render either — belt and braces
      // with the analytics assertion above.
      expect(find.textContaining('tokens for one more'), findsNothing);
    });

    testWidgets(
        'reel_v1 + STATE D props wired (firstBypassAvailable) → neither '
        'offer event fires', (tester) async {
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
                onUpgrade: () {},
                firstBypassAvailable: true,
                onFirstBypassRequested: (_) {},
                userDisplayName: 'Aisha',
                // STATE A-C props ALSO wired, matching a caller that hasn't
                // learned to stop passing them — STATE D must still win and
                // neither offer event may fire.
                onBypassRequested: (_) {},
                tokenBalance: 500,
                bypassesUsedToday: 0,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
        events.where((e) =>
            e.$1 == 'ai_bypass_offered' || e.$1 == 'first_bypass_offered'),
        isEmpty,
      );
      expect(find.text('One more on us, Aisha'), findsNothing);
    });

    testWidgets(
        'gateReason alone (weeklyPool) settles reel_v1 without a cohort read '
        '— still no offer events', (tester) async {
      // Reset the cohort to unknown to prove the REASON alone is enough —
      // `reasonSettlesIt` in `show()` skips the cohort await entirely for
      // weeklyPool/rerollPremium.
      await gating.debugSetCohort(null);
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
                gateReason: GateReason.weeklyPool,
                onUpgrade: () {},
                onBypassRequested: (_) {},
                tokenBalance: 500,
                bypassesUsedToday: 0,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
        events.where((e) =>
            e.$1 == 'ai_bypass_offered' || e.$1 == 'first_bypass_offered'),
        isEmpty,
      );
    });
  });

  group('source-level — every offer emit site is newTier-guarded', () {
    test(
        'ai_bypass_offered / first_bypass_offered only ever appear inside an '
        'if/else-if chain whose branches are gated by willRenderStateD / '
        'willRenderBypassSlot, both of which carry !newTier', () {
      final source = File(
        'lib/features/paywall/widgets/daily_cap_sheet.dart',
      ).readAsStringSync();

      // Pin the two predicate definitions each carry `!newTier` — this is
      // the exact clause the behavioural tests above depend on. Mutation:
      // deleting `!newTier` from either line makes this assertion fail
      // WITHOUT needing to run a widget test — a faster, more precise
      // signal for the exact regression this whole file exists to prevent.
      final willRenderStateD = RegExp(
        r'final willRenderStateD = firstBypassAvailable &&\s*'
        r'!isPremium &&\s*'
        r'!newTier &&\s*'
        r'onFirstBypassRequested != null;',
      );
      expect(
        willRenderStateD.hasMatch(source),
        isTrue,
        reason: 'willRenderStateD must carry !newTier',
      );

      final willRenderBypassSlot = RegExp(
        r'final willRenderBypassSlot = !willRenderStateD &&\s*'
        r'!isPremium &&\s*'
        r'!newTier &&\s*'
        r'onBypassRequested != null',
      );
      expect(
        willRenderBypassSlot.hasMatch(source),
        isTrue,
        reason: 'willRenderBypassSlot must carry !newTier',
      );

      // There is exactly one emit call for each event in this file (the
      // `show()` offer block) — a second, unguarded emit site anywhere else
      // in the file would be the actual failure mode this test exists to
      // catch, since it could bypass the two predicates entirely.
      expect(
        'firstBypassOffered'.allMatches(source).length,
        1,
        reason: 'a second first_bypass_offered emit site would not be '
            'covered by the willRenderStateD guard above',
      );
      expect(
        'aiBypassOffered'.allMatches(source).length,
        1,
        reason: 'a second ai_bypass_offered emit site would not be covered '
            'by the willRenderBypassSlot guard above',
      );
    });
  });
}
