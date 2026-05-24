import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/onboarding_screen.dart';
import 'package:sakina/features/onboarding/screens/sign_up_email_screen.dart';
import 'package:sakina/features/onboarding/widgets/onboarding_autofocus_text_field.dart';

import 'screens/_test_utils.dart';

void main() {
  testWidgets(
    'Sign-up email screen autofocus fires when currentPage == '
    'onboardingEmailPageIndex (19)',
    (tester) async {
      useOnboardingViewport(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cachedOnboardingStateProvider.overrideWithValue(
              const OnboardingState(currentPage: onboardingEmailPageIndex),
            ),
          ],
          child: const MaterialApp(home: OnboardingScreen()),
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
        isTrue,
        reason:
            'On the email screen the text field must autofocus. The original '
            'bug gated on PageView index 21 (Encouragement) so keyboard never '
            'opened on the actual email screen at PageView index 19.',
      );
      // Pin the constant to its expected value — if PageView ordering shifts
      // again, this is the failure that points the fix at the right place.
      expect(onboardingEmailPageIndex, 19);

      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets(
    'Sign-up email screen does NOT autofocus when shown off its own page',
    (tester) async {
      useOnboardingViewport(tester);

      // Render the email screen in isolation while the provider says we are
      // on page 21 — the exact value the ORIGINAL bug used. Reverting the
      // fix to `currentPage == 21` would re-trigger autofocus here and
      // this assertion would flip from isFalse to isTrue, failing the test.
      // (Pre-fix code: `state.currentPage == 21` while screen actually sits
      // at PageView index 19. Page 21 was EncouragementScreen, so autofocus
      // never fired in practice — but as a regression pin, page 21 is the
      // most aggressive value to test against.)
      // PageView in OnboardingScreen is lazy and may not build the email
      // subtree from an arbitrary starting index, so we mount the screen
      // directly to exercise its own gating logic in isolation.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cachedOnboardingStateProvider.overrideWithValue(
              const OnboardingState(currentPage: 21),
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
}
