import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/onboarding_screen.dart';
import 'package:sakina/features/onboarding/screens/sign_up_email_screen.dart';
import 'package:sakina/features/onboarding/screens/sign_up_password_screen.dart';
import 'package:sakina/features/onboarding/widgets/onboarding_autofocus_text_field.dart';
import 'package:sakina/services/app_config_service.dart';

import 'screens/_test_utils.dart';

/// The signup trio's autofocus is gated on "am I the page on display", which
/// is a different index in each of the three flows (One Ship W2-E1):
/// reel email=10/password=11, trimmed 14/15, legacy 19/20. Before W2 the check
/// read a module constant, so the screen could only ever autofocus in one flow.
void main() {
  Future<void> pumpAt(
    WidgetTester tester,
    FlowStubAppConfig config,
    int page,
  ) async {
    useOnboardingViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigServiceProvider.overrideWithValue(config),
          appSessionProvider.overrideWithValue(buildTestAppSession()),
          cachedOnboardingStateProvider
              .overrideWithValue(OnboardingState(currentPage: page)),
        ],
        // Keyed on flow AND page: `_flowFuture` and `_pageController` are both
        // `late final` per State, so re-pumping an unkeyed screen in the same
        // test silently reuses the first flow and the first start page.
        child: MaterialApp(
          home: OnboardingScreen(key: ValueKey('${config.flow}-$page')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  bool emailAutofocus(WidgetTester tester) => tester
      .widget<OnboardingAutofocusTextField>(
        find.descendant(
          of: find.byType(SignUpEmailScreen),
          matching: find.byType(OnboardingAutofocusTextField),
        ),
      )
      .shouldRequestFocus;

  testWidgets('reel: the email screen autofocuses on page 10', (tester) async {
    await pumpAt(
      tester,
      FlowStubAppConfig.reel(),
      onboardingReelEmailPageIndex,
    );
    expect(emailAutofocus(tester), isTrue);
    expect(onboardingReelEmailPageIndex, 10);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('trimmed: the email screen autofocuses on page 14',
      (tester) async {
    await pumpAt(
      tester,
      FlowStubAppConfig.trimmed(),
      onboardingEmailPageIndex,
    );
    expect(emailAutofocus(tester), isTrue);
    expect(onboardingEmailPageIndex, 14);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('legacy: the email screen autofocuses on page 19',
      (tester) async {
    // Latent bug the reel flow's `pageIndex` param exposed: the legacy list
    // left these screens comparing against the TRIMMED constants, so the field
    // never autofocused for a kill-switch-to-legacy user.
    await pumpAt(
      tester,
      FlowStubAppConfig.legacy(),
      onboardingLegacyEmailPageIndex,
    );
    expect(emailAutofocus(tester), isTrue);
    expect(onboardingLegacyEmailPageIndex, 19);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets(
    'the email screen does NOT autofocus when shown off its own page',
    (tester) async {
      useOnboardingViewport(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cachedOnboardingStateProvider.overrideWithValue(
              const OnboardingState(currentPage: 16),
            ),
          ],
          child: MaterialApp(
            home: SignUpEmailScreen(onNext: () {}, onBack: () {}),
          ),
        ),
      );
      await tester.pump();

      expect(
        emailAutofocus(tester),
        isFalse,
        reason: 'Autofocus must be gated to the email page; otherwise the '
            'keyboard would steal focus on adjacent pages built lazily by '
            'PageView.',
      );

      await tester.pump(const Duration(seconds: 2));
    },
  );

  // One pump per test on purpose: `onboardingProvider` reads
  // `cachedOnboardingStateProvider` ONCE at creation, so a second pumpWidget in
  // the same test keeps the first start page no matter what the override says.
  group('signup-trio PageView index structural pin', () {
    testWidgets('reel: page 10 is the email screen', (tester) async {
      await pumpAt(
        tester,
        FlowStubAppConfig.reel(),
        onboardingReelEmailPageIndex,
      );
      expect(find.byType(SignUpEmailScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('reel: page 11 is the password screen', (tester) async {
      await pumpAt(
        tester,
        FlowStubAppConfig.reel(),
        onboardingReelPasswordPageIndex,
      );
      expect(find.byType(SignUpPasswordScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('trimmed: page 14 is the email screen', (tester) async {
      await pumpAt(
        tester,
        FlowStubAppConfig.trimmed(),
        onboardingEmailPageIndex,
      );
      expect(find.byType(SignUpEmailScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('trimmed: page 15 is the password screen', (tester) async {
      await pumpAt(
        tester,
        FlowStubAppConfig.trimmed(),
        onboardingPasswordPageIndex,
      );
      expect(find.byType(SignUpPasswordScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });

    test('constant values match the expected PageView indices', () {
      expect(onboardingReelEmailPageIndex, 10);
      expect(onboardingReelPasswordPageIndex, 11);
      expect(onboardingReelPostSignupPageIndex, 12);

      expect(onboardingEmailPageIndex, 14);
      expect(onboardingPasswordPageIndex, 15);
      expect(onboardingPostSignupPageIndex, 16);
    });
  });
}
