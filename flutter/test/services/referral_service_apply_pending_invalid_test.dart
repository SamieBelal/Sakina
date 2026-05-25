import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/referral_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tests for the soft-fail contract of [ReferralService.applyPendingReferralIfAny].
///
/// As of the referral-polish PR the method returns
/// `({bool ok, bool granted7d, String? reason})` instead of `Future<void>`,
/// surfacing the server's `apply_referral` reason taxonomy
/// (`invalid`, `self_referral`, `already_referred_same_code`,
/// `already_referred_other_code`, or null).
///
/// **Stub approach — why a behavioral subclass.**
/// The project has no mock `SupabaseClient` in test infra (the real
/// `.rpc<dynamic>` chain returns proxy types that are hard to fake without
/// a code-gen mock library). We don't want to introduce one just for this
/// PR. The next-best thing is `_TestableReferralService`, which mirrors the
/// production [applyPendingReferralIfAny] prefs-lifecycle EXACTLY:
///   * reads `pending_referral` from SharedPreferences,
///   * "calls the RPC" — programmable via [nextResult] or [nextThrow],
///   * clears prefs ONLY after a successful (non-throwing) RPC,
///   * rethrows on RPC failure.
///
/// This is admittedly testing-our-own-mirror, but it pins the lifecycle
/// shape so a future refactor that, e.g., clears prefs BEFORE awaiting the
/// RPC (the original kill-window bug) would fail these tests if mirrored
/// faithfully. The RPC bodies themselves are covered by
/// `supabase/tests/referrals_test.sql`.
///
/// See `test/widgets/referral_code_field_test.dart` for the original
/// Fake/Spy pattern this file copies.
class _StubSupabase extends Fake implements SupabaseClient {}

/// Mirrors production [ReferralService.applyPendingReferralIfAny] prefs
/// lifecycle so we can test the (ok, granted7d, reason) tuple shape +
/// rethrow contract without a SupabaseClient mock.
class _TestableReferralService extends ReferralService {
  _TestableReferralService() : super(_StubSupabase());

  /// Programmable RPC return. When [nextThrow] is non-null it is rethrown.
  ({bool ok, bool granted7d, String? reason})? nextResult;
  Object? nextThrow;
  int rpcCalls = 0;

  @override
  Future<({bool ok, bool granted7d, String? reason})> applyPendingReferralIfAny(
      String userId) async {
    if (userId.isEmpty) {
      return (ok: false, granted7d: false, reason: null);
    }
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(referralPendingReferralPrefsKey);
    if (code == null || code.isEmpty) {
      return (ok: false, granted7d: false, reason: null);
    }

    rpcCalls++;
    try {
      if (nextThrow != null) {
        // Production rethrows so the defensive cold-launch path can retry —
        // and crucially leaves prefs in place.
        debugPrint('[_TestableReferralService] synthetic RPC throw');
        throw nextThrow!;
      }
    } catch (_) {
      // Mirror production: leave prefs intact, rethrow.
      rethrow;
    }

    // Production clears prefs AFTER a successful RPC (kill-resilient).
    await prefs.remove(referralPendingReferralPrefsKey);
    await prefs.remove(referralPendingReferralSourcePrefsKey);

    final r = nextResult ?? (ok: false, granted7d: false, reason: null);
    return r;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _TestableReferralService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = _TestableReferralService();
  });

  group('applyPendingReferralIfAny — soft-fail tuple contract', () {
    test('ok:true reason:null returns (ok:true, granted7d:true) AND clears prefs',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(referralPendingReferralPrefsKey, 'GIFTCODE');
      await prefs.setString(
          referralPendingReferralSourcePrefsKey, 'onboarding_field');

      service.nextResult = (ok: true, granted7d: true, reason: null);

      final result = await service.applyPendingReferralIfAny('user-1');

      expect(result.ok, isTrue);
      expect(result.granted7d, isTrue);
      expect(result.reason, isNull);
      expect(service.rpcCalls, 1);
      // Successful happy path clears both keys.
      expect(prefs.getString(referralPendingReferralPrefsKey), isNull);
      expect(prefs.getString(referralPendingReferralSourcePrefsKey), isNull);
    });

    test(
        'ok:false reason:invalid returns soft-fail tuple AND clears prefs '
        '(server processed the request)', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(referralPendingReferralPrefsKey, 'BADCODE1');

      service.nextResult = (ok: false, granted7d: false, reason: 'invalid');

      final result = await service.applyPendingReferralIfAny('user-2');

      expect(result.ok, isFalse);
      expect(result.granted7d, isFalse);
      expect(result.reason, 'invalid');
      // Server replied (didn't throw) so prefs are drained — no retry loop.
      expect(prefs.getString(referralPendingReferralPrefsKey), isNull);
    });

    test('ok:false reason:self_referral returns soft-fail tuple AND clears prefs',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(referralPendingReferralPrefsKey, 'SELFCODE');

      service.nextResult =
          (ok: false, granted7d: false, reason: 'self_referral');

      final result = await service.applyPendingReferralIfAny('user-3');

      expect(result.ok, isFalse);
      expect(result.reason, 'self_referral');
      expect(prefs.getString(referralPendingReferralPrefsKey), isNull);
    });

    test(
        'ok:false reason:already_referred_other_code returns soft-fail tuple '
        'AND clears prefs (idempotency case)', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(referralPendingReferralPrefsKey, 'OTHERCD2');

      service.nextResult = (
        ok: false,
        granted7d: false,
        reason: 'already_referred_other_code',
      );

      final result = await service.applyPendingReferralIfAny('user-4');

      expect(result.ok, isFalse);
      expect(result.reason, 'already_referred_other_code');
      // Server processed it (even if it rejected) — prefs drained so we
      // don't loop forever on the defensive cold-launch retry.
      expect(prefs.getString(referralPendingReferralPrefsKey), isNull);
    });

    test(
        'REGRESSION: RPC throws → method RETHROWS AND prefs are NOT cleared '
        '(kill-resilient defensive retry path)', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(referralPendingReferralPrefsKey, 'KEEPCODE');
      await prefs.setString(
          referralPendingReferralSourcePrefsKey, 'deep_link');

      service.nextThrow = Exception('synthetic network failure');

      await expectLater(
        service.applyPendingReferralIfAny('user-5'),
        throwsA(isA<Exception>()),
      );

      // Both prefs survive the throw — AppSession's cold-launch reconciler
      // will retry on the next auth event.
      expect(prefs.getString(referralPendingReferralPrefsKey), 'KEEPCODE');
      expect(prefs.getString(referralPendingReferralSourcePrefsKey), 'deep_link');
    });

    test(
        'empty userId short-circuits before touching prefs (no RPC, no clear)',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(referralPendingReferralPrefsKey, 'STILLHRE');

      final result = await service.applyPendingReferralIfAny('');

      expect(result.ok, isFalse);
      expect(result.reason, isNull);
      expect(service.rpcCalls, 0);
      expect(prefs.getString(referralPendingReferralPrefsKey), 'STILLHRE');
    });

    test('missing pending_referral key returns clean no-op', () async {
      final result = await service.applyPendingReferralIfAny('user-6');

      expect(result.ok, isFalse);
      expect(result.granted7d, isFalse);
      expect(result.reason, isNull);
      expect(service.rpcCalls, 0);
    });
  });
}
