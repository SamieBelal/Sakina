// W6 Wave C, D5 — `daily_cap_hit` gains `reason`. `daily_cap_hit` already
// fired on every block a free user can hit, in both cohorts, from one
// function (`GatingService._emitCapHit`); before this wave it carried only
// `{feature}`, so warmup exhaustion vs weekly-pool block vs lapsed-trial vs
// re-roll wall were indistinguishable. D5 explicitly rejected minting a
// second `ai_allowance_exhausted` event for the new tier — that would fork
// the cap-hit→upgrade funnel exactly across the T0 boundary the pre/post
// comparison depends on — so this pins the ADDED property on the ONE event,
// and that premium fair-use (a silent "take a breath", never a paywall)
// still produces none at all.

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/daily_usage_service.dart' as daily;
import 'package:sakina/services/gating_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

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
  tzdata.initializeTimeZones();

  late FakeSupabaseSyncService fakeSync;
  late _FakePurchaseService fakePurchase;
  late GatingService gating;
  late List<({String event, Map<String, dynamic> props})> emitted;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    fakePurchase = _FakePurchaseService();
    PurchaseService.debugSetOverride(fakePurchase);
    gating = GatingService.test();
    debugResetUserLocalDay();
    debugUserTimeZoneOverride = 'UTC';
    debugUserLocalDayClock = () => DateTime.utc(2026, 7, 29, 12);
    daily.debugDailyUsageClock = () => DateTime.utc(2026, 7, 29, 12);
    await hydrateTokenCache(balance: 500, totalSpent: 0);
    emitted = [];
    GatingService.onAnalyticsEvent =
        (event, props) => emitted.add((event: event, props: props));
  });

  tearDown(() {
    debugResetUserLocalDay();
    daily.debugDailyUsageClock = null;
    SupabaseSyncService.debugReset();
    PurchaseService.debugClearOverride();
    GatingService.onAnalyticsEvent = null;
  });

  List<({String event, Map<String, dynamic> props})> capHits() =>
      emitted.where((e) => e.event == AnalyticsEvents.dailyCapHit).toList();

  Future<void> setUsageToday(GatedFeature feature, int count) async {
    final prefs = await SharedPreferences.getInstance();
    final featureKey = switch (feature) {
      GatedFeature.reflect => 'reflect',
      GatedFeature.builtDua => 'built_dua',
      GatedFeature.discoverName => 'discover_name',
    };
    const today = '2026-07-29';
    await prefs.setInt(
      fakeSync.scopedKey('daily_usage_${featureKey}_$today'),
      count,
    );
  }

  test('legacy free user at the cap → reason=daily_cap', () async {
    fakePurchase.trial = false;
    await gating.debugSetWarmupRemaining(GatedFeature.builtDua, 0);
    await setUsageToday(GatedFeature.builtDua, daily.dailyFreeBuiltDuas);

    final result = await gating.canUse(GatedFeature.builtDua);

    expect(result.reason, GateReason.dailyCap);
    final hits = capHits();
    expect(hits, hasLength(1));
    expect(hits.single.props[AnalyticsEvents.propReason],
        AnalyticsEvents.gateReasonDailyCap);
  });

  test('lapsed trialer at the cap → reason=had_trial_no_budget', () async {
    await gating.debugSetHadTrial(true);
    await setUsageToday(GatedFeature.reflect, daily.dailyFreeReflects);

    final result = await gating.canUse(GatedFeature.reflect);

    expect(result.reason, GateReason.hadTrialNoBudget);
    final hits = capHits();
    expect(hits, hasLength(1));
    expect(hits.single.props[AnalyticsEvents.propReason],
        AnalyticsEvents.gateReasonHadTrialNoBudget);
  });

  test('reel_v1 weekly pool spent → reason=weekly_pool', () async {
    await gating.debugSetCohort(GatingService.cohortReelV1);
    await gating.debugSetWarmupRemaining(GatedFeature.reflect, 0);
    await gating.debugSetWeeklyPool(used: 3, weekStart: '2026-07-27');

    final result = await gating.canUse(GatedFeature.reflect);

    expect(result.reason, GateReason.weeklyPool);
    final hits = capHits();
    expect(hits, hasLength(1));
    expect(hits.single.props[AnalyticsEvents.propReason],
        AnalyticsEvents.gateReasonWeeklyPool);
  });

  test('reel_v1 discoverName re-roll past warmup → reason=reroll_premium',
      () async {
    await gating.debugSetCohort(GatingService.cohortReelV1);
    await gating.debugSetWarmupRemaining(GatedFeature.discoverName, 0);

    final result = await gating.canUse(GatedFeature.discoverName);

    expect(result.reason, GateReason.rerollPremium);
    final hits = capHits();
    expect(hits, hasLength(1));
    expect(hits.single.props[AnalyticsEvents.propReason],
        AnalyticsEvents.gateReasonRerollPremium);
  });

  test(
      'premium fair-use ceiling emits NO daily_cap_hit at all — mutation: '
      'routing premiumFairUse through _emitCapHit would break this',
      () async {
    fakePurchase.premium = true;
    await setUsageToday(
      GatedFeature.reflect,
      GatingService.premiumDailyFairUseCap,
    );

    final result = await gating.canUse(GatedFeature.reflect);

    expect(result.reason, GateReason.premiumFairUse);
    expect(capHits(), isEmpty);
  });

  test('every reason produces its OWN wire value, never a shared default',
      () async {
    // Guards against a lazy implementation that always emits the same
    // literal string regardless of which GateReason actually fired.
    final seen = <String>{};

    await gating.debugSetWarmupRemaining(GatedFeature.builtDua, 0);
    await setUsageToday(GatedFeature.builtDua, daily.dailyFreeBuiltDuas);
    await gating.canUse(GatedFeature.builtDua);
    seen.add(capHits().last.props[AnalyticsEvents.propReason] as String);

    emitted.clear();
    await gating.debugSetHadTrial(true);
    await setUsageToday(GatedFeature.reflect, daily.dailyFreeReflects);
    await gating.canUse(GatedFeature.reflect);
    seen.add(capHits().last.props[AnalyticsEvents.propReason] as String);

    emitted.clear();
    await gating.debugSetHadTrial(false);
    await gating.debugSetCohort(GatingService.cohortReelV1);
    await gating.debugSetWarmupRemaining(GatedFeature.reflect, 0);
    await gating.debugSetWeeklyPool(used: 3, weekStart: '2026-07-27');
    await gating.canUse(GatedFeature.reflect);
    seen.add(capHits().last.props[AnalyticsEvents.propReason] as String);

    emitted.clear();
    await gating.debugSetWarmupRemaining(GatedFeature.discoverName, 0);
    await gating.canUse(GatedFeature.discoverName);
    seen.add(capHits().last.props[AnalyticsEvents.propReason] as String);

    expect(seen, hasLength(4),
        reason: 'all four blocking reasons must map to distinct wire values');
  });
}
