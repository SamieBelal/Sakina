import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/encouragement_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// EncouragementScreen runs a post-frame callback in initState that drains
/// `OnboardingState.referralApplyFailedReason`. If the flag is non-null, the
/// screen:
///   1. clears the flag (so re-mounts don't double-fire)
///   2. shows a SnackBar with the canonical recovery copy
///
/// These tests pump the screen with various initial OnboardingState values
/// and assert the SnackBar surfaces (or doesn't) as expected.
///
/// Why we override the `onboardingProvider` directly with a pre-seeded
/// notifier: this is the cleanest way to inject initial state without
/// monkey-patching SharedPreferences and waiting for the async hydrate path.

const _expectedSnackbarCopy =
    "We couldn't apply your friend's code. You can try again in Settings → Redeem a referral code.";

/// Larger viewport — the encouragement illustration + headlines + tease copy
/// need ~iPad height to lay out without overflowing. Mirrors the wide-viewport
/// pattern used in save_progress_referral_field_test.dart.
void _useWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1536, 2732);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required OnboardingNotifier notifier,
}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      onboardingProvider.overrideWith((ref) => notifier),
    ],
    child: MaterialApp(
      home: EncouragementScreen(onNext: () {}, onBack: () {}),
    ),
  ));
  // Initial frame + post-frame callback in initState.
  await tester.pump();
  // Let the SnackBar animation start.
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('EncouragementScreen · recovery snackbar', () {
    testWidgets(
      "flag='invalid' → snackbar appears with canonical copy AND flag is cleared",
      (tester) async {
        _useWideViewport(tester);
        final notifier = OnboardingNotifier()
          ..setReferralApplyFailedReason('invalid');

        await _pumpScreen(tester, notifier: notifier);

        expect(find.text(_expectedSnackbarCopy), findsOneWidget,
            reason: 'Recovery snackbar must surface for reason=invalid');
        expect(notifier.state.referralApplyFailedReason, isNull,
            reason: 'Flag must be drained after the snackbar fires so a '
                're-mount does not double-fire');
      },
    );

    testWidgets(
      "flag='self_referral' → snackbar appears with the SAME canonical copy",
      (tester) async {
        // The copy intentionally doesn't differentiate between reasons —
        // both invalid and self_referral surface the same recovery message
        // pointing the user at Settings.
        _useWideViewport(tester);
        final notifier = OnboardingNotifier()
          ..setReferralApplyFailedReason('self_referral');

        await _pumpScreen(tester, notifier: notifier);

        expect(find.text(_expectedSnackbarCopy), findsOneWidget,
            reason: 'self_referral must surface the SAME recovery copy as '
                'invalid — the reason string is captured but not branched on');
        expect(notifier.state.referralApplyFailedReason, isNull);
      },
    );

    testWidgets(
      'flag=null → NO snackbar appears (the silent happy path)',
      (tester) async {
        _useWideViewport(tester);
        final notifier = OnboardingNotifier();
        expect(notifier.state.referralApplyFailedReason, isNull);

        await _pumpScreen(tester, notifier: notifier);

        expect(find.text(_expectedSnackbarCopy), findsNothing,
            reason: 'No flag set → no snackbar. The default onboarding '
                'experience must be clean.');
        expect(find.byType(SnackBar), findsNothing);
      },
    );

    testWidgets(
      're-mounting EncouragementScreen after first drain does NOT fire the '
      'snackbar a second time (because state.referralApplyFailedReason is null)',
      (tester) async {
        // Conceptually: imagine a user navigates away from EncouragementScreen
        // (e.g. taps back, then forward again) WITHIN the same onboarding
        // session. The flag was drained on the first mount, so the second
        // mount must be a no-op.
        //
        // We model this with two separate notifiers because StateNotifier
        // instances are disposed by their ProviderScope on tear-down — so
        // sharing a single notifier across two pumpWidget calls would hit
        // a "used after dispose" StateError. The contract under test is
        // about the FLAG VALUE on the SECOND mount, which is null because
        // the first mount cleared it.
        _useWideViewport(tester);

        // First mount with flag set — snackbar fires, flag drains.
        final first = OnboardingNotifier()
          ..setReferralApplyFailedReason('invalid');
        await _pumpScreen(tester, notifier: first);
        expect(find.text(_expectedSnackbarCopy), findsOneWidget);
        expect(first.state.referralApplyFailedReason, isNull,
            reason: 'First mount must drain the flag');

        // Tear the tree down.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();

        // Second mount with a flag-null notifier — represents the same
        // session state after the first drain.
        final second = OnboardingNotifier();
        expect(second.state.referralApplyFailedReason, isNull);
        await _pumpScreen(tester, notifier: second);

        expect(find.text(_expectedSnackbarCopy), findsNothing,
            reason: 'A second mount with flag=null must NOT re-fire the '
                'snackbar — that is the contract that prevents the '
                'recovery-snackbar from double-firing within an onboarding '
                'session.');
      },
    );

    testWidgets(
      'canonical recovery copy is pinned exactly (against copy drift)',
      (tester) async {
        // Copy drift is one of the easiest ways to break the EXP funnel
        // assertions. Pin the exact string verbatim — if a contributor
        // softens the language ("oops!" / "no worries") this test fails
        // and the change has to be explicit + reviewed.
        _useWideViewport(tester);
        final notifier = OnboardingNotifier()
          ..setReferralApplyFailedReason('invalid');

        await _pumpScreen(tester, notifier: notifier);

        final snack = tester.widget<SnackBar>(find.byType(SnackBar));
        final text = snack.content as Text;
        expect(
          text.data,
          _expectedSnackbarCopy,
          reason: 'Recovery copy must match the string pinned in this test '
              'verbatim — change both deliberately.',
        );
      },
    );
  });
}
