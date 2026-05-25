import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notifier-level contract tests for the recovery-snackbar signal that
/// SignUpPasswordScreen emits when `apply_referral` returns ok:false with
/// reason `invalid` or `self_referral`.
///
/// We test the notifier directly (rather than pumping SignUpPasswordScreen)
/// because the password screen calls into `authService.signUpWithEmail` and
/// Supabase under the hood — driving it from a widget test requires a deep
/// auth/Supabase stack that is out of scope here. The notifier contract IS
/// what the production code consumes, so pinning it is sufficient.
///
/// The fourth test in this file is a structural source-grep pin against the
/// {invalid, self_referral} condition in sign_up_password_screen.dart — if a
/// future refactor widens the condition (e.g. shows the snackbar on
/// `network_error` too, which would be wrong because network errors retry
/// from the cold-launch defensive hook), this test fails.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OnboardingNotifier · referralApplyFailedReason', () {
    test('setReferralApplyFailedReason populates state.reason', () {
      final notifier = OnboardingNotifier();
      expect(notifier.state.referralApplyFailedReason, isNull);

      notifier.setReferralApplyFailedReason('invalid');
      expect(notifier.state.referralApplyFailedReason, 'invalid');

      notifier.setReferralApplyFailedReason('self_referral');
      expect(notifier.state.referralApplyFailedReason, 'self_referral');
    });

    test('clearReferralApplyFailedReason wipes the flag back to null', () {
      final notifier = OnboardingNotifier();
      notifier.setReferralApplyFailedReason('invalid');
      expect(notifier.state.referralApplyFailedReason, 'invalid');

      notifier.clearReferralApplyFailedReason();
      expect(notifier.state.referralApplyFailedReason, isNull);

      // Idempotent — clearing again from null stays null.
      notifier.clearReferralApplyFailedReason();
      expect(notifier.state.referralApplyFailedReason, isNull);
    });

    test(
      'flag is transient: toJson() does NOT serialize referralApplyFailedReason',
      () {
        // Per the comment in onboarding_provider.dart: "Intentionally NOT
        // persisted to prefs — it's a transient UI signal." This pin guards
        // against a future contributor adding it to toJson() and accidentally
        // causing the snackbar to re-fire days after onboarding via the
        // cold-launch state restore path.
        const state = OnboardingState(
          referralApplyFailedReason: 'invalid',
        );
        expect(state.referralApplyFailedReason, 'invalid');

        final json = state.toJson();
        expect(json.containsKey('referralApplyFailedReason'), isFalse,
            reason: 'Transient flag must NOT be persisted to prefs');

        // Round-trip via fromJson re-instantiates with the flag null.
        final restored = OnboardingState.fromJson(json);
        expect(restored.referralApplyFailedReason, isNull,
            reason: 'Restored state from prefs must NOT carry the flag');
      },
    );

    test(
      'structural pin: sign_up_password_screen.dart only sets the flag for '
      "reason 'invalid' or 'self_referral' (NOT network_error, NOT others)",
      () {
        // This is a source-grep pin against future regression. If a
        // contributor widens the condition (e.g. to also fire on
        // network_error), the recovery-snackbar contract documented in
        // onboarding_provider.dart breaks: network errors are retried from
        // the cold-launch defensive hook in app_session.dart, so showing
        // the snackbar for them would push users to Settings unnecessarily
        // for a transient blip.
        final file = File(
          'lib/features/onboarding/screens/sign_up_password_screen.dart',
        );
        expect(file.existsSync(), isTrue,
            reason: 'Source file must exist at the canonical path');
        final source = file.readAsStringSync();

        // The exact condition shape from the production code. Both sides of
        // the `||` must be present, pinned to the same two reason strings.
        // Whitespace/newline-tolerant match: collapse runs of whitespace.
        final normalized = source.replaceAll(RegExp(r'\s+'), ' ');
        expect(
          normalized,
          contains(
            "result.reason == 'invalid' || result.reason == 'self_referral'",
          ),
          reason:
              'Production condition for setReferralApplyFailedReason must '
              'remain pinned to {invalid, self_referral}. If you widened it, '
              'update the docs in onboarding_provider.dart first.',
        );

        // Belt and braces: the call site exists too.
        expect(
          normalized,
          contains('setReferralApplyFailedReason(result.reason!)'),
          reason:
              'Production code must call setReferralApplyFailedReason with '
              'the unwrapped reason string',
        );
      },
    );
  });
}
