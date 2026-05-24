import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/encouragement_screen.dart';
import 'package:sakina/features/onboarding/screens/onboarding_screen.dart';
import 'package:sakina/features/onboarding/screens/sign_up_email_screen.dart';
import 'package:sakina/features/onboarding/screens/sign_up_password_screen.dart';
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

  // Structural pin: the 3 sign-up indices must map to their expected
  // screens. If a future PageView reshuffle silently moves SignUpEmailScreen
  // (or password / encouragement) to a different index, this test fails
  // loudly and the diff points the fix at the right place — instead of
  // autofocus quietly stopping work in the wild. The positive autofocus
  // test above implicitly relies on this too, but pinning it explicitly
  // makes the structural invariant obvious to anyone reordering pages.
  group('Sign-up PageView index structural pin', () {
    Future<void> pumpOnboardingAtPage(WidgetTester tester, int page) async {
      useOnboardingViewport(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cachedOnboardingStateProvider.overrideWithValue(
              OnboardingState(currentPage: page),
            ),
          ],
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      );
      await tester.pump();
    }

    testWidgets(
      'PageView index 19 (onboardingEmailPageIndex) is SignUpEmailScreen',
      (tester) async {
        await pumpOnboardingAtPage(tester, onboardingEmailPageIndex);
        expect(
          find.byType(SignUpEmailScreen),
          findsOneWidget,
          reason:
              'PageView index 19 must build SignUpEmailScreen. If this fails '
              'after a reorder, update onboardingEmailPageIndex in '
              'onboarding_provider.dart to the new PageView index AND audit '
              'the autofocus gate in sign_up_email_screen.dart for the same '
              'shift.',
        );
        // Let pending timers (entrance animations) settle so the test
        // teardown doesn't flag "Timer still pending."
        await tester.pump(const Duration(seconds: 2));
      },
    );

    testWidgets(
      'PageView index 20 (onboardingPasswordPageIndex) is SignUpPasswordScreen',
      (tester) async {
        await pumpOnboardingAtPage(tester, onboardingPasswordPageIndex);
        expect(
          find.byType(SignUpPasswordScreen),
          findsOneWidget,
          reason:
              'PageView index 20 must build SignUpPasswordScreen. Update '
              'onboardingPasswordPageIndex if this reshuffled.',
        );
        await tester.pump(const Duration(seconds: 2));
      },
    );

    testWidgets(
      'PageView index 21 (onboardingEncouragementPageIndex) is '
      'EncouragementScreen',
      (tester) async {
        await pumpOnboardingAtPage(tester, onboardingEncouragementPageIndex);
        expect(
          find.byType(EncouragementScreen),
          findsOneWidget,
          reason:
              'PageView index 21 must build EncouragementScreen. Update '
              'onboardingEncouragementPageIndex if this reshuffled.',
        );
        await tester.pump(const Duration(seconds: 2));
      },
    );

    test('constant values match expected PageView indices', () {
      expect(onboardingEmailPageIndex, 19);
      expect(onboardingPasswordPageIndex, 20);
      expect(onboardingEncouragementPageIndex, 21);
    });
  });
}
