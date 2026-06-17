import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/analytics_event_names.dart';
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
  late List<({String event, Map<String, dynamic> props})> emitted;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    fakePurchase = _FakePurchaseService();
    PurchaseService.debugSetOverride(fakePurchase);
    gating = GatingService.test();
    emitted = [];
    GatingService.onAnalyticsEvent =
        (event, props) => emitted.add((event: event, props: props));
  });

  tearDown(() {
    GatingService.onAnalyticsEvent = null;
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
    final now = DateTime.now().toUtc();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await prefs.setInt(
      fakeSync.scopedKey('daily_usage_${featureKey}_$today'),
      count,
    );
  }

  test('emits daily_cap_hit with feature when a lapsed-trial user is blocked',
      () async {
    fakePurchase.premium = false;
    // Lapsed trialer → no warmup, 1/day cap. canUse reads the had_trial latch
    // from SharedPreferences (NOT PurchaseService.hadTrial), so set it there.
    await gating.debugSetHadTrial(true);
    await setUsageToday(GatedFeature.reflect, daily.dailyFreeReflects);

    final result = await gating.canUse(GatedFeature.reflect);

    expect(result.allowed, isFalse);
    expect(result.reason, GateReason.hadTrialNoBudget);
    final caps =
        emitted.where((e) => e.event == AnalyticsEvents.dailyCapHit).toList();
    expect(caps, hasLength(1));
    expect(caps.single.props[AnalyticsEvents.propFeature], 'reflect');
  });

  test('emits daily_cap_hit when a free (no-trial) user is blocked at the cap',
      () async {
    fakePurchase.premium = false;
    fakePurchase.trial = false;
    // Exhaust warmup so we fall through to the daily cap, then hit the cap.
    await gating.debugSetWarmupRemaining(GatedFeature.builtDua, 0);
    await setUsageToday(GatedFeature.builtDua, daily.dailyFreeBuiltDuas);

    final result = await gating.canUse(GatedFeature.builtDua);

    expect(result.allowed, isFalse);
    expect(result.reason, GateReason.dailyCap);
    final caps =
        emitted.where((e) => e.event == AnalyticsEvents.dailyCapHit).toList();
    expect(caps, hasLength(1));
    expect(caps.single.props[AnalyticsEvents.propFeature], 'built_dua');
  });

  test('does NOT emit daily_cap_hit when the user is allowed', () async {
    fakePurchase.premium = false;
    fakePurchase.trial = false; // warmup remaining → allowed
    final result = await gating.canUse(GatedFeature.discoverName);

    expect(result.allowed, isTrue);
    expect(emitted.where((e) => e.event == AnalyticsEvents.dailyCapHit),
        isEmpty);
  });

  test('does NOT emit daily_cap_hit for a premium user (never capped to paywall)',
      () async {
    fakePurchase.premium = true;
    await setUsageToday(GatedFeature.reflect, GatingService.premiumDailyFairUseCap);

    final result = await gating.canUse(GatedFeature.reflect);

    expect(result.allowed, isFalse);
    expect(result.reason, GateReason.premiumFairUse);
    // Premium fair-use is a silent "take a breath", NOT a paywall cap-hit.
    expect(emitted.where((e) => e.event == AnalyticsEvents.dailyCapHit),
        isEmpty);
  });
}
