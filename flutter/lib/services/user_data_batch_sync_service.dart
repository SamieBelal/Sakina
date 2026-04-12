import 'package:sakina/features/daily/providers/daily_question_provider.dart';
import 'package:sakina/features/discovery/providers/discovery_quiz_provider.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/achievements_service.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/checkin_history_service.dart';
import 'package:sakina/services/daily_usage_service.dart';
import 'package:sakina/services/daily_rewards_service.dart';
import 'package:sakina/services/premium_grants_service.dart';
import 'package:sakina/services/streak_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/tier_up_scroll_service.dart';
import 'package:sakina/services/title_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/xp_service.dart';

class UserDataBatchPayload {
  const UserDataBatchPayload(this.raw);

  final Map<String, dynamic> raw;

  factory UserDataBatchPayload.fromRpc(Map<String, dynamic> raw) {
    return UserDataBatchPayload(Map<String, dynamic>.from(raw));
  }

  bool containsKey(String key) => raw.containsKey(key);

  Map<String, dynamic>? objectSection(String key) {
    if (!raw.containsKey(key)) return null;
    final value = raw[key];
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }

  List<Map<String, dynamic>>? listSection(String key) {
    if (!raw.containsKey(key)) return null;
    final value = raw[key];
    if (value is! List) return null;
    return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }
}

Future<void> hydrateUserDataFromBatchRpc() async {
  final userId = supabaseSyncService.currentUserId;
  if (userId == null) return;

  await Future.wait([
    prepareXpCacheForHydration(),
    prepareTokenCacheForHydration(),
    prepareTierUpScrollCacheForHydration(),
    prepareStreakCacheForHydration(),
    prepareDailyRewardsCacheForHydration(),
    preparePremiumGrantCacheForHydration(),
    prepareTitlePrefsCacheForHydration(),
    migrateCheckinHistoryCache(),
    migrateReflectionCachesForHydration(),
    migrateDuaCachesForHydration(),
    migrateCardCollectionCachesForHydration(),
    migrateAchievementsCacheForHydration(),
    migrateDiscoveryResultsCacheForHydration(),
    migrateQuestProgressCacheForHydration(),
  ]);

  final payloadRaw = await supabaseSyncService
      .callRpc<Map<String, dynamic>>('sync_all_user_data');
  if (payloadRaw == null) return;

  final payload = UserDataBatchPayload.fromRpc(payloadRaw);

  final xp = payload.objectSection('xp');
  final totalXp = _intValue(xp?['total_xp']);
  if (totalXp != null) {
    await hydrateXpCache(totalXp: totalXp);
  }

  final tokens = payload.objectSection('tokens');
  final balance = _intValue(tokens?['balance']);
  final totalSpent = _intValue(tokens?['total_spent']);
  if (balance != null && totalSpent != null) {
    await hydrateTokenCache(balance: balance, totalSpent: totalSpent);
  }
  final tierUpScrolls = _intValue(tokens?['tier_up_scrolls']);
  if (tierUpScrolls != null) {
    await hydrateTierUpScrollCache(balance: tierUpScrolls);
  }

  final streak = payload.objectSection('streak');
  final currentStreak = _intValue(streak?['current_streak']);
  final longestStreak = _intValue(streak?['longest_streak']);
  if (currentStreak != null && longestStreak != null) {
    await hydrateStreakCache(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastActive: _stringValue(streak?['last_active']),
    );
  }

  final dailyRewards = payload.objectSection('daily_rewards');
  final currentDay = _intValue(dailyRewards?['current_day']);
  final streakFreezeOwned = _boolValue(dailyRewards?['streak_freeze_owned']);
  if (currentDay != null && streakFreezeOwned != null) {
    await hydrateDailyRewardsCache(
      currentDay: currentDay,
      lastClaimDate: _stringValue(dailyRewards?['last_claim_date']),
      streakFreezeOwned: streakFreezeOwned,
    );
  }
  if (dailyRewards != null &&
      dailyRewards.containsKey('last_premium_grant_month')) {
    await hydratePremiumGrantCache(
      lastGrantMonth: _stringValue(dailyRewards['last_premium_grant_month']),
    );
  }

  final profile = payload.objectSection('profile');
  if (profile != null) {
    await hydrateTitlePrefsCache(
      selectedTitle: _stringValue(profile['selected_title']),
      isAutoTitle: _boolValue(profile['is_auto_title']) ?? true,
    );
    final createdAt = _stringValue(profile['created_at']);
    if (createdAt != null) {
      await hydrateFirstStepsEligibilityFromBatch(createdAt: createdAt);
    }
  }

  await _hydrateOrSeedListSection(
    rows: payload.listSection('checkin_history'),
    hydrate: hydrateCheckinHistoryCacheFromRows,
    seed: seedCheckinHistoryToSupabaseFromLocalCache,
  );
  await _hydrateOrSeedListSection(
    rows: payload.listSection('reflections'),
    hydrate: hydrateReflectionCacheFromRows,
    seed: seedReflectionsToSupabaseFromLocalCache,
  );
  await _hydrateOrSeedListSection(
    rows: payload.listSection('built_duas'),
    hydrate: hydrateBuiltDuaCacheFromRows,
    seed: seedBuiltDuasToSupabaseFromLocalCache,
  );
  await _hydrateOrSeedListSection(
    rows: payload.listSection('card_collection'),
    hydrate: hydrateCardCollectionCacheFromRows,
    seed: seedCardCollectionToSupabaseFromLocalCache,
  );
  await _hydrateOrSeedListSection(
    rows: payload.listSection('achievements'),
    hydrate: hydrateAchievementsCacheFromRows,
    seed: seedAchievementsToSupabaseFromLocalCache,
  );
  await _hydrateOrSeedDiscoveryResults(
    hasSection: payload.containsKey('discovery_results'),
    section: payload.objectSection('discovery_results'),
  );
  await _hydrateOrSeedDailyUsage(
    hasSection: payload.containsKey('daily_usage'),
    section: payload.objectSection('daily_usage'),
    rows: payload.listSection('daily_usage'),
  );
  await _hydrateOrSeedListSection(
    rows: payload.listSection('daily_answers'),
    hydrate: hydrateDailyAnswersCacheFromRows,
    seed: seedDailyAnswersToSupabaseFromLocalCache,
  );
  await _hydrateOrSeedListSection(
    rows: payload.listSection('quest_progress'),
    hydrate: hydrateQuestProgressCacheFromRows,
    seed: seedQuestProgressToSupabaseFromLocalCache,
  );

  if (!payload.containsKey('achievements')) {
    await syncAchievementsCacheFromSupabase();
  }
  if (!payload.containsKey('discovery_results')) {
    await syncDiscoveryResultsFromSupabase();
  }
  if (!payload.containsKey('daily_usage')) {
    await syncDailyUsageFromSupabase();
  }
  if (!payload.containsKey('daily_answers')) {
    await syncDailyAnswersFromSupabase();
  }
  if (!payload.containsKey('quest_progress')) {
    await syncQuestProgressFromSupabase();
  }
}

Future<void> _hydrateOrSeedListSection({
  required List<Map<String, dynamic>>? rows,
  required Future<void> Function(List<Map<String, dynamic>> rows) hydrate,
  required Future<void> Function() seed,
}) async {
  if (rows == null) return;
  if (rows.isEmpty) {
    await seed();
    return;
  }
  await hydrate(rows);
}

Future<void> _hydrateOrSeedDiscoveryResults({
  required bool hasSection,
  required Map<String, dynamic>? section,
}) async {
  if (!hasSection) return;
  if (section == null) {
    await seedDiscoveryResultsToSupabaseFromLocalCache();
    return;
  }

  final anchorNames = section['anchor_names'];
  if (anchorNames is! List) return;
  await hydrateDiscoveryResultsCacheFromPayload(anchorNames);
}

Future<void> _hydrateOrSeedDailyUsage({
  required bool hasSection,
  required Map<String, dynamic>? section,
  required List<Map<String, dynamic>>? rows,
}) async {
  if (!hasSection) return;
  if (rows != null) {
    if (rows.isEmpty) {
      await seedDailyUsageToSupabaseFromLocalCache();
      return;
    }
    await hydrateDailyUsageCacheFromRows(rows);
    return;
  }
  if (section == null) {
    await seedDailyUsageToSupabaseFromLocalCache();
    return;
  }
  await hydrateDailyUsageCacheFromPayload(section);
}

int? _intValue(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}

String? _stringValue(dynamic value) {
  if (value is String) return value;
  return null;
}

bool? _boolValue(dynamic value) {
  if (value is bool) return value;
  return null;
}
