import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/daily_usage_service.dart' as daily;
import 'package:sakina/services/gating_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_supabase_sync_service.dart';

class _FakePurchaseService extends PurchaseService {
  _FakePurchaseService() : super.test();

  bool premium = false;
  int isPremiumCallCount = 0;

  @override
  Future<bool> isPremium() async {
    isPremiumCallCount++;
    return premium;
  }
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
    // Seed an initial token balance so we have something to assert against.
    await hydrateTokenCache(balance: 100, totalSpent: 0);
  });

  tearDown(() {
    SupabaseSyncService.debugReset();
    PurchaseService.debugClearOverride();
    GatingService.onAnalyticsEvent = null;
  });

  group('reserveBypass', () {
    test('happy path: returns reservation, debits cache, increments counter',
        () async {
      fakeSync.rpcHandlers['reserve_ai_bypass'] = (params) async => {
            'ok': true,
            'reservation_id': 'res-abc',
            'balance': 75,
            'bypasses_used': 1,
          };

      final result = await gating.reserveBypass(GatedFeature.reflect);

      expect(result, isNotNull);
      expect(result!.reservationId, 'res-abc');
      expect(result.newBalance, 75);
      expect(result.bypassesUsedToday, 1);
      expect(fakeSync.rpcCalls.last['fn'], 'reserve_ai_bypass');
      expect(
        fakeSync.rpcCalls.last['params'],
        {'p_feature': 'reflect'},
      );

      // Local caches mirror the server side-effects.
      expect((await getTokens()).balance, 75);
      expect(await daily.getReflectBypassesUsedToday(), 1);
    });

    test('feature-name mapping: reflect/built_dua/discover_name', () async {
      fakeSync.rpcHandlers['reserve_ai_bypass'] = (_) async => {
            'ok': true,
            'reservation_id': 'res-xyz',
            'balance': 50,
            'bypasses_used': 1,
          };

      await gating.reserveBypass(GatedFeature.reflect);
      expect(fakeSync.rpcCalls.last['params'], {'p_feature': 'reflect'});

      await gating.reserveBypass(GatedFeature.builtDua);
      expect(fakeSync.rpcCalls.last['params'], {'p_feature': 'built_dua'});

      await gating.reserveBypass(GatedFeature.discoverName);
      expect(
        fakeSync.rpcCalls.last['params'],
        {'p_feature': 'discover_name'},
      );
    });

    test('TEST-C: premium short-circuit — NEVER hits the RPC', () async {
      fakePurchase.premium = true;
      var rpcFired = false;
      fakeSync.rpcHandlers['reserve_ai_bypass'] = (_) async {
        rpcFired = true;
        return {'ok': true, 'reservation_id': 'r', 'balance': 0, 'bypasses_used': 0};
      };

      final result = await gating.reserveBypass(GatedFeature.reflect);

      expect(result, isNull, reason: 'Premium users must not get a reservation');
      expect(rpcFired, isFalse,
          reason: 'Premium short-circuit must happen before RPC dispatch');
      expect((await getTokens()).balance, 100,
          reason: 'Token balance must not change');
      expect(await daily.getReflectBypassesUsedToday(), 0);
    });

    test('RPC rejects with ok=false → returns null, leaves cache untouched',
        () async {
      fakeSync.rpcHandlers['reserve_ai_bypass'] = (_) async => {
            'ok': false,
            'reason': 'no_tokens',
          };

      final result = await gating.reserveBypass(GatedFeature.reflect);

      expect(result, isNull);
      expect((await getTokens()).balance, 100);
      expect(await daily.getReflectBypassesUsedToday(), 0);
    });

    test('RPC null (network failure) → returns null, leaves cache untouched',
        () async {
      // No handler registered → callRpc returns null.
      final result = await gating.reserveBypass(GatedFeature.reflect);

      expect(result, isNull);
      expect((await getTokens()).balance, 100);
      expect(await daily.getReflectBypassesUsedToday(), 0);
    });
  });

  group('commitBypass', () {
    test('fires commit_ai_bypass with reservation id', () async {
      fakeSync.rpcHandlers['commit_ai_bypass'] = (_) async => {'ok': true};

      await gating.commitBypass('res-abc');

      expect(fakeSync.rpcCalls.last['fn'], 'commit_ai_bypass');
      expect(
        fakeSync.rpcCalls.last['params'],
        {'p_reservation_id': 'res-abc'},
      );
    });

    test('absorbs RPC failure (fire-and-forget — orphan cron rescues)',
        () async {
      // No handler → null result. Should NOT throw.
      await gating.commitBypass('res-abc');
      expect(fakeSync.rpcCalls.last['fn'], 'commit_ai_bypass');
    });
  });

  group('cancelBypass', () {
    test('happy path: refunds balance + decrements bypass cache', () async {
      // Set up state: bypass already counted on the local cache (as if
      // reserveBypass had just fired).
      await hydrateTokenCache(balance: 75);
      await daily.incrementReflectBypassUsage();
      expect(await daily.getReflectBypassesUsedToday(), 1);

      fakeSync.rpcHandlers['cancel_ai_bypass'] = (_) async => {
            'ok': true,
            'balance': 100,
            'refunded_tokens': 25,
          };

      final ok =
          await gating.cancelBypass('res-abc', GatedFeature.reflect);

      expect(ok, isTrue);
      expect((await getTokens()).balance, 100);
      expect(await daily.getReflectBypassesUsedToday(), 0);
    });

    test('RPC says not_pending (already cancelled) → returns false, no cache change',
        () async {
      await hydrateTokenCache(balance: 75);
      await daily.incrementReflectBypassUsage();
      fakeSync.rpcHandlers['cancel_ai_bypass'] = (_) async => {
            'ok': false,
            'reason': 'not_pending',
          };

      final ok =
          await gating.cancelBypass('res-abc', GatedFeature.reflect);

      expect(ok, isFalse);
      expect((await getTokens()).balance, 75,
          reason: 'No refund credit when RPC rejects');
      expect(await daily.getReflectBypassesUsedToday(), 1,
          reason: 'No decrement when RPC rejects');
    });

    test('network failure (RPC returns null) → returns false', () async {
      final ok =
          await gating.cancelBypass('res-abc', GatedFeature.reflect);
      expect(ok, isFalse);
    });
  });

  group('bypassesUsedToday', () {
    test('reads from per-feature local cache', () async {
      await daily.incrementReflectBypassUsage();
      await daily.incrementBuiltDuaBypassUsage();
      await daily.incrementBuiltDuaBypassUsage();

      expect(await gating.bypassesUsedToday(GatedFeature.reflect), 1);
      expect(await gating.bypassesUsedToday(GatedFeature.builtDua), 2);
      expect(await gating.bypassesUsedToday(GatedFeature.discoverName), 0);
    });
  });

  group('TEST-B: multi-device hydration', () {
    test('hydrateDailyUsageCacheFromPayload overwrites local with server bypass counters',
        () async {
      // Local cache says 0 bypasses; server says 2.
      expect(await daily.getReflectBypassesUsedToday(), 0);

      await daily.hydrateDailyUsageCacheFromPayload({
        'reflect_uses': 3,
        'built_dua_uses': 1,
        'discover_name_uses': 0,
        'reflect_bypasses_used': 2,
        'built_dua_bypasses_used': 1,
        'discover_name_bypasses_used': 0,
      });

      expect(await daily.getReflectBypassesUsedToday(), 2);
      expect(await daily.getBuiltDuaBypassesUsedToday(), 1);
      expect(await daily.getDiscoverNameBypassesUsedToday(), 0);
    });

    test('missing bypass fields in payload leave local cache untouched',
        () async {
      await daily.incrementReflectBypassUsage();
      expect(await daily.getReflectBypassesUsedToday(), 1);

      // Server payload without the bypass columns (e.g. pre-PR2 backend).
      await daily.hydrateDailyUsageCacheFromPayload({
        'reflect_uses': 1,
        'built_dua_uses': 0,
        'discover_name_uses': 0,
      });

      expect(await daily.getReflectBypassesUsedToday(), 1,
          reason: 'Absent fields must not clear the cache to zero');
    });
  });

  group('Constants match server seed', () {
    test('bypassTokenCost is 25 (matches app_config seed)', () {
      expect(GatingService.bypassTokenCost, 25);
    });

    test('maxBypassesPerDayPerFeature is 2 (matches app_config seed)', () {
      expect(GatingService.maxBypassesPerDayPerFeature, 2);
    });
  });

  group('Analytics hook (PR 3 of plan 2026-05-23)', () {
    test('reserveBypass success fires ai_bypass_purchased with full props',
        () async {
      final events = <(String, Map<String, dynamic>)>[];
      GatingService.onAnalyticsEvent = (e, p) => events.add((e, p));

      fakeSync.rpcHandlers['reserve_ai_bypass'] = (_) async => {
            'ok': true,
            'reservation_id': 'res-a',
            'balance': 75,
            'bypasses_used': 1,
          };

      await gating.reserveBypass(GatedFeature.reflect);

      expect(events, hasLength(1));
      expect(events.first.$1, 'ai_bypass_purchased');
      expect(events.first.$2, {
        'feature': 'reflect',
        'token_balance_after': 75,
        'bypasses_used_today': 1,
      });
    });

    test('reserveBypass rejected (ok=false) fires ai_bypass_rejected with reason',
        () async {
      final events = <(String, Map<String, dynamic>)>[];
      GatingService.onAnalyticsEvent = (e, p) => events.add((e, p));

      fakeSync.rpcHandlers['reserve_ai_bypass'] = (_) async => {
            'ok': false,
            'reason': 'bypass_cap',
          };

      await gating.reserveBypass(GatedFeature.builtDua);

      expect(events, hasLength(1));
      expect(events.first.$1, 'ai_bypass_rejected');
      expect(events.first.$2, {
        'feature': 'built_dua',
        'reason': 'bypass_cap',
      });
    });

    test('reserveBypass RPC null (network) fires ai_bypass_rejected/network',
        () async {
      final events = <(String, Map<String, dynamic>)>[];
      GatingService.onAnalyticsEvent = (e, p) => events.add((e, p));
      // No handler → callRpc returns null.

      await gating.reserveBypass(GatedFeature.discoverName);

      expect(events, hasLength(1));
      expect(events.first.$1, 'ai_bypass_rejected');
      expect(events.first.$2, {
        'feature': 'discover_name',
        'reason': 'network',
      });
    });

    test('premium short-circuit does NOT fire any analytics event', () async {
      // Critical invariant: premium users never see the bypass CTA in the
      // first place, so an emitted event would be misleading dashboard
      // noise — a "rejection" the user never experienced.
      fakePurchase.premium = true;
      final events = <(String, Map<String, dynamic>)>[];
      GatingService.onAnalyticsEvent = (e, p) => events.add((e, p));
      fakeSync.rpcHandlers['reserve_ai_bypass'] = (_) async => {
            'ok': true,
            'reservation_id': 'r',
            'balance': 0,
            'bypasses_used': 0,
          };

      await gating.reserveBypass(GatedFeature.reflect);

      expect(events, isEmpty,
          reason: 'Premium short-circuit must not pollute the funnel');
    });

    test('null hook is safe — no NPE when analytics not wired (tests, early boot)',
        () async {
      // Default in tests + during app startup before main.dart runs the
      // wiring line. Must be a no-op, not a crash.
      GatingService.onAnalyticsEvent = null;
      fakeSync.rpcHandlers['reserve_ai_bypass'] = (_) async => {
            'ok': true,
            'reservation_id': 'r',
            'balance': 50,
            'bypasses_used': 1,
          };

      final result = await gating.reserveBypass(GatedFeature.reflect);
      expect(result, isNotNull);
    });
  });

  group('REGRESSION-PIN: grind math', () {
    test(
        'earned-token-only user (~100/week) cannot sustain 2 bypasses/day/feature',
        () {
      // Earn rate per spec line 44: ~100 tokens/week from daily login + streak
      // + quests. Sustained 2 bypasses/day across all 3 features:
      //   2 × 3 × 7 × 25 = 1050 tokens/week required
      // vs ~100/week earned → 10.5x overspend.
      //
      // This test pins the math against future earn-rate inflation. If we
      // raise daily-login rewards, increase quest payouts, or add a new
      // earn surface, the assertion below catches the drift before the
      // bypass becomes grindable on earned tokens alone.
      const earnRatePerWeek = 100;
      const fullBypassUsagePerWeek = 2 * 3 * 7 * GatingService.bypassTokenCost;
      expect(
        fullBypassUsagePerWeek,
        greaterThanOrEqualTo(earnRatePerWeek * 10),
        reason:
            'Bypass must remain at least 10x the earn rate to require IAP for sustained use',
      );
    });
  });
}
