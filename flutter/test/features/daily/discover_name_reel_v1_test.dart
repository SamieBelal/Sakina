// One Ship W5 — Wave D.3: `discoverName` becomes a genuine 1/day for `reel_v1`.
//
// D10②: the day-open reveal is ONE PER DAY, FREE, and PERMANENTLY UNGATED. A
// second Name the same day is premium, after a lifetime warmup of three
// re-rolls. `reel_v1` only — legacy keeps today's effective 2/day until the
// softener wave.
//
// THE PROPERTY THIS FILE EXISTS FOR, stated plainly because it is a safety
// property and not an economic one: the day-open reveal is the surface where
// the user is asked what is on their heart. That surface must never be able to
// answer a disclosure with a cap sheet. It cannot, because it consults NO GATE
// AT ALL — `discoverName` reads the free-reveal marker in `daily_usage_service`
// and, on the day's first reveal, returns without ever calling `GatingService`.
//
// The tightening in this wave makes that guarantee load-bearing in a way it was
// not before. Under legacy rules a day-open reveal that DID consult the gate
// would usually have been allowed anyway (the daily allowance was still there),
// so the bug would have been invisible. Under `reel_v1` the gate says NO to
// every re-roll past warmup — so the same bug now shows the paywall to someone
// who has just opened the app to say they are struggling. Hence
// `_GateSpy`: these tests assert the gate was never ASKED, not merely that the
// answer came back yes.

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/services/daily_usage_service.dart' as daily_usage;
import 'package:sakina/services/gating_service.dart';
import 'package:sakina/services/name_queue_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../support/fake_supabase_sync_service.dart';

class _FakePurchaseService extends PurchaseService {
  _FakePurchaseService() : super.test();
  bool premium = false;
  @override
  Future<bool> isPremium() async => premium;
}

/// A real `GatingService` that records every gate question put to it.
///
/// Not a stub: `canUse` / `markUsed` run the production bodies, so the counters
/// below say "the gate was consulted", never "the gate would have said X".
class _GateSpy extends GatingService {
  _GateSpy() : super.test();

  int canUseCalls = 0;
  int markUsedCalls = 0;

  @override
  Future<GateResult> canUse(GatedFeature feature, {bool? isPremiumHint}) {
    canUseCalls++;
    return super.canUse(feature, isPremiumHint: isPremiumHint);
  }

  @override
  Future<UsageOutcome> markUsed(GatedFeature feature, {bool? isPremiumHint}) {
    markUsedCalls++;
    return super.markUsed(feature, isPremiumHint: isPremiumHint);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  late FakeSupabaseSyncService fakeSync;
  late _FakePurchaseService fakePurchase;
  late _GateSpy gate;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    fakePurchase = _FakePurchaseService();
    PurchaseService.debugSetOverride(fakePurchase);
    gate = _GateSpy();
    GatingService.debugSetOverride(gate);
    await hydrateTokenCache(balance: 100, totalSpent: 0);
    debugResetUserLocalDay();
    debugUserTimeZoneOverride = 'UTC';
    await gate.debugSetCohort('reel_v1');
  });

  tearDown(() {
    debugResetUserLocalDay();
    GatingService.debugClearOverride();
    SupabaseSyncService.debugReset();
    PurchaseService.debugClearOverride();
  });

  String warmupKey() => fakeSync.scopedKey('warmup_discoverName_remaining');

  Future<void> setWarmup(int n) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(warmupKey(), n);
  }

  Future<int> warmupRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(warmupKey()) ?? -1;
  }

  Future<int> usageToday() => daily_usage.getDiscoverNameUsageToday();

  /// Spends the day's free reveal so the NEXT one is a metered re-roll.
  Future<void> takeFreeDailyReveal() => daily_usage.markFreeDailyRevealTaken();

  // -------------------------------------------------------------------------
  // The day-open reveal consults no gate.
  // -------------------------------------------------------------------------

  test('the day-open reveal happens WITHOUT the gate ever being asked',
      () async {
    await setWarmup(0);

    // Establish that the gate, if asked, would refuse — so a passing reveal
    // below cannot be explained by a permissive gate.
    final wouldRefuse = await gate.canUse(GatedFeature.discoverName);
    expect(wouldRefuse.allowed, isFalse);
    expect(wouldRefuse.reason, GateReason.rerollPremium);
    final baselineCanUse = gate.canUseCalls;
    final baselineMarkUsed = gate.markUsedCalls;

    final notifier = DailyLoopNotifier();
    addTearDown(notifier.dispose);
    await notifier.discoverName();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(notifier.state.checkinDone, isTrue,
        reason: 'the reveal happened even though the gate would have said no');
    expect(gate.canUseCalls, baselineCanUse,
        reason: 'the day-open reveal must not ASK. A gate that is asked and '
            'happens to answer yes is one refactor away from answering no on '
            'the screen where someone has just disclosed how they feel');
    expect(gate.markUsedCalls, baselineMarkUsed,
        reason: 'and it must not CHARGE');
    expect(await usageToday(), 0);
    expect(await warmupRemaining(), 0, reason: 'warmup untouched');
    expect(await daily_usage.hasTakenFreeDailyRevealToday(), isTrue,
        reason: 'but the free reveal IS spent — the next one is a re-roll');
  });

  test('the day-open reveal does not spend the warmup either', () async {
    await setWarmup(3);
    final notifier = DailyLoopNotifier();
    addTearDown(notifier.dispose);

    await notifier.discoverName();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(gate.markUsedCalls, 0);
    expect(await warmupRemaining(), 3,
        reason: 'three re-rolls means three RE-ROLLS; burning one on the free '
            'day-open would make the lifetime budget two');
  });

  test('the free reveal returns tomorrow, so the wall is 1/day not 1/ever',
      () async {
    await setWarmup(0);
    await takeFreeDailyReveal();
    expect(await daily_usage.hasTakenFreeDailyRevealToday(), isTrue);
    expect((await gate.canUse(GatedFeature.discoverName)).allowed, isFalse);

    daily_usage.debugDailyUsageClock = () => DateTime.utc(2099, 1, 2, 12);
    addTearDown(() => daily_usage.debugDailyUsageClock = null);

    expect(await daily_usage.hasTakenFreeDailyRevealToday(), isFalse,
        reason: 'the free reveal is what makes the tightened tier survivable; '
            'it has to come back every day');
  });

  // -------------------------------------------------------------------------
  // The re-roll: three warmups, then the wall.
  // -------------------------------------------------------------------------

  test('a re-roll spends warmup, and the wall lands after three', () async {
    await setWarmup(3);
    await takeFreeDailyReveal();
    final notifier = DailyLoopNotifier();
    addTearDown(notifier.dispose);

    for (var i = 0; i < 3; i++) {
      expect((await gate.canUse(GatedFeature.discoverName)).allowed, isTrue,
          reason: 're-roll ${i + 1} is inside the warmup');
      await notifier.resetToday();
      await notifier.discoverName();
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }

    expect(await warmupRemaining(), 0);
    final blocked = await gate.canUse(GatedFeature.discoverName);
    expect(blocked.allowed, isFalse);
    expect(blocked.reason, GateReason.rerollPremium);
  });

  test('a double-tapped re-roll decrements warmup EXACTLY once', () async {
    await setWarmup(3);
    await takeFreeDailyReveal();
    final notifier = DailyLoopNotifier();
    addTearDown(notifier.dispose);

    // Both CTAs hold a synchronous in-flight guard of their own, but with the
    // charge living in the provider the provider has to be safe alone:
    // `checkinLoading` is set before the first await, so the second call
    // returns without reaching the reveal — or the charge.
    final first = notifier.discoverName();
    final second = notifier.discoverName();
    await Future.wait([first, second]);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(notifier.state.checkinDone, isTrue);
    expect(gate.markUsedCalls, 1,
        reason: 'a double-tap is one reveal, so it is one charge');
    expect(await warmupRemaining(), 2,
        reason: 'two decrements would hand the wall to the user a re-roll '
            'early, and the warmup is a LIFETIME budget — there is no next '
            'day that gives it back');
  });

  test('a FAILED re-roll spends no warmup', () async {
    await setWarmup(3);
    await takeFreeDailyReveal();
    // The reveal genuinely does not happen — the unseal RPC explodes. Mirrors
    // the failure injection in `discover_name_mark_used_test.dart`.
    final notifier = DailyLoopNotifier(
      nameQueueService: NameQueueService(
        currentUserId: () => fakeSync.userId,
        selectRows: (_) async => [
          {'position': 1, 'name_id': 11, 'unsealed_at': null},
          {'position': 2, 'name_id': 22, 'unsealed_at': null},
        ],
        callRpc: (_, __) async => throw StateError('unseal exploded'),
      ),
    );
    addTearDown(notifier.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await notifier.discoverName();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(notifier.state.error, isNotNull);
    expect(await warmupRemaining(), 3,
        reason: 'a lifetime budget spent on a reveal that did not happen is '
            'never given back');
  });

  // -------------------------------------------------------------------------
  // Legacy is untouched by all of the above.
  // -------------------------------------------------------------------------

  test('legacy: the day-open reveal still asks nothing, and the re-roll is '
      'still allowed', () async {
    await gate.debugSetCohort('legacy');
    await setWarmup(0);

    final notifier = DailyLoopNotifier();
    addTearDown(notifier.dispose);
    await notifier.discoverName();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(gate.canUseCalls, 0);
    expect(await usageToday(), 0);
    expect((await gate.canUse(GatedFeature.discoverName)).allowed, isTrue,
        reason: 'today\'s effective 2/day survives until the softener wave');
  });
}
