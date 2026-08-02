// W6 Wave A — `free_tier_cohort` super property.
//
// This CANNOT be registered at boot: it is a user-scoped prefs key written
// only by `GatingService.hydrateFromProfile` from the `sync_all_user_data`
// payload, so on a fresh install it does not exist until the first sync
// lands. It is registered from the existing `GatingService.onProfileHydrated`
// hook instead (wired in `app_lifecycle_observer.dart`, a second statement at
// the existing wiring, not a second hook).
//
// See docs/superpowers/plans/2026-08-01-one-ship-06-instrumentation.md §4
// Wave A, step 5.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/app_lifecycle_observer.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/gating_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_supabase_sync_service.dart';

class _SuperPropSpy extends AnalyticsService {
  final List<Map<String, dynamic>> superPropCalls = [];
  final List<Map<String, dynamic>> deviceSuperPropCalls = [];

  @override
  void setSuperProperties(Map<String, dynamic> props) =>
      superPropCalls.add(Map<String, dynamic>.from(props));

  @override
  void cacheDeviceSuperProperties(Map<String, dynamic> props) {
    deviceSuperPropCalls.add(Map<String, dynamic>.from(props));
    setSuperProperties(props);
  }

  @override
  void track(String event, {Map<String, dynamic>? properties}) {}

  bool get sawFreeTierCohort => [...superPropCalls, ...deviceSuperPropCalls]
      .any((c) => c.containsKey(AnalyticsEvents.propFreeTierCohort));
}

void main() {
  // `hydrateFromProfile` writes its cache under a user-scoped key
  // (`supabaseSyncService.scopedKey`), which needs a Supabase client this
  // plain `flutter_test` process never initializes — same fake used by
  // gating_service_cohort_free_tier_test.dart and friends.
  setUp(() => SupabaseSyncService.debugSetInstance(
        FakeSupabaseSyncService(userId: 'user-1'),
      ));
  tearDown(() {
    GatingService.onProfileHydrated = null;
    SupabaseSyncService.debugReset();
  });

  group('NOT registered at boot', () {
    test(
        'registerBootstrapAnalytics never touches free_tier_cohort',
        () async {
      // MUTATION THAT MUST FAIL THIS TEST: register
      // `AnalyticsEvents.propFreeTierCohort` inside
      // `registerBootstrapAnalytics` (e.g. hardcoding 'legacy'). Verified by
      // hand: temporarily adding
      // `analytics.setSuperProperties({AnalyticsEvents.propFreeTierCohort: 'legacy'})`
      // to that function made `sawFreeTierCohort` true and this test fail.
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final analytics = _SuperPropSpy();

      await registerBootstrapAnalytics(
        analytics: analytics,
        prefs: prefs,
        platform: 'ios',
        appVersion: '1.3.0+1',
        flagOnboardingTrim: true,
        flagHardPaywall: true,
        flagGuidedTour: true,
        isPremium: false,
        installId: 'install-abc',
      );

      expect(analytics.sawFreeTierCohort, isFalse,
          reason: 'a fresh install has no free_tier_cohort value until the '
              'first sync_all_user_data — registering it at boot would '
              'either read nothing (a null super property, worse than an '
              'absent one) or read a stale value from a previous user on a '
              'shared device');
    });
  });

  group('registered from onProfileHydrated, once the cache is fresh',
      () {
    testWidgets('reel_v1 cohort registers reel_v1', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final analytics = _SuperPropSpy();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [analyticsProvider.overrideWithValue(analytics)],
          child: const AppLifecycleObserver(child: SizedBox.shrink()),
        ),
      );
      await tester.pump();

      // Simulates the sync_all_user_data hydration that wires the real
      // trigger: hydrateFromProfile writes the cache AND fires
      // onProfileHydrated itself (gating_service.dart's own call chain) — no
      // need to invoke the hook directly, which would test the wiring
      // against itself rather than the real caller.
      await GatingService().hydrateFromProfile({
        'free_tier_cohort': GatingService.cohortReelV1,
      });
      await tester.pump();

      expect(analytics.sawFreeTierCohort, isTrue,
          reason: 'onProfileHydrated fired but free_tier_cohort was never '
              'registered');
      final registered = analytics.superPropCalls.firstWhere(
        (c) => c.containsKey(AnalyticsEvents.propFreeTierCohort),
      );
      expect(registered[AnalyticsEvents.propFreeTierCohort],
          GatingService.cohortReelV1);
    });

    testWidgets('legacy (absent/unrecognised) cohort registers legacy',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final analytics = _SuperPropSpy();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [analyticsProvider.overrideWithValue(analytics)],
          child: const AppLifecycleObserver(child: SizedBox.shrink()),
        ),
      );
      await tester.pump();

      await GatingService().hydrateFromProfile({
        // No free_tier_cohort key at all — the pre-20260727100300-backend /
        // genuine-legacy-account case `hydrateFromProfile`'s own comment
        // documents.
      });
      await tester.pump();

      expect(analytics.sawFreeTierCohort, isTrue);
      final registered = analytics.superPropCalls.firstWhere(
        (c) => c.containsKey(AnalyticsEvents.propFreeTierCohort),
      );
      expect(registered[AnalyticsEvents.propFreeTierCohort], 'legacy');
    });

    testWidgets('a throwing read never breaks the hydration signal',
        (tester) async {
      // The banner-refresh statement that already lived in this hook must
      // keep firing even if the analytics registration added alongside it
      // throws.
      SharedPreferences.setMockInitialValues({});
      final analytics = _ThrowingSpy();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [analyticsProvider.overrideWithValue(analytics)],
          child: const AppLifecycleObserver(child: SizedBox.shrink()),
        ),
      );
      await tester.pump();

      await expectLater(
        GatingService()
            .hydrateFromProfile({'free_tier_cohort': GatingService.cohortReelV1}),
        completes,
      );
      await tester.pump();
    });
  });
}

class _ThrowingSpy extends AnalyticsService {
  @override
  void setSuperProperties(Map<String, dynamic> props) =>
      throw StateError('boom');

  @override
  void track(String event, {Map<String, dynamic>? properties}) {}
}
