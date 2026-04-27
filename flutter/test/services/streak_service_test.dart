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

  test('logActivity keeps the local log idempotent', () async {
    await logActivity();
    await logActivity();

    final activity = await getActivityLog();
    expect(activity.length, 1);
    expect(fakeSync.insertCalls.length, 2);
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
  });
}
