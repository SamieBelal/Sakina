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
}
