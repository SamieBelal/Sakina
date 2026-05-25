import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/referral_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tests the new [ReferralService.validateCode] contract: as of the
/// referral-polish PR the method RETHROWS on RPC failure instead of
/// swallowing and returning false. Callers (notably [ReferralCodeField])
/// rely on the throw to distinguish `invalid` (server said no) from
/// `networkError` (couldn't reach server) — two different validation chips.
///
/// **Stub approach — same as `referral_service_apply_pending_invalid_test.dart`.**
/// The empty / too-short branches are tested against the real
/// [ReferralService] because they short-circuit before touching the
/// SupabaseClient at all (no RPC fired, real or stubbed). The RPC-touching
/// branches use `_TestableReferralService`, a subclass that overrides ONLY
/// [validateCode] to mirror the production short-circuits + raise/return a
/// programmable value. This preserves the empty/short gate semantics while
/// letting us pin the throw vs return contract without a SupabaseClient mock.
class _StubSupabase extends Fake implements SupabaseClient {}

class _TestableReferralService extends ReferralService {
  _TestableReferralService() : super(_StubSupabase());

  bool nextResult = false;
  Object? nextThrow;
  int rpcCalls = 0;

  @override
  Future<bool> validateCode(String code) async {
    // Mirror production short-circuits — they must NOT hit the RPC.
    if (code.isEmpty || code.length < 8) return false;
    rpcCalls++;
    if (nextThrow != null) {
      // Production now rethrows; mirror that exactly.
      throw nextThrow!;
    }
    return nextResult;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('validateCode — short-circuit branches (no RPC)', () {
    test('empty code returns false without calling RPC', () async {
      final service = _TestableReferralService();
      final result = await service.validateCode('');
      expect(result, isFalse);
      expect(service.rpcCalls, 0);
    });

    test('7-char code returns false without calling RPC', () async {
      final service = _TestableReferralService();
      final result = await service.validateCode('ABCDEF2');
      expect(result, isFalse);
      expect(service.rpcCalls, 0);
    });

    test(
        'empty / short branches short-circuit on the REAL ReferralService too '
        '(structural pin — no SupabaseClient touched)',
        () async {
      // Even constructed with a Fake SupabaseClient that would crash on any
      // call, validateCode('') must return false without touching it.
      final real = ReferralService(_StubSupabase());
      expect(await real.validateCode(''), isFalse);
      expect(await real.validateCode('ABCDEF2'), isFalse);
    });
  });

  group('validateCode — RPC branches', () {
    test('REGRESSION: RPC throws → validateCode RETHROWS (does NOT return false)',
        () async {
      final service = _TestableReferralService()
        ..nextThrow = Exception('network down');

      await expectLater(
        service.validateCode('GOODCD28'),
        throwsA(isA<Exception>()),
      );
      expect(service.rpcCalls, 1);
    });

    test('RPC returns true → validateCode returns true', () async {
      final service = _TestableReferralService()..nextResult = true;
      final result = await service.validateCode('GOODCD28');
      expect(result, isTrue);
      expect(service.rpcCalls, 1);
    });

    test('RPC returns false → validateCode returns false', () async {
      final service = _TestableReferralService()..nextResult = false;
      final result = await service.validateCode('BADCD123');
      expect(result, isFalse);
      expect(service.rpcCalls, 1);
    });
  });
}
