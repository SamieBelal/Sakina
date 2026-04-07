import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/services/ai_service.dart' as ai;
import 'package:sakina/services/daily_usage_service.dart';
import 'package:sakina/services/xp_service.dart';
import 'package:sakina/services/streak_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum ReflectScreenState { input, followup, loading, result, offtopic }

enum ReflectStep { name, reflection, story, dua }

// ---------------------------------------------------------------------------
// Saved reflection model
// ---------------------------------------------------------------------------

class SavedReflection {
  final String id;
  final String date;
  final String userText;
  final String name;
  final String nameArabic;
  final String reframePreview;
  final String reframe;
  final String story;
  final String duaArabic;
  final String duaTransliteration;
  final String duaTranslation;
  final String duaSource;
  final List<Map<String, String>> relatedNames;

  const SavedReflection({
    required this.id,
    required this.date,
    required this.userText,
    required this.name,
    required this.nameArabic,
    required this.reframePreview,
    this.reframe = '',
    this.story = '',
    this.duaArabic = '',
    this.duaTransliteration = '',
    this.duaTranslation = '',
    this.duaSource = '',
    this.relatedNames = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'userText': userText,
    'name': name,
    'nameArabic': nameArabic,
    'reframePreview': reframePreview,
    'reframe': reframe,
    'story': story,
    'duaArabic': duaArabic,
    'duaTransliteration': duaTransliteration,
    'duaTranslation': duaTranslation,
    'duaSource': duaSource,
    'relatedNames': relatedNames,
  };

  factory SavedReflection.fromJson(Map<String, dynamic> json) => SavedReflection(
    id: json['id'] as String,
    date: json['date'] as String,
    userText: json['userText'] as String,
    name: json['name'] as String,
    nameArabic: json['nameArabic'] as String,
    reframePreview: json['reframePreview'] as String,
    reframe: json['reframe'] as String? ?? '',
    story: json['story'] as String? ?? '',
    duaArabic: json['duaArabic'] as String? ?? '',
    duaTransliteration: json['duaTransliteration'] as String? ?? '',
    duaTranslation: json['duaTranslation'] as String? ?? '',
    duaSource: json['duaSource'] as String? ?? '',
    relatedNames: (json['relatedNames'] as List<dynamic>?)
        ?.map((e) => Map<String, String>.from(e as Map))
        .toList() ?? [],
  );
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ReflectState {
  final ReflectScreenState screenState;
  final String userText;
  final ai.ReflectResponse? result;
  final String? error;
  final ReflectStep currentStep;
  final List<ai.FollowUpQuestion> followUpQuestions;
  final List<String> followUpAnswers;
  final int currentFollowUpIndex;
  final Set<String> selectedEmotions;
  final List<SavedReflection> savedReflections;
  /// True when the user has hit the free daily limit and must spend a token.
  final bool needsToken;

  const ReflectState({
    this.screenState = ReflectScreenState.input,
    this.userText = '',
    this.result,
    this.error,
    this.currentStep = ReflectStep.name,
    this.followUpQuestions = const [],
    this.followUpAnswers = const [],
    this.currentFollowUpIndex = 0,
    this.selectedEmotions = const {},
    this.savedReflections = const [],
    this.needsToken = false,
  });

  ReflectState copyWith({
    ReflectScreenState? screenState,
    String? userText,
    ai.ReflectResponse? result,
    String? error,
    ReflectStep? currentStep,
    List<ai.FollowUpQuestion>? followUpQuestions,
    List<String>? followUpAnswers,
    int? currentFollowUpIndex,
    Set<String>? selectedEmotions,
    List<SavedReflection>? savedReflections,
    bool? needsToken,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return ReflectState(
      screenState: screenState ?? this.screenState,
      userText: userText ?? this.userText,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
      currentStep: currentStep ?? this.currentStep,
      followUpQuestions: followUpQuestions ?? this.followUpQuestions,
      followUpAnswers: followUpAnswers ?? this.followUpAnswers,
      currentFollowUpIndex: currentFollowUpIndex ?? this.currentFollowUpIndex,
      selectedEmotions: selectedEmotions ?? this.selectedEmotions,
      savedReflections: savedReflections ?? this.savedReflections,
      needsToken: needsToken ?? this.needsToken,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ReflectNotifier extends StateNotifier<ReflectState> {
  ReflectNotifier() : super(const ReflectState()) {
    _loadSavedReflections();
  }

  void setUserText(String text) {
    state = state.copyWith(userText: text);
  }

  void toggleEmotion(String emotion) {
    final updated = Set<String>.from(state.selectedEmotions);
    if (updated.contains(emotion)) {
      updated.remove(emotion);
    } else {
      updated.add(emotion);
    }
    state = state.copyWith(selectedEmotions: updated);
  }

  /// Called by the UI after the user approves spending a token.
  /// Clears the needsToken flag and proceeds with submission.
  Future<void> submitWithToken() async {
    state = state.copyWith(needsToken: false);
    await _doSubmit();
  }

  /// Submit user text. Checks daily usage first; sets needsToken if limit hit.
  Future<void> submit() async {
    final isFree = await canReflectFree();
    if (!isFree) {
      state = state.copyWith(needsToken: true);
      return;
    }
    await incrementReflectUsage();
    await _doSubmit();
  }

  Future<void> _doSubmit() async {
    try {
      state = state.copyWith(screenState: ReflectScreenState.loading, clearError: true);

      final questions = await ai.getFollowUpQuestions(state.userText);

      if (questions.isNotEmpty) {
        state = state.copyWith(
          screenState: ReflectScreenState.followup,
          followUpQuestions: questions,
          followUpAnswers: [],
          currentFollowUpIndex: 0,
        );
      } else {
        await _reflect(_buildCombinedText([]));
      }
    } catch (e) {
      state = state.copyWith(
        screenState: ReflectScreenState.input,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  /// Record a follow-up answer. If last question, triggers reflect.
  Future<void> answerFollowUp(String answer) async {
    final updatedAnswers = [...state.followUpAnswers, answer];
    final isLast = state.currentFollowUpIndex >= state.followUpQuestions.length - 1;

    state = state.copyWith(followUpAnswers: updatedAnswers);

    if (isLast) {
      await _reflect(_buildCombinedText(updatedAnswers));
    } else {
      state = state.copyWith(currentFollowUpIndex: state.currentFollowUpIndex + 1);
    }
  }

  /// Skip follow-ups and reflect with just the original text.
  Future<void> skipFollowUps() async {
    await _reflect(_buildCombinedText([]));
  }

  /// Advance result step: name → reflection → story → dua.
  Future<void> continueStep() async {
    const nextStep = {
      ReflectStep.name: ReflectStep.reflection,
      ReflectStep.reflection: ReflectStep.story,
      ReflectStep.story: ReflectStep.dua,
    };
    final next = nextStep[state.currentStep];
    if (next != null) {
      // Award XP when advancing to story or dua steps
      if (next == ReflectStep.story) {
        await awardXp(xpStoryRead);
      } else if (next == ReflectStep.dua) {
        await awardXp(xpDuaRead);
      }
      state = state.copyWith(currentStep: next);
    }
  }

  /// Go back one result step: dua → story → reflection → name.
  void previousStep() {
    const prevStep = {
      ReflectStep.reflection: ReflectStep.name,
      ReflectStep.story: ReflectStep.reflection,
      ReflectStep.dua: ReflectStep.story,
    };
    final prev = prevStep[state.currentStep];
    if (prev != null) {
      state = state.copyWith(currentStep: prev);
    }
  }

  /// Delete a saved reflection.
  Future<void> deleteReflection(String id) async {
    final updated = state.savedReflections.where((r) => r.id != id).toList();
    state = state.copyWith(savedReflections: updated);
    await _persistReflections(updated);
  }

  /// Reset to input state (preserves saved reflections).
  void reset() {
    state = ReflectState(savedReflections: state.savedReflections);
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  Future<void> _reflect(String text) async {
    try {
      state = state.copyWith(screenState: ReflectScreenState.loading, clearError: true);

      // TODO: Build ReflectContext from journal/anchors when those are implemented
      final response = await ai.reflectWithClaude(text);

      if (response.offTopic) {
        state = state.copyWith(
          screenState: ReflectScreenState.offtopic,
          result: response,
        );
      } else {
        state = state.copyWith(
          screenState: ReflectScreenState.result,
          result: response,
          currentStep: ReflectStep.name,
        );
        // Award XP and track streak for completed reflection
        await awardXp(xpReflectionComplete);
        await markActiveToday();
        await logActivity();
        // Auto-save the reflection
        await _saveReflection(response);
      }
    } catch (e) {
      state = state.copyWith(
        screenState: ReflectScreenState.input,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  String _buildCombinedText(List<String> answers) {
    final buffer = StringBuffer(state.userText);
    if (state.selectedEmotions.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Emotions: ${state.selectedEmotions.join(', ')}');
    }
    for (var i = 0; i < answers.length; i++) {
      if (i < state.followUpQuestions.length) {
        buffer
          ..writeln()
          ..writeln('Q: ${state.followUpQuestions[i].question}')
          ..writeln('A: ${answers[i]}');
      }
    }
    return buffer.toString();
  }

  Future<void> _saveReflection(ai.ReflectResponse response) async {
    final preview = response.reframe.length > 150
        ? '${response.reframe.substring(0, 150)}...'
        : response.reframe;

    final reflection = SavedReflection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now().toIso8601String(),
      userText: state.userText,
      name: response.name,
      nameArabic: response.nameArabic,
      reframePreview: preview,
      reframe: response.reframe,
      story: response.story,
      duaArabic: response.duaArabic,
      duaTransliteration: response.duaTransliteration,
      duaTranslation: response.duaTranslation,
      duaSource: response.duaSource,
      relatedNames: response.relatedNames
          .map((r) => {'name': r.name, 'nameArabic': r.nameArabic})
          .toList(),
    );

    final updated = [reflection, ...state.savedReflections];
    state = state.copyWith(savedReflections: updated);
    await _persistReflections(updated);
  }

  Future<void> _loadSavedReflections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('saved_reflections');
      if (json != null) {
        final list = (jsonDecode(json) as List)
            .map((e) => SavedReflection.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(savedReflections: list);
      }
    } catch (_) {}
  }

  Future<void> _persistReflections(List<SavedReflection> reflections) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'saved_reflections',
      jsonEncode(reflections.map((r) => r.toJson()).toList()),
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final reflectProvider =
    StateNotifierProvider<ReflectNotifier, ReflectState>((ref) {
  return ReflectNotifier();
});
