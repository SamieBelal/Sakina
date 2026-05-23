import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/daily_usage_service.dart' as daily;
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

  // Anchor "now" so the 24h Day-1 window is deterministic.
  final fixedNow = DateTime.parse('2026-05-25T12:00:00Z');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    fakePurchase = _FakePurchaseService();
    PurchaseService.debugSetOverride(fakePurchase);
    gating = GatingService.test();
    GatingService.debugNowUtc = () => fixedNow;
  });

  tearDown(() {
    SupabaseSyncService.debugReset();
    PurchaseService.debugClearOverride();
    GatingService.onAnalyticsEvent = null;
    GatingService.debugNowUtc = null;
  });

  group('firstBypassEligible', () {
    test('returns true when within 24h window AND not consumed', () async {
      await gating.hydrateFromProfile({
        'first_bypass_consumed': false,
        'created_at': '2026-05-25T01:00:00Z', // 11h ago
      });
      expect(await gating.firstBypassEligible(), isTrue);
    });

    test('returns false when first_bypass_consumed=true', () async {
      await gating.hydrateFromProfile({
        'first_bypass_consumed': true,
        'created_at': '2026-05-25T11:00:00Z', // 1h ago — still in window
      });
      expect(await gating.firstBypassEligible(), isFalse);
    });

    test('returns false when signup_at is older than 24h (window expired)',
        () async {
      await gating.hydrateFromProfile({
        'first_bypass_consumed': false,
        'created_at': '2026-05-23T12:00:00Z', // 48h ago
      });
      expect(await gating.firstBypassEligible(), isFalse);
    });

    test('returns false on the 24h boundary exactly (strict isAfter)',
        () async {
      await gating.hydrateFromProfile({
        'first_bypass_consumed': false,
        'created_at': '2026-05-24T12:00:00Z', // exactly 24h ago
      });
      expect(await gating.firstBypassEligible(), isFalse,
          reason: 'Boundary is exclusive — fresh signup pinned by strict >');
    });

    test('returns false when signup_at missing (defense against corruption)',
        () async {
      await gating.hydrateFromProfile({'first_bypass_consumed': false});
      expect(await gating.firstBypassEligible(), isFalse);
    });

    test('returns false when signup_at is malformed (defense)', () async {
      await gating.hydrateFromProfile({
        'first_bypass_consumed': false,
        'created_at': 'not-a-date',
      });
      expect(await gating.firstBypassEligible(), isFalse);
    });

    test('returns false for premium users (short-circuits before cache read)',
        () async {
      fakePurchase.premium = true;
      await gating.hydrateFromProfile({
        'first_bypass_consumed': false,
        'created_at': '2026-05-25T11:00:00Z',
      });
      expect(await gating.firstBypassEligible(), isFalse,
          reason: 'Premium users never see DailyCapSheet — bypass irrelevant');
    });

    test('defaults to false on a clean install (no hydration)', () async {
      expect(await gating.firstBypassEligible(), isFalse,
          reason: 'Absence of signup_at must NOT eligibility-leak');
    });
  });

  group('displayName', () {
    test('returns hydrated display_name', () async {
      await gating.hydrateFromProfile({'display_name': 'Aisha'});
      expect(await gating.displayName(), 'Aisha');
    });

    test('falls back to "Friend" when display_name not hydrated', () async {
      expect(await gating.displayName(), 'Friend');
    });

    test('hydration ignores empty string (treat as missing)', () async {
      await gating.hydrateFromProfile({'display_name': ''});
      expect(await gating.displayName(), 'Friend');
    });
  });

  group('claimFirstBypass', () {
    test('happy path: flips consumed latch, increments bypass cache, fires '
        'first_bypass_claimed', () async {
      await gating.hydrateFromProfile({
        'first_bypass_consumed': false,
        'created_at': '2026-05-25T11:00:00Z',
      });
      final events = <(String, Map<String, dynamic>)>[];
      GatingService.onAnalyticsEvent = (e, p) => events.add((e, p));

      fakeSync.rpcHandlers['claim_first_bypass'] = (params) async => {
            'ok': true,
            'bypasses_used': 1,
          };

      final ok = await gating.claimFirstBypass(GatedFeature.reflect);

      expect(ok, isTrue);
      expect(fakeSync.rpcCalls.last['fn'], 'claim_first_bypass');
      expect(fakeSync.rpcCalls.last['params'], {'p_feature': 'reflect'});
      // Local cache reflects the claim — next eligibility check now false
      expect(await gating.firstBypassEligible(), isFalse,
          reason: 'Consumed latch must flip synchronously on success');
      expect(await daily.getReflectBypassesUsedToday(), 1);
      expect(events, hasLength(1));
      expect(events.first.$1, 'first_bypass_claimed');
      expect(events.first.$2, {
        'feature': 'reflect',
        'bypasses_used_today': 1,
      });
    });

    test('RPC rejects with already_consumed → returns false, fires '
        'rejected/already_consumed', () async {
      final events = <(String, Map<String, dynamic>)>[];
      GatingService.onAnalyticsEvent = (e, p) => events.add((e, p));
      fakeSync.rpcHandlers['claim_first_bypass'] = (_) async => {
            'ok': false,
            'reason': 'already_consumed',
          };

      final ok = await gating.claimFirstBypass(GatedFeature.builtDua);

      expect(ok, isFalse);
      expect(events, hasLength(1));
      expect(events.first.$1, 'first_bypass_rejected');
      expect(events.first.$2, {
        'feature': 'built_dua',
        'reason': 'already_consumed',
      });
    });

    test('RPC null (network) → returns false, fires rejected/network',
        () async {
      final events = <(String, Map<String, dynamic>)>[];
      GatingService.onAnalyticsEvent = (e, p) => events.add((e, p));
      // No handler → callRpc returns null.

      final ok = await gating.claimFirstBypass(GatedFeature.discoverName);

      expect(ok, isFalse);
      expect(events, hasLength(1));
      expect(events.first.$1, 'first_bypass_rejected');
      expect(events.first.$2, {
        'feature': 'discover_name',
        'reason': 'network',
      });
    });

    test('premium short-circuit: NEVER hits the RPC, NEVER fires analytics',
        () async {
      fakePurchase.premium = true;
      var rpcFired = false;
      final events = <(String, Map<String, dynamic>)>[];
      GatingService.onAnalyticsEvent = (e, p) => events.add((e, p));
      fakeSync.rpcHandlers['claim_first_bypass'] = (_) async {
        rpcFired = true;
        return {'ok': true, 'bypasses_used': 1};
      };

      final ok = await gating.claimFirstBypass(GatedFeature.reflect);

      expect(ok, isFalse);
      expect(rpcFired, isFalse,
          reason: 'Premium must short-circuit before RPC dispatch');
      expect(events, isEmpty,
          reason: 'Premium must not pollute the funnel');
    });

    test('null hook is safe (tests + pre-main.dart boot)', () async {
      GatingService.onAnalyticsEvent = null;
      fakeSync.rpcHandlers['claim_first_bypass'] = (_) async => {
            'ok': true,
            'bypasses_used': 1,
          };
      // Just call it — if the null hook caused an NPE, this would throw
      // and the test would fail. Plain async call is the right pattern;
      // `returnsNormally` is sync-only and doesn't await the inner future.
      final ok = await gating.claimFirstBypass(GatedFeature.reflect);
      expect(ok, isTrue);
    });
  });
}
