import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/features/reflect/models/reflect_verse.dart';
import 'package:sakina/services/ai_service.dart' as ai;
import 'package:sakina/services/gating_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/streak_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();
const String _reflectionsKey = 'saved_reflections';

typedef ReflectFollowUpLoader = Future<List<ai.FollowUpQuestion>> Function(
  String userText,
);
typedef ReflectResponseLoader = Future<ai.ReflectResponse> Function(
    String text);
typedef ReflectNow = DateTime Function();
typedef ReflectIdFactory = String Function();

String _defaultReflectIdFactory() => _uuid.v4();

class ReflectDependencies {
  final ReflectFollowUpLoader getFollowUpQuestions;
  final ReflectResponseLoader reflect;
  final ReflectNow now;
  final ReflectIdFactory createId;

  const ReflectDependencies({
    required this.getFollowUpQuestions,
    required this.reflect,
    required this.now,
    required this.createId,
  });
}

const _defaultReflectDependencies = ReflectDependencies(
  getFollowUpQuestions: ai.getFollowUpQuestions,
  reflect: ai.reflectWithOpenAI,
  now: DateTime.now,
  createId: _defaultReflectIdFactory,
);

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
  final List<SavedVerse> verses;
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
    this.verses = const [],
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
        'verses': verses.map((v) => v.toJson()).toList(),
        'duaArabic': duaArabic,
        'duaTransliteration': duaTransliteration,
        'duaTranslation': duaTranslation,
        'duaSource': duaSource,
        'relatedNames': relatedNames,
      };

  factory SavedReflection.fromJson(Map<String, dynamic> json) =>
      SavedReflection(
        id: json['id'] as String,
        date: json['date'] as String,
        userText: json['userText'] as String,
        name: json['name'] as String,
        nameArabic: json['nameArabic'] as String,
        reframePreview: json['reframePreview'] as String,
        reframe: json['reframe'] as String? ?? '',
        story: json['story'] as String? ?? '',
        verses: (json['verses'] as List<dynamic>?)
                ?.map((e) => ReflectVerse.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        duaArabic: json['duaArabic'] as String? ?? '',
        duaTransliteration: json['duaTransliteration'] as String? ?? '',
        duaTranslation: json['duaTranslation'] as String? ?? '',
        duaSource: json['duaSource'] as String? ?? '',
        relatedNames: (json['relatedNames'] as List<dynamic>?)
                ?.map((e) => Map<String, String>.from(e as Map))
                .toList() ??
            [],
      );

  /// Convert to Supabase row format.
  Map<String, dynamic> toSupabaseRow(String userId) => {
        'id': id,
        'user_id': userId,
        'saved_at': date,
        'user_text': userText,
        'name': name,
        'name_arabic': nameArabic,
        'reframe_preview': reframePreview,
        'reframe': reframe,
        'story': story,
        'verses': verses.map((v) => v.toJson()).toList(),
        'dua_arabic': duaArabic,
        'dua_transliteration': duaTransliteration,
        'dua_translation': duaTranslation,
        'dua_source': duaSource,
        'related_names': relatedNames,
      };

  /// Create from a Supabase row.
  factory SavedReflection.fromSupabaseRow(Map<String, dynamic> row) =>
      SavedReflection(
        id: row['id'] as String? ?? _uuid.v4(),
        date: row['saved_at'] as String? ?? '',
        userText: row['user_text'] as String? ?? '',
        name: row['name'] as String? ?? '',
        nameArabic: row['name_arabic'] as String? ?? '',
        reframePreview: row['reframe_preview'] as String? ?? '',
        reframe: row['reframe'] as String? ?? '',
        story: row['story'] as String? ?? '',
        verses: (row['verses'] as List<dynamic>?)
                ?.map((e) => ReflectVerse.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        duaArabic: row['dua_arabic'] as String? ?? '',
        duaTransliteration: row['dua_transliteration'] as String? ?? '',
        duaTranslation: row['dua_translation'] as String? ?? '',
        duaSource: row['dua_source'] as String? ?? '',
        relatedNames: (row['related_names'] as List<dynamic>?)
                ?.map((e) => Map<String, String>.from(e as Map))
                .toList() ??
            [],
      );
}

// ---------------------------------------------------------------------------
// Supabase sync
// ---------------------------------------------------------------------------

Future<void> migrateReflectionCachesForHydration() async {
  final prefs = await SharedPreferences.getInstance();
  await supabaseSyncService.migrateLegacyStringCache(prefs, _reflectionsKey);
}

Future<void> seedReflectionsToSupabaseFromLocalCache() async {
  await supabaseSyncService.seedListFromLocalCache(
    table: 'user_reflections',
    cacheKey: _reflectionsKey,
    toRows: (localItems, userId) => localItems
        .map((e) => SavedReflection.fromJson(e as Map<String, dynamic>)
            .toSupabaseRow(userId))
        .toList(),
  );
}

Future<void> hydrateReflectionCacheFromRows(
  List<Map<String, dynamic>> remoteRows,
) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    supabaseSyncService.scopedKey(_reflectionsKey),
    jsonEncode(
      remoteRows
          .map((r) => SavedReflection.fromSupabaseRow(r).toJson())
          .toList(),
    ),
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

  /// Set when the user attempted to reflect but the gating layer blocked the
  /// call. Reason determines which paywall sheet the screen shows
  /// (warmup-exhausted vs daily-cap). Cleared by [ReflectNotifier.dismissGate].
  final GateResult? gateResult;

  /// Non-null on the one-shot transition moment when this reflect call
  /// decremented the warmup counter from 1 to 0. Screen reads this to fire
  /// [WarmupExhaustedSheet] exactly once, then calls
  /// [ReflectNotifier.dismissWarmupExhausted] to clear.
  final GatedFeature? warmupJustExhausted;

  /// True when a save was blocked by the free-tier journal limit. UI should
  /// surface the upgrade sheet and call [ReflectNotifier.dismissUpgradePrompt]
  /// when the user acknowledges. Previously this case was a silent no-op.
  final bool needsUpgrade;

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
    this.gateResult,
    this.warmupJustExhausted,
    this.needsUpgrade = false,
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
    GateResult? gateResult,
    GatedFeature? warmupJustExhausted,
    bool? needsUpgrade,
    bool clearResult = false,
    bool clearError = false,
    bool clearGateResult = false,
    bool clearWarmupJustExhausted = false,
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
      gateResult: clearGateResult ? null : (gateResult ?? this.gateResult),
      warmupJustExhausted: clearWarmupJustExhausted
          ? null
          : (warmupJustExhausted ?? this.warmupJustExhausted),
      needsUpgrade: needsUpgrade ?? this.needsUpgrade,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ReflectNotifier extends StateNotifier<ReflectState> {
  ReflectNotifier({
    ReflectDependencies? dependencies,
    @visibleForTesting bool loadOnInit = true,
  })  : _dependencies = dependencies ?? _defaultReflectDependencies,
        super(const ReflectState()) {
    if (loadOnInit) {
      _loadSavedReflections();
    }
  }

  final ReflectDependencies _dependencies;
  bool _consumeFreeUsageOnSuccess = false;

  /// Reservation id held during a bypass-funded submit. Set by [submitWithBypass]
  /// before the AI call, cleared on either successful commit or after
  /// `GatingService.cancelBypass` returns. Non-null means a reserve has fired
  /// and the token+counter mutations are in flight on the server.
  ///
  /// If a 4th gated feature is added, extract a BypassFlowMixin — three sites
  /// is the YAGNI threshold (plan 2026-05-23 line 305).
  String? _activeBypassReservationId;

  /// Captured during [submit] alongside `_consumeFreeUsageOnSuccess` so the
  /// follow-on [GatingService.markUsed] call can skip a redundant
  /// `PurchaseService().isPremium()` round-trip (RevenueCat method-channel
  /// hop). Cleared in the same paths that clear `_consumeFreeUsageOnSuccess`.
  bool? _premiumAtSubmit;

  /// Synchronous re-entry flag. Flipped true at the very top of [submit]
  /// BEFORE any `await`, so a second tap that lands while the first is still
  /// inside `GatingService.canUse()` is rejected. Using
  /// `state.screenState == loading` for this is not enough: that flag is only
  /// set inside `_doSubmit`, which runs after the async gate-check — so two
  /// taps race past it and both increment the counter. Mirrors the duas
  /// `_submitInFlight` regression fix from §7 D-E5 (2026-04-26, verified live
  /// with `built_dua_uses=2` after a single double-tap).
  bool _submitInFlight = false;

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

  /// Clears the gate-blocked flag after the paywall sheet is dismissed.
  void dismissGate() {
    state = state.copyWith(clearGateResult: true);
  }

  /// Clears the warmup-just-exhausted signal after the WarmupExhaustedSheet
  /// has been shown and dismissed.
  void dismissWarmupExhausted() {
    state = state.copyWith(clearWarmupJustExhausted: true);
  }

  /// Submit user text. Checks the gating layer first; if blocked, exposes the
  /// [GateResult] on state for the screen to render the right paywall sheet.
  Future<void> submit() async {
    if (_submitInFlight ||
        state.screenState == ReflectScreenState.loading) {
      return;
    }
    _submitInFlight = true;
    try {
      // Resolve premium status ONCE for this submit cycle. Both canUse and
      // the follow-on markUsed need it; without the cache each one fires its
      // own RevenueCat method-channel hop.
      final premium = await PurchaseService().isPremium();
      final gate = await GatingService()
          .canUse(GatedFeature.reflect, isPremiumHint: premium);
      if (!gate.allowed) {
        state = state.copyWith(gateResult: gate);
        return;
      }
      _premiumAtSubmit = premium;
      _consumeFreeUsageOnSuccess = true;
      await _doSubmit();
    } finally {
      _submitInFlight = false;
    }
  }

  /// Submit user text using an AI bypass: spend tokens to get one extra
  /// reflection past the daily cap. Reserves on the server first (atomic
  /// token debit + bypass-counter increment), then runs the same AI flow
  /// as [submit]. On AI success the reservation is committed; on AI failure
  /// the reservation is cancelled and tokens refunded.
  ///
  /// Returns silently when the reserve RPC rejects (insufficient tokens,
  /// bypass cap reached, premium short-circuit). The screen-level toast
  /// is the caller's responsibility — they already know the local state.
  Future<void> submitWithBypass() async {
    if (_submitInFlight ||
        state.screenState == ReflectScreenState.loading) {
      return;
    }
    _submitInFlight = true;
    try {
      final reservation =
          await GatingService().reserveBypass(GatedFeature.reflect);
      if (reservation == null) {
        // Sheet caller stays open / re-renders with stale-state copy.
        state = state.copyWith(error: 'Bypass unavailable. Try again.');
        return;
      }
      _activeBypassReservationId = reservation.reservationId;
      // The bypass path doesn't count against the warmup/daily counters via
      // markUsed — the reserve RPC already incremented the daily-uses row
      // server-side, and the warmup counter is unrelated (bypass is a
      // post-warmup mechanic). Skip both markers.
      _consumeFreeUsageOnSuccess = false;
      _premiumAtSubmit = false;
      await _doSubmit();
    } finally {
      _submitInFlight = false;
    }
  }

  Future<void> _doSubmit() async {
    try {
      state = state.copyWith(
          screenState: ReflectScreenState.loading, clearError: true);

      final questions =
          await _dependencies.getFollowUpQuestions(state.userText);

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
      _consumeFreeUsageOnSuccess = false;
      _premiumAtSubmit = null;
      await _cancelActiveBypassIfAny();
      state = state.copyWith(
        screenState: ReflectScreenState.input,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  /// Record a follow-up answer. If last question, triggers reflect.
  Future<void> answerFollowUp(String answer) async {
    final updatedAnswers = [...state.followUpAnswers, answer];
    final isLast =
        state.currentFollowUpIndex >= state.followUpQuestions.length - 1;

    state = state.copyWith(followUpAnswers: updatedAnswers);

    if (isLast) {
      await _reflect(_buildCombinedText(updatedAnswers));
    } else {
      state =
          state.copyWith(currentFollowUpIndex: state.currentFollowUpIndex + 1);
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
  ///
  /// Optimistic + reconciling: removes locally first, then attempts the server
  /// delete. If the server call throws (airplane / RLS / 5xx), restores the
  /// local list and re-persists, then surfaces an error string the UI can
  /// show as a snackbar. Regression for §9 J-E4 (2026-04-26).
  Future<void> deleteReflection(String id) async {
    final previous = List<SavedReflection>.from(state.savedReflections);
    final updated = previous.where((r) => r.id != id).toList();
    state = state.copyWith(savedReflections: updated, clearError: true);
    await _persistReflections(updated);

    final userId = supabaseSyncService.currentUserId;
    if (userId == null) return;

    try {
      await supabaseSyncService.deleteRow('user_reflections', 'id', id);
    } catch (_) {
      state = state.copyWith(
        savedReflections: previous,
        error: "Couldn't delete the reflection. Please try again.",
      );
      await _persistReflections(previous);
    }
  }

  @visibleForTesting
  void debugSeedReflections(List<SavedReflection> reflections) {
    state = state.copyWith(savedReflections: reflections);
  }

  /// Reset to input state (preserves saved reflections).
  void reset() {
    _consumeFreeUsageOnSuccess = false;
    _premiumAtSubmit = null;
    // If a reset lands while a bypass is mid-flight, fire-and-forget the
    // cancel so the user's tokens don't sit reserved until the orphan cron
    // rescues. We intentionally don't await — reset() is sync-shaped for
    // UI callers.
    final id = _activeBypassReservationId;
    _activeBypassReservationId = null;
    if (id != null) {
      GatingService().cancelBypass(id, GatedFeature.reflect);
    }
    state = ReflectState(savedReflections: state.savedReflections);
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  Future<void> _reflect(String text) async {
    try {
      state = state.copyWith(
          screenState: ReflectScreenState.loading, clearError: true);

      // TODO: Build ReflectContext from journal/anchors when those are implemented
      final response = await _dependencies.reflect(text);

      if (response.offTopic) {
        _consumeFreeUsageOnSuccess = false;
        _premiumAtSubmit = null;
        // Off-topic is treated as "no value delivered" — cancel any active
        // bypass so the user gets their tokens back. Mirrors the existing
        // free-usage no-consume behaviour just above.
        await _cancelActiveBypassIfAny();
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
        if (_consumeFreeUsageOnSuccess) {
          final outcome = await GatingService().markUsed(
            GatedFeature.reflect,
            isPremiumHint: _premiumAtSubmit,
          );
          _consumeFreeUsageOnSuccess = false;
          _premiumAtSubmit = null;
          if (outcome == UsageOutcome.warmupJustExhausted) {
            state =
                state.copyWith(warmupJustExhausted: GatedFeature.reflect);
          }
        }
        await _commitActiveBypassIfAny();
        // Track streak (XP for Reflect is intentionally zero — only Muhasabah,
        // quests, and streak milestones grant XP).
        await markActiveToday();
        await logActivity();
        // Auto-save the reflection
        await _saveReflection(response);
      }
    } catch (e) {
      _consumeFreeUsageOnSuccess = false;
      _premiumAtSubmit = null;
      await _cancelActiveBypassIfAny();
      state = state.copyWith(
        screenState: ReflectScreenState.input,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  /// Fire-and-forget commit of an active bypass reservation. Failures here
  /// are absorbed because the server-side orphan-cleanup cron will rescue a
  /// missed-commit by cancelling the (still-pending) reservation after 15
  /// min — at which point the user already received the AI value, so they
  /// effectively got a free use. Acceptable failure mode.
  Future<void> _commitActiveBypassIfAny() async {
    final id = _activeBypassReservationId;
    if (id == null) return;
    _activeBypassReservationId = null;
    await GatingService().commitBypass(id);
  }

  Future<void> _cancelActiveBypassIfAny() async {
    final id = _activeBypassReservationId;
    if (id == null) return;
    _activeBypassReservationId = null;
    // Best-effort: a cancel-RPC failure (offline, RLS race) just means the
    // reservation stays pending until the orphan-cleanup cron picks it up.
    await GatingService().cancelBypass(id, GatedFeature.reflect);
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

  static const int freeJournalLimit = 5;

  /// Called by the UI after the upgrade sheet is dismissed or acknowledged.
  void dismissUpgradePrompt() {
    state = state.copyWith(needsUpgrade: false);
  }

  Future<void> _saveReflection(ai.ReflectResponse response) async {
    // Check journal limit for free users
    final premium = await PurchaseService().isPremium();
    if (!premium && state.savedReflections.length >= freeJournalLimit) {
      state = state.copyWith(needsUpgrade: true);
      return;
    }

    final preview = response.reframe.length > 150
        ? '${response.reframe.substring(0, 150)}...'
        : response.reframe;

    final reflectionId = _dependencies.createId();
    final reflection = SavedReflection(
      id: reflectionId,
      date: _dependencies.now().toIso8601String(),
      userText: state.userText,
      name: response.name,
      nameArabic: response.nameArabic,
      reframePreview: preview,
      reframe: response.reframe,
      story: response.story,
      verses: response.verses,
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

    // Write to Supabase
    final userId = supabaseSyncService.currentUserId;
    if (userId != null) {
      await supabaseSyncService.insertRow(
        'user_reflections',
        reflection.toSupabaseRow(userId),
      );
    }
  }

  Future<void> _loadSavedReflections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = await supabaseSyncService.migrateLegacyStringCache(
        prefs,
        _reflectionsKey,
      );
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
      supabaseSyncService.scopedKey(_reflectionsKey),
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
