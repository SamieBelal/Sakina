import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/settings/widgets/redeem_code_sheet.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/referral_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stand-in for [SupabaseClient]. Never invoked because the fake overrides
/// validateCode + redeemCodeNow end-to-end — we just need a non-null
/// reference to satisfy the ReferralService constructor.
class _StubSupabase extends Fake implements SupabaseClient {}

/// Spy fake — overrides both [validateCode] (so the ReferralCodeField's
/// inline live validation flows freely) AND [redeemCodeNow] (so the
/// sheet's Redeem button result is controllable per test).
class _FakeReferralService extends ReferralService {
  _FakeReferralService() : super(_StubSupabase());

  // validateCode controls
  bool validateResult = true;

  // redeemCodeNow controls
  ({bool ok, bool granted7d, String? reason}) redeemResult =
      (ok: true, granted7d: true, reason: null);
  Duration redeemDelay = Duration.zero;
  final List<({String userId, String code})> calls = [];

  @override
  Future<bool> validateCode(String code) async {
    if (code.length < 8) return false;
    return validateResult;
  }

  @override
  Future<({bool ok, bool granted7d, String? reason})> redeemCodeNow(
      String userId, String code) async {
    calls.add((userId: userId, code: code));
    if (redeemDelay > Duration.zero) {
      await Future.delayed(redeemDelay);
    }
    return redeemResult;
  }
}

class _TrackingSpy extends AnalyticsService {
  final List<(String, Map<String, dynamic>?)> tracked = [];
  @override
  void track(String event, {Map<String, dynamic>? properties}) {
    tracked.add((event, properties));
  }
}

Future<void> _pumpSheet(
  WidgetTester tester, {
  required _FakeReferralService fake,
  required _TrackingSpy spy,
  String userId = 'user-123',
}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      referralServiceProvider.overrideWithValue(fake),
      analyticsProvider.overrideWithValue(spy),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: RedeemCodeSheet(userId: userId),
      ),
    ),
  ));
}

/// Type a valid 8-char code (formatter-safe alphabet) and drain the
/// field's 300ms debounce + the live validateCode microtask.
Future<void> _enterCode(WidgetTester tester, String code) async {
  await tester.enterText(find.byType(TextField), code);
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pumpAndSettle();
}

void main() {
  group('RedeemCodeSheet', () {
    testWidgets('happy path: ok+granted shows blessing copy and auto-dismisses',
        (tester) async {
      final fake = _FakeReferralService()
        ..redeemResult = (ok: true, granted7d: true, reason: null);
      final spy = _TrackingSpy();
      // Wrap in a Navigator so we can confirm pop() actually unmounts.
      await tester.pumpWidget(ProviderScope(
        overrides: [
          referralServiceProvider.overrideWithValue(fake),
          analyticsProvider.overrideWithValue(spy),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: ctx,
                    builder: (_) =>
                        const RedeemCodeSheet(userId: 'user-123'),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await _enterCode(tester, 'ABCD2EFG');
      await tester.tap(find.text('Redeem'));
      await tester.pumpAndSettle();

      expect(find.textContaining('7 days of Sakina'), findsOneWidget);
      expect(find.text('جزاك الله خيرًا'), findsOneWidget);

      // Sheet still mounted before the 2.5s auto-dismiss.
      expect(find.byType(RedeemCodeSheet), findsOneWidget);
      // Drain the auto-dismiss timer.
      await tester.pump(const Duration(milliseconds: 2600));
      await tester.pumpAndSettle();
      expect(find.byType(RedeemCodeSheet), findsNothing,
          reason: 'Happy path should auto-dismiss after 2.5s');
    });

    testWidgets(
        'T5 regression: already_referred_other_code shows lockout copy + does NOT auto-dismiss',
        (tester) async {
      final fake = _FakeReferralService()
        ..redeemResult = (
          ok: true,
          granted7d: false,
          reason: 'already_referred_other_code'
        );
      final spy = _TrackingSpy();
      await _pumpSheet(tester, fake: fake, spy: spy);

      await _enterCode(tester, 'ABCD2EFG');
      await tester.tap(find.text('Redeem'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('only one per account'),
        findsOneWidget,
      );

      // Wait past the auto-dismiss window. Lockout must NEVER auto-dismiss
      // — the user has to see + acknowledge the message.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.byType(RedeemCodeSheet), findsOneWidget,
          reason: 'Lockout copy must stay until user explicitly closes');
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets(
        'idempotent_same_code shows "already used this code" + auto-dismisses',
        (tester) async {
      final fake = _FakeReferralService()
        ..redeemResult = (
          ok: true,
          granted7d: false,
          reason: 'idempotent_same_code'
        );
      final spy = _TrackingSpy();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          referralServiceProvider.overrideWithValue(fake),
          analyticsProvider.overrideWithValue(spy),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: ctx,
                    builder: (_) =>
                        const RedeemCodeSheet(userId: 'user-123'),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await _enterCode(tester, 'ABCD2EFG');
      await tester.tap(find.text('Redeem'));
      await tester.pumpAndSettle();

      expect(find.textContaining('already used this code'), findsOneWidget);
      // Auto-dismiss
      await tester.pump(const Duration(milliseconds: 2600));
      await tester.pumpAndSettle();
      expect(find.byType(RedeemCodeSheet), findsNothing);
    });

    testWidgets('self_referral shows "can\'t redeem your own code"',
        (tester) async {
      final fake = _FakeReferralService()
        ..redeemResult = (ok: false, granted7d: false, reason: 'self_referral');
      final spy = _TrackingSpy();
      await _pumpSheet(tester, fake: fake, spy: spy);

      await _enterCode(tester, 'ABCD2EFG');
      await tester.tap(find.text('Redeem'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining("can't redeem your own code"),
        findsOneWidget,
      );
    });

    testWidgets('chain_referral shows "this account isn\'t eligible"',
        (tester) async {
      final fake = _FakeReferralService()
        ..redeemResult =
            (ok: false, granted7d: false, reason: 'chain_referral');
      final spy = _TrackingSpy();
      await _pumpSheet(tester, fake: fake, spy: spy);

      await _enterCode(tester, 'ABCD2EFG');
      await tester.tap(find.text('Redeem'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining("account isn't eligible"),
        findsOneWidget,
      );
    });

    testWidgets(
        'invalid_code shows "couldn\'t find that code" + Try-again returns user to entry',
        (tester) async {
      final fake = _FakeReferralService()
        ..redeemResult = (ok: false, granted7d: false, reason: 'invalid_code');
      final spy = _TrackingSpy();
      await _pumpSheet(tester, fake: fake, spy: spy);

      await _enterCode(tester, 'ABCD2EFG');
      await tester.tap(find.text('Redeem'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining("couldn't find that code"),
        findsOneWidget,
      );
      // The retry button should be present, letting the user edit + retry.
      expect(find.text('Try again'), findsOneWidget);
      // The TextField stays populated under the hood (it's recreated on
      // retry but with the value visible to the user via re-entry).
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      // We're back on the entry screen (Redeem button is back).
      expect(find.text('Redeem'), findsOneWidget);
    });

    testWidgets('network_error shows "check your connection" copy',
        (tester) async {
      final fake = _FakeReferralService()
        ..redeemResult = (ok: false, granted7d: false, reason: 'network_error');
      final spy = _TrackingSpy();
      await _pumpSheet(tester, fake: fake, spy: spy);

      await _enterCode(tester, 'ABCD2EFG');
      await tester.tap(find.text('Redeem'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Check your connection'),
        findsOneWidget,
      );
    });

    testWidgets('C2 regression: rapid double-tap fires redeemCodeNow exactly once',
        (tester) async {
      final fake = _FakeReferralService()
        // Add a small delay so the second tap arrives while the first is
        // still in-flight — that's exactly when the button-disable guard
        // is load-bearing.
        ..redeemDelay = const Duration(milliseconds: 200)
        ..redeemResult = (ok: true, granted7d: true, reason: null);
      final spy = _TrackingSpy();
      await _pumpSheet(tester, fake: fake, spy: spy);

      await _enterCode(tester, 'ABCD2EFG');
      // First tap kicks off the (200ms delayed) redeem and disables the
      // button. Try to tap a second time mid-flight; the disabled button
      // should absorb the tap so we end up with exactly one RPC call.
      await tester.tap(find.text('Redeem'));
      await tester.pump(const Duration(milliseconds: 50));

      // While the redeem is in flight, the spinner has replaced the
      // "Redeem" label and the ElevatedButton is disabled (onPressed null).
      final btn = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(btn.onPressed, isNull,
          reason: 'Button must be disabled while redemption is in-flight');

      // Try a second tap on the now-disabled button — this is the gesture
      // we're guarding against. tester.tap won't actually find the
      // "Redeem" text any more (it's been replaced by the spinner), so
      // simulate a tap on the button rect via byType.
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 50));

      // Drain the delayed redeem.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(fake.calls.length, 1,
          reason: 'Double-tap must result in exactly one redeem call');
    });

    testWidgets(
        'analytics: tapping Redeem fires referral_settings_redeem_submitted',
        (tester) async {
      final fake = _FakeReferralService()
        ..redeemResult = (ok: true, granted7d: true, reason: null);
      final spy = _TrackingSpy();
      await _pumpSheet(tester, fake: fake, spy: spy);

      await _enterCode(tester, 'ABCD2EFG');
      await tester.tap(find.text('Redeem'));
      await tester.pumpAndSettle();

      expect(
        spy.tracked
            .where((e) => e.$1 == AnalyticsEvents.referralSettingsRedeemSubmitted),
        isNotEmpty,
      );
    });
  });
}
