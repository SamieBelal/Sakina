import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/screens/onboarding_screen.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/app_config_service.dart';

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
  testWidgets('OnboardingScreen fires onboarding_started exactly once',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final spy = _SpyAnalytics();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsProvider.overrideWithValue(spy),
          appConfigServiceProvider.overrideWithValue(_StubAppConfig()),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    // The event fires from a post-frame callback in initState.
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
}
