import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/sign_up_password_screen.dart';
import 'package:sakina/features/onboarding/widgets/onboarding_autofocus_text_field.dart';
import 'package:sakina/features/onboarding/widgets/onboarding_continue_button.dart';
import 'package:sakina/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/_test_utils.dart';

/// Widget-level regression guard for the post-signup session-race dead end.
///
/// Before the fix, when the recovery failed the screen showed
/// "Account created — tap Continue to finish signing in." — but tapping
/// Continue re-ran signUp and threw "User already registered", trapping the
/// user in onboarding. These tests pump the real screen with a fake
/// AuthService and assert the screen now:
///   - surfaces the ACTUAL auth error (so the user understands what to do),
///   - never shows the old dead-end copy,
///   - does NOT advance onboarding (onNext) when no session was established.
///
/// The happy / recovered paths fan out into the referral + persist stack,
/// which this repo deliberately does not widget-test (see
/// sign_up_password_referral_apply_failed_test.dart). The recovery DECISION
/// itself is covered exhaustively in test/services/sign_up_recovery_test.dart.

/// Fake that returns a canned [SignUpResult] without touching Supabase.
/// `signUpWithRecovery` is virtual on AuthService; `_supabase` is lazy and
/// never read because no other method runs.
class _StubAuthService extends AuthService {
  _StubAuthService(this._result);
  final SignUpResult _result;
  int callCount = 0;

  @override
  Future<SignUpResult> signUpWithRecovery(
    String email,
    String password, {
    String? fullName,
  }) async {
    callCount += 1;
    return _result;
  }
}

Future<_StubAuthService> _pumpPasswordScreen(
  WidgetTester tester,
  SignUpResult result, {
  required void Function() onNext,
}) async {
  useOnboardingViewport(tester);
  final auth = _StubAuthService(result);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        // Seed the notifier so signUpEmail is present (the screen returns
        // early without it) and the page is "active" for autofocus.
        cachedOnboardingStateProvider.overrideWithValue(
          const OnboardingState(
            currentPage: onboardingPasswordPageIndex,
            signUpEmail: 'taken@example.com',
          ),
        ),
      ],
      child: MaterialApp(
        home: SignUpPasswordScreen(onNext: onNext, onBack: () {}),
      ),
    ),
  );
  await tester.pump();
  return auth;
}

Future<void> _enterPasswordAndSubmit(WidgetTester tester) async {
  await tester.enterText(
    find.byType(OnboardingAutofocusTextField),
    'hunter2',
  );
  await tester.pump();
  await tester.tap(find.byType(OnboardingContinueButton));
  await tester.pump(); // run _submit
  await tester.pump(); // let the SnackBar mount
}

/// Drains the SnackBar's auto-dismiss timer (and any one-shot intro
/// animations) so the test doesn't trip the "Timer still pending" invariant.
/// Call AFTER asserting the SnackBar is visible.
Future<void> _drainTimers(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'failed recovery (existing email + wrong password) surfaces the real auth '
    'error, not the old dead-end copy, and does not advance',
    (tester) async {
      var nextCalled = false;
      final auth = await _pumpPasswordScreen(
        tester,
        const SignUpResult(
          SignUpOutcome.failed,
          errorMessage: 'Invalid login credentials',
        ),
        onNext: () => nextCalled = true,
      );

      await _enterPasswordAndSubmit(tester);

      expect(auth.callCount, 1, reason: 'signUpWithRecovery should run once');
      expect(find.text('Invalid login credentials'), findsOneWidget,
          reason: 'the actual auth error must reach the user');
      expect(
        find.textContaining('tap Continue to finish signing in'),
        findsNothing,
        reason: 'the dead-end recovery lie must be gone',
      );
      expect(nextCalled, isFalse,
          reason: 'no session established → onboarding must not advance');

      await _drainTimers(tester);
    },
  );

  testWidgets(
    'pure session-race failure (no auth message) shows the generic retry '
    'copy and does not advance',
    (tester) async {
      var nextCalled = false;
      await _pumpPasswordScreen(
        tester,
        const SignUpResult(SignUpOutcome.failed), // errorMessage null
        onNext: () => nextCalled = true,
      );

      await _enterPasswordAndSubmit(tester);

      expect(find.text('Something went wrong. Please try again.'),
          findsOneWidget);
      expect(find.textContaining('tap Continue to finish signing in'),
          findsNothing);
      expect(nextCalled, isFalse);

      await _drainTimers(tester);
    },
  );

  testWidgets(
    'email already registered → honest "log in instead" copy, no advance, and '
    're-tapping stays safe (the original dead-end loop is gone)',
    (tester) async {
      var nextCalled = false;
      final auth = await _pumpPasswordScreen(
        tester,
        const SignUpResult(SignUpOutcome.emailAlreadyRegistered),
        onNext: () => nextCalled = true,
      );

      await _enterPasswordAndSubmit(tester);

      expect(find.textContaining('already has an account'), findsOneWidget,
          reason: 'existing-email users are pointed at logging in');
      expect(find.textContaining('tap Continue to finish signing in'),
          findsNothing);
      expect(nextCalled, isFalse,
          reason: 'must NOT advance / overwrite the existing account');
      expect(auth.callCount, 1);

      // The original bug: a second tap re-ran signUp into a "User already
      // registered" dead end. Now it just re-shows the honest message — the
      // stub returns the same result, no crash, still no advance.
      await tester.tap(find.byType(OnboardingContinueButton));
      await tester.pump();
      await tester.pump();
      expect(auth.callCount, 2);
      expect(nextCalled, isFalse);

      await _drainTimers(tester);
    },
  );
}
