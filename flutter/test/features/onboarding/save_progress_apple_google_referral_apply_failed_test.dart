import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';

/// Notifier-level pin for the `referralApplyFailedReason` contract.
///
/// The Apple, Google, and Email signup paths in SaveProgressScreen /
/// SignUpPasswordScreen all call `setReferralApplyFailedReason(reason)` when
/// `applyPendingReferralIfAny` returns `ok:false` with reason `invalid` or
/// `self_referral`. The EncouragementScreen drains this flag on mount and
/// fires a recovery snackbar pointing the user at Settings → Redeem.
///
/// The Apple/Google code paths themselves exercise platform SDKs and can't
/// be widget-tested here. The cleanest pin is at the notifier level: as long
/// as the public contract holds (set, clear, replace, no prefs leak), all
/// three signup paths and the EncouragementScreen consumer remain wired up
/// correctly.
void main() {
  group('OnboardingNotifier.setReferralApplyFailedReason', () {
    test('defaults to null on a fresh notifier', () {
      final notifier = OnboardingNotifier();
      expect(notifier.state.referralApplyFailedReason, isNull);
      notifier.dispose();
    });

    test('set stores the reason on state', () {
      final notifier = OnboardingNotifier();
      notifier.setReferralApplyFailedReason('invalid');
      expect(notifier.state.referralApplyFailedReason, 'invalid');
      notifier.dispose();
    });

    test('clear resets the flag back to null', () {
      final notifier = OnboardingNotifier();
      notifier.setReferralApplyFailedReason('invalid');
      expect(notifier.state.referralApplyFailedReason, 'invalid');

      notifier.clearReferralApplyFailedReason();
      expect(notifier.state.referralApplyFailedReason, isNull);
      notifier.dispose();
    });

    test('self_referral reason is stored verbatim', () {
      final notifier = OnboardingNotifier();
      notifier.setReferralApplyFailedReason('self_referral');
      expect(notifier.state.referralApplyFailedReason, 'self_referral');
      notifier.dispose();
    });

    test('second set replaces the first (last-write-wins, no append)', () {
      final notifier = OnboardingNotifier();
      notifier.setReferralApplyFailedReason('invalid');
      expect(notifier.state.referralApplyFailedReason, 'invalid');

      notifier.setReferralApplyFailedReason('self_referral');
      // Replaced, not appended/merged.
      expect(notifier.state.referralApplyFailedReason, 'self_referral');
      notifier.dispose();
    });

    test('set → clear → set cycle works (re-armable for re-signup attempts)',
        () {
      final notifier = OnboardingNotifier();
      notifier.setReferralApplyFailedReason('invalid');
      notifier.clearReferralApplyFailedReason();
      expect(notifier.state.referralApplyFailedReason, isNull);

      notifier.setReferralApplyFailedReason('self_referral');
      expect(notifier.state.referralApplyFailedReason, 'self_referral');
      notifier.dispose();
    });

    test(
        'flag does NOT serialize to prefs (transient UI signal — survives '
        'only the live session)', () {
      final notifier = OnboardingNotifier();
      notifier.setReferralApplyFailedReason('invalid');

      final json = notifier.state.toJson();
      // The whole point: a stale invalid code from a prior session must NOT
      // resurrect as a snackbar days later.
      expect(json.containsKey('referralApplyFailedReason'), isFalse,
          reason:
              'referralApplyFailedReason is a one-shot UI signal and must '
              'NOT be persisted via toJson — otherwise a stale value could '
              'fire on cold launch after the session ended.');
      notifier.dispose();
    });
  });
}
