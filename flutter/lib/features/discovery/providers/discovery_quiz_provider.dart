import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/constants/discovery_quiz.dart';
import 'package:sakina/services/public_catalog_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _discoveryQuizResultsKey = 'sakina_discovery_quiz_results_v1';
const _legacyDiscoveryQuizResultsKey = 'discovery_quiz_anchors';
const _legacyAnchorNamesKey = 'anchor_names';

class DiscoveryQuizState {
  final int currentQuestion;
  final List<int?> selectedAnswers;
  final List<AnchorResult>? results;
  final bool completed;
  final bool quizStarted;
  final bool initialized;

  const DiscoveryQuizState({
    this.currentQuestion = 0,
    this.selectedAnswers = const [],
    this.results,
    this.completed = false,
    this.quizStarted = false,
    this.initialized = false,
  });

  DiscoveryQuizState copyWith({
    int? currentQuestion,
    List<int?>? selectedAnswers,
    List<AnchorResult>? results,
    bool? completed,
    bool? quizStarted,
    bool? initialized,
    bool clearResults = false,
  }) {
    return DiscoveryQuizState(
      currentQuestion: currentQuestion ?? this.currentQuestion,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      results: clearResults ? null : (results ?? this.results),
      completed: completed ?? this.completed,
      quizStarted: quizStarted ?? this.quizStarted,
      initialized: initialized ?? this.initialized,
    );
  }
}

class DiscoveryQuizNotifier extends StateNotifier<DiscoveryQuizState> {
  DiscoveryQuizNotifier() : super(const DiscoveryQuizState()) {
    unawaited(_loadSavedResults());
  }

  List<QuizQuestion> get questions => discoveryQuizQuestionsCatalog;
  int get questionCount => questions.length;

  Future<void> _loadSavedResults() async {
    final results = await loadSavedDiscoveryQuizResults();
    if (results.isEmpty) {
      state = state.copyWith(initialized: true);
      return;
    }

    state = state.copyWith(
      completed: true,
      results: results,
      initialized: true,
    );
  }

  void ensureQuizReady() {
    if (!state.initialized || state.completed || state.quizStarted) return;
    startQuiz();
  }

  void startQuiz() {
    state = state.copyWith(
      quizStarted: true,
      currentQuestion: 0,
      selectedAnswers: [],
      clearResults: true,
      completed: false,
      initialized: true,
    );
  }

  void goBack() {
    if (state.currentQuestion == 0) return;
    state = state.copyWith(currentQuestion: state.currentQuestion - 1);
  }

  void answerQuestion(int optionIndex) {
    final updatedAnswers = [...state.selectedAnswers];
    final currentIndex = state.currentQuestion;

    if (updatedAnswers.length > currentIndex) {
      updatedAnswers[currentIndex] = optionIndex;
      if (updatedAnswers.length > currentIndex + 1) {
        updatedAnswers.removeRange(currentIndex + 1, updatedAnswers.length);
      }
    } else {
      updatedAnswers.add(optionIndex);
    }

    final isLast = currentIndex >= questionCount - 1;
    if (isLast) {
      state = state.copyWith(selectedAnswers: updatedAnswers);
      unawaited(completeQuiz());
      return;
    }

    state = state.copyWith(
      selectedAnswers: updatedAnswers,
      currentQuestion: currentIndex + 1,
    );
  }

  Future<void> completeQuiz() async {
    final results = calculateQuizResults(
      state.selectedAnswers.map((value) => value ?? 0).toList(),
    );

    state = state.copyWith(
      completed: true,
      results: results,
      quizStarted: false,
    );

    await saveDiscoveryQuizResults(results);
  }

  Future<List<String>> getAnchors() async {
    return loadSavedDiscoveryQuizAnchorNames();
  }

  void onCatalogRefreshed() {
    state = state.copyWith();
  }
}

Future<void> saveDiscoveryQuizResults(List<AnchorResult> results) async {
  final prefs = await SharedPreferences.getInstance();
  final payload = jsonEncode({
    'version': 1,
    'results': results.map(_encodeAnchorResult).toList(),
  });

  await prefs.setString(_discoveryQuizResultsKey, payload);
  await prefs.remove(_legacyDiscoveryQuizResultsKey);
  await prefs.remove(_legacyAnchorNamesKey);
}

Future<List<AnchorResult>> loadSavedDiscoveryQuizResults() async {
  final prefs = await SharedPreferences.getInstance();

  String? normalizedJson;
  try {
    normalizedJson = prefs.getString(_discoveryQuizResultsKey);
  } catch (_) {}
  final normalized = _decodeSavedResults(normalizedJson);
  if (normalized.isNotEmpty) return normalized;

  String? legacyResultsJson;
  try {
    legacyResultsJson = prefs.getString(_legacyDiscoveryQuizResultsKey);
  } catch (_) {}
  final legacyResults = _decodeSavedResults(legacyResultsJson);
  if (legacyResults.isNotEmpty) {
    await saveDiscoveryQuizResults(legacyResults);
    return legacyResults;
  }

  String? legacyAnchorsJson;
  try {
    legacyAnchorsJson = prefs.getString(_legacyAnchorNamesKey);
  } catch (_) {}
  final legacyAnchors = _decodeSavedResults(legacyAnchorsJson);
  if (legacyAnchors.isNotEmpty) {
    await saveDiscoveryQuizResults(legacyAnchors);
    return legacyAnchors;
  }

  final legacyAnchorNames = prefs.getStringList(_legacyAnchorNamesKey);
  if (legacyAnchorNames != null && legacyAnchorNames.isNotEmpty) {
    final migrated = legacyAnchorNames
        .map((name) => _anchorResultFromName(name))
        .whereType<AnchorResult>()
        .toList();
    if (migrated.isNotEmpty) {
      await saveDiscoveryQuizResults(migrated);
      return migrated;
    }
  }

  return [];
}

Future<List<String>> loadSavedDiscoveryQuizAnchorNames() async {
  final results = await loadSavedDiscoveryQuizResults();
  return results.map((result) => result.name).toList();
}

List<AnchorResult> _decodeSavedResults(String? rawJson) {
  if (rawJson == null || rawJson.isEmpty) return const [];

  try {
    final decoded = jsonDecode(rawJson);
    if (decoded is Map<String, dynamic>) {
      final results = decoded['results'];
      if (results is List) {
        return results
            .map((item) => _anchorResultFromJson(item))
            .whereType<AnchorResult>()
            .toList();
      }
    }

    if (decoded is List) {
      return decoded
          .map((item) => _anchorResultFromJson(item))
          .whereType<AnchorResult>()
          .toList();
    }
  } catch (_) {}

  return const [];
}

Map<String, dynamic> _encodeAnchorResult(AnchorResult result) {
  return {
    'nameKey': result.nameKey,
    'name': result.name,
    'arabic': result.arabic,
    'score': result.score,
    'anchor': result.anchor,
    'detail': result.detail,
  };
}

AnchorResult? _anchorResultFromJson(dynamic item) {
  if (item is String) return _anchorResultFromName(item);
  if (item is! Map) return null;

  final map = Map<String, dynamic>.from(item);
  final name = map['name']?.toString() ?? '';
  if (name.isEmpty) return null;

  final fallback = _anchorResultFromName(name);
  return AnchorResult(
    nameKey: map['nameKey']?.toString() ?? fallback?.nameKey ?? '',
    name: name,
    arabic: map['arabic']?.toString() ?? fallback?.arabic ?? '',
    score: (map['score'] as num?)?.toInt() ?? fallback?.score ?? 0,
    anchor: map['anchor']?.toString() ?? fallback?.anchor ?? '',
    detail: map['detail']?.toString() ?? fallback?.detail ?? '',
  );
}

AnchorResult? _anchorResultFromName(String name) {
  for (final entry in nameAnchorsCatalog.entries) {
    if (entry.value.name == name) {
      return AnchorResult(
        nameKey: entry.key,
        name: entry.value.name,
        arabic: entry.value.arabic,
        score: 0,
        anchor: entry.value.anchor,
        detail: entry.value.detail,
      );
    }
  }
  return null;
}

final discoveryQuizProvider =
    StateNotifierProvider<DiscoveryQuizNotifier, DiscoveryQuizState>((ref) {
  final notifier = DiscoveryQuizNotifier();
  ref.listen<int>(
    publicCatalogRegistryProvider.select((registry) => registry.revision),
    (_, __) {
      notifier.onCatalogRefreshed();
    },
  );
  return notifier;
});
