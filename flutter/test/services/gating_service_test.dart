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
  bool trial = false;

  @override
  Future<bool> isPremium() async => premium;

  @override
  Future<bool> hadTrial() async => trial;
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

  Future<void> setUsageToday(GatedFeature feature, int count) async {
    final prefs = await SharedPreferences.getInstance();
    final featureKey = switch (feature) {
      GatedFeature.reflect => 'reflect',
      GatedFeature.builtDua => 'built_dua',
      GatedFeature.discoverName => 'discover_name',
    };
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final scoped = fakeSync.scopedKey('daily_usage_${featureKey}_$today');
    await prefs.setInt(scoped, count);
  }

  group('Premium fair-use ceiling', () {
    setUp(() {
      fakePurchase.premium = true;
    });

    for (final feature in GatedFeature.values) {
      test('${feature.name}: allows uses below cap (boundary at 29)', () async {
        await setUsageToday(feature, 29);
        final result = await gating.canUse(feature);
        expect(result.allowed, isTrue);
        expect(result.reason, GateReason.ok);
      });

      test('${feature.name}: blocks at exactly 30 (cap hit)', () async {
        await setUsageToday(feature, GatingService.premiumDailyFairUseCap);
        final result = await gating.canUse(feature);
        expect(result.allowed, isFalse);
        expect(result.reason, GateReason.premiumFairUse);
      });

      test('${feature.name}: blocks above cap (31)', () async {
        await setUsageToday(feature, 31);
        final result = await gating.canUse(feature);
        expect(result.allowed, isFalse);
        expect(result.reason, GateReason.premiumFairUse);
      });
    }

    test('zero usage = ok', () async {
      final result = await gating.canUse(GatedFeature.reflect);
      expect(result.allowed, isTrue);
      expect(result.reason, GateReason.ok);
    });
  });

  group('Free + warmup phase', () {
    for (final feature in GatedFeature.values) {
      test('${feature.name}: returns warmupRemaining=full budget on first use',
          () async {
        final result = await gating.canUse(feature);
        expect(result.allowed, isTrue);
        expect(result.reason, GateReason.warmupRemaining);
        expect(result.remaining, GatingService.warmupBudget[feature]);
      });

      test('${feature.name}: warmup decrements per markUsed', () async {
        final budget = GatingService.warmupBudget[feature]!;
        for (var i = 0; i < budget; i++) {
          final res = await gating.canUse(feature);
          expect(res.allowed, isTrue);
          expect(res.reason, GateReason.warmupRemaining);
          expect(res.remaining, budget - i);
          await gating.markUsed(feature);
        }
        // Budget exhausted → transitions to dailyCap (no daily uses yet so first
        // capped attempt is OK; 2nd will block).
        final exhausted = await gating.canUse(feature);
        expect(exhausted.allowed, isTrue);
        expect(exhausted.reason, GateReason.ok);
      });
    }

    test('warmup write attempts a Supabase upsert (tolerant of missing column)',
        () async {
      await gating.markUsed(GatedFeature.reflect);
      // Should have attempted to write `warmup_reflect_remaining` to user_profiles.
      final profileWrites = fakeSync.upsertCalls
          .where((c) => c['table'] == 'user_profiles')
          .toList();
      expect(profileWrites, hasLength(1));
      expect(
        (profileWrites.single['data'] as Map)['warmup_reflect_remaining'],
        9,
      );
    });
  });

  group('Free + capped (warmup exhausted)', () {
    setUp(() async {
      // Drain all warmups to 0.
      for (final f in GatedFeature.values) {
        await gating.debugSetWarmupRemaining(f, 0);
      }
    });

    for (final feature in GatedFeature.values) {
      test('${feature.name}: 1st daily use ok, 2nd blocked', () async {
        final first = await gating.canUse(feature);
        expect(first.allowed, isTrue);
        expect(first.reason, GateReason.ok);

        await gating.markUsed(feature);

        final second = await gating.canUse(feature);
        expect(second.allowed, isFalse);
        expect(second.reason, GateReason.dailyCap);
      });
    }
  });

  group('had_trial latch (REGRESSION)', () {
    setUp(() async {
      // Lapsed trialer: had_trial flipped on, but warmup counters are still
      // at their full default values. The gate MUST resolve to capped phase
      // anyway — this pins the lapsed-trialer skip rule against future refactors.
      await gating.debugSetHadTrial(true);
    });

    for (final feature in GatedFeature.values) {
      test(
          '${feature.name}: had_trial=true forces capped resolution even with '
          'positive warmup counters', () async {
        // Sanity: warmup remains untouched.
        // The very first call should NOT return warmupRemaining.
        final first = await gating.canUse(feature);
        expect(first.allowed, isTrue);
        expect(first.reason, GateReason.ok,
            reason: 'lapsed trialer skips warmup; first daily use is allowed');

        await gating.markUsed(feature);

        final second = await gating.canUse(feature);
        expect(second.allowed, isFalse);
        expect(second.reason, GateReason.hadTrialNoBudget,
            reason:
                'second use of the day for a lapsed trialer must be blocked '
                'with hadTrialNoBudget reason');
      });

      test('${feature.name}: markUsed increments daily counter (NOT warmup) '
          'when had_trial=true', () async {
        await gating.markUsed(feature);
        // Warmup counter should remain at default (NOT decremented).
        final prefs = await SharedPreferences.getInstance();
        final scopedKey =
            fakeSync.scopedKey('warmup_${feature.name}_remaining');
        final stored = prefs.getInt(scopedKey);
        expect(stored, isNull,
            reason: 'lapsed trialer must not consume warmup budget');

        // Daily counter should have advanced.
        final usageGetter = switch (feature) {
          GatedFeature.reflect => daily.getReflectUsageToday,
          GatedFeature.builtDua => daily.getBuiltDuaUsageToday,
          GatedFeature.discoverName => daily.getDiscoverNameUsageToday,
        };
        expect(await usageGetter(), 1);
      });
    }
  });

  group('markUsed routes correctly per phase', () {
    test('premium: increments daily, not warmup', () async {
      fakePurchase.premium = true;
      await gating.markUsed(GatedFeature.reflect);
      expect(await daily.getReflectUsageToday(), 1);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt(fakeSync.scopedKey('warmup_reflect_remaining')),
        isNull,
      );
    });

    test('warmup phase: decrements warmup, not daily', () async {
      await gating.markUsed(GatedFeature.builtDua);
      expect(await daily.getBuiltDuaUsageToday(), 0,
          reason: 'daily counter must not advance during warmup phase');
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt(fakeSync.scopedKey('warmup_builtDua_remaining')),
        9,
      );
    });

    test('capped phase: increments daily, not warmup', () async {
      await gating.debugSetWarmupRemaining(GatedFeature.discoverName, 0);
      await gating.markUsed(GatedFeature.discoverName);
      expect(await daily.getDiscoverNameUsageToday(), 1);
    });
  });

  group('canUse contract', () {
    test('GateResult exposes its three pieces of state', () {
      const a = GateResult(
        allowed: true,
        reason: GateReason.warmupRemaining,
        remaining: 7,
      );
      expect(a.allowed, isTrue);
      expect(a.reason, GateReason.warmupRemaining);
      expect(a.remaining, 7);
    });

    test('warmup budgets match spec (10/10/5)', () {
      expect(GatingService.warmupBudget[GatedFeature.reflect], 10);
      expect(GatingService.warmupBudget[GatedFeature.builtDua], 10);
      expect(GatingService.warmupBudget[GatedFeature.discoverName], 5);
    });

    test('premium fair-use cap is 30', () {
      expect(GatingService.premiumDailyFairUseCap, 30);
    });
  });
}
