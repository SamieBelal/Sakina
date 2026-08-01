import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/features/onboarding/screens/onboarding_screen.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/app_config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/_test_utils.dart';

/// W6 Wave A — the LOAD-BEARING ordering pin (plan §4 Wave A).
///
/// `onboarding_flow` (and the `unknown`-at-entry reel-hook pair) must reach
/// Mixpanel BEFORE the first `onboarding_started` fires: Mixpanel stamps super
/// properties at SEND time and never backfills, so a registration one line too
/// low costs the funnel's WIDEST event its segmentation, and the resulting
/// chart just looks like organic traffic — no error, no signal.
///
/// **MUTATION THAT MUST FAIL THIS TEST:** move the `setSuperProperties` call
/// in `onboarding_screen.dart`'s `_flowFuture.then` continuation to AFTER
/// `_emitEntryFunnelEvents(initialPage)`. Verified by hand: with the call
/// moved down, `superIndex` lands after `startedIndex` and the
/// `lessThan` assertion fails.
class _OrderedSpy extends AnalyticsService {
  /// One entry per `setSuperProperties`/`track` call, in call order, so the
  /// two streams can be compared against each other directly.
  final List<String> callOrder = [];
  final List<Map<String, dynamic>> superPropCalls = [];

  @override
  void setSuperProperties(Map<String, dynamic> props) {
    callOrder.add('super:${props.keys.join(',')}');
    superPropCalls.add(Map<String, dynamic>.from(props));
  }

  @override
  void track(String event, {Map<String, dynamic>? properties}) {
    callOrder.add('track:$event');
  }

  @override
  void timeEvent(String event) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'onboarding_flow / reel_hook / reel_hook_source are registered before '
      'onboarding_started', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final analytics = _OrderedSpy();
    useOnboardingViewport(tester);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigServiceProvider.overrideWithValue(FlowStubAppConfig.reel()),
          appSessionProvider.overrideWithValue(buildTestAppSession()),
          analyticsProvider.overrideWithValue(analytics),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    // The flow flag read and the `_flowFuture.then` continuation are both
    // async — a few pumps to let them settle, same as the sibling flow tests.
    for (var i = 0; i < 6; i++) {
      await tester.pump();
    }

    final superIndex = analytics.callOrder.indexWhere(
      (c) =>
          c.startsWith('super:') &&
          c.contains(AnalyticsEvents.propOnboardingFlow),
    );
    final startedIndex = analytics.callOrder
        .indexWhere((c) => c == 'track:${AnalyticsEvents.onboardingStarted}');

    expect(superIndex, isNot(-1),
        reason: 'onboarding_flow was never registered as a super property');
    expect(startedIndex, isNot(-1),
        reason: 'onboarding_started never fired');
    expect(
      superIndex,
      lessThan(startedIndex),
      reason: 'onboarding_flow must be registered BEFORE the funnel\'s '
          'widest event, or it is absent on every event before it forever',
    );

    // D2: reel_hook / reel_hook_source ride the SAME call as onboarding_flow
    // — registered together, at entry, both `unknown`.
    final props = analytics.superPropCalls[superIndex];
    expect(props[AnalyticsEvents.propReelHookSource],
        AnalyticsEvents.reelHookSourceUnknown);
    expect(
        props[AnalyticsEvents.propReelHook], AnalyticsEvents.reelHookSourceUnknown);

    // Flushes the hook screen's staggered fade-in animations so no timer is
    // still pending when the test ends (same convention as
    // onboarding_flow_integration_test.dart's pumpReel callers).
    await tester.pump(const Duration(seconds: 2));
  });
}
