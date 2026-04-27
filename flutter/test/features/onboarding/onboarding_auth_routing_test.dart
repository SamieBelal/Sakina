import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/onboarding_screen.dart';
import 'package:sakina/features/onboarding/screens/save_progress_screen.dart';
import 'package:sakina/features/onboarding/screens/sign_up_password_screen.dart';
import 'package:sakina/features/onboarding/widgets/onboarding_autofocus_text_field.dart';

import 'screens/_test_utils.dart';

void main() {
  testWidgets(
    'social auth on Save Progress jumps to Encouragement (page 24), '
    'skipping Email (22) and Password (23)',
    (tester) async {
      useOnboardingViewport(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cachedOnboardingStateProvider.overrideWithValue(
              const OnboardingState(currentPage: 21),
            ),
          ],
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      );
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(OnboardingScreen)),
      );
      expect(container.read(onboardingProvider).currentPage, 21,
          reason: 'precondition: starts on Save Progress page');

      // Invoke the wiring under test directly. Exercising the actual Apple/
      // Google buttons would invoke native sign-in plugins which can't run
      // in widget tests; what we care about is the routing wiring after
      // OAuth succeeds.
      final saveProgress = tester.widget<SaveProgressScreen>(
        find.byType(SaveProgressScreen),
      );
      saveProgress.onSocialAuthComplete();

      // _goToPage uses jumpToPage when |delta| > 1, so state advances on
      // the next pump.
      await tester.pump();

      expect(
        container.read(onboardingProvider).currentPage,
        24,
        reason:
            'Social-auth users are already authenticated; the email + password '
            'screens are redundant and must be skipped.',
      );

      // Drain pending flutter_animate timers before teardown.
      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets(
    'Sign-up password screen autofocus is gated on the correct page index',
    (tester) async {
      useOnboardingViewport(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cachedOnboardingStateProvider.overrideWithValue(
              const OnboardingState(currentPage: 23),
            ),
          ],
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      );
      await tester.pump();

      final field = tester.widget<OnboardingAutofocusTextField>(
        find.descendant(
          of: find.byType(SignUpPasswordScreen),
          matching: find.byType(OnboardingAutofocusTextField),
        ),
      );

      expect(
        field.shouldRequestFocus,
        isTrue,
        reason:
            'On the password screen (page 23) the text field must autofocus. '
            'A stale page-index check silently disables focus.',
      );

      await tester.pump(const Duration(seconds: 2));
    },
  );
}
