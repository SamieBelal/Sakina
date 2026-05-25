// Structural regression pin for the defensive cold-launch referral retry
// in `lib/core/app_session.dart`.
//
// CONTRACT: `AppSessionNotifier._reconcilePendingReferralOnAuth(userId)` MUST
// NOT touch the onboarding state's `referralApplyFailedReason` flag (or any
// other onboarding-scoped UI surface). The flag drives a "couldn't apply
// your code" snackbar shown DURING the onboarding paywall flow. The
// cold-launch retry fires after auth events — sometimes days after the user
// finished onboarding — so wiring it into the onboarding-state flag would
// surface a stale, contextless snackbar on home / settings / any random
// authenticated screen. This was the exact regression PR-19 introduced
// before this pin existed.
//
// WHY STRUCTURAL (source-read) RATHER THAN BEHAVIORAL.
// The method is private (`_reconcilePendingReferralOnAuth`), the snackbar
// is fired several layers above AppSession (onboarding screen reads
// `OnboardingState.referralApplyFailedReason`), and the surface in question
// (`onboardingProvider`) is not even imported in app_session.dart today.
// A behavioral test would have to spin up a full ProviderScope + GoRouter +
// fake auth + fake onboarding notifier just to assert "nothing happened" —
// expensive, brittle, and easy to silently break by mocking the wrong layer.
//
// A source-level assertion is precise: if a future refactor adds an import
// of `onboarding_provider.dart`, or starts calling `setReferralApplyFailedReason`,
// this test fails with a clear "you broke the contract" message before the
// regression ever ships. The cost is having to update the file at the same
// time as a legitimate (well-considered) change to that contract — which is
// the correct friction.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'app_session.dart does NOT reference onboarding state or the '
      'referralApplyFailedReason flag (cold-launch retry must stay silent)',
      () async {
    // Resolve the source file via the package's lib/ root. Tests run with
    // cwd == project root, so this relative path is stable.
    final file = File('lib/core/app_session.dart');
    expect(
      file.existsSync(),
      isTrue,
      reason: 'Expected to find lib/core/app_session.dart relative to '
          'project root (cwd: ${Directory.current.path})',
    );

    final source = await file.readAsString();

    // ---- Contract violations ------------------------------------------
    //
    // Each `expect` below is a separate assertion so a failure pinpoints
    // EXACTLY which contract clause was broken.

    expect(
      source.contains('setReferralApplyFailedReason'),
      isFalse,
      reason:
          'app_session.dart must NOT call setReferralApplyFailedReason. '
          'The defensive cold-launch retry fires AFTER onboarding; setting '
          'this flag here would surface a stale "couldn\'t apply your code" '
          'snackbar on home/settings days later. Route the failure through '
          "the onboarding flow's own apply path instead.",
    );

    expect(
      source.contains('referralApplyFailedReason'),
      isFalse,
      reason:
          'app_session.dart must NOT read or reference referralApplyFailedReason. '
          'See the regression note at the top of this test.',
    );

    expect(
      source.contains('onboardingProvider'),
      isFalse,
      reason:
          'app_session.dart must NOT depend on onboardingProvider. The '
          'cold-launch reconciler runs in an auth context that has no notion '
          'of "are we currently in onboarding" — wiring those layers together '
          'creates exactly the stale-snackbar bug this test pins against.',
    );

    expect(
      source.contains('OnboardingState'),
      isFalse,
      reason:
          'app_session.dart must NOT import or reference OnboardingState. '
          'The cold-launch reconciler must remain a fire-and-forget call '
          'to ReferralService — no UI side effects.',
    );

    expect(
      source.contains('OnboardingNotifier'),
      isFalse,
      reason:
          'app_session.dart must NOT import or reference OnboardingNotifier. '
          'Same reason as the OnboardingState pin above.',
    );

    // Positive pin: verify the reconciler itself still exists. If someone
    // deletes it entirely, that's also a contract change worth surfacing.
    expect(
      source.contains('_reconcilePendingReferralOnAuth'),
      isTrue,
      reason:
          'The defensive cold-launch reconciler appears to have been removed. '
          'If this is intentional (e.g., moved to a different layer) update '
          'this test to match the new location.',
    );
  });
}
