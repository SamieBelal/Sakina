import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/constants/discovery_quiz.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class DiscoveryQuizState {
  final int currentQuestion;
  final List<int> selectedAnswers;
  final List<AnchorResult>? results;
  final bool completed;
  final bool quizStarted;

  const DiscoveryQuizState({
    this.currentQuestion = 0,
    this.selectedAnswers = const [],
    this.results,
    this.completed = false,
    this.quizStarted = false,
  });

  DiscoveryQuizState copyWith({
    int? currentQuestion,
    List<int>? selectedAnswers,
    List<AnchorResult>? results,
    bool? completed,
    bool? quizStarted,
    bool clearResults = false,
  }) {
    return DiscoveryQuizState(
      currentQuestion: currentQuestion ?? this.currentQuestion,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      results: clearResults ? null : (results ?? this.results),
      completed: completed ?? this.completed,
      quizStarted: quizStarted ?? this.quizStarted,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class DiscoveryQuizNotifier extends StateNotifier<DiscoveryQuizState> {
  DiscoveryQuizNotifier() : super(const DiscoveryQuizState()) {
    _loadSavedResults();
  }

  static const _prefsKey = 'discovery_quiz_anchors';

  Future<void> _loadSavedResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_prefsKey);
      if (savedJson != null) {
        final List<dynamic> decoded = jsonDecode(savedJson) as List<dynamic>;
        final anchors = decoded.map((e) {
          final map = e as Map<String, dynamic>;
          return AnchorResult(
            nameKey: map['nameKey'] as String,
            name: map['name'] as String,
            arabic: map['arabic'] as String,
            score: map['score'] as int,
            anchor: map['anchor'] as String,
            detail: map['detail'] as String,
          );
        }).toList();

        state = state.copyWith(
          completed: true,
          results: anchors,
        );
      }
    } catch (_) {}
  }

  void startQuiz() {
    state = state.copyWith(
      quizStarted: true,
      currentQuestion: 0,
      selectedAnswers: [],
      clearResults: true,
      completed: false,
    );
  }

  void answerQuestion(int optionIndex) {
    final updatedAnswers = [...state.selectedAnswers, optionIndex];
    final isLast = state.currentQuestion >= discoveryQuizQuestions.length - 1;

    if (isLast) {
      state = state.copyWith(selectedAnswers: updatedAnswers);
      completeQuiz();
    } else {
      state = state.copyWith(
        selectedAnswers: updatedAnswers,
        currentQuestion: state.currentQuestion + 1,
      );
    }
  }

  Future<void> completeQuiz() async {
    final results = calculateQuizResults(state.selectedAnswers);

    state = state.copyWith(
      completed: true,
      results: results,
      quizStarted: false,
    );

    // Persist top 3 anchors
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(results.map((r) => <String, dynamic>{
          'nameKey': r.nameKey,
          'name': r.name,
          'arabic': r.arabic,
          'score': r.score,
          'anchor': r.anchor,
          'detail': r.detail,
        }).toList());
      await prefs.setString(_prefsKey, encoded);
    } catch (_) {}
  }

  /// Returns saved anchor name strings (e.g. ['Ar-Rahman', 'Al-Wadud', 'As-Sabur']).
  Future<List<String>> getAnchors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_prefsKey);
      if (savedJson != null) {
        final List<dynamic> decoded = jsonDecode(savedJson) as List<dynamic>;
        return decoded
            .map((e) => (e as Map<String, dynamic>)['name'] as String)
            .toList();
      }
    } catch (_) {}
    return [];
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final discoveryQuizProvider =
    StateNotifierProvider<DiscoveryQuizNotifier, DiscoveryQuizState>((ref) {
  return DiscoveryQuizNotifier();
});
