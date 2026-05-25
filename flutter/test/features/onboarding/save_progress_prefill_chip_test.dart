import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/features/onboarding/screens/save_progress_screen.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/referral_service.dart';
import 'package:sakina/widgets/referral_code_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wider-than-default phone viewport. The onboarding `useOnboardingViewport`
/// helper (1170x2532 @ 3.0 dpr = 390 logical px wide) is too narrow once the
/// referral disclosure is inserted — Google Fonts metrics push the
/// SocialSignInButton row past 286px and trip a paint-time overflow that
/// fails the test before our `expect`s run. Using a wider iPad-class viewport
/// gives the layout enough headroom while still exercising the same code.
void _useWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1536, 2732);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

class _TrackingSpy extends AnalyticsService {
  final List<(String, Map<String, dynamic>?)> tracked = [];
  @override
  void track(String event, {Map<String, dynamic>? properties}) {
    tracked.add((event, properties));
  }
}

/// Fake referral service whose `validateCode` can be tuned to:
///   * return a fixed `bool` synchronously (default for valid/invalid),
///   * throw an Exception (network error),
///   * or be held open by a Completer so the test can observe the
///     loading state before the validation resolves.
class _FakeReferralService extends ReferralService {
  _FakeReferralService() : super(_StubSupabase());

  bool nextResult = true;
  Object? nextThrow;
  Completer<bool>? gateCompleter;
  final List<String> calls = [];

  @override
  Future<bool> validateCode(String code) async {
    calls.add(code);
    if (gateCompleter != null) {
      return gateCompleter!.future;
    }
    if (nextThrow != null) throw nextThrow!;
    return nextResult;
  }
}

class _StubSupabase extends Fake implements SupabaseClient {}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _TrackingSpy spy,
  required _FakeReferralService fakeReferral,
}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      analyticsProvider.overrideWithValue(spy),
      referralServiceProvider.overrideWithValue(fakeReferral),
    ],
    child: MaterialApp(
      home: SaveProgressScreen(
        onNext: () {},
        onBack: () {},
        onSocialAuthComplete: () {},
      ),
    ),
  ));
  // Initial pump triggers async _hydrateReferralPrefs. Let microtasks flush.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

/// Locate the `Container` decoration of the prefilled chip and return the
/// background color. The chip is the outermost decorated container that
/// contains the code text — searching upward from the code Text is robust
/// across animation/layout wrappers.
Color _chipBackgroundColor(WidgetTester tester, String code) {
  final container = tester.widgetList<Container>(find.byType(Container))
      .firstWhere((c) {
    final d = c.decoration;
    if (d is! BoxDecoration) return false;
    if (d.color != AppColors.primaryLight &&
        d.color != AppColors.surfaceLight) {
      return false;
    }
    // Must contain the code text somewhere in its subtree.
    final containerFinder = find.byWidget(c);
    return tester
        .widgetList(find.descendant(
            of: containerFinder, matching: find.text(code)))
        .isNotEmpty;
  });
  return (container.decoration as BoxDecoration).color!;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'a) Loading state — pre-validation pump shows optimistic check_circle, no subtitle',
    (tester) async {
      _useWideViewport(tester);
      SharedPreferences.setMockInitialValues({
        referralPendingReferralPrefsKey: 'PREFILLD1',
        referralPendingReferralSourcePrefsKey:
            AnalyticsEvents.referralSourceDeepLink,
      });

      final spy = _TrackingSpy();
      // Hold the validateCode future open with a Completer so we can pin
      // the loading-state visuals before resolution.
      final fake = _FakeReferralService()..gateCompleter = Completer<bool>();
      await _pumpScreen(tester, spy: spy, fakeReferral: fake);

      // Chip auto-expanded with optimistic green check (loading == null state
      // renders as if valid so the happy path doesn't flicker).
      expect(find.text('PREFILLD1'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.text('Change code'), findsOneWidget);

      // No problem subtitles are visible yet.
      expect(
        find.text("We couldn't verify this code. You can continue or change it."),
        findsNothing,
      );
      expect(
        find.text("Couldn't check right now — we'll verify when you sign up."),
        findsNothing,
      );

      // Other icon variants must not have been rendered.
      expect(find.byIcon(Icons.help_outline_rounded), findsNothing);
      expect(find.byIcon(Icons.wifi_off_rounded), findsNothing);

      // Tear-down: complete the gate so pending timers don't leak.
      fake.gateCompleter!.complete(true);
      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets(
    'b) Valid state — green check_circle + primaryLight chip background',
    (tester) async {
      _useWideViewport(tester);
      SharedPreferences.setMockInitialValues({
        referralPendingReferralPrefsKey: 'PREFILLD1',
        referralPendingReferralSourcePrefsKey:
            AnalyticsEvents.referralSourceDeepLink,
      });

      final spy = _TrackingSpy();
      final fake = _FakeReferralService()..nextResult = true;
      await _pumpScreen(tester, spy: spy, fakeReferral: fake);

      // Let validateCode microtask resolve + setState rebuild.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('PREFILLD1'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.help_outline_rounded), findsNothing);
      expect(find.byIcon(Icons.wifi_off_rounded), findsNothing);

      // Standard chip styling — primaryLight bg.
      expect(
        _chipBackgroundColor(tester, 'PREFILLD1'),
        AppColors.primaryLight,
      );

      // No problem subtitle present.
      expect(
        find.textContaining("couldn't verify"),
        findsNothing,
      );

      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets(
    'c) Invalid state — help icon + subtitle + Change code + sign-in buttons remain enabled',
    (tester) async {
      _useWideViewport(tester);
      SharedPreferences.setMockInitialValues({
        referralPendingReferralPrefsKey: 'PREFILLD1',
        referralPendingReferralSourcePrefsKey:
            AnalyticsEvents.referralSourceDeepLink,
      });

      final spy = _TrackingSpy();
      final fake = _FakeReferralService()..nextResult = false;
      await _pumpScreen(tester, spy: spy, fakeReferral: fake);

      // Let validateCode microtask resolve + setState rebuild.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Muted help icon now, green check is gone.
      expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      expect(find.byIcon(Icons.wifi_off_rounded), findsNothing);

      // Helper subtitle text rendered.
      expect(
        find.text(
            "We couldn't verify this code. You can continue or change it."),
        findsOneWidget,
      );

      // Chip background flipped to surfaceLight (problem state).
      expect(
        _chipBackgroundColor(tester, 'PREFILLD1'),
        AppColors.surfaceLight,
      );

      // Change-code escape hatch still present.
      expect(find.text('Change code'), findsOneWidget);

      // Continuation pin — sign-in buttons remain rendered (NEVER blocked).
      expect(find.text('Sign in with Apple'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets(
    'd) NetworkError state — wifi_off icon + soft-error subtitle',
    (tester) async {
      _useWideViewport(tester);
      SharedPreferences.setMockInitialValues({
        referralPendingReferralPrefsKey: 'PREFILLD1',
        referralPendingReferralSourcePrefsKey:
            AnalyticsEvents.referralSourceDeepLink,
      });

      final spy = _TrackingSpy();
      final fake = _FakeReferralService()
        ..nextThrow = Exception('connection refused');
      await _pumpScreen(tester, spy: spy, fakeReferral: fake);

      // Drain the validateCode microtask (throw + catch + setState).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Wifi-off icon now, no green check / help.
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      expect(find.byIcon(Icons.help_outline_rounded), findsNothing);

      // Soft-error subtitle rendered.
      expect(
        find.text(
            "Couldn't check right now — we'll verify when you sign up."),
        findsOneWidget,
      );

      // Chip flips to surfaceLight (problem state).
      expect(
        _chipBackgroundColor(tester, 'PREFILLD1'),
        AppColors.surfaceLight,
      );

      // Sign-in buttons still present (continuation unblocked).
      expect(find.text('Sign in with Apple'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets(
    'e) Race guard — tapping Change code mid-validate does NOT resurrect a stale subtitle',
    (tester) async {
      _useWideViewport(tester);
      SharedPreferences.setMockInitialValues({
        referralPendingReferralPrefsKey: 'PREFILLD1',
        referralPendingReferralSourcePrefsKey:
            AnalyticsEvents.referralSourceDeepLink,
      });

      final spy = _TrackingSpy();
      // Hold validation open so we can intercept it with "Change code".
      final completer = Completer<bool>();
      final fake = _FakeReferralService()..gateCompleter = completer;
      await _pumpScreen(tester, spy: spy, fakeReferral: fake);

      // Chip is in loading (optimistic check) state.
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.text('Change code'), findsOneWidget);

      // User taps Change code BEFORE validation resolves.
      await tester.tap(find.text('Change code'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Chip is gone (unlocked → editable ReferralCodeField rendered instead).
      expect(find.text('PREFILLD1'), findsNothing);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      expect(find.byType(ReferralCodeField), findsOneWidget);

      // Now resolve validation as invalid. Race guard in
      // `_validatePrefilledCode` checks `!_isPrefillLocked || _prefilledCode
      // != code` and bails — no setState, no chip resurrection.
      completer.complete(false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Chip and stale subtitle must NOT have come back.
      expect(find.text('PREFILLD1'), findsNothing);
      expect(
        find.text(
            "We couldn't verify this code. You can continue or change it."),
        findsNothing,
      );
      expect(find.byIcon(Icons.help_outline_rounded), findsNothing);
      // Editable field still rendered (unlock survived).
      expect(find.byType(ReferralCodeField), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
    },
  );
}
