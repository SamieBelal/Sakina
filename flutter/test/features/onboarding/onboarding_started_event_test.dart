import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/features/onboarding/screens/onboarding_screen.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/app_config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/_test_utils.dart';

/// Records every track call so we can assert the funnel-entry event fires.
class _SpyAnalytics extends AnalyticsService {
  final events = <({String event, Map<String, dynamic>? props})>[];

  @override
  void track(String event, {Map<String, dynamic>? properties}) =>
      events.add((event: event, props: properties));

  // timeEvent is invoked from the same post-frame callback; swallow it.
  @override
  void timeEvent(String event) {}
}

/// Trimmed-flow stub, mirroring onboarding_flow_integration_test.dart.
class _StubAppConfig extends AppConfigService {
  _StubAppConfig() : super.forTest();
  @override
  Future<bool> getBool(String key, {required bool fallback}) async => true;
  @override
  Future<void> primeCache(List<String> keys) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The flow resolver probes the app_config CACHE (SharedPreferences) before
  // deciding, so every test that mounts OnboardingScreen needs prefs available.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('OnboardingScreen fires onboarding_started exactly once',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final spy = _SpyAnalytics();
    // The screen reads the session in initState to decide whether a saved run
    // belongs to an account that still exists. Authenticated here, which is the
    // ordinary case and leaves the restart path untaken.
    final appSession = AppSessionNotifier(
      initialOnboarded: false,
      authStateChanges: const Stream<AuthState>.empty(),
      isAuthenticatedProvider: () => true,
      currentUserIdProvider: () => 'user-1',
      hydrateEconomyCache: () async {},
      hasCompletedOnboarding: () async => false,
    );
    addTearDown(appSession.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsProvider.overrideWithValue(spy),
          appConfigServiceProvider.overrideWithValue(_StubAppConfig()),
          appSessionProvider.overrideWithValue(appSession),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    // The event fires from the flow-future continuation, an await or two after
    // initState.
    await tester.pump();
    await tester.pump();

    final started =
        spy.events.where((e) => e.event == AnalyticsEvents.onboardingStarted);
    expect(started, hasLength(1),
        reason: 'onboarding_started is the funnel-entry denominator — once per '
            'onboarding start');
    expect(started.single.props?['entry_page'], 0,
        reason: 'a fresh start carries entry_page 0');

    await tester.pumpAndSettle(const Duration(seconds: 2));
  });

  testWidgets(
      'the FIRST step_viewed carries the RESOLVED flow\'s step name, not the '
      'optimistic reel default', (tester) async {
    // The flow flag resolves one await after initState, and `_flow` starts
    // optimistically on `reel`. Emitting the entry events from an initState
    // post-frame callback therefore stamped EVERY kill-switch user's first
    // funnel event with a reel step name for a page they never saw — the
    // funnel's widest step, mis-segmented. The entry events now ride the
    // flow-future continuation instead.
    useOnboardingViewport(tester);
    final spy = _SpyAnalytics();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsProvider.overrideWithValue(spy),
          appConfigServiceProvider
              .overrideWithValue(FlowStubAppConfig.trimmed()),
          appSessionProvider.overrideWithValue(buildTestAppSession()),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }

    final viewed = spy.events
        .where((e) => e.event == AnalyticsEvents.onboardingStepViewed)
        .toList();
    expect(viewed, hasLength(1));
    expect(viewed.single.props?['step_name'], 'first_checkin',
        reason: 'trimmed page 0 is the first check-in; reel_hook would be a '
            'page this user is never shown');
    expect(viewed.single.props?['step_index'], 0);
    expect(
      spy.events.where((e) => e.event == AnalyticsEvents.onboardingStarted),
      hasLength(1),
      reason: 'the entry event moved with the step event — still exactly once',
    );

    await tester.pump(const Duration(seconds: 2));
  });
}
