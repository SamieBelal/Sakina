// `_decrementWarmup`'s server-authored branch (the counter came from the
// user's own row, not synthesized from the `warmup_*_size` dial — see
// `_warmupProvisionalKey`) now spends via the atomic `consume_warmup_allowance`
// RPC instead of pushing a client-computed absolute through `upsertRawRow`.
//
// THE BUG this replaces: two devices each holding a stale local counter both
// computed `current - 1` and pushed the same literal value — the
// decrement-only freemium guard let both writes through, so one real AI call
// went unrecorded, permanently (`hydrateFromProfile` then adopts the
// under-counted server value on both devices). See
// `supabase/migrations/20260802020000_consume_warmup_allowance.sql`.
//
// This file pins: the RPC is called with the right feature key; the SERVER's
// `remaining` — never a locally-computed number — lands in the prefs cache;
// an unreachable server and a refused RPC both write nothing; premium never
// reaches the RPC; a throwing RPC never escapes `markUsed`; and the
// provisional (dial-synthesized) counter still never touches the RPC at all.

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/gating_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_supabase_sync_service.dart';

class _FakePurchaseService extends PurchaseService {
  _FakePurchaseService() : super.test();
  bool premium = false;
  @override
  Future<bool> isPremium() async => premium;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;
  late _FakePurchaseService fakePurchase;
  late GatingService gating;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    fakePurchase = _FakePurchaseService();
    PurchaseService.debugSetOverride(fakePurchase);
    gating = GatingService.test();
  });

  tearDown(() {
    SupabaseSyncService.debugReset();
    PurchaseService.debugClearOverride();
  });

  List<Map<String, dynamic>> warmupRpcCalls() =>
      fakeSync.rpcCalls.where((c) => c['fn'] == 'consume_warmup_allowance').toList();

  const featureKeys = <GatedFeature, String>{
    GatedFeature.reflect: 'reflect',
    GatedFeature.builtDua: 'built_dua',
    GatedFeature.discoverName: 'discover_name',
  };

  group('server-authored counter spends via consume_warmup_allowance', () {
    for (final feature in GatedFeature.values) {
      test('${feature.name}: RPC is called with p_feature=${featureKeys[feature]}',
          () async {
        // MUTATION: calling the RPC with the wrong feature key (e.g. always
        // 'reflect') would still pass every OTHER assertion in this file —
        // this is the one that catches it.
        await gating.debugSetWarmupRemaining(feature, 3);
        fakeSync.rpcHandlers['consume_warmup_allowance'] =
            (params) async => {'allowed': true, 'remaining': 2};

        await gating.markUsed(feature);

        final calls = warmupRpcCalls();
        expect(calls, hasLength(1));
        expect(calls.single['params'], {'p_feature': featureKeys[feature]});
      });
    }

    test(
        "the SERVER's `remaining` lands in the cache, never a locally-computed "
        '`current - 1`', () async {
      // MUTATION: this is the one that catches reverting to `current - 1` —
      // local would write 2 (3 - 1), the server answer is a deliberately
      // different number so the two cannot be confused.
      await gating.debugSetWarmupRemaining(GatedFeature.reflect, 3);
      fakeSync.rpcHandlers['consume_warmup_allowance'] =
          (params) async => {'allowed': true, 'remaining': 41};

      await gating.markUsed(GatedFeature.reflect);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt(fakeSync.scopedKey('warmup_reflect_remaining')),
        41,
      );
    });

    test(
        'an unreachable server (no handler registered → callRpc returns null) '
        'writes nothing and denies nothing', () async {
      await gating.debugSetWarmupRemaining(GatedFeature.builtDua, 3);
      // No handler registered for 'consume_warmup_allowance'.

      await gating.markUsed(GatedFeature.builtDua);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt(fakeSync.scopedKey('warmup_builtDua_remaining')),
        3,
        reason: 'the cache must be untouched — neither a local decrement nor '
            'a guess at the server outcome',
      );
    });

    test('a THROWING RPC does not escape markUsed and writes nothing',
        () async {
      await gating.debugSetWarmupRemaining(GatedFeature.reflect, 3);
      fakeSync.rpcHandlers['consume_warmup_allowance'] =
          (params) async => throw Exception('network blip');

      await expectLater(gating.markUsed(GatedFeature.reflect), completes,
          reason: 'a throw here must never propagate out of markUsed — see '
              '_consumeWeeklyPool\'s identical "belt and braces" catch');

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt(fakeSync.scopedKey('warmup_reflect_remaining')),
        3,
        reason: 'fails open: nothing written on the throwing path',
      );
    });

    test('a refused RPC (allowed:false) does not decrement locally', () async {
      await gating.debugSetWarmupRemaining(GatedFeature.discoverName, 1);
      fakeSync.rpcHandlers['consume_warmup_allowance'] =
          (params) async => {'allowed': false, 'remaining': 0};

      await gating.markUsed(GatedFeature.discoverName);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt(fakeSync.scopedKey('warmup_discoverName_remaining')),
        1,
        reason: 'a refused spend makes NO WRITE server-side (see the RPC\'s '
            'own doc comment) — the client must mirror that, not stamp a '
            'guessed 0 over a counter it never actually spent',
      );
    });

    test('a malformed response (missing `remaining`) writes nothing',
        () async {
      await gating.debugSetWarmupRemaining(GatedFeature.reflect, 3);
      fakeSync.rpcHandlers['consume_warmup_allowance'] =
          (params) async => {'allowed': true};

      await gating.markUsed(GatedFeature.reflect);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt(fakeSync.scopedKey('warmup_reflect_remaining')),
        3,
      );
    });
  });

  group('premium never reaches the RPC', () {
    test('premium short-circuits before any warmup RPC fires', () async {
      fakePurchase.premium = true;
      fakeSync.rpcHandlers['consume_warmup_allowance'] = (params) async {
        fail('premium user reached consume_warmup_allowance');
      };

      await gating.markUsed(GatedFeature.reflect, isPremiumHint: true);

      expect(warmupRpcCalls(), isEmpty);
    });
  });

  group('the provisional (dial-synthesized) counter never calls the RPC', () {
    test(
        'a counter with no local key at all (synthesized from the dial) is '
        'decremented purely locally — the RPC would spend against the wrong '
        'row basis for a value nobody has confirmed against the server',
        () async {
      // No debugSetWarmupRemaining call → `_readWarmup` synthesizes from the
      // offline fallback dial (fromStore: false), which is exactly the
      // `pushToServer: false` path.
      fakeSync.rpcHandlers['consume_warmup_allowance'] = (params) async {
        fail('a provisional counter must never spend the RPC');
      };

      await gating.markUsed(GatedFeature.reflect);

      expect(warmupRpcCalls(), isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt(fakeSync.scopedKey('warmup_reflect_remaining')),
        GatingService.warmupBudget[GatedFeature.reflect]! - 1,
      );
    });
  });
}
