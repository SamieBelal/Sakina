import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    title: 'Review a past reflection',
    description: 'Revisit a saved entry in your Journal.',
    icon: Icons.bookmark_rounded,
    xpReward: 10, tokenReward: 3,
  ),
  QuestTemplate(
    poolIndex: 4,
    title: 'Browse the duas library',
    description: 'Explore duas by category in the Duas tab.',
    icon: Icons.menu_book_rounded,
    xpReward: 10, tokenReward: 3,
  ),
  QuestTemplate(
    poolIndex: 5,
    title: 'Share a reflection',
    description: 'Share your result card with someone.',
    icon: Icons.share_rounded,
    xpReward: 15, tokenReward: 5,
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
    title: 'Save a dua',
    description: 'Save a built dua to your personal library.',
    icon: Icons.favorite_rounded,
    xpReward: 10, tokenReward: 3,
  ),
  QuestTemplate(
    poolIndex: 8,
    title: 'Reflect on gratitude',
    description: 'Write a reflection about something you\'re grateful for.',
    icon: Icons.wb_sunny_rounded,
    xpReward: 15, tokenReward: 5,
  ),
  QuestTemplate(
    poolIndex: 9,
    title: 'Complete the Discovery Quiz',
    description: 'Take the personality quiz to find your anchor Names.',
    icon: Icons.psychology_rounded,
    xpReward: 20, tokenReward: 5,
  ),
];

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
    title: 'Share 2 reflections',
    description: 'Share your reflection cards twice.',
    icon: Icons.share_rounded,
    xpReward: 30, tokenReward: 2, scrollReward: 1,
    target: 2,
  ),
  QuestTemplate(
    poolIndex: 4,
    title: 'Visit Collection 3 days',
    description: 'Open your Collection on 3 different days.',
    icon: Icons.grid_view_rounded,
    xpReward: 40, tokenReward: 3, scrollReward: 2,
    target: 3,
  ),
];

const _monthlyPool = <QuestTemplate>[
  QuestTemplate(
    poolIndex: 0,
    title: 'Discover 10 Names',
    description: 'Grow your collection to 10+ discovered Names.',
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

    // ── Rotate daily: pick 3 from 10 ─────────────────────────────────────────
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

    // ── Rotate weekly: pick 2 from 5 ─────────────────────────────────────────
    final weekIndices = _rotateIndices(_isoWeekNumber(), _weeklyPool.length, 2);
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

    // ── Rotate monthly: pick 1 from 5 ────────────────────────────────────────
    final monthIndex = DateTime.now().month % _monthlyPool.length;
    final mt = _monthlyPool[monthIndex];
    final monthly = [
      Quest(
        id: 'monthly_${mt.poolIndex}_$month',
        cadence: QuestCadence.monthly,
        title: mt.title,
        description: mt.description,
        icon: mt.icon,
        xpReward: mt.xpReward,
        tokenReward: mt.tokenReward,
        scrollReward: mt.scrollReward,
        poolIndex: mt.poolIndex,
        target: mt.target,
      ),
    ];

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
  // Daily quest triggers
  // ─────────────────────────────────────────────────────────────────────────────

  /// Pool 0 & 8: Complete a Reflection / Reflect on gratitude.
  /// Also marks the First Steps "Reflect on a Feeling" beginner quest.
  Future<void> onReflectCompleted() async {
    await _tryComplete(QuestCadence.daily, 0);
    await _tryComplete(QuestCadence.daily, 8);
    await _markBeginnerComplete(BeginnerQuestId.firstReflect);
  }

  /// Fired from the Muhasabah Ameen step. Triggers the same daily quests
  /// as a reflection (existing behavior) and marks the First Steps
  /// "Your First Check-In" beginner quest.
  Future<void> onMuhasabahCompleted() async {
    await _tryComplete(QuestCadence.daily, 0);
    await _tryComplete(QuestCadence.daily, 8);
    await _markBeginnerComplete(BeginnerQuestId.firstMuhasabah);
  }

  /// Pool 1: Build a personal dua.
  /// Also marks the First Steps "Build Your Own Dua" beginner quest.
  Future<void> onBuiltDuaCompleted() async {
    await _tryComplete(QuestCadence.daily, 1);
    await _markBeginnerComplete(BeginnerQuestId.firstBuiltDua);
  }

  /// Pool 2: Visit your Collection
  Future<void> onCollectionVisited() async {
    await _tryComplete(QuestCadence.daily, 2);
  }

  /// Pool 3: Review a past reflection (Journal visited)
  Future<void> onJournalVisited() async {
    await _tryComplete(QuestCadence.daily, 3);
  }

  /// Pool 4: Browse the duas library
  Future<void> onDuasBrowsed() async {
    await _tryComplete(QuestCadence.daily, 4);
  }

  /// Pool 5: Share a reflection
  Future<void> onReflectionShared() async {
    await _tryComplete(QuestCadence.daily, 5);
  }

  /// Pool 6: Explore a Name of Allah
  Future<void> onNameExplored() async {
    await _tryComplete(QuestCadence.daily, 6);
  }

  /// Pool 7: Save a dua
  Future<void> onDuaSaved() async {
    await _tryComplete(QuestCadence.daily, 7);
  }

  /// Pool 9: Complete the Discovery Quiz
  Future<void> onDiscoveryQuizCompleted() async {
    await _tryComplete(QuestCadence.daily, 9);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Weekly quest triggers (threshold-based)
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

  /// Pool 0: Reflect 3 times this week
  Future<void> updateWeeklyReflections(int count) async {
    await _updateProgress(QuestCadence.weekly, 0, count);
  }

  /// Pool 1: Build 2 personal duas this week
  Future<void> updateWeeklyBuiltDuas(int count) async {
    await _updateProgress(QuestCadence.weekly, 1, count);
  }

  /// Pool 2: Discover 3 new Names this week
  Future<void> updateWeeklyDiscoveries(int count) async {
    await _updateProgress(QuestCadence.weekly, 2, count);
  }

  /// Pool 3: Share 2 reflections this week
  Future<void> updateWeeklyShares(int count) async {
    await _updateProgress(QuestCadence.weekly, 3, count);
  }

  /// Pool 4: Visit Collection 3 days this week
  Future<void> updateWeeklyCollectionVisits(int count) async {
    await _updateProgress(QuestCadence.weekly, 4, count);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Monthly quest triggers (threshold-based)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Pool 0: Discover 10 Names this month
  Future<void> updateMonthlyDiscoveries(int count) async {
    await _updateProgress(QuestCadence.monthly, 0, count);
  }

  /// Pool 1: Reflect 15 times this month
  Future<void> updateMonthlyReflections(int count) async {
    await _updateProgress(QuestCadence.monthly, 1, count);
  }

  /// Pool 2: Build 5 personal duas this month
  Future<void> updateMonthlyBuiltDuas(int count) async {
    await _updateProgress(QuestCadence.monthly, 2, count);
  }

  /// Pool 3: Unlock 3 Silver Names this month
  Future<void> updateMonthlySilverNames(int count) async {
    await _updateProgress(QuestCadence.monthly, 3, count);
  }

  /// Pool 4: Maintain a 20-day streak
  Future<void> updateMonthlyStreak(int streakCount) async {
    await _updateProgress(QuestCadence.monthly, 4, streakCount);
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
