import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/onboarding_screen.dart';
import 'package:sakina/features/onboarding/screens/sign_up_email_screen.dart';
import 'package:sakina/features/onboarding/screens/sign_up_password_screen.dart';
import 'package:sakina/features/onboarding/widgets/onboarding_autofocus_text_field.dart';
import 'package:sakina/services/app_config_service.dart';

import 'screens/_test_utils.dart';

// Trimmed-flow refactor (2026-05-25, Option α): page indices renumbered.
// New trimmed indices: email=14, password=15, post-signup=16.
class _StubAppConfig extends AppConfigService {
  _StubAppConfig({this.trimmed = true}) : super.forTest();
  final bool trimmed;
  @override
  Future<bool> getBool(String key, {required bool fallback}) async => trimmed;
  @override
  Future<void> primeCache(List<String> keys) async {}
}

void main() {
  testWidgets(
    'Sign-up email screen autofocus fires when currentPage == '
    'onboardingEmailPageIndex (14)',
    (tester) async {
      useOnboardingViewport(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigServiceProvider.overrideWithValue(_StubAppConfig()),
            cachedOnboardingStateProvider.overrideWithValue(
              const OnboardingState(currentPage: onboardingEmailPageIndex),
            ),
          ],
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      );
      await tester.pump();
      await tester.pump();

      final field = tester.widget<OnboardingAutofocusTextField>(
        find.descendant(
          of: find.byType(SignUpEmailScreen),
          matching: find.byType(OnboardingAutofocusTextField),
        ),
      );

      expect(
        field.shouldRequestFocus,
        isTrue,
        reason:
            'On the email screen the text field must autofocus.',
      );
      expect(onboardingEmailPageIndex, 14);

      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets(
    'Sign-up email screen does NOT autofocus when shown off its own page',
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

      final field = tester.widget<OnboardingAutofocusTextField>(
        find.descendant(
          of: find.byType(SignUpEmailScreen),
          matching: find.byType(OnboardingAutofocusTextField),
        ),
      );

      expect(
        field.shouldRequestFocus,
        isFalse,
        reason:
            'Autofocus must be gated to the email page; otherwise the keyboard '
            'would steal focus on adjacent pages built lazily by PageView.',
      );

      await tester.pump(const Duration(seconds: 2));
    },
  );

  group('Sign-up PageView index structural pin', () {
    Future<void> pumpOnboardingAtPage(WidgetTester tester, int page) async {
      useOnboardingViewport(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigServiceProvider.overrideWithValue(_StubAppConfig()),
            cachedOnboardingStateProvider.overrideWithValue(
              OnboardingState(currentPage: page),
            ),
          ],
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets(
      'PageView index 14 (onboardingEmailPageIndex) is SignUpEmailScreen',
      (tester) async {
        await pumpOnboardingAtPage(tester, onboardingEmailPageIndex);
        expect(find.byType(SignUpEmailScreen), findsOneWidget);
        await tester.pump(const Duration(seconds: 2));
      },
    );

    testWidgets(
      'PageView index 15 (onboardingPasswordPageIndex) is SignUpPasswordScreen',
      (tester) async {
        await pumpOnboardingAtPage(tester, onboardingPasswordPageIndex);
        expect(find.byType(SignUpPasswordScreen), findsOneWidget);
        await tester.pump(const Duration(seconds: 2));
      },
    );

    test('constant values match expected PageView indices', () {
      expect(onboardingEmailPageIndex, 14);
      expect(onboardingPasswordPageIndex, 15);
      expect(onboardingPostSignupPageIndex, 16);
    });
  });
}
