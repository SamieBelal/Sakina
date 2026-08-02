// Defect 1 (P1) — a killed/interrupted `claim_daily_reward` must be
// recoverable, not silently dropped.
//
// `submitDailyAnswer` fires `_claimDailyRewardAtSubmit()` WITHOUT awaiting it
// (`dailyRewardClaimFuture = _claimDailyRewardAtSubmit(); await
// discoverName();`) so the reveal never waits on a Supabase round trip. That
// is correct — but it also means a process kill (or a dropped connection)
// between the write and the RPC's response left NOTHING behind: the reveal
// survives (persisted, self-heals via the planner), but that day's
// `claim_daily_reward` never fired server-side. `claim_daily_reward` resets
// to day 0 on a single missed claim, so the next real claim could silently
// drop the user's 7-day escalation with no visible cause.
//
// The fix mirrors `recordPendingQueueSeed` / `retryPendingQueueSeed`
// (`name_queue_repair.dart`) — this codebase's established pattern for "a
// write started, we don't know if it landed, remember it and retry at next
// launch" — rather than inventing a second convention:
//
//   1. `_markRewardClaimPending()` writes a scoped marker BEFORE the RPC call
//      (not from a catch — a kill during the await never reaches a catch).
//   2. On success the marker clears.
//   3. On failure (or a kill that never even reaches the catch) it stays,
//      and the next `DailyLoopNotifier` — the next app open — retries it
//      exactly once via `_retryPendingRewardClaimIfAny()`, surfaced for
//      tests as `pendingRewardClaimRetryFuture`.
//
// Harness mirrors `daily_answer_submit_test.dart`'s reward-claim section
// exactly (same fake RPC registration, same `settle()` helper).

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../support/fake_supabase_sync_service.dart';

class _FreeUser extends PurchaseService {
  _FreeUser() : super.test();
  @override
  Future<bool> isPremium() async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  final nowUtc = DateTime.utc(2026, 8, 4, 3, 0);

  late FakeSupabaseSyncService fakeSync;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    PurchaseService.debugSetOverride(_FreeUser());
    await hydrateTokenCache(balance: 100, totalSpent: 0);
    debugResetUserLocalDay();
    debugUserTimeZoneOverride = 'UTC';
    debugDailyLoopClock = () => nowUtc;
  });

  tearDown(() {
    debugDailyLoopClock = () => DateTime.now().toUtc();
    debugResetUserLocalDay();
    DailyLoopNotifier.onAnalyticsEvent = null;
    SupabaseSyncService.debugReset();
    PurchaseService.debugClearOverride();
  });

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  int claimCalls() =>
      fakeSync.rpcCalls.where((c) => c['fn'] == 'claim_daily_reward').length;

  // ---------------------------------------------------------------------------
  // 1. A successful claim leaves no marker.
  // ---------------------------------------------------------------------------

  test('a successful claim leaves no pending marker', () async {
    fakeSync.rpcHandlers['claim_daily_reward'] = (_) async => {
          'current_day': 3,
          'last_claim_date': '2026-08-04',
          'token_balance': 115,
        };

    final notifier = DailyLoopNotifier();
    addTearDown(notifier.dispose);
    await settle();

    await notifier.submitDailyAnswer('feeling far from Allah');
    await notifier.dailyRewardClaimFuture;
    await settle();

    expect(claimCalls(), 1);
    expect(await notifier.debugHasPendingRewardClaim(), isFalse,
        reason: 'the claim landed and confirmed, so nothing is left to '
            'recover');
  });

  // ---------------------------------------------------------------------------
  // 2. A claim that never lands (process kill mid-RPC) leaves a marker that
  //    the NEXT app open retries.
  // ---------------------------------------------------------------------------

  test(
      'a claim interrupted mid-flight leaves a marker a later launch retries',
      () async {
    // The RPC never resolves — standing in for the process being killed
    // while the request is in flight. `_claimDailyRewardAtSubmit`'s await
    // never returns, so its `catch` never runs either; only a marker written
    // BEFORE the call can survive this.
    fakeSync.rpcHandlers['claim_daily_reward'] =
        (_) => Completer<Map<String, dynamic>>().future;

    final first = DailyLoopNotifier();
    addTearDown(first.dispose);
    await settle();

    await first.submitDailyAnswer('I keep sinning and going back');
    // Deliberately NOT awaiting `dailyRewardClaimFuture` — it never
    // completes, standing in for the app dying right here.
    await settle();

    expect(await first.debugHasPendingRewardClaim(), isTrue,
        reason: 'the marker must be written BEFORE the RPC call, or a kill '
            'during the await would leave nothing to recover from');

    // MUTATION THAT MUST FAIL THIS TEST: move `_markRewardClaimPending()`
    // to run only inside the `catch` block (or after `await
    // claimDailyReward()`) instead of before it — the marker would then
    // never be written for a hang like this one, and the assertion above
    // would see `false`.

    // The process "restarts": a fresh notifier, same user, same prefs.
    fakeSync.rpcHandlers['claim_daily_reward'] = (_) async => {
          'current_day': 4,
          'last_claim_date': '2026-08-04',
          'token_balance': 130,
        };
    final restored = DailyLoopNotifier();
    addTearDown(restored.dispose);
    await restored.pendingRewardClaimRetryFuture;
    await settle();

    expect(claimCalls(), 2,
        reason: 'one call from the interrupted submit, one from the retry '
            'at the next app open');
    expect(await restored.debugHasPendingRewardClaim(), isFalse,
        reason: 'the retry landed and confirmed, so the marker clears');
    expect(restored.state.rewardClaimResult?.day, 4,
        reason: 'the recovered claim result reaches state, same as the '
            'submit-time path');
  });

  // ---------------------------------------------------------------------------
  // 3. A claim that fails outright (not a hang) also leaves a marker, and it
  //    is retried exactly once per app open.
  // ---------------------------------------------------------------------------

  test('a claim that throws leaves the marker for exactly one retry per open',
      () async {
    fakeSync.rpcHandlers['claim_daily_reward'] =
        (_) async => throw StateError('rewards are down');

    final first = DailyLoopNotifier();
    addTearDown(first.dispose);
    await settle();

    await first.submitDailyAnswer('everything feels heavy');
    await first.dailyRewardClaimFuture;
    await settle();

    expect(claimCalls(), 1);
    expect(await first.debugHasPendingRewardClaim(), isTrue,
        reason: 'a thrown claim is exactly as unconfirmed as a hung one');

    // Still down on the next open — MUTATION THAT MUST FAIL THIS TEST: make
    // `_retryPendingRewardClaimIfAny` attempt the RPC more than once per
    // `_initialize` (e.g. a `for (attempt in 0..2)` around the call instead
    // of a single try) — `claimCalls()` would then read higher than 2 even
    // though the server never recovered.
    final restored = DailyLoopNotifier();
    addTearDown(restored.dispose);
    await restored.pendingRewardClaimRetryFuture;
    await settle();

    expect(claimCalls(), 2,
        reason: 'exactly one retry attempt for this app open, not a loop '
            'against a server that is still down');
    expect(await restored.debugHasPendingRewardClaim(), isTrue,
        reason: 'still unconfirmed — stays pending for the NEXT open');

    // Recovers on the third attempt (next open after that).
    fakeSync.rpcHandlers['claim_daily_reward'] = (_) async => {
          'current_day': 1,
          'last_claim_date': '2026-08-04',
        };
    final third = DailyLoopNotifier();
    addTearDown(third.dispose);
    await third.pendingRewardClaimRetryFuture;
    await settle();

    expect(claimCalls(), 3);
    expect(await third.debugHasPendingRewardClaim(), isFalse);
  });

  // ---------------------------------------------------------------------------
  // 4. The reveal is never blocked by any of this.
  // ---------------------------------------------------------------------------

  test('the reveal never waits on the claim, marker or no marker', () async {
    // Hangs forever, same as test 2 — if `submitDailyAnswer` awaited the
    // claim (directly or via the marker write), this test would time out
    // instead of completing.
    fakeSync.rpcHandlers['claim_daily_reward'] =
        (_) => Completer<Map<String, dynamic>>().future;

    final notifier = DailyLoopNotifier();
    addTearDown(notifier.dispose);
    await settle();

    await notifier.submitDailyAnswer('my mind will not stop racing');

    expect(notifier.state.checkinDone, isTrue,
        reason: 'the card is revealed the moment `submitDailyAnswer` '
            'returns, regardless of whether the claim (or its marker write) '
            'has settled');
    expect(notifier.state.engagedCard, isNotNull);
  });
}
