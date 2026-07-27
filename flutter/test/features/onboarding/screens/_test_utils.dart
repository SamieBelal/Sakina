import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/services/app_config_service.dart';
import 'package:sakina/services/notification_service.dart';

/// Sets a phone-sized test viewport so onboarding screens (which target real
/// device heights, ~800+ logical px) don't overflow the default 800x600
/// test surface. Call in `setUp` / at the top of a widget test. The reset
/// is registered via `addTearDown` on the tester.
void useOnboardingViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// [AppConfigService] stub that answers the two onboarding flow flags
/// INDEPENDENTLY, so a test can pin any one of the three flows (W2-E1).
///
/// The pre-W2 stubs in this directory returned one bool for every key. That was
/// harmless while `onboarding_trim_enabled` was the only flag read here; the
/// moment `reel_first_onboarding_enabled` joined it, a blanket `true` silently
/// re-pointed every "trimmed flow" test at the REEL flow. Every flow test goes
/// through this class so that cannot recur.
class FlowStubAppConfig extends AppConfigService {
  FlowStubAppConfig(this.flow) : super.forTest();

  FlowStubAppConfig.reel() : this(OnboardingFlowKind.reel);
  FlowStubAppConfig.trimmed() : this(OnboardingFlowKind.trimmed);
  FlowStubAppConfig.legacy() : this(OnboardingFlowKind.legacy);

  final OnboardingFlowKind flow;

  @override
  Future<bool> getBool(String key, {required bool fallback}) async {
    if (key == reelFirstOnboardingFlag) {
      return flow == OnboardingFlowKind.reel;
    }
    if (key == 'onboarding_trim_enabled') {
      return flow != OnboardingFlowKind.legacy;
    }
    return fallback;
  }

  @override
  Future<void> primeCache(List<String> keys) async {}

  /// The stub IS the cache, so the flow resolver's cold-cache probe (which
  /// otherwise awaits a fresh read of the reel flag before deciding) has
  /// nothing to wait for. Without this the probe would fall through to real
  /// SharedPreferences and stall every flow test on an unmocked plugin.
  @override
  Future<bool> hasCachedValue(String key) async => true;
}

class _SilentNotificationService extends NotificationService {
  @override
  Future<void> identifyUser(String userId) async {}
  @override
  Future<void> logout() async {}
  @override
  Future<void> syncTimezone() async {}
  @override
  Future<void> requestPermissionIfPreviouslyEnabled() async {}
}

/// A quiet [AppSessionNotifier] for onboarding widget tests.
///
/// Needed by any test whose PageView can reach the final gate: that page
/// watches `appSessionProvider`, which throws "Must be overridden in
/// ProviderScope" if it is left alone. The reel flow makes this common — its
/// gate is only 12 pages in, and both a bounds clamp and the social-auth jump
/// land on it directly.
AppSessionNotifier buildTestAppSession({bool hardPaywallFlow = false}) {
  final session = AppSessionNotifier(
    initialOnboarded: true,
    authStateChanges: const Stream.empty(),
    isAuthenticatedProvider: () => true,
    currentUserIdProvider: () => 'u1',
    hydrateEconomyCache: () async {},
    hasCompletedOnboarding: () async => true,
    isPremiumReader: () async => false,
    hardPaywallFlowReader: () async => hardPaywallFlow,
    notificationService: _SilentNotificationService(),
  );
  addTearDown(session.dispose);
  return session;
}
