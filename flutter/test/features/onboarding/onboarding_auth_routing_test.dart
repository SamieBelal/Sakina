import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/onboarding_screen.dart';
import 'package:sakina/features/onboarding/screens/paywall_screen.dart';
import 'package:sakina/features/onboarding/screens/save_progress_screen.dart';
import 'package:sakina/features/onboarding/screens/sign_up_password_screen.dart';
import 'package:sakina/features/onboarding/widgets/onboarding_autofocus_text_field.dart';
import 'package:sakina/services/app_config_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_supabase_sync_service.dart';
import 'screens/_test_utils.dart';

/// Social-auth users are already authenticated when OAuth returns, so the
/// email + password screens are redundant and must be skipped. WHERE they land
/// differs per flow (One Ship W2-E2, plan review 10):
///
///   * trimmed → Generating (16), the first page of the paywall flow.
///   * reel    → the final gate (13). The reveal and the plan both ran BEFORE
///               signup, so nothing is left to show them.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // The reel landing is the paywall gate; these are the seams that let it
    // render without StoreKit or a live Supabase.
    debugDisablePaywallAnimations = true;
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(FakeSupabaseSyncService(userId: 'u1'));
  });

  tearDown(() {
    debugDisablePaywallAnimations = false;
    SupabaseSyncService.debugReset();
  });

  Future<ProviderContainer> pumpAt(
    WidgetTester tester,
    FlowStubAppConfig config,
    int page,
  ) async {
    // The reel flow's social-auth landing IS the paywall gate, which overflows
    // a 390pt-wide test surface (flutter_test renders every glyph as a full em
    // square — same artifact documented in hook_problem_screen_test).
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigServiceProvider.overrideWithValue(config),
          appSessionProvider.overrideWithValue(buildTestAppSession()),
          cachedOnboardingStateProvider
              .overrideWithValue(OnboardingState(currentPage: page)),
        ],
        child: MaterialApp(home: OnboardingScreen(key: ValueKey(config.flow))),
      ),
    );
    // Three pumps: the reel flag future, the trim flag future (non-reel flows
    // await both), then the `.then` → setState rebuild.
    await tester.pump();
    await tester.pump();
    await tester.pump();
    return ProviderScope.containerOf(
      tester.element(find.byType(OnboardingScreen)),
    );
  }

  /// Invokes the wiring under test directly. Driving the real Apple/Google
  /// buttons would call native sign-in plugins, which can't run in a widget
  /// test; the routing AFTER OAuth succeeds is what this pins.
  void completeSocialAuth(WidgetTester tester) {
    tester
        .widget<SaveProgressScreen>(find.byType(SaveProgressScreen))
        .onSocialAuthComplete();
  }

  testWidgets(
    'reel flow: social auth on Save Progress (10) jumps to the final gate (13)',
    (tester) async {
      final container = await pumpAt(tester, FlowStubAppConfig.reel(), 10);
      expect(container.read(onboardingProvider).currentPage, 10,
          reason: 'precondition: starts on Save Progress (reel index)');

      completeSocialAuth(tester);
      // _goToPage uses jumpToPage when |delta| > 1, so state advances on the
      // next pump.
      await tester.pump();

      expect(
        container.read(onboardingProvider).currentPage,
        onboardingReelPostSignupPageIndex,
        reason: 'the reel flow has no post-signup interstitial — the page '
            'after the trio IS the paywall gate',
      );
      expect(onboardingReelPostSignupPageIndex, 13);
      expect(onboardingReelPostSignupPageIndex, onboardingReelLastPageIndex);

      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets(
    'trimmed flow: social auth on Save Progress (13) jumps to post-signup (16)',
    (tester) async {
      final container = await pumpAt(tester, FlowStubAppConfig.trimmed(), 13);
      expect(container.read(onboardingProvider).currentPage, 13,
          reason: 'precondition: starts on Save Progress (trimmed index)');

      completeSocialAuth(tester);
      await tester.pump();

      expect(
        container.read(onboardingProvider).currentPage,
        onboardingPostSignupPageIndex,
      );
      // Pinned 2026-05-25 by the trimmed-flow refactor; unchanged by W2.
      expect(onboardingPostSignupPageIndex, 16);

      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets(
    'legacy flow: social auth on Save Progress (18) jumps to Encouragement (21)',
    (tester) async {
      final container = await pumpAt(tester, FlowStubAppConfig.legacy(), 18);
      expect(container.read(onboardingProvider).currentPage, 18);

      completeSocialAuth(tester);
      await tester.pump();

      expect(
        container.read(onboardingProvider).currentPage,
        onboardingLegacyEncouragementPageIndex,
      );
      expect(onboardingLegacyEncouragementPageIndex, 21);

      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets(
    'reel flow: the password screen autofocuses on ITS page index (11)',
    (tester) async {
      await pumpAt(
        tester,
        FlowStubAppConfig.reel(),
        onboardingReelPasswordPageIndex,
      );

      final field = tester.widget<OnboardingAutofocusTextField>(
        find.descendant(
          of: find.byType(SignUpPasswordScreen),
          matching: find.byType(OnboardingAutofocusTextField),
        ),
      );

      expect(
        field.shouldRequestFocus,
        isTrue,
        reason: 'a page-index check pinned to the TRIMMED constant would '
            'silently disable focus for every reel user',
      );

      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets(
    'trimmed flow: the password screen autofocus is still gated on 15',
    (tester) async {
      await pumpAt(
        tester,
        FlowStubAppConfig.trimmed(),
        onboardingPasswordPageIndex,
      );

      final field = tester.widget<OnboardingAutofocusTextField>(
        find.descendant(
          of: find.byType(SignUpPasswordScreen),
          matching: find.byType(OnboardingAutofocusTextField),
        ),
      );

      expect(field.shouldRequestFocus, isTrue);
      expect(onboardingPasswordPageIndex, 15);

      await tester.pump(const Duration(seconds: 2));
    },
  );
}
