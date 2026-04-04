
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/constants/duas.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

enum DuaQuestType { built, browse, related }

class DuaQuest {
  final String id;
  final DuaQuestType type;
  final String title;
  final String arabic;
  final String reason;

  const DuaQuest({
    required this.id,
    required this.type,
    required this.title,
    required this.arabic,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'arabic': arabic,
        'reason': reason,
      };

  factory DuaQuest.fromJson(Map<String, dynamic> json) => DuaQuest(
        id: json['id'] as String,
        type: DuaQuestType.values.byName(json['type'] as String),
        title: json['title'] as String,
        arabic: json['arabic'] as String,
        reason: json['reason'] as String,
      );
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class QuestsState {
  final List<DuaQuest> quests;
  final Set<String> completedIds;
  final bool loaded;

  const QuestsState({
    this.quests = const [],
    this.completedIds = const {},
    this.loaded = false,
  });

  QuestsState copyWith({
    List<DuaQuest>? quests,
    Set<String>? completedIds,
    bool? loaded,
  }) {
    return QuestsState(
      quests: quests ?? this.quests,
      completedIds: completedIds ?? this.completedIds,
      loaded: loaded ?? this.loaded,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

const _completedKey = 'quests_completed';

class QuestsNotifier extends StateNotifier<QuestsState> {
  final Ref _ref;

  QuestsNotifier(this._ref) : super(const QuestsState()) {
    _loadQuests();
  }

  Future<void> _loadQuests() async {
    final prefs = await SharedPreferences.getInstance();

    // Restore completed IDs
    final completedJson = prefs.getStringList(_completedKey) ?? [];
    final completedIds = completedJson.toSet();

    final quests = <DuaQuest>[];

    // 1. Most recent saved built dua
    try {
      final builtDuas = _ref.read(duasProvider).savedBuiltDuas;
      if (builtDuas.isNotEmpty) {
        final recent = builtDuas.last;
        quests.add(DuaQuest(
          id: 'built_${recent.id}',
          type: DuaQuestType.built,
          title: 'Recite the dua you built for ${recent.need}',
          arabic: recent.arabic,
          reason: 'Revisiting your personal dua strengthens your connection.',
        ));
      }
    } catch (_) {}

    // 2. Browse dua matching time of day
    if (quests.length < 3) {
      try {
        final hour = DateTime.now().hour;
        final List<String> categories;
        if (hour < 12) {
          categories = ['morning', 'general'];
        } else if (hour < 17) {
          categories = ['afternoon', 'general'];
        } else {
          categories = ['evening', 'general'];
        }

        final timeDuas = browseDuas.where((d) =>
            categories.any((c) => d.category.toLowerCase().contains(c)));
        if (timeDuas.isNotEmpty) {
          final dua = timeDuas.first;
          quests.add(DuaQuest(
            id: 'browse_time_${dua.id}',
            type: DuaQuestType.browse,
            title: dua.title,
            arabic: dua.arabic,
            reason: _timeReason(hour),
          ));
        }
      } catch (_) {}
    }

    // 3. Random browse dua from anxiety/hope/gratitude categories
    if (quests.length < 3) {
      try {
        final fallbackCategories = ['anxiety', 'hope', 'gratitude'];
        final fallbackDuas = browseDuas.where((d) => fallbackCategories
            .any((c) => d.category.toLowerCase().contains(c)));
        if (fallbackDuas.isNotEmpty) {
          final list = fallbackDuas.toList()..shuffle();
          final dua = list.first;
          // Avoid duplicates
          if (!quests.any((q) => q.arabic == dua.arabic)) {
            quests.add(DuaQuest(
              id: 'browse_fallback_${dua.id}',
              type: DuaQuestType.browse,
              title: dua.title,
              arabic: dua.arabic,
              reason:
                  'A beautiful dua to carry with you through the day.',
            ));
          }
        }
      } catch (_) {}
    }

    state = state.copyWith(
      quests: quests,
      completedIds: completedIds,
      loaded: true,
    );
  }

  Future<void> completeQuest(String id) async {
    final updated = {...state.completedIds, id};
    state = state.copyWith(completedIds: updated);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_completedKey, updated.toList());
  }

  bool isCompleted(String id) => state.completedIds.contains(id);

  String _timeReason(int hour) {
    if (hour < 12) return 'Start your morning with this remembrance.';
    if (hour < 17) return 'A midday moment of reflection.';
    return 'Wind down your evening with this dua.';
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final questsProvider =
    StateNotifierProvider<QuestsNotifier, QuestsState>((ref) {
  // Read dependent providers so data is available
  ref.watch(duasProvider);
  ref.watch(reflectProvider);
  return QuestsNotifier(ref);
});
