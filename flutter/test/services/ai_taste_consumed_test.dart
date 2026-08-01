// W6 Wave C — `ai_taste_consumed` is the denominator `daily_cap_hit` has
// always been the numerator of: nothing fired on a successful spend before
// this wave. Pins it firing exactly once per successful call in `markUsed`,
// with the right `allowance` naming which budget was actually spent, and
// — the load-bearing invariant — NEVER for premium, because a payer's
// unlimited use is not a "taste".

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

  List<({String event, Map<String, dynamic> props})> tasteEvents() =>
      emitted.where((e) => e.event == AnalyticsEvents.aiTasteConsumed).toList();

  test('warmup spend emits allowance=warmup with the post-decrement remaining',
      () async {
    // Mutation this catches: reading `warmup.remaining` (pre-decrement)
    // instead of `warmup.remaining - 1` for the `remaining` property.
    await gating.debugSetWarmupRemaining(GatedFeature.reflect, 4);

    await gating.markUsed(GatedFeature.reflect, isPremiumHint: false);

    final events = tasteEvents();
    expect(events, hasLength(1));
    expect(events.single.props[AnalyticsEvents.propFeature], 'reflect');
    expect(events.single.props[AnalyticsEvents.propAllowance],
        AnalyticsEvents.allowanceWarmup);
    expect(events.single.props[AnalyticsEvents.propRemaining], 3);
  });

  test(
      'warmup spend emits exactly once even on the 1→0 exhaustion transition '
      '(a second, distinct signal — UsageOutcome.warmupJustExhausted — must '
      'not suppress this one)', () async {
    await gating.debugSetWarmupRemaining(GatedFeature.builtDua, 1);

    final outcome =
        await gating.markUsed(GatedFeature.builtDua, isPremiumHint: false);

    expect(outcome, UsageOutcome.warmupJustExhausted);
    final events = tasteEvents();
    expect(events, hasLength(1));
    expect(events.single.props[AnalyticsEvents.propAllowance],
        AnalyticsEvents.allowanceWarmup);
    expect(events.single.props[AnalyticsEvents.propRemaining], 0);
  });

  test('legacy post-warmup spend emits allowance=daily with cap-minus-used',
      () async {
    // No warmup left, no had_trial skip → falls to `_consumePostWarmup`'s
    // daily branch (legacy, or reel_v1 discoverName).
    await gating.debugSetWarmupRemaining(GatedFeature.reflect, 0);

    await gating.markUsed(GatedFeature.reflect, isPremiumHint: false);

    final events = tasteEvents();
    expect(events, hasLength(1));
    expect(events.single.props[AnalyticsEvents.propAllowance],
        AnalyticsEvents.allowanceDaily);
    // dailyFreeReflects == 1, so after the one legal use, 0 remain.
    expect(events.single.props[AnalyticsEvents.propRemaining], 0);
  });

  test('had_trial user skips warmup straight to the daily branch', () async {
    fakePurchase.premium = false;
    await gating.debugSetHadTrial(true);

    await gating.markUsed(GatedFeature.builtDua, isPremiumHint: false);

    final events = tasteEvents();
    expect(events, hasLength(1));
    expect(events.single.props[AnalyticsEvents.propAllowance],
        AnalyticsEvents.allowanceDaily);
  });

  test('reel_v1 post-warmup reflect spend emits allowance=weekly_pool with '
      "the RPC's own remaining", () async {
    await gating.debugSetCohort(GatingService.cohortReelV1);
    await gating.debugSetWarmupRemaining(GatedFeature.reflect, 0);
    fakeSync.rpcHandlers['consume_weekly_allowance'] = (params) async {
      expect(params?['p_feature'], 'reflect');
      return {'allowed': true, 'remaining': 2, 'week_start': '2026-07-27'};
    };

    await gating.markUsed(GatedFeature.reflect, isPremiumHint: false);

    final events = tasteEvents();
    expect(events, hasLength(1));
    expect(events.single.props[AnalyticsEvents.propAllowance],
        AnalyticsEvents.allowanceWeeklyPool);
    expect(events.single.props[AnalyticsEvents.propRemaining], 2);
  });

  test(
      'a weekly-pool RPC that fails (network / null response) emits NOTHING '
      '— matching the fail-open, write-nothing posture of the spend itself',
      () async {
    await gating.debugSetCohort(GatingService.cohortReelV1);
    await gating.debugSetWarmupRemaining(GatedFeature.builtDua, 0);
    // No handler registered → callRpc returns null (see FakeSupabaseSyncService).

    await gating.markUsed(GatedFeature.builtDua, isPremiumHint: false);

    expect(tasteEvents(), isEmpty);
  });

  test(
      'premium NEVER emits ai_taste_consumed, however many uses recorded '
      '(mutation: moving the emit ahead of the premium short-circuit in '
      'markUsed would break this)', () async {
    fakePurchase.premium = true;

    await gating.markUsed(GatedFeature.reflect, isPremiumHint: true);
    await gating.markUsed(GatedFeature.builtDua, isPremiumHint: true);
    await gating.markUsed(GatedFeature.discoverName, isPremiumHint: true);

    expect(tasteEvents(), isEmpty,
        reason: 'a payer spending an unlimited use is not a "taste"');
  });
}
