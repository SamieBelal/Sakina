import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/onboarding_screen.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/app_config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/_test_utils.dart';

/// A deleted account must not leave its answers behind for the next person.
///
/// The device keeps the whole onboarding blob in SharedPreferences. Deleting the
/// account server-side (or any other route that ends with a dead refresh token)
/// signs the device out but does NOT touch that blob — so the next "Get Started"
/// resumed the previous user's run: their intention, their name, their email,
/// and whatever page they had reached.
///
/// The discriminator is the saved PAGE, not a heuristic. The password screen only
/// advances past itself on a successful sign-up, so a saved page beyond it proves
/// an account was created. No session now means that account is gone.
///
/// Mid-flow users are deliberately untouched: everyone before the sign-up trio is
/// unauthenticated too, and restarting them would be a worse bug than this one.

class _SilentAnalytics extends AnalyticsService {
  @override
  void track(String event, {Map<String, dynamic>? properties}) {}
  @override
  void timeEvent(String event) {}
}

/// Forces the reel flow, which is the shipping page order.
class _ReelAppConfig extends AppConfigService {
  _ReelAppConfig() : super.forTest();
  @override
  Future<bool> getBool(String key, {required bool fallback}) async => true;
  @override
  Future<void> primeCache(List<String> keys) async {}
}

AppSessionNotifier _session({required bool authenticated}) =>
    AppSessionNotifier(
      initialOnboarded: false,
      authStateChanges: const Stream<AuthState>.empty(),
      isAuthenticatedProvider: () => authenticated,
      currentUserIdProvider: () => authenticated ? 'user-1' : null,
      hydrateEconomyCache: () async {},
      hasCompletedOnboarding: () async => false,
    );

/// A plain intake question, comfortably before the sign-up trio.
const int _midFlowPage = 3;

/// The previous user's run: they finished sign-up and reached the paywall.
const _postSignupRun = OnboardingState(
  currentPage: onboardingReelLastPageIndex,
  onboardingFlow: onboardingFlowReel,
  intention: 'Spiritual Growth',
  signUpName: 'Previous Person',
  signUpEmail: 'previous@example.com',
  ageRange: '25-34',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('shouldRestartOnboarding', () {
    test('a completed sign-up with no session means the account is gone', () {
      expect(
        shouldRestartOnboarding(
          savedPage: onboardingReelLastPageIndex,
          flow: OnboardingFlowKind.reel,
          isAuthenticated: false,
        ),
        isTrue,
      );
    });

    test('the same page with a session is an ordinary resume', () {
      expect(
        shouldRestartOnboarding(
          savedPage: onboardingReelLastPageIndex,
          flow: OnboardingFlowKind.reel,
          isAuthenticated: true,
        ),
        isFalse,
      );
    });

    test('a run that never reached sign-up is left alone', () {
      // Everyone mid-flow is unauthenticated — sign-up is the LAST step.
      for (final page in [
        1,
        onboardingReelNamePageIndex,
        onboardingReelEmailPageIndex,
        onboardingReelPasswordPageIndex,
      ]) {
        expect(
          shouldRestartOnboarding(
            savedPage: page,
            flow: OnboardingFlowKind.reel,
            isAuthenticated: false,
          ),
          isFalse,
          reason: 'page $page is reachable without ever creating an account',
        );
      }
    });

    test('holds for the kill-switch flows too', () {
      expect(
        shouldRestartOnboarding(
          savedPage: onboardingLastPageIndex,
          flow: OnboardingFlowKind.trimmed,
          isAuthenticated: false,
        ),
        isTrue,
      );
      expect(
        shouldRestartOnboarding(
          savedPage: onboardingPasswordPageIndex,
          flow: OnboardingFlowKind.trimmed,
          isAuthenticated: false,
        ),
        isFalse,
      );
    });

    test('an unresolved flow restarts a page past every flow\'s sign-up', () {
      // initState runs before the flag resolves and must not wait to decide.
      expect(
        shouldRestartOnboarding(
          savedPage: onboardingLegacyLastPageIndex,
          flow: null,
          isAuthenticated: false,
        ),
        isTrue,
      );
    });

    test(
        'an unresolved flow NEVER restarts a page that is a sign-up screen '
        'in some flow', () {
      // The predicate is `savedPage > boundary`, so a LOWER boundary matches
      // MORE pages. With the flow unknown the boundary must therefore be the
      // LATEST of the three, not the earliest: erring low wipes a live user's
      // whole intake, while erring high costs at most one frame before the
      // flow-exact pass corrects it.
      //
      // Reel 16/17 are the sign-up email and password screens — reachable by
      // someone who has never had an account, and the single most common place
      // to background the app (going to look up an email address).
      for (final page in [
        onboardingReelEmailPageIndex,
        onboardingReelPasswordPageIndex,
        onboardingLegacyEmailPageIndex,
        onboardingLegacyPasswordPageIndex,
      ]) {
        expect(
          shouldRestartOnboarding(
            savedPage: page,
            flow: null,
            isAuthenticated: false,
          ),
          isFalse,
          reason: 'page $page is a sign-up screen in at least one flow, so an '
              'unresolved flow must not throw the run away',
        );
      }
    });
  });

  group('OnboardingScreen', () {
    testWidgets('starts a deleted account\'s device from the very beginning',
        (tester) async {
      useOnboardingViewport(tester);
      final appSession = _session(authenticated: false);
      addTearDown(appSession.dispose);

      final container = ProviderContainer(
        overrides: [
          analyticsProvider.overrideWithValue(_SilentAnalytics()),
          appConfigServiceProvider.overrideWithValue(_ReelAppConfig()),
          appSessionProvider.overrideWithValue(appSession),
          cachedOnboardingStateProvider.overrideWithValue(_postSignupRun),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      final state = container.read(onboardingProvider);
      expect(state.currentPage, 0, reason: 'the run starts over, not mid-flow');
      expect(
        state.intention,
        isNull,
        reason: "the previous user's answers must not be inherited",
      );
      expect(state.signUpEmail, isNull);
      expect(state.signUpName, isNull);
      expect(state.ageRange, isNull);
    });

    testWidgets('leaves a signed-in returner exactly where they were',
        (tester) async {
      useOnboardingViewport(tester);
      final appSession = _session(authenticated: true);
      addTearDown(appSession.dispose);

      final container = ProviderContainer(
        overrides: [
          analyticsProvider.overrideWithValue(_SilentAnalytics()),
          appConfigServiceProvider.overrideWithValue(_ReelAppConfig()),
          appSessionProvider.overrideWithValue(appSession),
          cachedOnboardingStateProvider.overrideWithValue(_postSignupRun),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      );
      await tester.pump();
      await tester.pump();

      final state = container.read(onboardingProvider);
      expect(state.currentPage, onboardingReelLastPageIndex);
      expect(state.intention, 'Spiritual Growth');
    });

    testWidgets('preserves a mid-flow run that never created an account',
        (tester) async {
      useOnboardingViewport(tester);
      final appSession = _session(authenticated: false);
      addTearDown(appSession.dispose);

      final container = ProviderContainer(
        overrides: [
          analyticsProvider.overrideWithValue(_SilentAnalytics()),
          appConfigServiceProvider.overrideWithValue(_ReelAppConfig()),
          appSessionProvider.overrideWithValue(appSession),
          cachedOnboardingStateProvider.overrideWithValue(
            const OnboardingState(
              currentPage: _midFlowPage,
              onboardingFlow: onboardingFlowReel,
              intention: 'Difficult Time',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      final state = container.read(onboardingProvider);
      expect(
        state.currentPage,
        _midFlowPage,
        reason: 'they are mid-flow and unauthenticated because signup has not '
            'happened yet — that is not a deleted account',
      );
      expect(state.intention, 'Difficult Time');
    });
  });
}
