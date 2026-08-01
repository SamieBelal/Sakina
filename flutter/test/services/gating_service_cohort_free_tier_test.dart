// One Ship W5 — Wave D.2 / D.3 / D.4: the cohort-scoped free tier.
//
// One gate, two economies, selected by `user_profiles.free_tier_cohort`:
//
//   legacy  — unchanged, byte for byte. 10/10/5 warmups, a local 1/day cap per
//             feature, `discoverName` at an effective 2/day, the token bypass
//             and the Day-1 freebie both available. The existing base is
//             migrated by the SOFTENER wave, announced; nothing here may
//             tighten them.
//   reel_v1 — `reflect` + `builtDua` share a server-authoritative WEEKLY POOL
//             (`consume_weekly_allowance`); `discoverName` keeps its free
//             day-open reveal and has NO free re-roll past warmup; the bypass
//             does not exist.
//
// The three properties worth stating up front, because each of them is a
// failure this suite exists to catch rather than a feature it documents:
//
//   * `isNewCohort` fails to FALSE. Legacy is the more generous tier, so an
//     account whose cohort cannot be determined is never handed the tighter
//     rules on a guess.
//   * The pool RPC fails OPEN and writes NOTHING when it fails. A network blip
//     may neither charge twice nor lock anyone out.
//   * The premium short-circuit in `reserveBypass` stays the FIRST statement,
//     ahead of the cohort read. Premium must never reach that RPC regardless
//     of which economy the account is on (CLAUDE.md).

import 'package:flutter_test/flutter_test.dart';
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
  @override
  Future<bool> isPremium() async => premium;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  late FakeSupabaseSyncService fakeSync;
  late _FakePurchaseService fakePurchase;
  late GatingService gating;

  // Wednesday 2026-07-29. Its ISO Monday is 2026-07-27; the week before is
  // 2026-07-20. Pinned rather than computed so the expectations below are
  // literals a reader can check, not a re-run of the implementation's own
  // arithmetic.
  const thisMonday = '2026-07-27';
  const lastMonday = '2026-07-20';

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
  });

  tearDown(() {
    debugResetUserLocalDay();
    daily.debugDailyUsageClock = null;
    SupabaseSyncService.debugReset();
    PurchaseService.debugClearOverride();
    GatingService.onAnalyticsEvent = null;
  });

  Future<void> setCohort(String? cohort) => gating.debugSetCohort(cohort);

  Future<void> exhaustWarmup(GatedFeature f) =>
      gating.debugSetWarmupRemaining(f, 0);

  /// Registers a `consume_weekly_allowance` handler that behaves like the real
  /// RPC: it decrements a server-side counter and reports what is left.
  /// Returns the call log so tests can assert on the feature key and the count.
  List<Map<String, dynamic>> installPoolRpc({int poolSize = 3, int used = 0}) {
    var serverUsed = used;
    fakeSync.rpcHandlers['consume_weekly_allowance'] = (params) async {
      if (serverUsed >= poolSize) {
        return {'allowed': false, 'remaining': 0, 'week_start': thisMonday};
      }
      serverUsed += 1;
      return {
        'allowed': true,
        'remaining': poolSize - serverUsed,
        'week_start': thisMonday,
      };
    };
    return fakeSync.rpcCalls;
  }

  List<Map<String, dynamic>> rpcCallsTo(String fn) =>
      fakeSync.rpcCalls.where((c) => c['fn'] == fn).toList();

  // ===========================================================================
  // isNewCohort — the seam, and its fail-to-false posture.
  // ===========================================================================

  group('isNewCohort', () {
    test('reel_v1 → true', () async {
      await setCohort('reel_v1');
      expect(await gating.isNewCohort(), isTrue);
    });

    test('legacy → false', () async {
      await setCohort('legacy');
      expect(await gating.isNewCohort(), isFalse);
    });

    test('no cached value at all → false (the fresh-install case)', () async {
      expect(await gating.isNewCohort(), isFalse,
          reason: 'a fresh install before the first batch sync knows nothing '
              'about the account; it must take the GENEROUS tier, not the '
              'tightened one');
    });

    test('an unrecognised value → false', () async {
      for (final junk in ['REEL_V1', 'reel_v2', '', 'true', 'reel_v1 ']) {
        await setCohort(junk);
        expect(await gating.isNewCohort(), isFalse,
            reason: 'only an exact "reel_v1" selects the tightened tier; '
                '"$junk" is an unknown cohort and unknown means legacy');
      }
    });

    test('never touches the network — no RPC, no row read', () async {
      await setCohort('reel_v1');
      await gating.isNewCohort();
      expect(fakeSync.rpcCalls, isEmpty);
      expect(fakeSync.upsertCalls, isEmpty);
      expect(fakeSync.rawUpsertCalls, isEmpty);
    });

    test('is scoped per user — another account does not inherit it', () async {
      await setCohort('reel_v1');
      expect(await gating.isNewCohort(), isTrue);
      fakeSync.userId = 'user-2';
      expect(await gating.isNewCohort(), isFalse,
          reason: 'sign-in as someone else must not carry the cohort across');
    });
  });

  group('hydrateFromProfile is the only writer of the cohort', () {
    test('stamps reel_v1 from the server payload', () async {
      await gating.hydrateFromProfile({'free_tier_cohort': 'reel_v1'});
      expect(await gating.isNewCohort(), isTrue);
    });

    test('a legacy payload CLEARS a previously cached reel_v1', () async {
      await setCohort('reel_v1');
      await gating.hydrateFromProfile({'free_tier_cohort': 'legacy'});
      expect(await gating.isNewCohort(), isFalse);
    });

    test('a null / absent key clears rather than leaving a stale value',
        () async {
      await setCohort('reel_v1');
      await gating.hydrateFromProfile({'free_tier_cohort': null});
      expect(await gating.isNewCohort(), isFalse);

      await setCohort('reel_v1');
      await gating.hydrateFromProfile(const {});
      expect(await gating.isNewCohort(), isFalse,
          reason: 'a pre-20260727100300 backend returns no key at all; that '
              'is not evidence of reel_v1');
    });
  });

  // ===========================================================================
  // D.2 — the weekly pool. reflect / builtDua.
  // ===========================================================================

  group('canUse: reflect + builtDua branch on cohort', () {
    for (final feature in [GatedFeature.reflect, GatedFeature.builtDua]) {
      test('${feature.name}: legacy past warmup keeps the DAILY cap', () async {
        await setCohort('legacy');
        await exhaustWarmup(feature);

        expect((await gating.canUse(feature)).allowed, isTrue);
        await gating.markUsed(feature);

        final blocked = await gating.canUse(feature);
        expect(blocked.allowed, isFalse);
        expect(blocked.reason, GateReason.dailyCap,
            reason: 'legacy is unchanged — a daily cap, not a weekly pool');
        expect(rpcCallsTo('consume_weekly_allowance'), isEmpty,
            reason: 'the pool RPC must never fire for a legacy account');
      });

      test('${feature.name}: reel_v1 past warmup uses the WEEKLY POOL',
          () async {
        await setCohort('reel_v1');
        await exhaustWarmup(feature);

        final first = await gating.canUse(feature);
        expect(first.allowed, isTrue);
        expect(first.reason, GateReason.ok);
        expect(first.remaining, 3, reason: 'the full pool is unspent');
      });

      test('${feature.name}: reel_v1 is NOT governed by the daily counter',
          () async {
        await setCohort('reel_v1');
        await exhaustWarmup(feature);
        // A day's worth of the LEGACY allowance, spent. Under the old rules
        // this alone would block.
        await daily.incrementReflectUsage();
        await daily.incrementBuiltDuaUsage();

        expect((await gating.canUse(feature)).allowed, isTrue,
            reason: 'the weekly pool REPLACES the daily cap for reel_v1 — a '
                'gate that still consulted the daily counter would give the '
                'new cohort 1/day AND 3/week, which is neither policy');
      });
    }

    test('reel_v1: the pool is SHARED across reflect and builtDua', () async {
      await setCohort('reel_v1');
      await exhaustWarmup(GatedFeature.reflect);
      await exhaustWarmup(GatedFeature.builtDua);
      installPoolRpc();

      await gating.markUsed(GatedFeature.reflect);
      await gating.markUsed(GatedFeature.reflect);
      await gating.markUsed(GatedFeature.builtDua);

      final gate = await gating.canUse(GatedFeature.builtDua);
      expect(gate.allowed, isFalse);
      expect(gate.reason, GateReason.weeklyPool);
      expect(gate.remaining, 0,
          reason: 'three uses across BOTH features exhaust one pool of three');
    });

    test('reel_v1: a spent pool reports weeklyPool, not dailyCap', () async {
      await setCohort('reel_v1');
      await exhaustWarmup(GatedFeature.reflect);
      await gating.debugSetWeeklyPool(used: 3, weekStart: thisMonday);

      final gate = await gating.canUse(GatedFeature.reflect);
      expect(gate.allowed, isFalse);
      expect(gate.reason, GateReason.weeklyPool,
          reason: 'the sheet has to tell a MONDAY reset story, not a '
              'tomorrow one (D10③) — it branches on this reason');
    });

    test('reel_v1: a spent pool from LAST week does not lock the user out',
        () async {
      await setCohort('reel_v1');
      await exhaustWarmup(GatedFeature.reflect);
      await gating.debugSetWeeklyPool(used: 3, weekStart: lastMonday);

      expect((await gating.canUse(GatedFeature.reflect)).allowed, isTrue,
          reason: 'weekly_pool_used only resets INSIDE the RPC. A gate that '
              'trusted a stale used-count would refuse, the RPC would never '
              'be called, and the reset would never happen — a PERMANENT '
              'lockout, not a one-week one');
    });

    test('reel_v1: no week marker at all reads as a full pool', () async {
      await setCohort('reel_v1');
      await exhaustWarmup(GatedFeature.reflect);
      await gating.debugSetWeeklyPool(used: 3, weekStart: null);

      expect((await gating.canUse(GatedFeature.reflect)).allowed, isTrue,
          reason: 'a count with no week to date it is not evidence of a spent '
              'week');
    });

    test('the pool size is a server dial, not a constant', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_config_cache_v1_weekly_pool_size', '1');
      await prefs.setInt('app_config_cache_v1_weekly_pool_size_at',
          DateTime.now().millisecondsSinceEpoch);

      await setCohort('reel_v1');
      await exhaustWarmup(GatedFeature.reflect);
      expect(await gating.weeklyPoolSize(), 1);
      expect(GatingService.weeklyPoolSizeFallback, isNot(1),
          reason: 'the fallback must differ from the dial, otherwise this '
              'test would pass against a service that ignores config');

      await gating.debugSetWeeklyPool(used: 1, weekStart: thisMonday);
      expect((await gating.canUse(GatedFeature.reflect)).reason,
          GateReason.weeklyPool);
    });

    test('a negative dial is corruption and falls back, never inverts the gate',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_config_cache_v1_weekly_pool_size', '-5');
      await prefs.setInt('app_config_cache_v1_weekly_pool_size_at',
          DateTime.now().millisecondsSinceEpoch);
      expect(await gating.weeklyPoolSize(),
          GatingService.weeklyPoolSizeFallback);
    });
  });

  group('markUsed: the pool is spent server-side', () {
    test('reel_v1 reflect calls consume_weekly_allowance, not the daily counter',
        () async {
      await setCohort('reel_v1');
      await exhaustWarmup(GatedFeature.reflect);
      installPoolRpc();

      await gating.markUsed(GatedFeature.reflect);

      final calls = rpcCallsTo('consume_weekly_allowance');
      expect(calls, hasLength(1));
      expect(calls.single['params'], {'p_feature': 'reflect'},
          reason: 'the RPC rejects anything but reflect / built_dua');
      expect(await daily.getReflectUsageToday(), 0,
          reason: 'charging BOTH the pool and the daily counter would take '
              'two uses for one call');
    });

    test('reel_v1 builtDua sends the RPC\'s own feature key', () async {
      await setCohort('reel_v1');
      await exhaustWarmup(GatedFeature.builtDua);
      installPoolRpc();

      await gating.markUsed(GatedFeature.builtDua);
      expect(rpcCallsTo('consume_weekly_allowance').single['params'],
          {'p_feature': 'built_dua'});
    });

    test('legacy reflect increments the daily counter and fires no RPC',
        () async {
      await setCohort('legacy');
      await exhaustWarmup(GatedFeature.reflect);
      installPoolRpc();

      await gating.markUsed(GatedFeature.reflect);

      expect(await daily.getReflectUsageToday(), 1);
      expect(rpcCallsTo('consume_weekly_allowance'), isEmpty);
    });

    test('the server\'s remaining is mirrored into the cache', () async {
      await setCohort('reel_v1');
      await exhaustWarmup(GatedFeature.reflect);
      installPoolRpc();

      await gating.markUsed(GatedFeature.reflect);
      expect(await gating.weeklyPoolRemaining(), 2);
      await gating.markUsed(GatedFeature.reflect);
      expect(await gating.weeklyPoolRemaining(), 1);
    });

    test('a server refusal drives the cache to empty — the server corrects us',
        () async {
      await setCohort('reel_v1');
      await exhaustWarmup(GatedFeature.reflect);
      // Server says the pool is already gone (e.g. spent on another device)
      // while the local cache still believes it is full.
      fakeSync.rpcHandlers['consume_weekly_allowance'] = (_) async =>
          {'allowed': false, 'remaining': 0, 'week_start': thisMonday};

      expect((await gating.canUse(GatedFeature.reflect)).allowed, isTrue,
          reason: 'the stale cache lets one call through — that is the '
              'fail-open cost, and it is bounded to one');
      await gating.markUsed(GatedFeature.reflect);

      final gate = await gating.canUse(GatedFeature.reflect);
      expect(gate.allowed, isFalse);
      expect(gate.reason, GateReason.weeklyPool,
          reason: 'the server\'s verdict overwrites the cache, so the NEXT '
              'attempt is refused rather than looping forever');
    });

    test('premium never spends the pool', () async {
      fakePurchase.premium = true;
      await setCohort('reel_v1');
      installPoolRpc();

      await gating.markUsed(GatedFeature.reflect);
      expect(rpcCallsTo('consume_weekly_allowance'), isEmpty);
      expect(await daily.getReflectUsageToday(), 1,
          reason: 'premium stays on the fair-use counter it has always used');
    });

    test('the warmup 1 → 0 transition signals once and leaves the pool whole',
        () async {
      await setCohort('reel_v1');
      await gating.debugSetWarmupRemaining(GatedFeature.reflect, 1);
      installPoolRpc();

      final outcome = await gating.markUsed(GatedFeature.reflect);
      expect(outcome, UsageOutcome.warmupJustExhausted);
      expect(rpcCallsTo('consume_weekly_allowance'), isEmpty,
          reason: 'the N+1 rule this transition carries is a SAME-DAY, '
              'per-feature one — it exists because the daily counter would '
              'otherwise hand out a second use before midnight. The pool has '
              'no such granularity: past warmup it IS the week\'s whole '
              'allowance, so there is no double-grant to buy back, only a use '
              'to confiscate');
      expect(await gating.weeklyPoolRemaining(), 3);

      // And the allowance that follows is the full advertised three, not two.
      for (var i = 0; i < 3; i++) {
        expect((await gating.canUse(GatedFeature.reflect)).allowed, isTrue);
        await gating.markUsed(GatedFeature.reflect);
      }
      expect((await gating.canUse(GatedFeature.reflect)).reason,
          GateReason.weeklyPool);
    });

    test('legacy KEEPS the same-day charge on the warmup 1 → 0 transition',
        () async {
      await setCohort('legacy');
      await gating.debugSetWarmupRemaining(GatedFeature.reflect, 1);

      expect(await gating.markUsed(GatedFeature.reflect),
          UsageOutcome.warmupJustExhausted);
      expect(await daily.getReflectUsageToday(), 1,
          reason: 'unchanged, byte for byte: without it the legacy user gets '
              'a second reflection today on top of the exhausting one');
      expect((await gating.canUse(GatedFeature.reflect)).reason,
          GateReason.dailyCap);
    });

    test('reel_v1 discoverName KEEPS the same-day charge — it is pool-exempt '
        'and stays on the daily counter', () async {
      await setCohort('reel_v1');
      await gating.debugSetWarmupRemaining(GatedFeature.discoverName, 1);

      expect(await gating.markUsed(GatedFeature.discoverName),
          UsageOutcome.warmupJustExhausted);
      expect(await daily.getDiscoverNameUsageToday(), 1,
          reason: 'user_daily_usage.discover_name_uses is what analytics and '
              'multi-device reconciliation read');
      expect(rpcCallsTo('consume_weekly_allowance'), isEmpty);
    });

    test(
        'exhausting one feature\'s warmup does not spend the SHARED pool the '
        'other feature also draws on', () async {
      await setCohort('reel_v1');
      await gating.debugSetWarmupRemaining(GatedFeature.reflect, 1);
      await gating.debugSetWarmupRemaining(GatedFeature.builtDua, 1);
      installPoolRpc();

      expect(await gating.markUsed(GatedFeature.reflect),
          UsageOutcome.warmupJustExhausted);
      expect(await gating.markUsed(GatedFeature.builtDua),
          UsageOutcome.warmupJustExhausted);

      expect(rpcCallsTo('consume_weekly_allowance'), isEmpty,
          reason: 'the warmup already paid for both of those calls. The daily '
              'counter this rule was written for is PER FEATURE and resets '
              'tomorrow; the pool is SHARED and resets on Monday, so charging '
              'it here takes builtDua\'s allowance to pay for reflect\'s '
              'warmup and cannot be undone until Monday');
      expect(await gating.weeklyPoolRemaining(), 3,
          reason: 'a user who has just finished both warmups has made zero '
              'post-warmup calls, so all three of the week\'s uses must '
              'still be there');
    });

    test('warmup still runs BEFORE the pool for reel_v1', () async {
      await setCohort('reel_v1');
      await gating.debugSetWarmupRemaining(GatedFeature.reflect, 2);
      installPoolRpc();

      final gate = await gating.canUse(GatedFeature.reflect);
      expect(gate.reason, GateReason.warmupRemaining);
      await gating.markUsed(GatedFeature.reflect);
      expect(rpcCallsTo('consume_weekly_allowance'), isEmpty,
          reason: 'a warmup use is free; spending the pool as well would burn '
              'the whole week inside the warmup');
    });
  });

  group('the pool RPC fails OPEN', () {
    test('an unreachable server writes NOTHING and denies NOTHING', () async {
      await setCohort('reel_v1');
      await exhaustWarmup(GatedFeature.reflect);
      // No handler registered → `callRpc` answers null, exactly as production
      // does for both "refused" and "never reached".

      await gating.markUsed(GatedFeature.reflect);

      expect(await gating.weeklyPoolRemaining(), 3,
          reason: 'the client does not know whether the RPC ran. Charging '
              'locally would double-charge on the next successful call; the '
              'cache must stay exactly as the last authoritative sync left it');
      expect((await gating.canUse(GatedFeature.reflect)).allowed, isTrue,
          reason: 'and a network blip must never lock anyone out');
    });

    test('a malformed response is treated as a failure, not as zero remaining',
        () async {
      await setCohort('reel_v1');
      await exhaustWarmup(GatedFeature.reflect);
      fakeSync.rpcHandlers['consume_weekly_allowance'] =
          (_) async => {'allowed': true};

      await gating.markUsed(GatedFeature.reflect);
      expect(await gating.weeklyPoolRemaining(), 3);
      expect((await gating.canUse(GatedFeature.reflect)).allowed, isTrue);
    });

    test('a THROWING call does not escape markUsed', () async {
      await setCohort('reel_v1');
      await exhaustWarmup(GatedFeature.reflect);
      fakeSync.rpcHandlers['consume_weekly_allowance'] =
          (_) async => throw StateError('socket died');

      await expectLater(gating.markUsed(GatedFeature.reflect), completes,
          reason: 'a throw escaping here would propagate into the caller and, '
              'on the discover path, flip a reveal that HAPPENED into an error');
      expect(await gating.weeklyPoolRemaining(), 3);
    });

    test('a week marker is never stamped without a usable count', () async {
      await setCohort('reel_v1');
      await exhaustWarmup(GatedFeature.reflect);
      await gating.debugSetWeeklyPool(used: 3, weekStart: lastMonday);
      // Malformed: a week, but nothing to say how much of it is left.
      fakeSync.rpcHandlers['consume_weekly_allowance'] =
          (_) async => {'allowed': true, 'week_start': thisMonday};

      await gating.markUsed(GatedFeature.reflect);
      expect((await gating.canUse(GatedFeature.reflect)).allowed, isTrue,
          reason: 'stamping THIS week over a stale count of 3 would present '
              'last week\'s spend as this week\'s');
    });
  });

  // ===========================================================================
  // The client's week boundary has to be the SAME boundary
  // `consume_weekly_allowance` computes with
  // `date_trunc('week', now() at time zone safe_user_tz(uid))`. If it drifts,
  // the stale-week rule either denies a user their Monday or hands out a week
  // they have not earned — so the edges are pinned here as literals rather
  // than left to the arithmetic.
  // ===========================================================================

  group('the local week boundary', () {
    /// 3 = "the cached week is stale, take the probe"; 0 = "that IS this week".
    Future<int> remainingAgainst(String weekStart) async {
      await gating.debugSetWeeklyPool(used: 3, weekStart: weekStart);
      return gating.weeklyPoolRemaining();
    }

    void pin(String zone, DateTime utcInstant) {
      debugResetUserLocalDay();
      debugUserTimeZoneOverride = zone;
      debugUserLocalDayClock = () => utcInstant;
    }

    test('Sunday belongs to the week that STARTED on Monday, as ISO says',
        () async {
      // Sun 2026-11-01 13:00 in New York. date_trunc('week') → 2026-10-26.
      pin('America/New_York', DateTime.utc(2026, 11, 1, 18));
      expect(await remainingAgainst('2026-10-26'), 0);
      expect(await remainingAgainst('2026-10-19'), 3);
    });

    test('a DST transition does not move the week', () async {
      // US DST ends 02:00 local on Sun 2026-11-01. Either side of it, the week
      // is still the one that began Mon 2026-10-26 — the date-only arithmetic
      // has no wall-clock hour to lose.
      pin('America/New_York', DateTime.utc(2026, 11, 1, 4)); // 00:00 EDT
      expect(await remainingAgainst('2026-10-26'), 0);
      pin('America/New_York', DateTime.utc(2026, 11, 1, 7)); // 02:00 EST
      expect(await remainingAgainst('2026-10-26'), 0);
      // …and the following Monday does roll it over.
      pin('America/New_York', DateTime.utc(2026, 11, 2, 12));
      expect(await remainingAgainst('2026-10-26'), 3);
    });

    test('a zone east of UTC crosses into Monday before UTC does — the skew '
        'the probe bounds', () async {
      // Sun 2026-11-01 12:00 UTC is already Mon 2026-11-02 01:00 in Auckland.
      // A server whose `safe_user_tz` has degraded to 'UTC' (the state
      // `handle_new_user` leaves every account in until the device syncs its
      // zone) is still in the week of 2026-10-26 for another 13 hours.
      pin('Pacific/Auckland', DateTime.utc(2026, 11, 1, 12));
      expect(await remainingAgainst('2026-10-26'), 3,
          reason: 'the client is in a new week the server has not reached — '
              'this is the honest, non-adversarial source of the disagreement '
              'the group below exists to bound');
      pin('UTC', DateTime.utc(2026, 11, 1, 12));
      expect(await remainingAgainst('2026-10-26'), 0,
          reason: 'and the same instant read in UTC is still last week');
    });
  });

  // ===========================================================================
  // The stale-week optimism is a PROBE, not a standing permission.
  //
  // `weeklyPoolRemaining` reports a full pool whenever the cached `week_start`
  // predates the client's local Monday, so the call can reach the server and
  // let the server perform the reset only it can perform. The hazard is that
  // the marker the server writes back is the SERVER's week — so if the two
  // disagree about which week it is, the optimism never expires and the client
  // waves through call after call that the server declines every time.
  //
  // That disagreement is ordinary, not adversarial: `handle_new_user` inserts
  // `user_notification_preferences` with no timezone, and `safe_user_tz`
  // answers 'UTC' for a blank one. Until the device syncs its zone the server
  // computes the week in UTC while the client computes it in the device zone —
  // so for the first hours of a user east of UTC's local Monday, the client is
  // in the new week and the server is not. A wrong device clock produces the
  // same shape and does not expire at all.
  // ===========================================================================

  group('stale-week optimism is bounded', () {
    /// A server stuck in LAST week: it never resets and never allows.
    /// `week_start` comes back as the server's own week, which is what makes
    /// the client's marker permanently "stale" from its own point of view.
    void installBehindServer() {
      fakeSync.rpcHandlers['consume_weekly_allowance'] = (_) async =>
          {'allowed': false, 'remaining': 0, 'week_start': lastMonday};
    }

    test('a server whose week is BEHIND the client\'s cannot be milked', () async {
      await setCohort('reel_v1');
      await exhaustWarmup(GatedFeature.reflect);
      await gating.debugSetWeeklyPool(used: 3, weekStart: lastMonday);
      installBehindServer();

      var allowed = 0;
      for (var i = 0; i < 6; i++) {
        if ((await gating.canUse(GatedFeature.reflect)).allowed) {
          allowed += 1;
          await gating.markUsed(GatedFeature.reflect);
        }
      }

      expect(allowed, 1,
          reason: 'exactly one probe: the first call has to reach the server '
              'so a pending reset can happen, but once the server has ANSWERED '
              'for a week it has not rolled over, repeating the question just '
              'buys free AI calls the server already refused to pay for');
    });

    test('the probe is retried on the next local day, so a pending reset is '
        'never locked out', () async {
      await setCohort('reel_v1');
      await exhaustWarmup(GatedFeature.reflect);
      await gating.debugSetWeeklyPool(used: 3, weekStart: lastMonday);
      installBehindServer();

      expect((await gating.canUse(GatedFeature.reflect)).allowed, isTrue);
      await gating.markUsed(GatedFeature.reflect);
      expect((await gating.canUse(GatedFeature.reflect)).allowed, isFalse);

      // Next local day, same ISO week (Thu 2026-07-30 → Monday 2026-07-27).
      debugUserLocalDayClock = () => DateTime.utc(2026, 7, 30, 12);
      daily.debugDailyUsageClock = () => DateTime.utc(2026, 7, 30, 12);

      expect((await gating.canUse(GatedFeature.reflect)).allowed, isTrue,
          reason: 'the client cannot learn that the server has rolled over '
              'without asking, so the question must come back — bounded, not '
              'abandoned. Refusing forever is the permanent lockout the '
              'stale-week rule exists to prevent');
    });

    test('a count with no week alongside it also spends the probe', () async {
      await setCohort('reel_v1');
      await exhaustWarmup(GatedFeature.reflect);
      await gating.debugSetWeeklyPool(used: 3, weekStart: lastMonday);
      // Usable `remaining`, no `week_start`: the cached marker keeps its stale
      // value, so silence about the week cannot count as agreement that it
      // rolled over — that would reopen the loop through the malformed path.
      fakeSync.rpcHandlers['consume_weekly_allowance'] =
          (_) async => {'allowed': false, 'remaining': 0};

      expect((await gating.canUse(GatedFeature.reflect)).allowed, isTrue);
      await gating.markUsed(GatedFeature.reflect);
      expect((await gating.canUse(GatedFeature.reflect)).allowed, isFalse);
    });

    test('a server that DOES roll over clears the probe immediately', () async {
      await setCohort('reel_v1');
      await exhaustWarmup(GatedFeature.reflect);
      await gating.debugSetWeeklyPool(used: 3, weekStart: lastMonday);
      installPoolRpc(); // resets, and answers with thisMonday

      expect((await gating.canUse(GatedFeature.reflect)).allowed, isTrue);
      await gating.markUsed(GatedFeature.reflect);

      expect(await gating.weeklyPoolRemaining(), 2,
          reason: 'the honest Monday path is untouched: the server reset, and '
              'the user has the rest of their week');
      expect((await gating.canUse(GatedFeature.reflect)).allowed, isTrue);
    });
  });

  group('hydrateFromProfile mirrors the server pool state', () {
    test('used + week_start make the pool readable', () async {
      await setCohort('reel_v1');
      await gating.hydrateFromProfile({
        'weekly_pool_used': 2,
        'weekly_pool_week_start': thisMonday,
      });
      expect(await gating.weeklyPoolRemaining(), 1);
    });

    test('a null week_start clears the marker', () async {
      await gating.debugSetWeeklyPool(used: 3, weekStart: thisMonday);
      await gating.hydrateFromProfile({
        'weekly_pool_used': 3,
        'weekly_pool_week_start': null,
      });
      expect(await gating.weeklyPoolRemaining(), 3,
          reason: 'never consumed server-side means the pool is whole');
    });

    test('a timestamp-shaped week_start is tolerated', () async {
      await gating.hydrateFromProfile({
        'weekly_pool_used': 3,
        'weekly_pool_week_start': '$thisMonday' 'T00:00:00+00:00',
      });
      expect(await gating.weeklyPoolRemaining(), 0);
    });
  });

  // ===========================================================================
  // D.3 — discoverName: a genuine 1/day for reel_v1.
  // ===========================================================================

  group('canUse: discoverName', () {
    test('legacy past warmup still gets its metered re-roll', () async {
      await setCohort('legacy');
      await exhaustWarmup(GatedFeature.discoverName);

      final gate = await gating.canUse(GatedFeature.discoverName);
      expect(gate.allowed, isTrue,
          reason: 'today\'s effective 2/day is preserved until the softener '
              'wave — one free day-open plus one metered re-roll');
    });

    test('reel_v1 past warmup: the re-roll is PREMIUM', () async {
      await setCohort('reel_v1');
      await exhaustWarmup(GatedFeature.discoverName);

      final gate = await gating.canUse(GatedFeature.discoverName);
      expect(gate.allowed, isFalse);
      expect(gate.reason, GateReason.rerollPremium);
      expect(gate.remaining, 0);
    });

    test('reel_v1: no daily allowance exists to be waited out', () async {
      await setCohort('reel_v1');
      await exhaustWarmup(GatedFeature.discoverName);
      // A completely untouched daily counter — under the legacy rules this is
      // precisely the state in which a re-roll is ALLOWED.
      expect(await daily.getDiscoverNameUsageToday(), 0);
      expect((await gating.canUse(GatedFeature.discoverName)).allowed, isFalse,
          reason: '"1/day" means the free day-open reveal and nothing else; a '
              'zeroed daily counter must not re-open the re-roll');
    });

    test('reel_v1 keeps the lifetime warmup before the wall', () async {
      await setCohort('reel_v1');
      await gating.debugSetWarmupRemaining(GatedFeature.discoverName, 3);

      for (var i = 3; i > 0; i--) {
        final gate = await gating.canUse(GatedFeature.discoverName);
        expect(gate.allowed, isTrue, reason: 'warmup use ${4 - i}');
        expect(gate.reason, GateReason.warmupRemaining);
        await gating.markUsed(GatedFeature.discoverName);
      }

      final blocked = await gating.canUse(GatedFeature.discoverName);
      expect(blocked.allowed, isFalse);
      expect(blocked.reason, GateReason.rerollPremium,
          reason: 'a gate nobody has bumped into sells nothing — the wall '
              'lands after three re-rolls, not at minute one');
    });

    test('reel_v1 discoverName is EXEMPT from the weekly pool', () async {
      await setCohort('reel_v1');
      await exhaustWarmup(GatedFeature.discoverName);
      installPoolRpc();

      await gating.markUsed(GatedFeature.discoverName);

      expect(rpcCallsTo('consume_weekly_allowance'), isEmpty,
          reason: 'the RPC RAISEs on discover_name — it is never pooled — and '
              'pooling it would let a re-roll eat a Reflect');
      expect(await daily.getDiscoverNameUsageToday(), 1,
          reason: 'user_daily_usage.discover_name_uses is still the row the '
              'analytics and multi-device reconciliation read');
    });

    test('premium re-rolls freely on both cohorts', () async {
      fakePurchase.premium = true;
      for (final cohort in ['reel_v1', 'legacy']) {
        await setCohort(cohort);
        expect((await gating.canUse(GatedFeature.discoverName)).allowed, isTrue,
            reason: 'the wall is a free-tier mechanic ($cohort)');
      }
    });
  });

  group('daily_cap_hit still fires for the new cohort', () {
    test('the weekly-pool block emits it', () async {
      final events = <String>[];
      GatingService.onAnalyticsEvent = (e, _) => events.add(e);
      await setCohort('reel_v1');
      await exhaustWarmup(GatedFeature.reflect);
      await gating.debugSetWeeklyPool(used: 3, weekStart: thisMonday);

      await gating.canUse(GatedFeature.reflect);
      expect(events, contains('daily_cap_hit'),
          reason: 'this is the numerator of the cap-hit → upgrade funnel; '
              'renaming it for the pool would fork a live funnel');
    });

    test('the re-roll wall emits it', () async {
      final events = <String>[];
      GatingService.onAnalyticsEvent = (e, _) => events.add(e);
      await setCohort('reel_v1');
      await exhaustWarmup(GatedFeature.discoverName);

      await gating.canUse(GatedFeature.discoverName);
      expect(events, contains('daily_cap_hit'));
    });

    test('premium fair-use never emits it', () async {
      final events = <String>[];
      GatingService.onAnalyticsEvent = (e, _) => events.add(e);
      fakePurchase.premium = true;
      await setCohort('reel_v1');
      for (var i = 0; i < GatingService.premiumDailyFairUseCap; i++) {
        await daily.incrementReflectUsage();
      }

      final gate = await gating.canUse(GatedFeature.reflect);
      expect(gate.reason, GateReason.premiumFairUse);
      expect(events, isEmpty,
          reason: 'a silent "take a breath", never a paywall');
    });
  });

  // ===========================================================================
  // D.4 — the bypass does not exist for reel_v1.
  // ===========================================================================

  group('bypass removal (reel_v1)', () {
    setUp(() {
      fakeSync.rpcHandlers['reserve_ai_bypass'] = (_) async => {
            'ok': true,
            'reservation_id': 'res-1',
            'balance': 475,
            'bypasses_used': 1,
          };
      fakeSync.rpcHandlers['claim_first_bypass'] =
          (_) async => {'ok': true, 'bypasses_used': 1};
    });

    test('reserveBypass refuses and never reaches the RPC', () async {
      await setCohort('reel_v1');
      expect(await gating.reserveBypass(GatedFeature.reflect), isNull);
      expect(rpcCallsTo('reserve_ai_bypass'), isEmpty,
          reason: 'refusing after the debit would take the tokens anyway');
    });

    test('claimFirstBypass refuses and never burns the server latch', () async {
      await setCohort('reel_v1');
      expect(await gating.claimFirstBypass(GatedFeature.reflect), isFalse);
      expect(rpcCallsTo('claim_first_bypass'), isEmpty,
          reason: 'first_bypass_consumed is a one-way latch — spending it for '
              'a cohort that cannot use the result is unrecoverable');
    });

    test('firstBypassEligible is false even inside the 24h window', () async {
      await setCohort('reel_v1');
      await gating.hydrateFromProfile({
        'free_tier_cohort': 'reel_v1',
        'created_at': DateTime.utc(2026, 7, 29, 6).toIso8601String(),
        'first_bypass_consumed': false,
      });
      GatingService.debugNowUtc = () => DateTime.utc(2026, 7, 29, 12);
      addTearDown(() => GatingService.debugNowUtc = null);

      expect(await gating.firstBypassEligible(), isFalse,
          reason: 'STATE D would offer a door claimFirstBypass now refuses');
    });

    test('the IAP→sub banner trigger is retired', () async {
      await setCohort('reel_v1');
      await gating.hydrateFromProfile({
        'free_tier_cohort': 'reel_v1',
        'created_at': DateTime.utc(2026, 6, 1).toIso8601String(),
        'lifetime_bypasses_purchased': 20,
        'iap_upsell_banner_dismissed_at': null,
      });
      GatingService.debugNowUtc = () => DateTime.utc(2026, 7, 29, 12);
      addTearDown(() => GatingService.debugNowUtc = null);

      expect(await gating.iapToSubBannerEligible(), isFalse,
          reason: 'every other predicate passes; only the cohort stops it — '
              '"buy the sub instead of more bypasses" is incoherent to a '
              'cohort that cannot buy a bypass');
    });

    test('PREMIUM short-circuits reserveBypass ahead of the cohort read',
        () async {
      fakePurchase.premium = true;
      await setCohort('legacy');
      expect(await gating.reserveBypass(GatedFeature.reflect), isNull);
      expect(rpcCallsTo('reserve_ai_bypass'), isEmpty,
          reason: 'CLAUDE.md: premium must NEVER reach reserveBypass. The '
              'cohort check is additive and sits behind it, so a premium user '
              'on either cohort is refused before any token can move');

      fakePurchase.premium = true;
      await setCohort('reel_v1');
      expect(await gating.reserveBypass(GatedFeature.reflect), isNull);
      expect(rpcCallsTo('reserve_ai_bypass'), isEmpty);
    });
  });

  group('bypass survives untouched for legacy', () {
    setUp(() {
      fakeSync.rpcHandlers['reserve_ai_bypass'] = (_) async => {
            'ok': true,
            'reservation_id': 'res-1',
            'balance': 475,
            'bypasses_used': 1,
          };
      fakeSync.rpcHandlers['claim_first_bypass'] =
          (_) async => {'ok': true, 'bypasses_used': 1};
    });

    test('reserveBypass still works', () async {
      await setCohort('legacy');
      final res = await gating.reserveBypass(GatedFeature.reflect);
      expect(res, isNotNull);
      expect(res!.reservationId, 'res-1');
    });

    test('claimFirstBypass still works', () async {
      await setCohort('legacy');
      expect(await gating.claimFirstBypass(GatedFeature.reflect), isTrue);
    });

    test('firstBypassEligible still true inside the window', () async {
      await setCohort('legacy');
      await gating.hydrateFromProfile({
        'free_tier_cohort': 'legacy',
        'created_at': DateTime.utc(2026, 7, 29, 6).toIso8601String(),
        'first_bypass_consumed': false,
      });
      GatingService.debugNowUtc = () => DateTime.utc(2026, 7, 29, 12);
      addTearDown(() => GatingService.debugNowUtc = null);

      expect(await gating.firstBypassEligible(), isTrue);
    });

    test('the IAP→sub banner still triggers', () async {
      await setCohort('legacy');
      await gating.hydrateFromProfile({
        'free_tier_cohort': 'legacy',
        'created_at': DateTime.utc(2026, 6, 1).toIso8601String(),
        'lifetime_bypasses_purchased': 20,
        'iap_upsell_banner_dismissed_at': null,
      });
      GatingService.debugNowUtc = () => DateTime.utc(2026, 7, 29, 12);
      addTearDown(() => GatingService.debugNowUtc = null);

      expect(await gating.iapToSubBannerEligible(), isTrue);
    });

    test('an UNKNOWN cohort keeps the bypass — fail-to-false end to end',
        () async {
      // No cohort cached at all: the fresh-install / sync-failed case.
      expect(await gating.isNewCohort(), isFalse);
      expect(await gating.reserveBypass(GatedFeature.reflect), isNotNull,
          reason: 'the unknown-cohort account gets the generous tier whole, '
              'not a half-tightened hybrid');
    });
  });
}
