import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/constants/daily_questions.dart';
import 'package:sakina/services/public_catalog_service.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/services/streak_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _dailyAnswerKey(String date) =>
    supabaseSyncService.scopedKey('daily_answer_$date');

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class DailyQuestionState {
  final DailyQuestion? question;
  final bool answered;
  final String? selectedAnswer;
  final String? resultName;
  final String? resultNameArabic;
  final bool loading;

  const DailyQuestionState({
    this.question,
    this.answered = false,
    this.selectedAnswer,
    this.resultName,
    this.resultNameArabic,
    this.loading = false,
  });

  DailyQuestionState copyWith({
    DailyQuestion? question,
    bool? answered,
    String? selectedAnswer,
    String? resultName,
    String? resultNameArabic,
    bool? loading,
  }) {
    return DailyQuestionState(
      question: question ?? this.question,
      answered: answered ?? this.answered,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      resultName: resultName ?? this.resultName,
      resultNameArabic: resultNameArabic ?? this.resultNameArabic,
      loading: loading ?? this.loading,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class DailyQuestionNotifier extends StateNotifier<DailyQuestionState> {
  DailyQuestionNotifier() : super(const DailyQuestionState()) {
    loadTodaysQuestion();
  }

  Future<void> onCatalogRefreshed() async {
    await loadTodaysQuestion();
  }

  Future<void> loadTodaysQuestion() async {
    final question = getTodaysDailyQuestion();
    state = state.copyWith(question: question);

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = await supabaseSyncService.migrateLegacyStringCache(
        prefs,
        'daily_answer_${todayKey()}',
      );

      if (savedJson != null) {
        final data = jsonDecode(savedJson) as Map<String, dynamic>;
        state = state.copyWith(
          answered: true,
          selectedAnswer: data['answer'] as String?,
          resultName: data['name'] as String?,
          resultNameArabic: data['nameArabic'] as String?,
        );
      }
    } catch (_) {}
  }

  Future<void> answerQuestion(String answer) async {
    state = state.copyWith(loading: true, selectedAnswer: answer);

    try {
      final questionText = state.question?.question ?? '';
      final response = await getDailyResponse([questionText, answer]);

      // No XP — only Muhasabah, quests, and streak milestones grant XP.
      await markActiveToday();

      state = state.copyWith(
        answered: true,
        resultName: response.name,
        resultNameArabic: response.nameArabic,
        loading: false,
      );

      // Persist today's answer
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _dailyAnswerKey(todayKey()),
        jsonEncode({
          'date': todayKey(),
          'questionId': state.question?.id,
          'answer': answer,
          'name': response.name,
          'nameArabic': response.nameArabic,
          'teaching': '',
          'duaArabic': '',
          'duaTransliteration': '',
          'duaTranslation': '',
        }),
      );

      // Sync to Supabase
      final userId = supabaseSyncService.currentUserId;
      if (userId != null) {
        await supabaseSyncService.insertRow('user_daily_answers', {
          'user_id': userId,
          'question_id': state.question?.id ?? 0,
          'selected_option': answer,
          'name_returned': response.name,
          'name_arabic': response.nameArabic,
          'teaching': '',
          'dua_arabic': '',
          'dua_transliteration': '',
          'dua_translation': '',
        });
      }
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }
}

/// Hydrate local daily answer cache from Supabase for today's question.
/// If server has today's answer, restore it locally. If server empty and
/// local exists, seed server from local.
Future<void> syncDailyAnswersFromSupabase() async {
  final userId = supabaseSyncService.currentUserId;
  if (userId == null) return;

  // Fetch all rows (we filter by today's date client-side — fetchRows
  // doesn't support compound filters).
  final rows = await supabaseSyncService.fetchRows(
    'user_daily_answers',
    userId,
    orderBy: 'answered_at',
  );

  if (_findTodayRow(rows) == null) {
    await seedDailyAnswersToSupabaseFromLocalCache();
    return;
  }
  await hydrateDailyAnswersCacheFromRows(rows);
}

Map<String, dynamic>? _findTodayRow(List<Map<String, dynamic>> rows) {
  final today = todayKey();
  return rows.cast<Map<String, dynamic>?>().firstWhere(
    (row) {
      final raw = row?['answered_at']?.toString();
      if (raw == null) return false;
      final parsed = DateTime.tryParse(raw)?.toLocal();
      if (parsed == null) return false;
      final localDate =
          '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
      return localDate == today;
    },
    orElse: () => null,
  );
}

Future<void> hydrateDailyAnswersCacheFromRows(
  List<Map<String, dynamic>> rows,
) async {
  final todayRow = _findTodayRow(rows);
  if (todayRow == null) return;

  final prefs = await SharedPreferences.getInstance();
  final today = todayKey();
  await prefs.setString(
    _dailyAnswerKey(today),
    jsonEncode({
      'date': today,
      'questionId': todayRow['question_id'],
      'answer': todayRow['selected_option'],
      'name': todayRow['name_returned'],
      'nameArabic': todayRow['name_arabic'],
      'teaching': todayRow['teaching'] ?? '',
      'duaArabic': todayRow['dua_arabic'] ?? '',
      'duaTransliteration': todayRow['dua_transliteration'] ?? '',
      'duaTranslation': todayRow['dua_translation'] ?? '',
    }),
  );
}

Future<void> seedDailyAnswersToSupabaseFromLocalCache() async {
  final userId = supabaseSyncService.currentUserId;
  if (userId == null) return;

  final prefs = await SharedPreferences.getInstance();
  final localJson = prefs.getString(_dailyAnswerKey(todayKey()));
  if (localJson == null) return;

  try {
    final data = jsonDecode(localJson) as Map<String, dynamic>;
    await supabaseSyncService.insertRow('user_daily_answers', {
      'user_id': userId,
      'question_id': data['questionId'] ?? 0,
      'selected_option': data['answer'] ?? '',
      'name_returned': data['name'] ?? '',
      'name_arabic': data['nameArabic'] ?? '',
      'teaching': data['teaching'] ?? '',
      'dua_arabic': data['duaArabic'] ?? '',
      'dua_transliteration': data['duaTransliteration'] ?? '',
      'dua_translation': data['duaTranslation'] ?? '',
    });
  } catch (_) {}
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final dailyQuestionProvider =
    StateNotifierProvider<DailyQuestionNotifier, DailyQuestionState>((ref) {
  final notifier = DailyQuestionNotifier();
  ref.listen<int>(
    publicCatalogRegistryProvider.select((registry) => registry.revision),
    (_, __) {
      notifier.onCatalogRefreshed();
    },
  );
  return notifier;
});
