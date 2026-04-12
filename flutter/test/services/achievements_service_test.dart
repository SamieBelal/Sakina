import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/achievements_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  test('syncAchievementsCacheFromSupabase hydrates from server', () async {
    fakeSync.rowLists['user_achievements'] = [
      {'user_id': 'user-1', 'achievement_id': 'first_name'},
      {'user_id': 'user-1', 'achievement_id': 'reflect_first'},
    ];

    await syncAchievementsCacheFromSupabase();

    final unlocked = await getUnlockedAchievements();
    expect(unlocked, {'first_name', 'reflect_first'});
  });

  test('syncAchievementsCacheFromSupabase seeds server when empty', () async {
    SharedPreferences.setMockInitialValues({
      'sakina_achievements_unlocked:user-1': jsonEncode(['bronze_10']),
    });

    await syncAchievementsCacheFromSupabase();

    expect(fakeSync.batchInsertCalls, hasLength(1));
    expect(fakeSync.batchInsertCalls.single['table'], 'user_achievements');
    final inserted = fakeSync.batchInsertCalls.single['rows'] as List<dynamic>;
    expect(inserted, hasLength(1));
    expect(inserted.first['achievement_id'], 'bronze_10');
  });

  test('unlockAchievement writes to Supabase and local cache', () async {
    final updated = await unlockAchievement('first_name');

    expect(updated, contains('first_name'));
    expect(fakeSync.insertCalls, hasLength(1));
    expect(fakeSync.insertCalls.single['table'], 'user_achievements');
    expect(
      (fakeSync.insertCalls.single['data'] as Map)['achievement_id'],
      'first_name',
    );

    final unlocked = await getUnlockedAchievements();
    expect(unlocked, contains('first_name'));
  });

  test('unlockAchievement is idempotent', () async {
    await unlockAchievement('first_name');
    await unlockAchievement('first_name');

    // Only one insert — the second call is a no-op.
    expect(fakeSync.insertCalls, hasLength(1));
  });

  test('checkAndUnlockAchievements skips unlock when scroll sync fails',
      () async {
    final newlyUnlocked = await checkAndUnlockAchievements(
      const AchievementCheckData(
        discoveredNames: 1,
        silverNames: 0,
        goldNames: 0,
        reflectionCount: 0,
        uniqueEmotions: 0,
        uniqueNamesInReflections: 0,
        builtDuaCount: 0,
        longestStreak: 0,
        currentStreak: 0,
        hadBrokenStreak: false,
        xpTotal: 0,
        level: 0,
        journalEntries: 0,
        dailyQuestsCompletedToday: 0,
        totalDailyQuests: 0,
      ),
    );

    expect(newlyUnlocked, isEmpty);
    expect(await getUnlockedAchievements(), isEmpty);
    expect(fakeSync.insertCalls, isEmpty);
    expect(fakeSync.rpcCalls.single['fn'], 'earn_scrolls');
  });

  test('scoped key isolation between users', () async {
    SharedPreferences.setMockInitialValues({
      'sakina_achievements_unlocked:user-1': jsonEncode(['first_name']),
      'sakina_achievements_unlocked:user-2': jsonEncode(['bronze_10']),
    });

    final unlocked1 = await getUnlockedAchievements();
    expect(unlocked1, {'first_name'});

    fakeSync.userId = 'user-2';
    final unlocked2 = await getUnlockedAchievements();
    expect(unlocked2, {'bronze_10'});
  });

  test('legacy unscoped key migrates on first read', () async {
    SharedPreferences.setMockInitialValues({
      'sakina_achievements_unlocked': jsonEncode(['reflect_first']),
    });

    final unlocked = await getUnlockedAchievements();
    expect(unlocked, {'reflect_first'});

    // The scoped key should now exist after migration.
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('sakina_achievements_unlocked:user-1'),
      jsonEncode(['reflect_first']),
    );
  });

  test('legacy unscoped key is DELETED after migration (cross-user safety)',
      () async {
    SharedPreferences.setMockInitialValues({
      'sakina_achievements_unlocked': jsonEncode(['reflect_first']),
    });

    // User A signs in, migration runs.
    await getUnlockedAchievements();

    // Legacy key must be gone — otherwise User B signing in on the same
    // device would inherit User A's data.
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.containsKey('sakina_achievements_unlocked'),
      isFalse,
      reason: 'legacy unscoped key must be deleted after first migration '
          'to prevent cross-user bleed on shared devices',
    );

    // User A signs out, User B signs in.
    fakeSync.userId = 'user-2';
    final unlockedForB = await getUnlockedAchievements();

    // User B should see their own empty state, NOT User A's achievements.
    expect(unlockedForB, isEmpty);
  });
}
