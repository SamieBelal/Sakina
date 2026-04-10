import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/checkin_history_service.dart';
import 'package:sakina/services/streak_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/xp_service.dart';
import 'package:sakina/services/tier_up_scroll_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Cadence
// ---------------------------------------------------------------------------

enum QuestCadence { daily, weekly, monthly }

// ---------------------------------------------------------------------------
// First Steps (one-time beginner quests for new users)
// ---------------------------------------------------------------------------

/// Accounts created on or after this UTC date are eligible for First Steps.
/// Existing users (created before) never see the section.
final DateTime firstStepsShipDate = DateTime.utc(2026, 4, 9);

enum BeginnerQuestId { firstMuhasabah, firstReflect, firstBuiltDua }

extension BeginnerQuestIdX on BeginnerQuestId {
  String get key {
    switch (this) {
      case BeginnerQuestId.firstMuhasabah:
        return 'first_muhasabah';
      case BeginnerQuestId.firstReflect:
        return 'first_reflect';
      case BeginnerQuestId.firstBuiltDua:
        return 'first_built_dua';
    }
  }

  static BeginnerQuestId? fromKey(String key) {
    for (final id in BeginnerQuestId.values) {
      if (id.key == key) return id;
    }
    return null;
  }
}

class BeginnerQuest {
  final BeginnerQuestId id;
  final String title;
  final String description;
  final IconData icon;
  final int xpReward;
  final int tokenReward;
  final int scrollReward;
  final String route;

  const BeginnerQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.xpReward,
    required this.tokenReward,
    required this.scrollReward,
    required this.route,
  });
}

const List<BeginnerQuest> beginnerQuests = [
  BeginnerQuest(
    id: BeginnerQuestId.firstMuhasabah,
    title: 'Your First Check-In',
    description: 'Complete a Muhasabah and meet a Name of Allah.',
    icon: Icons.favorite_rounded,
    xpReward: 75,
    tokenReward: 50,
    scrollReward: 5,
    route: '/muhasabah',
  ),
  BeginnerQuest(
    id: BeginnerQuestId.firstReflect,
    title: 'Reflect on a Feeling',
    description: 'Write a reflection and receive a personalized response.',
    icon: Icons.edit_note_rounded,
    xpReward: 75,
    tokenReward: 50,
    scrollReward: 5,
    route: '/reflect',
  ),
  BeginnerQuest(
    id: BeginnerQuestId.firstBuiltDua,
    title: 'Build Your Own Dua',
    description: 'Craft a custom dua for something on your heart.',
    icon: Icons.auto_awesome,
    xpReward: 75,
    tokenReward: 50,
    scrollReward: 5,
    route: '/duas',
  ),
];

/// Bundle bonus granted when all 3 First Steps quests are completed.
const int firstStepsBundleXp = 50;
const int firstStepsBundleTokens = 100;
const int firstStepsBundleScrolls = 5;

/// Snapshot of a freshly-earned bundle celebration to drive the UI overlay.
class FirstStepsBundleCelebration {
  final int xp;
  final int tokens;
  final int scrolls;
  const FirstStepsBundleCelebration({
    required this.xp,
    required this.tokens,
    required this.scrolls,
  });
}

// ---------------------------------------------------------------------------
// Quest template (pool entry)
// ---------------------------------------------------------------------------

class QuestTemplate {
  final int poolIndex;
  final String title;
  final String description;
  final IconData icon;
  final int xpReward;
  final int tokenReward;
  final int scrollReward;
  final int target; // 0 = single-action (no progress bar), >0 = threshold

  const QuestTemplate({
    required this.poolIndex,
    required this.title,
    required this.description,
    required this.icon,
    required this.xpReward,
    this.tokenReward = 0,
    this.scrollReward = 0,
    this.target = 0,
  });
}

// ---------------------------------------------------------------------------
// Quest instance (generated from template + date)
// ---------------------------------------------------------------------------

class Quest {
  final String id;
  final QuestCadence cadence;
  final String title;
  final String description;
  final IconData icon;
  final int xpReward;
  final int tokenReward;
  final int scrollReward;
  final int poolIndex;
  final int target; // 0 = single-action, >0 = threshold quest

  const Quest({
    required this.id,
    required this.cadence,
    required this.title,
    required this.description,
    required this.icon,
    required this.xpReward,
    this.tokenReward = 0,
    this.scrollReward = 0,
    required this.poolIndex,
    this.target = 0,
  });
}

// ---------------------------------------------------------------------------
// Quest pools
// ---------------------------------------------------------------------------

// Daily pool — 9 unique single-shot quests, pick 3 per day.
// Pool indices are stable identifiers used in persisted completion records;
// don't reorder. Replace contents in place if a slot needs new meaning.
const _dailyPool = <QuestTemplate>[
  QuestTemplate(
    poolIndex: 0,
    title: 'Complete a Reflection',
    description: 'Open Reflect and share what\'s on your heart.',
    icon: Icons.auto_stories_rounded,
    xpReward: 15, tokenReward: 5,
  ),
  QuestTemplate(
    poolIndex: 1,
    title: 'Build a personal dua',
    description: 'Craft a dua for your specific need.',
    icon: Icons.auto_awesome,
    xpReward: 15, tokenReward: 5,
  ),
  QuestTemplate(
    poolIndex: 2,
    title: 'Visit your Collection',
    description: 'Browse your discovered Names of Allah.',
    icon: Icons.grid_view_rounded,
    xpReward: 10, tokenReward: 3,
  ),
  QuestTemplate(
    poolIndex: 3,
    title: 'Review your Journal',
    description: 'Open your Journal to revisit a saved entry.',
    icon: Icons.bookmark_rounded,
    xpReward: 10, tokenReward: 3,
  ),
  QuestTemplate(
    poolIndex: 4,
    title: 'Complete a Muhasabah',
    description: 'Do today\'s daily check-in.',
    icon: Icons.favorite_rounded,
    xpReward: 20, tokenReward: 5,
  ),
  QuestTemplate(
    poolIndex: 5,
    title: 'Save a related dua',
    description: 'Tap the heart on a related dua to save it for later.',
    icon: Icons.bookmark_add_rounded,
    xpReward: 10, tokenReward: 3,
  ),
  QuestTemplate(
    poolIndex: 6,
    title: 'Explore a Name of Allah',
    description: 'Tap into a Name in your Collection to learn more.',
    icon: Icons.search_rounded,
    xpReward: 10, tokenReward: 3,
  ),
  QuestTemplate(
    poolIndex: 7,
    title: 'Discover a new Name',
    description: 'Pull a card from your check-in to grow your collection.',
    icon: Icons.auto_fix_high_rounded,
    xpReward: 15, tokenReward: 5,
  ),
  QuestTemplate(
    poolIndex: 8,
    title: 'Tier up a card',
    description: 'Spend tier-up scrolls to upgrade a Name in your collection.',
    icon: Icons.military_tech_rounded,
    xpReward: 20, tokenReward: 5,
  ),
];

// Weekly pool — 7 threshold quests, pick 3 per week.
const _weeklyPool = <QuestTemplate>[
  QuestTemplate(
    poolIndex: 0,
    title: 'Reflect 3 times',
    description: 'Complete 3 Reflect sessions this week.',
    icon: Icons.auto_stories_rounded,
    xpReward: 50, tokenReward: 3, scrollReward: 2,
    target: 3,
  ),
  QuestTemplate(
    poolIndex: 1,
    title: 'Build 2 personal duas',
    description: 'Craft 2 duas for specific needs.',
    icon: Icons.auto_awesome,
    xpReward: 30, tokenReward: 2, scrollReward: 1,
    target: 2,
  ),
  QuestTemplate(
    poolIndex: 2,
    title: 'Discover 3 new Names',
    description: 'Encounter 3 new Names through check-ins.',
    icon: Icons.explore_rounded,
    xpReward: 40, tokenReward: 2, scrollReward: 2,
    target: 3,
  ),
  QuestTemplate(
    poolIndex: 3,
    title: 'Complete 5 Muhasabahs',
    description: 'Do 5 daily check-ins this week.',
    icon: Icons.favorite_rounded,
    xpReward: 60, tokenReward: 3, scrollReward: 2,
    target: 5,
  ),
  QuestTemplate(
    poolIndex: 4,
    title: 'Visit Collection 3 days',
    description: 'Open your Collection on 3 different days.',
    icon: Icons.grid_view_rounded,
    xpReward: 40, tokenReward: 3, scrollReward: 2,
    target: 3,
  ),
  QuestTemplate(
    poolIndex: 5,
    title: 'Save 3 related duas',
    description: 'Heart 3 related duas you discover this week.',
    icon: Icons.bookmark_add_rounded,
    xpReward: 35, tokenReward: 2, scrollReward: 1,
    target: 3,
  ),
  QuestTemplate(
    poolIndex: 6,
    title: 'Tier up 2 cards',
    description: 'Upgrade 2 Names in your collection this week.',
    icon: Icons.military_tech_rounded,
    xpReward: 60, tokenReward: 3, scrollReward: 3,
    target: 2,
  ),
];

// Monthly pool — 8 threshold quests, pick 3 per month.
const _monthlyPool = <QuestTemplate>[
  QuestTemplate(
    poolIndex: 0,
    title: 'Discover 10 Names',
    description: 'Grow your collection by 10 new Names this month.',
    icon: Icons.stars_rounded,
    xpReward: 150, tokenReward: 10, scrollReward: 5,
    target: 10,
  ),
  QuestTemplate(
    poolIndex: 1,
    title: 'Reflect 15 times',
    description: 'Complete 15 Reflect sessions this month.',
    icon: Icons.auto_stories_rounded,
    xpReward: 150, tokenReward: 10, scrollReward: 5,
    target: 15,
  ),
  QuestTemplate(
    poolIndex: 2,
    title: 'Build 5 personal duas',
    description: 'Craft 5 personal duas this month.',
    icon: Icons.auto_awesome,
    xpReward: 100, tokenReward: 8, scrollReward: 3,
    target: 5,
  ),
  QuestTemplate(
    poolIndex: 3,
    title: 'Unlock 3 Silver Names',
    description: 'Tier up 3 Names to Silver in your Collection.',
    icon: Icons.military_tech_rounded,
    xpReward: 120, tokenReward: 8, scrollReward: 4,
    target: 3,
  ),
  QuestTemplate(
    poolIndex: 4,
    title: 'Maintain a 20-day streak',
    description: 'Check in 20+ days this month to show true dedication.',
    icon: Icons.local_fire_department,
    xpReward: 150, tokenReward: 10, scrollReward: 5,
    target: 20,
  ),
  QuestTemplate(
    poolIndex: 5,
    title: 'Complete 20 Muhasabahs',
    description: 'Do 20 daily check-ins this month.',
    icon: Icons.favorite_rounded,
    xpReward: 150, tokenReward: 10, scrollReward: 5,
    target: 20,
  ),
  QuestTemplate(
    poolIndex: 6,
    title: 'Save 10 related duas',
    description: 'Heart 10 related duas you discover this month.',
    icon: Icons.bookmark_add_rounded,
    xpReward: 100, tokenReward: 8, scrollReward: 3,
    target: 10,
  ),
  QuestTemplate(
    poolIndex: 7,
    title: 'Unlock 1 Gold Name',
    description: 'Tier up a Name all the way to Gold this month.',
    icon: Icons.workspace_premium_rounded,
    xpReward: 200, tokenReward: 12, scrollReward: 8,
    target: 1,
  ),
];

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class QuestsState {
  final List<Quest> daily;
  final List<Quest> weekly;
  final List<Quest> monthly;
  final Set<String> completedIds;
  final Map<String, int> progress; // quest id → current count
  final bool loaded;

  // ── First Steps ───────────────────────────────────────────────────────────
  /// True if this account is eligible (created on/after the ship date).
  final bool firstStepsEligible;
  final Set<BeginnerQuestId> firstStepsCompleted;
  final bool firstStepsBundleClaimed;

  /// Set when the bundle bonus is awarded; UI consumes and clears it
  /// after presenting the celebration overlay.
  final FirstStepsBundleCelebration? pendingBundleCelebration;

  const QuestsState({
    this.daily = const [],
    this.weekly = const [],
    this.monthly = const [],
    this.completedIds = const {},
    this.progress = const {},
    this.loaded = false,
    this.firstStepsEligible = false,
    this.firstStepsCompleted = const {},
    this.firstStepsBundleClaimed = false,
    this.pendingBundleCelebration,
  });

  List<Quest> get all => [...daily, ...weekly, ...monthly];

  bool isCompleted(String id) => completedIds.contains(id);

  int getProgress(String id) => progress[id] ?? 0;

  int get dailyCompletedCount =>
      daily.where((q) => completedIds.contains(q.id)).length;

  bool isBeginnerCompleted(BeginnerQuestId id) =>
      firstStepsCompleted.contains(id);

  /// Show the First Steps section if the account is eligible and the
  /// section hasn't been fully retired (all 3 done + bundle claimed).
  bool get showFirstSteps =>
      firstStepsEligible &&
      !(firstStepsCompleted.length >= beginnerQuests.length &&
          firstStepsBundleClaimed);

  QuestsState copyWith({
    List<Quest>? daily,
    List<Quest>? weekly,
    List<Quest>? monthly,
    Set<String>? completedIds,
    Map<String, int>? progress,
    bool? loaded,
    bool? firstStepsEligible,
    Set<BeginnerQuestId>? firstStepsCompleted,
    bool? firstStepsBundleClaimed,
    FirstStepsBundleCelebration? pendingBundleCelebration,
    bool clearPendingBundleCelebration = false,
  }) {
    return QuestsState(
      daily: daily ?? this.daily,
      weekly: weekly ?? this.weekly,
      monthly: monthly ?? this.monthly,
      completedIds: completedIds ?? this.completedIds,
      progress: progress ?? this.progress,
      loaded: loaded ?? this.loaded,
      firstStepsEligible: firstStepsEligible ?? this.firstStepsEligible,
      firstStepsCompleted: firstStepsCompleted ?? this.firstStepsCompleted,
      firstStepsBundleClaimed:
          firstStepsBundleClaimed ?? this.firstStepsBundleClaimed,
      pendingBundleCelebration: clearPendingBundleCelebration
          ? null
          : (pendingBundleCelebration ?? this.pendingBundleCelebration),
    );
  }
}

// ---------------------------------------------------------------------------
// Date helpers
// ---------------------------------------------------------------------------

String _todayLabel() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}

String _weekLabel() {
  final n = DateTime.now();
  final monday = n.subtract(Duration(days: n.weekday - 1));
  return '${monday.year}-W${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
}

String _monthLabel() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}';
}

int _dayOfYear() {
  final now = DateTime.now();
  return now.difference(DateTime(now.year, 1, 1)).inDays;
}

int _isoWeekNumber() {
  final now = DateTime.now();
  final jan1 = DateTime(now.year, 1, 1);
  return ((now.difference(jan1).inDays + jan1.weekday - 1) / 7).ceil();
}

/// Midnight at the start of this week's Monday (local time).
DateTime _weekStart() {
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  return DateTime(monday.year, monday.month, monday.day);
}

/// Midnight at the start of the 1st of this month (local time).
DateTime _monthStart() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
}

// ---------------------------------------------------------------------------
// Rotation logic
// ---------------------------------------------------------------------------

/// Pick `count` indices from a pool of `poolSize`, deterministic by `seed`.
List<int> _rotateIndices(int seed, int poolSize, int count) {
  final indices = <int>{};
  for (var offset = 0; indices.length < count && offset < poolSize; offset++) {
    indices.add((seed + offset * 3) % poolSize);
  }
  return indices.toList();
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class _FirstStepsCacheSnapshot {
  final bool eligible;
  final Set<BeginnerQuestId> completed;
  final bool bundleClaimed;
  const _FirstStepsCacheSnapshot({
    required this.eligible,
    required this.completed,
    required this.bundleClaimed,
  });
}

const _completedKey = 'quests_completed_v2';
const _firstStepsCompletedKey = 'first_steps_completed_v1';
const _firstStepsBundleClaimedKey = 'first_steps_bundle_claimed_v1';
const _firstStepsEligibleKey = 'first_steps_eligible_v1';
const _tierUpsLogKey = 'tier_ups_log_v1';
const _collectionVisitDatesKey = 'collection_visit_dates_v1';
const _relatedDuaSavesLogKey = 'related_dua_saves_log_v1';

class QuestsNotifier extends StateNotifier<QuestsState> {
  QuestsNotifier() : super(const QuestsState()) {
    _load();
  }

  /// Re-runs `_load()`. Called from app session after a fresh sign-in /
  /// hydration so that newly synced First Steps state lands in the UI.
  Future<void> reload() => _load();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    // Load completed set
    final raw = prefs.getString(_completedKey);
    Set<String> completedIds = {};
    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List).cast<String>();
        completedIds = list.toSet();
      } catch (_) {}
    }

    // ── First Steps load ─────────────────────────────────────────────────────
    final firstStepsState = await _loadFirstStepsFromCache(prefs);

    final today = _todayLabel();
    final week = _weekLabel();
    final month = _monthLabel();

    // ── Rotate daily: pick 3 from 9 ──────────────────────────────────────────
    final dailyIndices = _rotateIndices(_dayOfYear(), _dailyPool.length, 3);
    final daily = dailyIndices.map((i) {
      final t = _dailyPool[i];
      return Quest(
        id: 'daily_${t.poolIndex}_$today',
        cadence: QuestCadence.daily,
        title: t.title,
        description: t.description,
        icon: t.icon,
        xpReward: t.xpReward,
        tokenReward: t.tokenReward,
        scrollReward: t.scrollReward,
        poolIndex: t.poolIndex,
        target: t.target,
      );
    }).toList();

    // ── Rotate weekly: pick 3 from 7 ─────────────────────────────────────────
    final weekIndices = _rotateIndices(_isoWeekNumber(), _weeklyPool.length, 3);
    final weekly = weekIndices.map((i) {
      final t = _weeklyPool[i];
      return Quest(
        id: 'weekly_${t.poolIndex}_$week',
        cadence: QuestCadence.weekly,
        title: t.title,
        description: t.description,
        icon: t.icon,
        xpReward: t.xpReward,
        tokenReward: t.tokenReward,
        scrollReward: t.scrollReward,
        poolIndex: t.poolIndex,
        target: t.target,
      );
    }).toList();

    // ── Rotate monthly: pick 3 from 8 ────────────────────────────────────────
    final monthIndices = _rotateIndices(
      DateTime.now().month,
      _monthlyPool.length,
      3,
    );
    final monthly = monthIndices.map((i) {
      final t = _monthlyPool[i];
      return Quest(
        id: 'monthly_${t.poolIndex}_$month',
        cadence: QuestCadence.monthly,
        title: t.title,
        description: t.description,
        icon: t.icon,
        xpReward: t.xpReward,
        tokenReward: t.tokenReward,
        scrollReward: t.scrollReward,
        poolIndex: t.poolIndex,
        target: t.target,
      );
    }).toList();

    state = state.copyWith(
      daily: daily,
      weekly: weekly,
      monthly: monthly,
      completedIds: completedIds,
      loaded: true,
      firstStepsEligible: firstStepsState.eligible,
      firstStepsCompleted: firstStepsState.completed,
      firstStepsBundleClaimed: firstStepsState.bundleClaimed,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // First Steps: load / persist
  // ─────────────────────────────────────────────────────────────────────────────

  Future<_FirstStepsCacheSnapshot> _loadFirstStepsFromCache(
    SharedPreferences prefs,
  ) async {
    final eligibleKey =
        supabaseSyncService.scopedKey(_firstStepsEligibleKey);
    final completedKey =
        supabaseSyncService.scopedKey(_firstStepsCompletedKey);
    final bundleKey =
        supabaseSyncService.scopedKey(_firstStepsBundleClaimedKey);

    final eligible = prefs.getBool(eligibleKey) ?? false;
    final bundleClaimed = prefs.getBool(bundleKey) ?? false;

    final completedRaw = prefs.getString(completedKey);
    final Set<BeginnerQuestId> completed = {};
    if (completedRaw != null) {
      try {
        final list = (jsonDecode(completedRaw) as List).cast<String>();
        for (final k in list) {
          final id = BeginnerQuestIdX.fromKey(k);
          if (id != null) completed.add(id);
        }
      } catch (_) {}
    }

    return _FirstStepsCacheSnapshot(
      eligible: eligible,
      completed: completed,
      bundleClaimed: bundleClaimed,
    );
  }

  Future<void> _persistFirstSteps({
    required Set<BeginnerQuestId> completed,
    required bool bundleClaimed,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      supabaseSyncService.scopedKey(_firstStepsCompletedKey),
      jsonEncode(completed.map((e) => e.key).toList()),
    );
    await prefs.setBool(
      supabaseSyncService.scopedKey(_firstStepsBundleClaimedKey),
      bundleClaimed,
    );

    // Mirror to Supabase (best-effort).
    final userId = supabaseSyncService.currentUserId;
    if (userId != null) {
      await supabaseSyncService.upsertRow('user_profiles', userId, {
        'id': userId,
        'first_steps_completed': completed.map((e) => e.key).toList(),
        'first_steps_bundle_claimed': bundleClaimed,
      });
    }
  }

  Future<void> _markBeginnerComplete(BeginnerQuestId id) async {
    if (!state.firstStepsEligible) return;
    if (state.firstStepsCompleted.contains(id)) return;

    final quest = beginnerQuests.firstWhere((q) => q.id == id);

    // Grant rewards first.
    if (quest.xpReward > 0) await awardXp(quest.xpReward);
    if (quest.tokenReward > 0) await earnTokens(quest.tokenReward);
    if (quest.scrollReward > 0) await earnTierUpScrolls(quest.scrollReward);

    final updatedCompleted = {...state.firstStepsCompleted, id};

    // Bundle bonus when all 3 are done and not yet claimed.
    bool bundleClaimed = state.firstStepsBundleClaimed;
    FirstStepsBundleCelebration? celebration;
    if (updatedCompleted.length >= beginnerQuests.length && !bundleClaimed) {
      if (firstStepsBundleXp > 0) await awardXp(firstStepsBundleXp);
      if (firstStepsBundleTokens > 0) await earnTokens(firstStepsBundleTokens);
      if (firstStepsBundleScrolls > 0) {
        await earnTierUpScrolls(firstStepsBundleScrolls);
      }
      bundleClaimed = true;
      celebration = const FirstStepsBundleCelebration(
        xp: firstStepsBundleXp,
        tokens: firstStepsBundleTokens,
        scrolls: firstStepsBundleScrolls,
      );
    }

    state = state.copyWith(
      firstStepsCompleted: updatedCompleted,
      firstStepsBundleClaimed: bundleClaimed,
      pendingBundleCelebration: celebration,
    );

    await _persistFirstSteps(
      completed: updatedCompleted,
      bundleClaimed: bundleClaimed,
    );
  }

  /// UI calls this after presenting the bundle celebration overlay.
  void clearPendingBundleCelebration() {
    if (state.pendingBundleCelebration == null) return;
    state = state.copyWith(clearPendingBundleCelebration: true);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Core completion
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> completeQuest(String id) async {
    if (state.completedIds.contains(id)) return;

    final quest = state.all.firstWhere(
      (q) => q.id == id,
      orElse: () => throw StateError('Quest not found: $id'),
    );

    final updated = {...state.completedIds, id};
    state = state.copyWith(completedIds: updated);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_completedKey, jsonEncode(updated.toList()));

    if (quest.xpReward > 0) await awardXp(quest.xpReward);
    if (quest.tokenReward > 0) await earnTokens(quest.tokenReward);
    if (quest.scrollReward > 0) await earnTierUpScrolls(quest.scrollReward);
  }

  /// Try to complete a quest by pool index + cadence if it's active today.
  Future<void> _tryComplete(QuestCadence cadence, int poolIndex) async {
    final String prefix;
    final String datePart;
    final List<Quest> pool;

    switch (cadence) {
      case QuestCadence.daily:
        prefix = 'daily';
        datePart = _todayLabel();
        pool = state.daily;
      case QuestCadence.weekly:
        prefix = 'weekly';
        datePart = _weekLabel();
        pool = state.weekly;
      case QuestCadence.monthly:
        prefix = 'monthly';
        datePart = _monthLabel();
        pool = state.monthly;
    }

    final id = '${prefix}_${poolIndex}_$datePart';
    if (pool.any((q) => q.id == id)) {
      await completeQuest(id);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Daily quest triggers — one per pool slot, all unique single-shot
  // ─────────────────────────────────────────────────────────────────────────────

  /// Daily pool 0. Also marks the First Steps "Reflect on a Feeling" quest.
  Future<void> onReflectCompleted() async {
    await _tryComplete(QuestCadence.daily, 0);
    await _markBeginnerComplete(BeginnerQuestId.firstReflect);
  }

  /// Daily pool 1. Also marks the First Steps "Build Your Own Dua" quest.
  Future<void> onBuiltDuaCompleted() async {
    await _tryComplete(QuestCadence.daily, 1);
    await _markBeginnerComplete(BeginnerQuestId.firstBuiltDua);
  }

  /// Daily pool 2. Also tracks distinct visit days for the weekly quest.
  Future<void> onCollectionVisited() async {
    await _tryComplete(QuestCadence.daily, 2);
    await _recordCollectionVisitDay();
  }

  /// Daily pool 3.
  Future<void> onJournalVisited() async {
    await _tryComplete(QuestCadence.daily, 3);
  }

  /// Daily pool 4. Also marks the First Steps "Your First Check-In" quest.
  Future<void> onMuhasabahCompleted() async {
    await _tryComplete(QuestCadence.daily, 4);
    await _markBeginnerComplete(BeginnerQuestId.firstMuhasabah);
  }

  /// Daily pool 5. Fires when the user hearts a related dua (not when they
  /// un-heart it). The caller is responsible for not firing on un-save.
  /// Also appends to a local log used by weekly + monthly threshold quests.
  Future<void> onDuaSaved() async {
    await _tryComplete(QuestCadence.daily, 5);
    await _recordRelatedDuaSaveEvent();
  }

  /// Daily pool 6.
  Future<void> onNameExplored() async {
    await _tryComplete(QuestCadence.daily, 6);
  }

  /// Daily pool 7. Fired when a card is engaged from a check-in pull.
  Future<void> onNameDiscovered() async {
    await _tryComplete(QuestCadence.daily, 7);
  }

  /// Daily pool 8. Fired on tier-up (manual via scrolls or auto via gacha).
  /// Also appends to a local tier-up log used by the weekly threshold quest.
  Future<void> onCardTieredUp() async {
    await _tryComplete(QuestCadence.daily, 8);
    await _recordTierUpEvent();
  }

  /// No-op stub. Discovery Quiz isn't in the active quest pools, but the
  /// hook is kept defined so future achievements / First Steps can wire it.
  Future<void> onDiscoveryQuizCompleted() async {
    // intentionally empty
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Threshold quest progress (weekly + monthly)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Update progress for a threshold quest and complete if target reached.
  Future<void> _updateProgress(QuestCadence cadence, int poolIndex, int count) async {
    final String prefix;
    final String datePart;
    final List<Quest> pool;

    switch (cadence) {
      case QuestCadence.daily:
        prefix = 'daily';
        datePart = _todayLabel();
        pool = state.daily;
      case QuestCadence.weekly:
        prefix = 'weekly';
        datePart = _weekLabel();
        pool = state.weekly;
      case QuestCadence.monthly:
        prefix = 'monthly';
        datePart = _monthLabel();
        pool = state.monthly;
    }

    final id = '${prefix}_${poolIndex}_$datePart';
    final quest = pool.cast<Quest?>().firstWhere((q) => q?.id == id, orElse: () => null);
    if (quest == null) return;

    final clamped = count.clamp(0, quest.target > 0 ? quest.target : count);
    final updated = {...state.progress, id: clamped};
    state = state.copyWith(progress: updated);

    if (quest.target > 0 && clamped >= quest.target) {
      await completeQuest(id);
    }
  }

  // ── Weekly thresholds (one per weekly pool slot) ───────────────────────────

  /// Weekly pool 0: Reflect 3 times this week
  Future<void> updateWeeklyReflections(int count) =>
      _updateProgress(QuestCadence.weekly, 0, count);

  /// Weekly pool 1: Build 2 personal duas this week
  Future<void> updateWeeklyBuiltDuas(int count) =>
      _updateProgress(QuestCadence.weekly, 1, count);

  /// Weekly pool 2: Discover 3 new Names this week
  Future<void> updateWeeklyDiscoveries(int count) =>
      _updateProgress(QuestCadence.weekly, 2, count);

  /// Weekly pool 3: Complete 5 Muhasabahs this week
  Future<void> updateWeeklyMuhasabahs(int count) =>
      _updateProgress(QuestCadence.weekly, 3, count);

  /// Weekly pool 4: Visit Collection 3 different days this week
  Future<void> updateWeeklyCollectionVisits(int count) =>
      _updateProgress(QuestCadence.weekly, 4, count);

  /// Weekly pool 5: Save 3 related duas this week
  Future<void> updateWeeklySavedRelatedDuas(int count) =>
      _updateProgress(QuestCadence.weekly, 5, count);

  /// Weekly pool 6: Tier up 2 cards this week
  Future<void> updateWeeklyTierUps(int count) =>
      _updateProgress(QuestCadence.weekly, 6, count);

  // ── Monthly thresholds (one per monthly pool slot) ─────────────────────────

  /// Monthly pool 0: Discover 10 new Names this month
  Future<void> updateMonthlyDiscoveries(int count) =>
      _updateProgress(QuestCadence.monthly, 0, count);

  /// Monthly pool 1: Reflect 15 times this month
  Future<void> updateMonthlyReflections(int count) =>
      _updateProgress(QuestCadence.monthly, 1, count);

  /// Monthly pool 2: Build 5 personal duas this month
  Future<void> updateMonthlyBuiltDuas(int count) =>
      _updateProgress(QuestCadence.monthly, 2, count);

  /// Monthly pool 3: Unlock 3 Silver Names this month
  Future<void> updateMonthlySilverNames(int count) =>
      _updateProgress(QuestCadence.monthly, 3, count);

  /// Monthly pool 4: Maintain a 20-day streak
  Future<void> updateMonthlyStreak(int streakCount) =>
      _updateProgress(QuestCadence.monthly, 4, streakCount);

  /// Monthly pool 5: Complete 20 Muhasabahs this month
  Future<void> updateMonthlyMuhasabahs(int count) =>
      _updateProgress(QuestCadence.monthly, 5, count);

  /// Monthly pool 6: Save 10 related duas this month
  Future<void> updateMonthlySavedRelatedDuas(int count) =>
      _updateProgress(QuestCadence.monthly, 6, count);

  /// Monthly pool 7: Unlock 1 Gold Name this month
  Future<void> updateMonthlyGoldNames(int count) =>
      _updateProgress(QuestCadence.monthly, 7, count);

  // ─────────────────────────────────────────────────────────────────────────────
  // Local trackers — counters that aren't derivable from existing data sources
  // ─────────────────────────────────────────────────────────────────────────────

  /// Append a tier-up event timestamp. Used by `tierUpsThisWeek()` and
  /// `tierUpsThisMonth()` to count events without scanning the full
  /// card collection (where tier-change timestamps aren't tracked).
  Future<void> _recordTierUpEvent() async {
    final prefs = await SharedPreferences.getInstance();
    final key = supabaseSyncService.scopedKey(_tierUpsLogKey);
    final raw = prefs.getString(key);
    final List<String> log = raw == null
        ? <String>[]
        : (jsonDecode(raw) as List).cast<String>();
    log.add(DateTime.now().toIso8601String());
    // Cap log size to avoid unbounded growth — 90 days of tier-ups is plenty
    // for any monthly window.
    if (log.length > 200) {
      log.removeRange(0, log.length - 200);
    }
    await prefs.setString(key, jsonEncode(log));
  }

  /// Count tier-up events whose timestamp falls in the current ISO week.
  Future<int> tierUpsThisWeek() async {
    return _countLoggedEventsSince(_tierUpsLogKey, _weekStart());
  }

  /// Count tier-up events whose timestamp falls in the current calendar month.
  Future<int> tierUpsThisMonth() async {
    return _countLoggedEventsSince(_tierUpsLogKey, _monthStart());
  }

  /// Append a related-dua save event timestamp. Used because the
  /// `SavedRelatedDua` model has no `savedAt` field of its own.
  Future<void> _recordRelatedDuaSaveEvent() async {
    final prefs = await SharedPreferences.getInstance();
    final key = supabaseSyncService.scopedKey(_relatedDuaSavesLogKey);
    final raw = prefs.getString(key);
    final List<String> log = raw == null
        ? <String>[]
        : (jsonDecode(raw) as List).cast<String>();
    log.add(DateTime.now().toIso8601String());
    if (log.length > 200) {
      log.removeRange(0, log.length - 200);
    }
    await prefs.setString(key, jsonEncode(log));
  }

  Future<int> relatedDuaSavesThisWeek() async {
    return _countLoggedEventsSince(_relatedDuaSavesLogKey, _weekStart());
  }

  Future<int> relatedDuaSavesThisMonth() async {
    return _countLoggedEventsSince(_relatedDuaSavesLogKey, _monthStart());
  }

  /// Record that the user opened the Collection on `today`. The set of
  /// distinct visit dates is then read by the weekly "visit 3 days" quest.
  Future<void> _recordCollectionVisitDay() async {
    final prefs = await SharedPreferences.getInstance();
    final key = supabaseSyncService.scopedKey(_collectionVisitDatesKey);
    final raw = prefs.getString(key);
    final Set<String> dates = raw == null
        ? <String>{}
        : (jsonDecode(raw) as List).cast<String>().toSet();
    dates.add(_todayLabel());
    // Keep at most 60 entries (≈ 2 months) so the set doesn't grow forever.
    if (dates.length > 60) {
      final sorted = dates.toList()..sort();
      dates
        ..clear()
        ..addAll(sorted.sublist(sorted.length - 60));
    }
    await prefs.setString(key, jsonEncode(dates.toList()));
  }

  /// Count distinct collection visit dates in the current ISO week.
  Future<int> collectionVisitDaysThisWeek() async {
    final prefs = await SharedPreferences.getInstance();
    final key = supabaseSyncService.scopedKey(_collectionVisitDatesKey);
    final raw = prefs.getString(key);
    if (raw == null) return 0;
    final dates = (jsonDecode(raw) as List).cast<String>();
    final weekStart = _weekStart();
    return dates.where((d) {
      final parsed = DateTime.tryParse(d);
      return parsed != null && !parsed.isBefore(weekStart);
    }).length;
  }

  Future<int> _countLoggedEventsSince(String baseKey, DateTime since) async {
    final prefs = await SharedPreferences.getInstance();
    final key = supabaseSyncService.scopedKey(baseKey);
    final raw = prefs.getString(key);
    if (raw == null) return 0;
    final log = (jsonDecode(raw) as List).cast<String>();
    return log.where((iso) {
      final parsed = DateTime.tryParse(iso);
      return parsed != null && !parsed.isBefore(since);
    }).length;
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final questsProvider =
    StateNotifierProvider<QuestsNotifier, QuestsState>((ref) {
  return QuestsNotifier();
});

// ---------------------------------------------------------------------------
// First Steps cache hydration from Supabase
// ---------------------------------------------------------------------------

/// Fetches `user_profiles.created_at` + first_steps_* columns and writes
/// the eligibility flag and completion state into SharedPreferences (scoped
/// to the current user). Called from app session hydration after sign-in.
///
/// Eligibility is `created_at >= firstStepsShipDate`, computed once and
/// cached locally — accounts created before the ship date never see the
/// First Steps section regardless of any later state.
Future<void> syncFirstStepsFromSupabase() async {
  final userId = supabaseSyncService.currentUserId;
  if (userId == null) return;

  try {
    final row = await Supabase.instance.client
        .from('user_profiles')
        .select('created_at, first_steps_completed, first_steps_bundle_claimed')
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return;

    final createdAtRaw = row['created_at'] as String?;
    if (createdAtRaw == null) return;
    final createdAt = DateTime.tryParse(createdAtRaw);
    if (createdAt == null) return;

    final eligible = !createdAt.toUtc().isBefore(firstStepsShipDate);

    final completedRaw = row['first_steps_completed'];
    final completedKeys = completedRaw is List
        ? completedRaw.whereType<String>().toList()
        : <String>[];
    final bundleClaimed = row['first_steps_bundle_claimed'] == true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      supabaseSyncService.scopedKey(_firstStepsEligibleKey),
      eligible,
    );
    await prefs.setString(
      supabaseSyncService.scopedKey(_firstStepsCompletedKey),
      jsonEncode(completedKeys),
    );
    await prefs.setBool(
      supabaseSyncService.scopedKey(_firstStepsBundleClaimedKey),
      bundleClaimed,
    );
  } catch (_) {
    // Best-effort — fall back to whatever's already cached locally.
  }
}

// ---------------------------------------------------------------------------
// Threshold quest progress recompute
// ---------------------------------------------------------------------------

/// Reads every data source the threshold quests depend on, derives current
/// counts for the active week / month, and feeds them into the corresponding
/// `update*` methods on `QuestsNotifier`.
///
/// Called from `QuestsScreen` on mount (and after hydration). Without this
/// pattern, weekly / monthly progress would only ever land in the in-memory
/// `QuestsState.progress` map at the moment a single trigger fires —
/// meaning a user who hasn't opened the quests page for a few days would see
/// stale "0/N" bars even after doing the underlying actions.
///
/// Cheap to call: each lookup is either a SharedPreferences read or an
/// in-memory provider state read. Idempotent.
Future<void> recomputeQuestProgress(WidgetRef ref) async {
  final notifier = ref.read(questsProvider.notifier);
  final weekStart = _weekStart();
  final monthStart = _monthStart();

  // ── Reflections (week + month) ───────────────────────────────────────────
  final reflectState = ref.read(reflectProvider);
  int reflectionsThisWeek = 0;
  int reflectionsThisMonth = 0;
  for (final r in reflectState.savedReflections) {
    final t = DateTime.tryParse(r.date);
    if (t == null) continue;
    if (!t.isBefore(weekStart)) reflectionsThisWeek++;
    if (!t.isBefore(monthStart)) reflectionsThisMonth++;
  }
  await notifier.updateWeeklyReflections(reflectionsThisWeek);
  await notifier.updateMonthlyReflections(reflectionsThisMonth);

  // ── Built duas (week + month) ────────────────────────────────────────────
  final duasState = ref.read(duasProvider);
  int builtDuasThisWeek = 0;
  int builtDuasThisMonth = 0;
  for (final d in duasState.savedBuiltDuas) {
    final t = DateTime.tryParse(d.savedAt);
    if (t == null) continue;
    if (!t.isBefore(weekStart)) builtDuasThisWeek++;
    if (!t.isBefore(monthStart)) builtDuasThisMonth++;
  }
  await notifier.updateWeeklyBuiltDuas(builtDuasThisWeek);
  await notifier.updateMonthlyBuiltDuas(builtDuasThisMonth);

  // ── Discoveries from card collection (week + month) ──────────────────────
  final collection = await getCardCollection();
  int discoveriesThisWeek = 0;
  int discoveriesThisMonth = 0;
  for (final entry in collection.discoveryDates.entries) {
    final t = DateTime.tryParse(entry.value);
    if (t == null) continue;
    if (!t.isBefore(weekStart)) discoveriesThisWeek++;
    if (!t.isBefore(monthStart)) discoveriesThisMonth++;
  }
  await notifier.updateWeeklyDiscoveries(discoveriesThisWeek);
  await notifier.updateMonthlyDiscoveries(discoveriesThisMonth);

  // ── Silver / Gold totals (cumulative, not month-bounded) ─────────────────
  // The current schema doesn't track tier-change timestamps so we can't
  // restrict these to "this month" — we use the running totals as a
  // best-effort approximation. The user only ever benefits.
  await notifier.updateMonthlySilverNames(collection.totalSilver);
  await notifier.updateMonthlyGoldNames(collection.totalGold);

  // ── Muhasabahs from check-in history (week + month) ──────────────────────
  final history = await getCheckinHistory();
  int muhasabahsThisWeek = 0;
  int muhasabahsThisMonth = 0;
  for (final r in history) {
    // CheckInRecord.date is YYYY-MM-DD; parse as local midnight.
    final t = DateTime.tryParse(r.date);
    if (t == null) continue;
    if (!t.isBefore(weekStart)) muhasabahsThisWeek++;
    if (!t.isBefore(monthStart)) muhasabahsThisMonth++;
  }
  await notifier.updateWeeklyMuhasabahs(muhasabahsThisWeek);
  await notifier.updateMonthlyMuhasabahs(muhasabahsThisMonth);

  // ── Streak (just push current value at the monthly target) ───────────────
  final streak = await getStreak();
  await notifier.updateMonthlyStreak(streak.currentStreak);

  // ── Local-log derived counters ───────────────────────────────────────────
  await notifier.updateWeeklyTierUps(await notifier.tierUpsThisWeek());
  await notifier.updateWeeklyCollectionVisits(
    await notifier.collectionVisitDaysThisWeek(),
  );
  await notifier.updateWeeklySavedRelatedDuas(
    await notifier.relatedDuaSavesThisWeek(),
  );
  await notifier.updateMonthlySavedRelatedDuas(
    await notifier.relatedDuaSavesThisMonth(),
  );
}
