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
  int isPremiumCallCount = 0;

  @override
  Future<bool> isPremium() async {
    isPremiumCallCount++;
    return premium;
  }

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

      test('${feature.name}: warmup decrements per markUsed; exhaust call '
          'also increments daily counter so the user is blocked on the very '
          'next same-day attempt (NOT given a free N+1 use)', () async {
        final budget = GatingService.warmupBudget[feature]!;
        UsageOutcome? lastOutcome;
        for (var i = 0; i < budget; i++) {
          final res = await gating.canUse(feature);
          expect(res.allowed, isTrue);
          expect(res.reason, GateReason.warmupRemaining);
          expect(res.remaining, budget - i);
          lastOutcome = await gating.markUsed(feature);
        }
        // The Nth (final) markUsed must signal the one-shot exhaust transition.
        expect(lastOutcome, UsageOutcome.warmupJustExhausted,
            reason:
                'the Nth call (1 → 0 warmup transition) must return '
                'warmupJustExhausted so the screen layer can fire the dedicated '
                'sheet exactly once');

        // Daily counter must read 1 immediately after exhaust — this is the
        // fix that prevents an extra free use on the Nth+1 attempt.
        final usageGetter = switch (feature) {
          GatedFeature.reflect => daily.getReflectUsageToday,
          GatedFeature.builtDua => daily.getBuiltDuaUsageToday,
          GatedFeature.discoverName => daily.getDiscoverNameUsageToday,
        };
        expect(await usageGetter(), 1,
            reason:
                'exhaust call (warmup 1 → 0) must also increment the daily '
                'counter so the next same-day attempt sees used >= cap');

        // The very next canUse must be blocked with dailyCap.
        final exhausted = await gating.canUse(feature);
        expect(exhausted.allowed, isFalse,
            reason:
                'after exhausting warmup, the (N+1)th attempt today must be '
                'blocked — user already received their N free uses');
        expect(exhausted.reason, GateReason.dailyCap);
      });
    }

    // Regression for the 2026-05-10 sim-test bug where warmup writes used
    // upsertRow (auto-injects user_id), which silently failed because
    // user_profiles primary key is `id`, not `user_id`. Loops over every
    // GatedFeature so a future refactor that fixes one branch but regresses
    // another is caught.
    final expectedColumns = <GatedFeature, String>{
      GatedFeature.reflect: 'warmup_reflect_remaining',
      GatedFeature.builtDua: 'warmup_built_dua_remaining',
      GatedFeature.discoverName: 'warmup_discover_name_remaining',
    };
    for (final feature in GatedFeature.values) {
      test(
          '${feature.name}: warmup write uses upsertRawRow with id (NOT '
          'upsertRow which would inject user_id and silently fail on '
          'user_profiles)', () async {
        await gating.markUsed(feature);
        expect(fakeSync.upsertCalls, isEmpty,
            reason: 'must NOT use upsertRow (injects user_id)');
        final profileWrites = fakeSync.rawUpsertCalls
            .where((c) => c['table'] == 'user_profiles')
            .toList();
        expect(profileWrites, hasLength(1));
        final data = profileWrites.single['data'] as Map;
        final expectedColumn = expectedColumns[feature]!;
        expect(data[expectedColumn], GatingService.warmupBudget[feature]! - 1,
            reason: 'must write to the correct snake_case column for $feature');
        expect(data['id'], isNotNull,
            reason: 'must include id so upsert matches the existing row');
      });
    }
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

  group('markUsed UsageOutcome', () {
    test('warmup 1 → 0 returns warmupJustExhausted', () async {
      await gating.debugSetWarmupRemaining(GatedFeature.reflect, 1);
      final outcome = await gating.markUsed(GatedFeature.reflect);
      expect(outcome, UsageOutcome.warmupJustExhausted);
    });

    test('warmup N>1 → N-1 returns ok', () async {
      await gating.debugSetWarmupRemaining(GatedFeature.reflect, 5);
      final outcome = await gating.markUsed(GatedFeature.reflect);
      expect(outcome, UsageOutcome.ok);
    });

    test('premium increment returns ok (never warmupJustExhausted)', () async {
      fakePurchase.premium = true;
      final outcome = await gating.markUsed(GatedFeature.reflect);
      expect(outcome, UsageOutcome.ok);
    });

    test('lapsed-trial daily increment returns ok', () async {
      await gating.debugSetHadTrial(true);
      final outcome = await gating.markUsed(GatedFeature.builtDua);
      expect(outcome, UsageOutcome.ok);
    });

    test('capped (warmup already 0) increment returns ok', () async {
      await gating.debugSetWarmupRemaining(GatedFeature.discoverName, 0);
      final outcome = await gating.markUsed(GatedFeature.discoverName);
      expect(outcome, UsageOutcome.ok);
    });

    test('only the transition call returns warmupJustExhausted; the next '
        'capped call returns ok', () async {
      await gating.debugSetWarmupRemaining(GatedFeature.reflect, 1);
      final transition = await gating.markUsed(GatedFeature.reflect);
      expect(transition, UsageOutcome.warmupJustExhausted);
      final after = await gating.markUsed(GatedFeature.reflect);
      expect(after, UsageOutcome.ok,
          reason:
              'second call falls into the daily-cap path and must not re-fire '
              'the one-shot warmup-exhausted signal');
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

  group('isPremiumHint plumbing — single-RC-roundtrip optimization', () {
    test('canUse with isPremiumHint skips PurchaseService.isPremium()',
        () async {
      fakePurchase.premium = true;
      fakePurchase.isPremiumCallCount = 0;

      final result = await gating.canUse(
        GatedFeature.reflect,
        isPremiumHint: true,
      );

      expect(result.allowed, isTrue);
      expect(result.reason, GateReason.ok);
      expect(fakePurchase.isPremiumCallCount, 0,
          reason: 'hint must short-circuit the RC round-trip');
    });

    test('markUsed with isPremiumHint skips PurchaseService.isPremium()',
        () async {
      fakePurchase.premium = true;
      fakePurchase.isPremiumCallCount = 0;

      await gating.markUsed(GatedFeature.reflect, isPremiumHint: true);

      expect(fakePurchase.isPremiumCallCount, 0,
          reason: 'hint must short-circuit the RC round-trip');
    });

    test('canUse without hint still calls isPremium() (backwards-compat)',
        () async {
      fakePurchase.premium = false;
      fakePurchase.isPremiumCallCount = 0;

      await gating.canUse(GatedFeature.reflect);

      expect(fakePurchase.isPremiumCallCount, 1);
    });

    test('hint=false routes to free path even when actual user is premium '
        '(hint is authoritative — caller takes responsibility)', () async {
      fakePurchase.premium = true; // Real status: premium.
      // Caller passes hint=false anyway. Gating must trust the hint.
      final result = await gating.canUse(
        GatedFeature.reflect,
        isPremiumHint: false,
      );
      expect(result.reason, GateReason.warmupRemaining,
          reason: 'hint overrides the underlying RC state');
    });
  });

  group('hydrateFromProfile', () {
    test(
        'overwrites local warmup counters AND had_trial latch from server '
        'profile payload — without this, reinstall would reset a lapsed '
        "trialer's gating state to fresh defaults, letting them grind "
        'warmup by uninstalling.', () async {
      // Pre-populate local prefs with stale values to prove they get
      // overwritten, not merged.
      await gating.debugSetWarmupRemaining(GatedFeature.reflect, 10);
      await gating.debugSetWarmupRemaining(GatedFeature.builtDua, 10);
      await gating.debugSetWarmupRemaining(GatedFeature.discoverName, 5);
      // had_trial defaults to false; explicit set to false to be explicit.
      await gating.debugSetHadTrial(false);

      await gating.hydrateFromProfile({
        'warmup_reflect_remaining': 0,
        'warmup_built_dua_remaining': 3,
        'warmup_discover_name_remaining': 1,
        'had_trial': true,
      });

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt(fakeSync.scopedKey('warmup_reflect_remaining')),
        0,
      );
      expect(
        prefs.getInt(fakeSync.scopedKey('warmup_builtDua_remaining')),
        3,
      );
      expect(
        prefs.getInt(fakeSync.scopedKey('warmup_discoverName_remaining')),
        1,
      );
      expect(
        prefs.getBool(fakeSync.scopedKey('had_trial')),
        true,
      );

      // Behavioral confirmation: with the latch on and warmup at zero, the
      // user is now resolved as Free+capped — the very state we want a
      // lapsed trialer to land in regardless of any prior local cache.
      final result = await gating.canUse(GatedFeature.reflect);
      expect(result.allowed, true,
          reason: 'first use today is allowed under the 1/day cap');

      // Use the day's budget then verify the second attempt blocks.
      await gating.markUsed(GatedFeature.reflect);
      final blocked = await gating.canUse(GatedFeature.reflect);
      expect(blocked.allowed, false);
      expect(blocked.reason, GateReason.hadTrialNoBudget);
    });

    test(
        'writes only under the current user scope — does not leak into '
        'another user (multi-account device safety)', () async {
      // user-1 receives a lapsed-trialer profile.
      await gating.hydrateFromProfile({
        'warmup_reflect_remaining': 0,
        'warmup_built_dua_remaining': 0,
        'warmup_discover_name_remaining': 0,
        'had_trial': true,
      });

      // Switch to user-2 — fresh user, no profile hydration yet.
      fakeSync.userId = 'user-2';

      final prefs = await SharedPreferences.getInstance();
      // user-2's keys must NOT carry user-1's lapsed-trialer state.
      expect(
        prefs.getBool(fakeSync.scopedKey('had_trial')),
        isNull,
        reason: 'had_trial latch must NOT leak across users',
      );
      expect(
        prefs.getInt(fakeSync.scopedKey('warmup_reflect_remaining')),
        isNull,
        reason: 'warmup counters must NOT leak across users',
      );

      // Behavioral confirmation: user-2 still gets a fresh warmup phase.
      final result = await gating.canUse(GatedFeature.reflect);
      expect(result.allowed, isTrue);
      expect(result.reason, GateReason.warmupRemaining,
          reason: 'user-2 must land in warmup phase, not lapsed-trialer phase');
    });

    test('skips fields that are missing or wrong type without crashing',
        () async {
      await gating.debugSetWarmupRemaining(GatedFeature.reflect, 7);
      await gating.debugSetHadTrial(true);

      // Empty payload — nothing should change.
      await gating.hydrateFromProfile({});

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt(fakeSync.scopedKey('warmup_reflect_remaining')),
        7,
      );
      expect(prefs.getBool(fakeSync.scopedKey('had_trial')), true);

      // Wrong types — also a no-op.
      await gating.hydrateFromProfile({
        'warmup_reflect_remaining': 'not-a-number',
        'had_trial': 'yes',
      });
      expect(
        prefs.getInt(fakeSync.scopedKey('warmup_reflect_remaining')),
        7,
      );
      expect(prefs.getBool(fakeSync.scopedKey('had_trial')), true);
    });
  });
}
