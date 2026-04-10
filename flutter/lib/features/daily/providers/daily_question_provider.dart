import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/constants/daily_questions.dart';
import 'package:sakina/services/public_catalog_service.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/services/streak_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      final key = 'daily_answer_${todayKey()}';
      final savedJson = prefs.getString(key);

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
      final key = 'daily_answer_${todayKey()}';
      await prefs.setString(
        key,
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
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }
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
