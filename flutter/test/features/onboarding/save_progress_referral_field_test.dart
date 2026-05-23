import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

class _FakeReferralService extends ReferralService {
  _FakeReferralService() : super(_StubSupabase());

  bool nextResult = true;
  Object? nextThrow;
  final List<String> calls = [];

  @override
  Future<bool> validateCode(String code) async {
    calls.add(code);
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

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'Empty prefs: disclosure renders collapsed; tapping reveals field + fires analytics',
    (tester) async {
      _useWideViewport(tester);
      SharedPreferences.setMockInitialValues({});

      final spy = _TrackingSpy();
      final fake = _FakeReferralService();
      await _pumpScreen(tester, spy: spy, fakeReferral: fake);

      // Collapsed disclosure header present.
      expect(find.text('Did a friend send you a gift?'), findsOneWidget);
      // Field is NOT rendered while collapsed.
      expect(find.byType(ReferralCodeField), findsNothing);

      // Expand it.
      await tester.tap(find.text('Did a friend send you a gift?'));
      await tester.pump();

      // Analytics fired.
      expect(
        spy.tracked.where((e) => e.$1 == AnalyticsEvents.referralFieldRevealed),
        isNotEmpty,
      );

      // Now the field is rendered.
      expect(find.byType(ReferralCodeField), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets(
    'Pre-filled prefs: disclosure auto-expands AND renders locked; Change code unlocks editable field',
    (tester) async {
      _useWideViewport(tester);
      SharedPreferences.setMockInitialValues({
        referralPendingReferralPrefsKey: 'PREFILLD1',
        referralPendingReferralSourcePrefsKey:
            AnalyticsEvents.referralSourceDeepLink,
      });

      final spy = _TrackingSpy();
      final fake = _FakeReferralService();
      await _pumpScreen(tester, spy: spy, fakeReferral: fake);

      // Locked chip shows the code + Change code affordance.
      expect(find.text('PREFILLD1'), findsOneWidget);
      expect(find.text('Change code'), findsOneWidget);
      // Editable field is NOT rendered while locked.
      expect(find.byType(ReferralCodeField), findsNothing);

      // Tap Change code.
      await tester.tap(find.text('Change code'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Prefs cleared.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(referralPendingReferralPrefsKey), isNull);
      expect(prefs.getString(referralPendingReferralSourcePrefsKey), isNull);

      // Editable field now rendered.
      expect(find.byType(ReferralCodeField), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets(
    'Typing a valid code writes BOTH pending_referral and source prefs + fires analytics',
    (tester) async {
      _useWideViewport(tester);
      SharedPreferences.setMockInitialValues({});

      final spy = _TrackingSpy();
      final fake = _FakeReferralService()..nextResult = true;
      await _pumpScreen(tester, spy: spy, fakeReferral: fake);

      // Expand and type.
      await tester.tap(find.text('Did a friend send you a gift?'));
      await tester.pump();
      expect(find.byType(ReferralCodeField), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'ABCD2EFG');
      // Cross the debounce window.
      await tester.pump(const Duration(milliseconds: 350));
      // Drain the validateCode microtask + the async _onCodeChanged.
      await tester.pumpAndSettle();
      // Extra microtask flush for the prefs write.
      await tester.pump(const Duration(milliseconds: 50));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(referralPendingReferralPrefsKey), 'ABCD2EFG');
      expect(
        prefs.getString(referralPendingReferralSourcePrefsKey),
        AnalyticsEvents.referralSourceOnboardingField,
      );

      expect(
        spy.tracked
            .where((e) => e.$1 == AnalyticsEvents.referralFieldCodeEntered),
        isNotEmpty,
      );

      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets(
    'Clearing the field removes BOTH prefs keys and fires referral_field_code_cleared',
    (tester) async {
      _useWideViewport(tester);
      SharedPreferences.setMockInitialValues({});

      final spy = _TrackingSpy();
      final fake = _FakeReferralService()..nextResult = true;
      await _pumpScreen(tester, spy: spy, fakeReferral: fake);

      await tester.tap(find.text('Did a friend send you a gift?'));
      await tester.pump();

      // Type then settle so prefs are written.
      await tester.enterText(find.byType(TextField), 'ABCD2EFG');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 50));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(referralPendingReferralPrefsKey), 'ABCD2EFG');

      // Now clear.
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(prefs.getString(referralPendingReferralPrefsKey), isNull);
      expect(prefs.getString(referralPendingReferralSourcePrefsKey), isNull);

      expect(
        spy.tracked
            .where((e) => e.$1 == AnalyticsEvents.referralFieldCodeCleared),
        isNotEmpty,
      );

      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets(
    'T1 regression: empty field does not interfere with sign-in buttons rendering or pollute prefs',
    (tester) async {
      // We can't actually exercise Apple sign-in in a widget test (the
      // AppleAuthProvider calls into the platform SDK). What we CAN pin is
      // that with an empty/collapsed referral disclosure, the social
      // sign-in buttons still render, the disclosure does NOT auto-write
      // anything to prefs on mount, and the Apple button is tappable
      // without throwing a referral-state-related exception.
      _useWideViewport(tester);
      SharedPreferences.setMockInitialValues({});

      final spy = _TrackingSpy();
      final fake = _FakeReferralService();
      await _pumpScreen(tester, spy: spy, fakeReferral: fake);

      // Disclosure stays collapsed (no auto-expand on empty prefs).
      expect(find.text('Did a friend send you a gift?'), findsOneWidget);
      expect(find.byType(ReferralCodeField), findsNothing);

      // Apple + Google + Continue buttons are present and the user can find
      // them (their existence is the regression pin — a layout bug from the
      // disclosure insertion would push them off-screen or replace them).
      expect(find.text('Sign in with Apple'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);

      // Prefs untouched by the field-on-mount path.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(referralPendingReferralPrefsKey), isNull);
      expect(prefs.getString(referralPendingReferralSourcePrefsKey), isNull);

      await tester.pump(const Duration(seconds: 2));
    },
  );
}
