import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/xp_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Cadence
// ---------------------------------------------------------------------------

enum QuestCadence { daily, weekly, monthly }

// ---------------------------------------------------------------------------
// Quest definition
// ---------------------------------------------------------------------------

class Quest {
  final String id; // date-stable, e.g. "daily_checkin_2025-04-05"
  final QuestCadence cadence;
  final String title;
  final String description;
  final String iconName; // maps to icon in UI
  final int xpReward;
  final int tokenReward;

  const Quest({
    required this.id,
    required this.cadence,
    required this.title,
    required this.description,
    required this.iconName,
    required this.xpReward,
    this.tokenReward = 0,
  });
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class QuestsState {
  final List<Quest> daily;
  final List<Quest> weekly;
  final List<Quest> monthly;
  final Set<String> completedIds;
  final bool loaded;

  const QuestsState({
    this.daily = const [],
    this.weekly = const [],
    this.monthly = const [],
    this.completedIds = const {},
    this.loaded = false,
  });

  List<Quest> get all => [...daily, ...weekly, ...monthly];

  bool isCompleted(String id) => completedIds.contains(id);

  int get dailyCompletedCount => daily.where((q) => completedIds.contains(q.id)).length;

  QuestsState copyWith({
    List<Quest>? daily,
    List<Quest>? weekly,
    List<Quest>? monthly,
    Set<String>? completedIds,
    bool? loaded,
  }) {
    return QuestsState(
      daily: daily ?? this.daily,
      weekly: weekly ?? this.weekly,
      monthly: monthly ?? this.monthly,
      completedIds: completedIds ?? this.completedIds,
      loaded: loaded ?? this.loaded,
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
  // ISO week: Monday-based
  final monday = n.subtract(Duration(days: n.weekday - 1));
  return '${monday.year}-W${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
}

String _monthLabel() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

const _completedKey = 'quests_completed_v2';

class QuestsNotifier extends StateNotifier<QuestsState> {
  QuestsNotifier(Ref ref) : super(const QuestsState()) {
    _load();
  }

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

    final today = _todayLabel();
    final week = _weekLabel();
    final month = _monthLabel();

    // ── Daily quests ──────────────────────────────────────────────────────────

    final daily = <Quest>[
      Quest(
        id: 'daily_checkin_$today',
        cadence: QuestCadence.daily,
        title: 'Complete today\'s muhasabah',
        description: 'Do your daily check-in and receive your Name of Allah.',
        iconName: 'checkin',
        xpReward: 20,
      ),
      Quest(
        id: 'daily_dua_$today',
        cadence: QuestCadence.daily,
        title: _timeDuaTitle(),
        description: _timeDuaDescription(),
        iconName: 'dua',
        xpReward: 10,
      ),
      Quest(
        id: 'daily_reflect_$today',
        cadence: QuestCadence.daily,
        title: 'Write a reflection',
        description: 'Open Reflect and share what is on your heart today.',
        iconName: 'reflect',
        xpReward: 15,
      ),
    ];

    // ── Weekly quests ─────────────────────────────────────────────────────────

    final weekly = <Quest>[
      Quest(
        id: 'weekly_checkins_$week',
        cadence: QuestCadence.weekly,
        title: 'Complete 5 check-ins this week',
        description: 'Build your habit of daily muhasabah — 5 out of 7 days.',
        iconName: 'streak',
        xpReward: 50,
        tokenReward: 3,
      ),
      Quest(
        id: 'weekly_built_dua_$week',
        cadence: QuestCadence.weekly,
        title: 'Build a personal dua',
        description: 'Use the Build a Dua feature to craft a dua for your specific need.',
        iconName: 'build_dua',
        xpReward: 30,
        tokenReward: 2,
      ),
    ];

    // ── Monthly quest ─────────────────────────────────────────────────────────

    final monthly = <Quest>[
      Quest(
        id: 'monthly_dedication_$month',
        cadence: QuestCadence.monthly,
        title: 'Maintain a 20-day streak',
        description: 'Check in 20 or more days this month to show true dedication.',
        iconName: 'fire',
        xpReward: 150,
        tokenReward: 10,
      ),
    ];

    state = state.copyWith(
      daily: daily,
      weekly: weekly,
      monthly: monthly,
      completedIds: completedIds,
      loaded: true,
    );
  }

  /// Mark a quest complete, award XP and tokens, persist.
  Future<void> completeQuest(String id) async {
    if (state.completedIds.contains(id)) return;

    final quest = state.all.firstWhere((q) => q.id == id, orElse: () => throw StateError('Quest not found: $id'));

    final updated = {...state.completedIds, id};
    state = state.copyWith(completedIds: updated);

    // Persist
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_completedKey, jsonEncode(updated.toList()));

    // Award XP
    if (quest.xpReward > 0) {
      await awardXp(quest.xpReward);
    }

    // Award tokens
    if (quest.tokenReward > 0) {
      await earnTokens(quest.tokenReward);
    }
  }

  /// Called externally when the user completes their daily check-in.
  Future<void> onCheckinCompleted() async {
    final today = _todayLabel();
    final id = 'daily_checkin_$today';
    if (state.daily.any((q) => q.id == id)) {
      await completeQuest(id);
    }
  }

  /// Called externally when the user completes a reflection.
  Future<void> onReflectCompleted() async {
    final today = _todayLabel();
    final id = 'daily_reflect_$today';
    if (state.daily.any((q) => q.id == id)) {
      await completeQuest(id);
    }
  }

  /// Called externally when user recites / opens the daily dua.
  Future<void> onDuaRecited() async {
    final today = _todayLabel();
    final id = 'daily_dua_$today';
    if (state.daily.any((q) => q.id == id)) {
      await completeQuest(id);
    }
  }

  /// Called externally when the user completes a built dua this week.
  Future<void> onBuiltDuaCompleted() async {
    final week = _weekLabel();
    final id = 'weekly_built_dua_$week';
    if (state.weekly.any((q) => q.id == id)) {
      await completeQuest(id);
    }
  }

  /// Called externally with current week's check-in count.
  Future<void> updateWeeklyCheckins(int count) async {
    if (count >= 5) {
      final week = _weekLabel();
      final id = 'weekly_checkins_$week';
      if (state.weekly.any((q) => q.id == id)) {
        await completeQuest(id);
      }
    }
  }

  /// Called externally with current streak count.
  Future<void> updateMonthlyStreak(int streakCount) async {
    if (streakCount >= 20) {
      final month = _monthLabel();
      final id = 'monthly_dedication_$month';
      if (state.monthly.any((q) => q.id == id)) {
        await completeQuest(id);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _timeDuaTitle() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Recite a morning dua';
    if (h < 17) return 'Recite an afternoon dua';
    return 'Recite an evening dua';
  }

  String _timeDuaDescription() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Open the Duas tab and recite a morning remembrance.';
    if (h < 17) return 'Take a midday moment — recite a dua from the Duas tab.';
    return 'Wind down your evening with a dua from the Duas tab.';
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final questsProvider =
    StateNotifierProvider<QuestsNotifier, QuestsState>((ref) {
  ref.watch(duasProvider);
  return QuestsNotifier(ref);
});
