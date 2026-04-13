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

  test('checkAndUnlockAchievements unlocks even when scroll sync fails',
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

    // Achievement unlocks even though scroll reward failed — prevents
    // transient failures from permanently blocking achievements.
    expect(newlyUnlocked, contains('first_name'));
    expect(await getUnlockedAchievements(), contains('first_name'));
    expect(fakeSync.rpcCalls.single['fn'], 'earn_scrolls');
  });

  group('checkAndUnlockAchievements threshold logic', () {
    setUp(() {
      // Make earn_scrolls succeed so achievements can actually unlock.
      fakeSync.rpcHandlers['earn_scrolls'] = (params) async => 99;
    });

    AchievementCheckData baseData({
      int discoveredNames = 0,
      int silverNames = 0,
      int goldNames = 0,
      int reflectionCount = 0,
      int uniqueEmotions = 0,
      int uniqueNamesInReflections = 0,
      int builtDuaCount = 0,
      int longestStreak = 0,
      int currentStreak = 0,
      bool hadBrokenStreak = false,
      int xpTotal = 0,
      int level = 0,
      int journalEntries = 0,
      int dailyQuestsCompletedToday = 0,
      int totalDailyQuests = 0,
      bool hasUsedScroll = false,
      bool hasCompleteSet = false,
      bool hasSelectedTitle = false,
      int unlockedTitleCount = 0,
      int weeklyQuestsCompleted = 0,
      int monthlyQuestsCompleted = 0,
      int totalTokensSpent = 0,
      int namesInvokedCount = 0,
    }) =>
        AchievementCheckData(
          discoveredNames: discoveredNames,
          silverNames: silverNames,
          goldNames: goldNames,
          reflectionCount: reflectionCount,
          uniqueEmotions: uniqueEmotions,
          uniqueNamesInReflections: uniqueNamesInReflections,
          builtDuaCount: builtDuaCount,
          longestStreak: longestStreak,
          currentStreak: currentStreak,
          hadBrokenStreak: hadBrokenStreak,
          xpTotal: xpTotal,
          level: level,
          journalEntries: journalEntries,
          dailyQuestsCompletedToday: dailyQuestsCompletedToday,
          totalDailyQuests: totalDailyQuests,
          hasUsedScroll: hasUsedScroll,
          hasCompleteSet: hasCompleteSet,
          hasSelectedTitle: hasSelectedTitle,
          unlockedTitleCount: unlockedTitleCount,
          weeklyQuestsCompleted: weeklyQuestsCompleted,
          monthlyQuestsCompleted: monthlyQuestsCompleted,
          totalTokensSpent: totalTokensSpent,
          namesInvokedCount: namesInvokedCount,
        );

    test('unlocks first_name at 1 discovered name', () async {
      final result =
          await checkAndUnlockAchievements(baseData(discoveredNames: 1));
      expect(result, contains('first_name'));
    });

    test('unlocks streak_7 at 7-day longest streak', () async {
      final result =
          await checkAndUnlockAchievements(baseData(longestStreak: 7));
      expect(result, contains('streak_7'));
    });

    test('unlocks comeback when broken streak and current >= 1', () async {
      final result = await checkAndUnlockAchievements(baseData(
        longestStreak: 5,
        currentStreak: 1,
        hadBrokenStreak: true,
      ));
      expect(result, contains('comeback'));
    });

    test('does not unlock comeback without a broken streak', () async {
      final result = await checkAndUnlockAchievements(baseData(
        longestStreak: 5,
        currentStreak: 5,
        hadBrokenStreak: false,
      ));
      expect(result, isNot(contains('comeback')));
    });

    test('unlocks all_quests_day when all daily quests done', () async {
      final result = await checkAndUnlockAchievements(baseData(
        dailyQuestsCompletedToday: 3,
        totalDailyQuests: 3,
      ));
      expect(result, contains('all_quests_day'));
    });

    test('does not unlock all_quests_day when totalDailyQuests is 0',
        () async {
      final result = await checkAndUnlockAchievements(baseData(
        dailyQuestsCompletedToday: 0,
        totalDailyQuests: 0,
      ));
      expect(result, isNot(contains('all_quests_day')));
    });

    test('does not re-unlock already unlocked achievements', () async {
      // First call unlocks first_name.
      await checkAndUnlockAchievements(baseData(discoveredNames: 1));
      fakeSync.insertCalls.clear();
      fakeSync.rpcCalls.clear();

      // Second call with same data should not re-unlock.
      final result =
          await checkAndUnlockAchievements(baseData(discoveredNames: 1));
      expect(result, isEmpty);
      expect(fakeSync.insertCalls, isEmpty);
    });

    test('unlocks multiple achievements in a single check', () async {
      final result = await checkAndUnlockAchievements(baseData(
        discoveredNames: 1,
        reflectionCount: 1,
        builtDuaCount: 1,
      ));
      expect(result, containsAll(['first_name', 'reflect_first', 'dua_first']));
    });
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
