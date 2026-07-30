// W4 Wave 1 — `markUsed` moved off the CTA and into `discoverName()`.
//
// Why this suite exists: the daily reveal used to be consumed at the button
// press (`progress_screen`'s completed-state CTA and muhasabah's "Seek Another
// Name" both called `GatingService.markUsed` around the call). That is
// survivable while the tap leads straight to the reveal, and stops being
// survivable the moment a question sits between the two — a user who opens the
// prompt and backs out would have burned their one free reveal for the day.
//
// The contract these tests pin, in the order the plan (§3, §11) states it:
//
//   1. `canUse` alone consumes NOTHING — it stays at the CTA, so a capped user
//      is told before being asked to disclose anything, and asking costs nil.
//   2. A completed reveal consumes exactly once.
//   3. A reveal that FAILED consumes nothing (`state.error` is the same signal
//      the bypass wrapper reads to decide commit-versus-refund).
//   4. A double-tap consumes once.
//   5. Both bypass paths consume nothing locally — the bypass RPCs own the
//      daily counter server-side — and a bypass whose reveal fails is refunded.
//   6. The warmup 1 → 0 transition still surfaces `warmupJustExhausted`, now via
//      `DailyLoopState` rather than a return value handed to a widget.

import 'package:flutter_riverpod/flutter_riverpod.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  late FakeSupabaseSyncService fakeSync;
  late _FakePurchaseService fakePurchase;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    fakePurchase = _FakePurchaseService();
    PurchaseService.debugSetOverride(fakePurchase);
    await hydrateTokenCache(balance: 100, totalSpent: 0);
    debugResetUserLocalDay();
  });

  tearDown(() {
    debugResetUserLocalDay();
    SupabaseSyncService.debugReset();
    PurchaseService.debugClearOverride();
  });

  String warmupKey() => fakeSync.scopedKey('warmup_discoverName_remaining');

  /// Puts the user past warmup so the DAILY counter — the thing a user actually
  /// loses when a reveal is consumed for nothing — is what moves.
  Future<void> exhaustWarmup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(warmupKey(), 0);
  }

  Future<int> warmupRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(warmupKey()) ?? GatingService.warmupBudget[
        GatedFeature.discoverName]!;
  }

  Future<int> usageToday() => daily_usage.getDiscoverNameUsageToday();

  /// A notifier whose real `discoverName` body always fails at the unseal RPC —
  /// the reveal genuinely does not happen. Mirrors the failure injection in
  /// `discover_name_dispose_cancel_test.dart` REGRESSION 8.
  DailyLoopNotifier failingNotifier() => DailyLoopNotifier(
        nameQueueService: NameQueueService(
          currentUserId: () => fakeSync.userId,
          selectRows: (_) async => [
            {'position': 1, 'name_id': 11, 'unsealed_at': null},
            {'position': 2, 'name_id': 22, 'unsealed_at': null},
          ],
          callRpc: (_, __) async => throw StateError('unseal exploded'),
        ),
      );

  // -------------------------------------------------------------------------
  // 1. Asking the gate costs nothing.
  // -------------------------------------------------------------------------

  test('canUse alone consumes nothing — the gate may be asked repeatedly',
      () async {
    await exhaustWarmup();

    for (var i = 0; i < 3; i++) {
      final gate = await GatingService().canUse(GatedFeature.discoverName);
      expect(gate.allowed, isTrue,
          reason: 'the day\'s free reveal is still unspent on attempt $i');
    }

    expect(await usageToday(), 0,
        reason: 'this is the whole point of the wave: the CTA may gate, and '
            'gating must not charge. A user who opens the question and backs '
            'out has spent nothing.');
  });

  test('canUse does not touch the warmup budget either', () async {
    await GatingService().canUse(GatedFeature.discoverName);
    expect(await warmupRemaining(), 5,
        reason: 'warmup is decremented by markUsed, never by the gate check');
  });

  // -------------------------------------------------------------------------
  // 2 + 3. Consumed on success, exactly once; never on failure.
  // -------------------------------------------------------------------------

  test('a completed reveal consumes the daily allowance exactly once',
      () async {
    await exhaustWarmup();
    final notifier = DailyLoopNotifier();
    addTearDown(notifier.dispose);

    await notifier.discoverName();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(notifier.state.error, isNull);
    expect(notifier.state.checkinDone, isTrue);
    expect(await usageToday(), 1);

    final gate = await GatingService().canUse(GatedFeature.discoverName);
    expect(gate.allowed, isFalse,
        reason: 'the reveal was delivered, so the next one meets the cap');
    expect(gate.reason, GateReason.dailyCap);
  });

  test('a reveal that fails consumes nothing', () async {
    await exhaustWarmup();
    final notifier = failingNotifier();
    addTearDown(notifier.dispose);
    // Let _initialize land first — copyWith clears `error`, so a late-resolving
    // init would wipe the error this test depends on.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await notifier.discoverName();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(notifier.state.error, isNotNull,
        reason: 'the unseal threw — the reveal did not happen');
    expect(notifier.state.engagedCard, isNull);
    expect(await usageToday(), 0,
        reason: 'a failed reveal must not cost the day\'s allowance — the '
            'retry would otherwise meet the cap sheet and cost 25 tokens');

    final gate = await GatingService().canUse(GatedFeature.discoverName);
    expect(gate.allowed, isTrue, reason: 'the user may still retry today');
  });

  test('a failed reveal does not burn warmup either', () async {
    final notifier = failingNotifier();
    addTearDown(notifier.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await notifier.discoverName();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(notifier.state.error, isNotNull);
    expect(await warmupRemaining(), 5);
  });

  // -------------------------------------------------------------------------
  // 4. Double-tap.
  // -------------------------------------------------------------------------

  test('two concurrent discoverName calls consume once', () async {
    await exhaustWarmup();
    final notifier = DailyLoopNotifier();
    addTearDown(notifier.dispose);

    // The two CTAs each hold a synchronous `_discoverInFlight` guard, but with
    // the charge living in the provider the provider has to be safe on its own:
    // `checkinLoading` is set before the first await, so the second call returns
    // without reaching the reveal — or the charge.
    final first = notifier.discoverName();
    final second = notifier.discoverName();
    await Future.wait([first, second]);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(notifier.state.checkinDone, isTrue);
    expect(await usageToday(), 1,
        reason: 'a double-tap is one reveal, so it is one charge');
  });

  // -------------------------------------------------------------------------
  // 5. The bypass paths.
  // -------------------------------------------------------------------------

  ProviderContainer bypassContainer(DailyLoopNotifier Function() build) {
    return ProviderContainer(overrides: [
      dailyLoopProvider.overrideWith((ref) => build()),
    ]);
  }

  test('a bypass-funded reveal does NOT mark used locally', () async {
    // The user is already capped — that is why they were offered a bypass at
    // all. `reserve_ai_bypass` increments the daily-uses row server-side, so a
    // client-side markUsed here would double-count the same reveal. Same
    // contract as `submitBuildWithBypass` / `submitWithBypass`.
    await exhaustWarmup();
    await daily_usage.incrementDiscoverNameUsage();

    fakeSync.rpcHandlers['reserve_ai_bypass'] = (_) async => {
          'ok': true,
          'reservation_id': 'r-1',
          'balance': 75,
          'bypasses_used': 1,
        };
    final committedIds = <String>[];
    fakeSync.rpcHandlers['commit_ai_bypass'] = (params) async {
      committedIds.add(params!['p_reservation_id'] as String);
      return {'ok': true};
    };

    final container = bypassContainer(DailyLoopNotifier.new);
    addTearDown(container.dispose);
    final notifier = container.read(dailyLoopProvider.notifier);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await notifier.discoverNameWithBypass();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(notifier.state.checkinDone, isTrue, reason: 'the reveal happened');
    expect(committedIds, ['r-1']);
    expect(await usageToday(), 1,
        reason: 'still just the one pre-existing use — the bypass owns its own '
            'increment server-side');
  });

  test('a bypass-funded reveal that fails is refunded and consumes nothing',
      () async {
    await exhaustWarmup();
    fakeSync.rpcHandlers['reserve_ai_bypass'] = (_) async => {
          'ok': true,
          'reservation_id': 'r-refund',
          'balance': 75,
          'bypasses_used': 1,
        };
    final committedIds = <String>[];
    final cancelledIds = <String>[];
    fakeSync.rpcHandlers['commit_ai_bypass'] = (params) async {
      committedIds.add(params!['p_reservation_id'] as String);
      return {'ok': true};
    };
    fakeSync.rpcHandlers['cancel_ai_bypass'] = (params) async {
      cancelledIds.add(params!['p_reservation_id'] as String);
      return {'ok': true, 'refunded_tokens': 25, 'balance': 100};
    };

    final container = bypassContainer(failingNotifier);
    addTearDown(container.dispose);
    final notifier = container.read(dailyLoopProvider.notifier);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await notifier.discoverNameWithBypass();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(cancelledIds, ['r-refund'],
        reason: 'the reveal failed — the 25 tokens come back. Moving markUsed '
            'into the same method that writes state.error must not disturb '
            'this: the charge is in its own try/catch at the tail, so it can '
            'neither set nor clear the signal the wrapper reads.');
    expect(committedIds, isEmpty);
    expect(await usageToday(), 0);
  });

  test('the day-1 freebie path does not mark used either', () async {
    await exhaustWarmup();
    await daily_usage.incrementDiscoverNameUsage();
    fakeSync.rpcHandlers['claim_first_bypass'] =
        (_) async => {'ok': true, 'bypasses_used': 1};

    final container = bypassContainer(DailyLoopNotifier.new);
    addTearDown(container.dispose);
    final notifier = container.read(dailyLoopProvider.notifier);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await notifier.discoverNameWithFirstBypass();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(notifier.state.checkinDone, isTrue);
    expect(await usageToday(), 1,
        reason: 'the freebie claim is atomic server-side and owns the count');
  });

  // -------------------------------------------------------------------------
  // 6. Warmup.
  // -------------------------------------------------------------------------

  test('a warmup reveal decrements warmup and leaves the daily counter alone',
      () async {
    final notifier = DailyLoopNotifier();
    addTearDown(notifier.dispose);

    await notifier.discoverName();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(await warmupRemaining(), 4);
    expect(await usageToday(), 0,
        reason: 'warmup and the daily cap are never both touched');
    expect(notifier.state.warmupJustExhausted, isNull,
        reason: 'only the 1 → 0 transition raises the signal');
  });

  test('the warmup 1 → 0 reveal still surfaces warmupJustExhausted', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(warmupKey(), 1);

    final notifier = DailyLoopNotifier();
    addTearDown(notifier.dispose);

    await notifier.discoverName();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(notifier.state.warmupJustExhausted, GatedFeature.discoverName,
        reason: 'the sheet is fired off this flag now that no widget is left '
            'awaiting markUsed\'s return value');
    expect(await warmupRemaining(), 0);
    expect(await usageToday(), 1,
        reason: 'GatingService books the exhausting call against the day too, '
            'so the user does not get N+1 free uses');

    notifier.dismissWarmupExhausted();
    expect(notifier.state.warmupJustExhausted, isNull,
        reason: 'one-shot: the sheet must not re-fire on the next rebuild');
    expect(notifier.state.checkinDone, isTrue,
        reason: 'clearing the signal must not disturb the rest of the state');
  });

  test('a reveal that fails never raises warmupJustExhausted', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(warmupKey(), 1);

    final notifier = failingNotifier();
    addTearDown(notifier.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await notifier.discoverName();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(notifier.state.warmupJustExhausted, isNull);
    expect(await warmupRemaining(), 1);
  });
}
