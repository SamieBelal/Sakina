/// `GatingService.describeAllowance` — the read-only ladder behind every
/// "N reflections left" line in the app (2026-08-07).
///
/// Two properties matter here and neither is obvious from the type:
///
///  1. **It emits nothing.** `canUse` calls `_emitCapHit` when it blocks, so
///     using it to render a label would post a `daily_cap_hit` on every screen
///     build and destroy the numerator of the cap-hit→upgrade funnel. That is
///     the entire reason this function exists rather than a `canUse` call.
///  2. **It distinguishes the warm-up from the pool.** They are different
///     grants with different copy — one never returns, the other returns on
///     Monday — and a caller handed a bare `int` cannot tell them apart. An
///     earlier draft of the copy did exactly that and told every new account
///     that their three LIFETIME reflections would come back next week.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'package:sakina/services/daily_usage_service.dart' as daily;
import 'package:sakina/services/gating_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/user_local_day.dart';

import '../support/fake_supabase_sync_service.dart';

class _FakePurchaseService extends PurchaseService {
  _FakePurchaseService() : super.test();
  bool premium = false;
  @override
  Future<bool> isPremium() async => premium;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  late FakeSupabaseSyncService fakeSync;
  late _FakePurchaseService fakePurchase;
  late GatingService gating;
  late List<String> emitted;

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
    emitted = [];
    GatingService.onAnalyticsEvent = (event, _) => emitted.add(event);
  });

  tearDown(() {
    debugResetUserLocalDay();
    daily.debugDailyUsageClock = null;
    SupabaseSyncService.debugReset();
    PurchaseService.debugClearOverride();
    GatingService.onAnalyticsEvent = null;
  });

  group('describeAllowance — the ladder', () {
    test('a premium subscriber has no number, and must not be given one',
        () async {
      fakePurchase.premium = true;
      final snap = await gating.describeAllowance(GatedFeature.reflect);

      expect(snap.kind, AllowanceKind.unlimited);
      // Not `remaining: 30`. The fair-use ceiling is a silent "take a breath",
      // not an allowance — quoting it would invent a limit the subscriber does
      // not have, which is the bug `DailyCapSheet.describesNewTier` exists for.
      expect(snap.remaining, isNull);
      expect(snap.hasCount, isFalse);
    });

    test('a fresh free account is in WARM-UP, not the weekly pool', () async {
      // No warm-up counter written yet — the dial supplies it. This is the
      // state EVERY new account is in, which is why getting its copy wrong is
      // not an edge case.
      final snap = await gating.describeAllowance(GatedFeature.reflect);

      expect(snap.kind, AllowanceKind.warmup);
      expect(snap.hasCount, isTrue);
      expect(snap.remaining, greaterThan(0));
    });

    test('warm-up spent + reel_v1 cohort → the weekly pool', () async {
      await gating.debugSetCohort(GatingService.cohortReelV1);
      await gating.debugSetWarmupRemaining(GatedFeature.reflect, 0);

      final snap = await gating.describeAllowance(GatedFeature.reflect);
      expect(snap.kind, AllowanceKind.weeklyPool);
    });

    test('warm-up spent + legacy cohort → no number at all', () async {
      // Legacy is a per-day cap of one. It has a remainder, technically, but a
      // line reading "1 left today" and then "0 left today" for the rest of the
      // evening is a countdown to a wall — the opposite of what this is for.
      await gating.debugSetCohort('legacy');
      await gating.debugSetWarmupRemaining(GatedFeature.reflect, 0);

      final snap = await gating.describeAllowance(GatedFeature.reflect);
      expect(snap.kind, AllowanceKind.unmetered);
      expect(snap.hasCount, isFalse);
    });

    test('discoverName is exempt from the pool even on reel_v1', () async {
      // Past warm-up its re-rolls are premium-only (`GateReason.rerollPremium`)
      // and the day's own Name consults no gate at all. Neither is a countable
      // remainder, so there is nothing honest to render.
      await gating.debugSetCohort(GatingService.cohortReelV1);
      await gating.debugSetWarmupRemaining(GatedFeature.discoverName, 0);

      final snap = await gating.describeAllowance(GatedFeature.discoverName);
      expect(snap.kind, AllowanceKind.unmetered);
    });

    test('a lapsed trialist skips warm-up, exactly as canUse does', () async {
      // `canUse` jumps straight to the post-warmup tier for `had_trial`. If
      // this did not, the label would promise a grant the gate will not honour
      // — the two must agree about which rule applies, which is why the branch
      // ORDER here is a copy of `canUse`'s rather than a delegation to it.
      await gating.debugSetCohort(GatingService.cohortReelV1);
      await gating.debugSetHadTrial(true);

      final snap = await gating.describeAllowance(GatedFeature.reflect);
      expect(snap.kind, AllowanceKind.weeklyPool,
          reason: 'a lapsed trialist has no warm-up left to describe');
    });
  });

  group('describeAllowance is silent', () {
    test('a spent pool produces NO daily_cap_hit', () async {
      await gating.debugSetCohort(GatingService.cohortReelV1);
      await gating.debugSetWarmupRemaining(GatedFeature.reflect, 0);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(fakeSync.scopedKey('weekly_pool_used'), 99);
      await prefs.setString(
          fakeSync.scopedKey('weekly_pool_week_start'), '2026-07-27');

      final snap = await gating.describeAllowance(GatedFeature.reflect);
      expect(snap.remaining, 0, reason: 'the pool really is spent');

      // THE point of this function. `canUse` in the same state emits
      // `daily_cap_hit`; a header line that did the same would post one event
      // per screen build and make the cap-hit→upgrade funnel unreadable.
      expect(emitted, isEmpty,
          reason: 'describeAllowance is a read. It must never emit, spend or '
              'write anything: $emitted');
    });

    test('canUse in the SAME state does emit — the contrast is the point',
        () async {
      await gating.debugSetCohort(GatingService.cohortReelV1);
      await gating.debugSetWarmupRemaining(GatedFeature.reflect, 0);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(fakeSync.scopedKey('weekly_pool_used'), 99);
      await prefs.setString(
          fakeSync.scopedKey('weekly_pool_week_start'), '2026-07-27');

      await gating.canUse(GatedFeature.reflect);

      // If this ever stops emitting, the silence asserted above stops meaning
      // anything and this pair of tests should be revisited together.
      expect(emitted, contains('daily_cap_hit'));
    });

    test('every kind is silent, not just the blocked one', () async {
      for (final premium in [true, false]) {
        fakePurchase.premium = premium;
        await gating.describeAllowance(GatedFeature.reflect);
      }
      expect(emitted, isEmpty);
    });
  });
}
