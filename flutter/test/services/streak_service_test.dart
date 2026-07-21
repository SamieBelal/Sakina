import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/daily_rewards_service.dart';
import 'package:sakina/services/streak_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
  });

  tearDown(SupabaseSyncService.debugReset);

  test('getStreak is a pure read and does not consume freeze', () async {
    SharedPreferences.setMockInitialValues({
      'sakina_current_streak': 5,
      'sakina_longest_streak': 7,
      'sakina_last_active': '2026-04-01',
      'sakina_daily_rewards': jsonEncode({
        'currentDay': 4,
        'lastClaimDate': '2026-04-09',
        'streakFreezeOwned': true,
      }),
    });
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);

    final state = await getStreak();

    expect(state.currentStreak, 5);
    expect((await getDailyRewards()).streakFreezeOwned, isTrue);
    expect(fakeSync.upsertCalls, isEmpty);
  });

  test('markActiveToday resets after a gap without freeze', () async {
    fakeSync.rows['user_streaks:user-1'] = {
      'current_streak': 5,
      'longest_streak': 10,
      'last_active': '2026-04-01',
    };
    fakeSync.rows['user_daily_rewards:user-1'] = {'streak_freeze_owned': false};

    final result = await markActiveToday();

    expect(result.currentStreak, 1);
    expect(result.longestStreak, 10);
    expect(fakeSync.rows['user_streaks:user-1']?['current_streak'], 1);
  });

  test('markActiveToday continues after a gap when freeze exists', () async {
    fakeSync.rows['user_streaks:user-1'] = {
      'current_streak': 5,
      'longest_streak': 10,
      'last_active': '2026-04-01',
    };
    // consumeStreakFreeze now uses the consume_streak_freeze RPC
    fakeSync.rpcHandlers['consume_streak_freeze'] = (_) async => true;

    final result = await markActiveToday();

    expect(result.currentStreak, 6);
  });

  test('markActiveToday is a no-op when already active today', () async {
    final today = DateTime.now().toUtc();
    final todayString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    fakeSync.rows['user_streaks:user-1'] = {
      'current_streak': 3,
      'longest_streak': 4,
      'last_active': todayString,
    };

    final result = await markActiveToday();

    expect(result.todayActive, isTrue);
    expect(result.currentStreak, 3);
    expect(fakeSync.upsertCalls, isEmpty);
  });

  test('logActivity is idempotent locally and on the server within a day',
      () async {
    await logActivity();
    await logActivity();

    final activity = await getActivityLog();
    expect(activity.length, 1, reason: 'local log dedupes by date');

    // Server must be written via an upsert with the composite-unique
    // onConflict — otherwise a second same-day write hits 23505 in prod.
    expect(
      fakeSync.insertCalls.where((c) => c['table'] == 'user_activity_log'),
      isEmpty,
      reason:
          'plain insertRow on user_activity_log violates the (user_id, active_date) '
          'unique constraint on the second same-day write',
    );
    final activityUpserts = fakeSync.upsertCalls
        .where((c) => c['table'] == 'user_activity_log')
        .toList();
    expect(
      activityUpserts.length,
      1,
      reason:
          'when the local cache shows today is already logged, no server write '
          'should fire on subsequent calls',
    );
    expect(activityUpserts.single['onConflict'], 'user_id,active_date');
  });

  test(
      'logActivity does not 23505 when server already has today (fresh device, '
      'stale cache)', () async {
    // Simulate a device where local prefs are empty but the server already
    // has today's row (e.g. user signed in on a new device after logging
    // activity elsewhere, or local prefs were cleared).
    final today = DateTime.now().toUtc();
    final todayString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    fakeSync.rowLists['user_activity_log'] = [
      {
        'id': 'preexisting',
        'user_id': 'user-1',
        'active_date': todayString,
      },
    ];

    await logActivity();

    // The single row remains; the upsert resolved by conflict, no duplicate.
    expect(fakeSync.rowLists['user_activity_log']!.length, 1);
    expect(
      fakeSync.insertCalls.where((c) => c['table'] == 'user_activity_log'),
      isEmpty,
    );
  });

  test(
      '§12 case 4: broken-streak reset preserves longest_streak in the '
      'user_streaks upsert payload (regression for "current resets to 1, '
      'longest preserved")', () async {
    // Pre-state: 10-day streak that's been the longest, broken 3 days ago.
    fakeSync.rows['user_streaks:user-1'] = {
      'current_streak': 10,
      'longest_streak': 10,
      'last_active': '2026-04-01',
    };
    fakeSync.rpcHandlers['consume_streak_freeze'] = (_) async => false;

    final today = DateTime.now().toUtc();
    final todayString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final result = await markActiveToday();

    // Returned state matches the contract.
    expect(result.currentStreak, 1);
    expect(result.longestStreak, 10);
    expect(result.lastActive, todayString);

    // Server upsert payload must preserve longest_streak. A future change
    // that drops longest_streak from the payload would silently truncate
    // the user's all-time record on every reset.
    final streakUpsert =
        fakeSync.upsertCalls.firstWhere((c) => c['table'] == 'user_streaks');
    final data = streakUpsert['data'] as Map<String, dynamic>;
    expect(data['current_streak'], 1);
    expect(data['longest_streak'], 10,
        reason:
            'longest_streak must be written through unchanged on reset — '
            'the user has earned it and a reset must never erase it');
    expect(data['last_active'], todayString);
  });

  // ---------------------------------------------------------------------------
  // §12 streak milestone coverage. testing-plan.md §10 line 232 lists "Streak
  // milestones trigger at correct thresholds" as in-scope; without these tests
  // a future change that drops a milestone, double-grants, or breaks the
  // scoped-prefs persistence would land silently.
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // Phase 2 — soft-decay repair ladder (§2b). Runs in server mode (fakeSync).
  // ---------------------------------------------------------------------------
  String _utcDay(int deltaDays) {
    final d = DateTime.now().toUtc().add(Duration(days: deltaDays));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  group('soft-decay ladder', () {
    test(
        'free effort-repair: one missed day, return within 48h → streak '
        'CONTINUES (no reset, no freeze), no pre-lapse', () async {
      fakeSync.rows['user_streaks:user-1'] = {
        'current_streak': 10,
        'longest_streak': 10,
        'last_active': _utcDay(-2), // missed only yesterday
      };
      fakeSync.rpcHandlers['consume_streak_freeze'] = (_) async => false;

      final result = await markActiveToday();

      expect(result.currentStreak, 11,
          reason: 'a return within the 48h window is forgiven for free');
      expect(result.preLapseStreak, 0, reason: 'no expiry → nothing to buy back');
    });

    test(
        'expired: return past 48h with no freeze → current resets to 1, '
        'pre_lapse saved for buy-back, longest preserved', () async {
      fakeSync.rows['user_streaks:user-1'] = {
        'current_streak': 20,
        'longest_streak': 20,
        'last_active': _utcDay(-4), // missed 3 days → past window
      };
      fakeSync.rpcHandlers['consume_streak_freeze'] = (_) async => false;

      final result = await markActiveToday();

      expect(result.currentStreak, 1);
      expect(result.longestStreak, 20, reason: 'longest never decreases');
      expect(result.preLapseStreak, 20, reason: 'the lost streak is restorable');
      expect(result.lapsedAt, isNotNull);
      expect(result.hasRestorableLapse, isTrue);
      // Persisted for the buy-back RPC.
      final data = fakeSync.upsertCalls
          .firstWhere((c) => c['table'] == 'user_streaks')['data'] as Map;
      expect(data['pre_lapse_streak'], 20);
      expect(data['lapsed_at'], isNotNull);
    });

    test('an excused missed day bridges the gap → streak continues', () async {
      fakeSync.rows['user_streaks:user-1'] = {
        'current_streak': 8,
        'longest_streak': 8,
        'last_active': _utcDay(-2),
      };
      fakeSync.rpcHandlers['add_excused_date'] =
          (_) async => {'ok': true, 'count_in_window': 1};

      // Excuse yesterday (the only missed day).
      final ok = await addExcusedDate(
          DateTime.now().toUtc().subtract(const Duration(days: 1)));
      expect(ok, isTrue);

      final result = await markActiveToday();
      expect(result.currentStreak, 9,
          reason: 'the only gap day was excused → treated as continuous');
      expect(result.preLapseStreak, 0);
    });
  });

  test(
      'clearLapseCache zeroes the persisted pre-lapse so a dismissed rescue '
      'does not re-surface (getStreak reports no restorable lapse)', () async {
    // An expired streak leaves a restorable pre-lapse in the cache.
    fakeSync.rows['user_streaks:user-1'] = {
      'current_streak': 20,
      'longest_streak': 20,
      'last_active': _utcDay(-4),
    };
    fakeSync.rpcHandlers['consume_streak_freeze'] = (_) async => false;

    final expired = await markActiveToday();
    expect(expired.hasRestorableLapse, isTrue,
        reason: 'precondition: the expiry left a buy-back-worthy pre-lapse');

    // Dismissing the rescue ("Start fresh") must clear the persisted lapse so
    // a same-day re-entry into muḥāsabah cannot re-offer it.
    await clearLapseCache();

    final after = await getStreak();
    expect(after.preLapseStreak, 0);
    expect(after.hasRestorableLapse, isFalse);
  });

  group('StreakState.repairCostTokens (server-priced mirror)', () {
    StreakState s(int pre) => StreakState(
        currentStreak: 1,
        longestStreak: pre,
        lastActive: '2026-01-01',
        todayActive: true,
        preLapseStreak: pre);
    test('< 7 → not offered (null)', () => expect(s(5).repairCostTokens, isNull));
    test('7–29 → 100', () {
      expect(s(7).repairCostTokens, 100);
      expect(s(29).repairCostTokens, 100);
    });
    test('30–89 → 250', () {
      expect(s(30).repairCostTokens, 250);
      expect(s(89).repairCostTokens, 250);
    });
    test('90+ → 500', () => expect(s(90).repairCostTokens, 500));
  });

  group('checkStreakMilestones', () {
    test('crossing day-7 returns the day-7 milestone exactly once', () async {
      final newly = await checkStreakMilestones(7);

      expect(newly.length, 1);
      expect(newly.first.milestone.days, 7);
      expect(newly.first.isNew, isTrue);
      expect(newly.first.milestone.xpReward, 100);
      expect(newly.first.milestone.scrollReward, 2);
      expect(newly.first.milestone.titleUnlock, 'Consistent');
    });

    test(
        'second call at the same streak does not re-grant — claimed set is '
        'persistent (idempotency regression guard)', () async {
      final first = await checkStreakMilestones(7);
      expect(first, hasLength(1));

      final second = await checkStreakMilestones(7);
      expect(second, isEmpty,
          reason:
              'Once a milestone is claimed, repeat calls at the same streak '
              'must return zero newly-reached milestones — otherwise rewards '
              'compound on every check-in');

      // And the claimed set is still persisted.
      final claimed = await getClaimedMilestones();
      expect(claimed, contains(7));
    });

    test(
        'jumping from streak 0 to streak 30 returns days 7, 14, AND 30 in one '
        'call — no thresholds skipped', () async {
      final newly = await checkStreakMilestones(30);
      final days = newly.map((m) => m.milestone.days).toList();

      expect(days, containsAll([7, 14, 30]));
      expect(days, isNot(contains(60)),
          reason: 'streak < 60 must not unlock the 60-day milestone');

      // Verify all three are persisted.
      final claimed = await getClaimedMilestones();
      expect(claimed, containsAll([7, 14, 30]));
    });

    test(
        'streak below the lowest threshold returns zero milestones and '
        'does not write the claimed key', () async {
      final newly = await checkStreakMilestones(6);
      expect(newly, isEmpty);

      final prefs = await SharedPreferences.getInstance();
      // No write should have happened — the function early-returns the
      // persistence step when newlyReached is empty.
      expect(prefs.getString('sakina_streak_milestones_claimed:user-1'),
          isNull);
    });

    test(
        'claimed milestones are stored under the user-scoped key '
        '(cross-user isolation)', () async {
      await checkStreakMilestones(14);

      final prefs = await SharedPreferences.getInstance();
      // Scoped form: <baseKey>:<userId>. The unscoped legacy key must NOT
      // be written by current code paths.
      expect(prefs.getString('sakina_streak_milestones_claimed:user-1'),
          isNotNull);
      expect(prefs.getString('sakina_streak_milestones_claimed'), isNull,
          reason:
              'Writes must go through scopedKey() so two users on the same '
              'device cannot see each other\'s milestone claims');
    });

    test(
        'after day-7 is claimed, advancing to day-14 returns ONLY the new '
        'day-14 milestone (not a re-issue of day-7)', () async {
      await checkStreakMilestones(7);
      final next = await checkStreakMilestones(14);

      expect(next, hasLength(1));
      expect(next.first.milestone.days, 14);
    });

    test(
        'server-authoritative claim prevents re-grant on cache-clear: local '
        'set empty but server says already-claimed → NOT newly reached (§2f)',
        () async {
      // Simulate a fresh device (empty local claimed-set) where the server
      // already recorded the day-7 claim.
      fakeSync.rpcHandlers['claim_streak_milestone'] =
          (_) async => {'newly_claimed': false};

      final newly = await checkStreakMilestones(7);
      expect(newly, isEmpty,
          reason: 'server says already claimed → no re-grant on new device');

      // And it is now cached locally so we do not re-call the RPC.
      final claimed = await getClaimedMilestones();
      expect(claimed, contains(7));
    });

    test(
        'server confirms a genuinely new claim → milestone IS newly reached',
        () async {
      fakeSync.rpcHandlers['claim_streak_milestone'] =
          (_) async => {'newly_claimed': true};

      final newly = await checkStreakMilestones(7);
      expect(newly, hasLength(1));
      expect(newly.first.milestone.days, 7);
    });

    test(
        'offline grant records pending claim; going online flushes it via RPC '
        'so a new device sees newly_claimed:false and does not double-grant '
        '(§offline-pending)', () async {
      // ── Phase A: offline (userId == null) ──────────────────────────────────
      fakeSync.userId = null;
      SupabaseSyncService.debugSetInstance(fakeSync);

      final offlineNewly = await checkStreakMilestones(7);
      expect(offlineNewly, hasLength(1),
          reason: 'offline grant must still fire locally');
      expect(offlineNewly.first.milestone.days, 7);
      expect(offlineNewly.first.isNew, isTrue);

      // The milestone must be in the pending-claims set so the flush can fire.
      final prefs = await SharedPreferences.getInstance();
      final pendingRaw =
          prefs.getString('sakina_streak_milestones_pending_server');
      expect(pendingRaw, isNotNull,
          reason:
              'offline grant must write the pending-server-claims set so it '
              'can be flushed when connectivity returns');

      // ── Phase B: user comes online ─────────────────────────────────────────
      fakeSync.userId = 'user-1';
      SupabaseSyncService.debugSetInstance(fakeSync);

      // The server has no record of this claim yet (newly_claimed = true would
      // be the server response, but we're only recording it — NOT re-granting).
      fakeSync.rpcHandlers['claim_streak_milestone'] =
          (_) async => {'newly_claimed': true};

      // Any call to checkStreakMilestones while online should flush pending.
      // Pass streak=7 again; local set already contains 7, so no new local
      // grant — but the flush must call claim_streak_milestone for the pending
      // day regardless.
      await checkStreakMilestones(7);

      final rpcCall = fakeSync.rpcCalls
          .where((c) => c['fn'] == 'claim_streak_milestone')
          .toList();
      expect(rpcCall, hasLength(1),
          reason:
              'going online must flush the pending offline grant by calling '
              'claim_streak_milestone on the server');
      expect((rpcCall.first['params'] as Map<String, dynamic>)['p_day'], 7,
          reason: 'the flush must target the day that was granted offline');

      // After flushing, the pending set must be cleared.
      final prefs2 = await SharedPreferences.getInstance();
      final pendingAfter =
          prefs2.getString('sakina_streak_milestones_pending_server:user-1');
      final pendingAfterUnscoped =
          prefs2.getString('sakina_streak_milestones_pending_server');
      final pendingDays = <int>{};
      if (pendingAfter != null) {
        pendingDays.addAll(
            (jsonDecode(pendingAfter) as List).cast<int>());
      }
      if (pendingAfterUnscoped != null) {
        pendingDays.addAll(
            (jsonDecode(pendingAfterUnscoped) as List).cast<int>());
      }
      expect(pendingDays, isEmpty,
          reason: 'pending set must be cleared after a successful flush');
    });
  });

  group('markActiveToday concurrency guard (T2 CRITICAL)', () {
    test('two concurrent calls run the ladder once; freeze not double-consumed',
        () async {
      fakeSync.rows['user_streaks:user-1'] = {
        'current_streak': 5,
        'longest_streak': 10,
        'last_active': '2026-04-01', // long gap → freeze branch
      };
      // Mimic the real RPC's `WHERE streak_freeze_owned = true`: it burns once,
      // then returns false. WITHOUT the in-flight guard the second concurrent
      // ladder run sees false and falls through to EXPIRED (streak → 1),
      // burning the streak the freeze just saved.
      var consumeCount = 0;
      fakeSync.rpcHandlers['consume_streak_freeze'] = (_) async {
        consumeCount++;
        return consumeCount == 1;
      };

      final f1 = markActiveToday();
      final f2 = markActiveToday();
      expect(identical(f1, f2), isTrue,
          reason: 'concurrent callers must share one in-flight Future');

      final results = await Future.wait([f1, f2]);
      expect(consumeCount, 1, reason: 'freeze must be consumed exactly once');
      expect(results[0].currentStreak, 6);
      expect(results[1].currentStreak, 6,
          reason: 'the loser must NOT fall through to EXPIRED (streak 1)');
    });
  });

  // ---------------------------------------------------------------------------
  // repairStreakPaid — RPC-success must survive a local-reconcile failure
  // ---------------------------------------------------------------------------
  // ---------------------------------------------------------------------------
  // addExcusedDate offline cap (§offline-excused-cap)
  // ---------------------------------------------------------------------------
  group('addExcusedDate offline cap', () {
    setUp(() {
      // Set userId to null so we exercise the offline (no-RPC) path.
      fakeSync.userId = null;
      SupabaseSyncService.debugSetInstance(fakeSync);
    });

    test(
        'offline: 8 distinct in-window dates are all accepted; '
        'a 9th in-window date is refused (returns false, not cached)', () async {
      // Add 8 distinct dates within the last 30 days (days 1..8 ago).
      for (var i = 1; i <= 8; i++) {
        final date = DateTime.now().toUtc().subtract(Duration(days: i));
        final result = await addExcusedDate(date);
        expect(result, isTrue, reason: 'date $i should be accepted (within cap)');
      }

      // Verify 8 dates are cached.
      final cached = await getExcusedDates();
      expect(cached.length, 8);

      // 9th in-window date must be refused.
      final ninthDate = DateTime.now().toUtc().subtract(const Duration(days: 9));
      final ninthResult = await addExcusedDate(ninthDate);
      expect(ninthResult, isFalse, reason: '9th in-window date must be blocked by the local cap');

      // Cache must NOT have grown.
      final cachedAfter = await getExcusedDates();
      expect(cachedAfter.length, 8, reason: 'refused date must not be written to cache');
    });

    test(
        'offline: re-adding an already-cached in-window date is a no-op '
        'success and does not consume a new slot', () async {
      // Fill to 8.
      for (var i = 1; i <= 8; i++) {
        await addExcusedDate(DateTime.now().toUtc().subtract(Duration(days: i)));
      }

      // Re-add the first date (already cached).
      final firstDate = DateTime.now().toUtc().subtract(const Duration(days: 1));
      final reAddResult = await addExcusedDate(firstDate);
      expect(reAddResult, isTrue,
          reason: 're-adding an already-cached date must be idempotent (true)');

      // Count stays at 8.
      final cached = await getExcusedDates();
      expect(cached.length, 8, reason: 'idempotent re-add must not grow the set');

      // 9th NEW date is still refused (the idempotent re-add did not shrink the cap).
      final ninthDate = DateTime.now().toUtc().subtract(const Duration(days: 9));
      final ninthResult = await addExcusedDate(ninthDate);
      expect(ninthResult, isFalse,
          reason: 'cap is still reached after idempotent re-add');
    });

    test(
        'offline: a date outside the 30-day window does NOT count toward the '
        'in-window cap', () async {
      // Add 8 in-window dates.
      for (var i = 1; i <= 8; i++) {
        await addExcusedDate(DateTime.now().toUtc().subtract(Duration(days: i)));
      }

      // Date 31 days ago is outside the window — must still succeed.
      final oldDate = DateTime.now().toUtc().subtract(const Duration(days: 31));
      final result = await addExcusedDate(oldDate);
      expect(result, isTrue,
          reason: 'out-of-window date does not count toward the rolling cap');
    });
  });

  group('repairStreakPaid', () {
    test(
        'RPC success + reconcile failure → still returns success:true with '
        'restored streak (server was charged; client must not report failure)',
        () async {
      // RPC returns a valid success payload.
      final rpcResult = <String, dynamic>{
        'current_streak': 15,
        'method': 'paid',
        'cost': 100,
      };
      // Inject a reconcile that always throws after a successful RPC.
      final result = await repairStreakPaid(
        preLapseStreak: 15,
        repairRpc: () async => rpcResult,
        reconcileCache: ({
          required int restoredStreak,
          required String method,
          required int cost,
        }) async {
          throw StateError('SharedPreferences write failed');
        },
      );

      expect(result.success, isTrue,
          reason:
              'RPC already debited tokens and restored the streak on the server; '
              'a local-cache failure must NOT flip success to false');
      expect(result.restoredStreak, 15);
      expect(result.reason, RepairFailReason.none);
      expect(result.needsTokens, isFalse);
    });

    test(
        'RPC failure with "insufficient" error → insufficientTokens + '
        'needsTokens:true (reason-mapping regression guard)',
        () async {
      final result = await repairStreakPaid(
        repairRpc: () async =>
            throw Exception('insufficient tokens in wallet'),
      );

      expect(result.success, isFalse);
      expect(result.reason, RepairFailReason.insufficientTokens);
      expect(result.needsTokens, isTrue);
    });

    test(
        'RPC failure with "rate-limited" error → rateLimited reason',
        () async {
      final result = await repairStreakPaid(
        repairRpc: () async => throw Exception('rate-limited: already repaired'),
      );

      expect(result.success, isFalse);
      expect(result.reason, RepairFailReason.rateLimited);
    });

    test(
        'RPC success with balance field → PaidRepairResult.newBalance equals '
        'the server-returned balance (token debit reflected in result)',
        () async {
      // The server atomically debits tokens and returns the post-debit balance.
      final rpcResult = <String, dynamic>{
        'current_streak': 12,
        'method': 'paid',
        'cost': 100,
        'balance': 350, // post-debit balance from the server
      };

      final result = await repairStreakPaid(
        preLapseStreak: 12,
        repairRpc: () async => rpcResult,
      );

      expect(result.success, isTrue);
      expect(result.newBalance, 350,
          reason:
              'PaidRepairResult must surface the server-returned post-debit '
              'balance so the caller can update dailyLoopProvider.tokenBalance');
    });
  });
}
