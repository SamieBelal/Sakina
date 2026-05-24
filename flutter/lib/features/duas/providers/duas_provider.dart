import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/constants/duas.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/services/gating_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/public_catalog_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();
const String _builtDuasKey = 'saved_built_duas';
const String _relatedDuasKey = 'saved_related_duas';
const String _browseDuaIdsKey = 'saved_browse_dua_ids';

typedef FindDuasLoader = Future<FindDuasResponse> Function(String need);
typedef BuildDuaLoader = Future<BuiltDuaResponse> Function(String need);
typedef DuaNow = DateTime Function();
typedef DuaIdFactory = String Function();

String _defaultDuaIdFactory() => _uuid.v4();

class DuasDependencies {
  final FindDuasLoader findDuas;
  final BuildDuaLoader buildDua;
  final DuaNow now;
  final DuaIdFactory createId;

  const DuasDependencies({
    required this.findDuas,
    required this.buildDua,
    required this.now,
    required this.createId,
  });
}

const _defaultDuasDependencies = DuasDependencies(
  findDuas: findDuas,
  buildDua: buildDua,
  now: DateTime.now,
  createId: _defaultDuaIdFactory,
);

// ---------------------------------------------------------------------------
// Tab enum
// ---------------------------------------------------------------------------

enum DuasTab { build }

// ---------------------------------------------------------------------------
// Saved dua model
// ---------------------------------------------------------------------------

class SavedBuiltDua {
  final String id;
  final String savedAt;
  final String need;
  final String arabic;
  final String transliteration;
  final String translation;

  const SavedBuiltDua({
    required this.id,
    required this.savedAt,
    required this.need,
    required this.arabic,
    required this.transliteration,
    required this.translation,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'savedAt': savedAt,
        'need': need,
        'arabic': arabic,
        'transliteration': transliteration,
        'translation': translation,
      };

  factory SavedBuiltDua.fromJson(Map<String, dynamic> json) => SavedBuiltDua(
        id: json['id'] as String,
        savedAt: json['savedAt'] as String,
        need: json['need'] as String,
        arabic: json['arabic'] as String,
        transliteration: json['transliteration'] as String,
        translation: json['translation'] as String,
      );

  Map<String, dynamic> toSupabaseRow(String userId) => {
        'id': id,
        'user_id': userId,
        'saved_at': savedAt,
        'need': need,
        'arabic': arabic,
        'transliteration': transliteration,
        'translation': translation,
      };

  factory SavedBuiltDua.fromSupabaseRow(Map<String, dynamic> row) =>
      SavedBuiltDua(
        id: row['id'] as String? ?? _uuid.v4(),
        savedAt: row['saved_at'] as String? ?? '',
        need: row['need'] as String? ?? '',
        arabic: row['arabic'] as String? ?? '',
        transliteration: row['transliteration'] as String? ?? '',
        translation: row['translation'] as String? ?? '',
      );
}

class SavedRelatedDua {
  final String id;
  final String title;
  final String arabic;
  final String transliteration;
  final String translation;
  final String source;

  const SavedRelatedDua({
    required this.id,
    required this.title,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'arabic': arabic,
        'transliteration': transliteration,
        'translation': translation,
        'source': source,
      };

  factory SavedRelatedDua.fromJson(Map<String, dynamic> json) =>
      SavedRelatedDua(
        id: json['id'] as String,
        title: json['title'] as String,
        arabic: json['arabic'] as String,
        transliteration: json['transliteration'] as String,
        translation: json['translation'] as String,
        source: json['source'] as String,
      );
}

// ---------------------------------------------------------------------------
// Supabase sync
// ---------------------------------------------------------------------------

Future<void> migrateDuaCachesForHydration() async {
  final prefs = await SharedPreferences.getInstance();
  await supabaseSyncService.migrateLegacyStringCache(prefs, _builtDuasKey);
  await supabaseSyncService.migrateLegacyStringCache(prefs, _relatedDuasKey);
  await supabaseSyncService.migrateLegacyStringListCache(
      prefs, _browseDuaIdsKey);
}

Future<void> seedBuiltDuasToSupabaseFromLocalCache() async {
  await supabaseSyncService.seedListFromLocalCache(
    table: 'user_built_duas',
    cacheKey: _builtDuasKey,
    toRows: (localItems, userId) => localItems
        .map((e) => SavedBuiltDua.fromJson(e as Map<String, dynamic>)
            .toSupabaseRow(userId))
        .toList(),
  );
}

Future<void> hydrateBuiltDuaCacheFromRows(
  List<Map<String, dynamic>> remoteRows,
) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    supabaseSyncService.scopedKey(_builtDuasKey),
    jsonEncode(
      remoteRows.map((r) => SavedBuiltDua.fromSupabaseRow(r).toJson()).toList(),
    ),
  );
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class DuasState {
  final DuasTab? activeTab;
  final String selectedCategory;
  final String browseQuery;
  final Set<String> savedDuaIds;
  final String findNeed;
  final FindDuasResponse? findResult;
  final bool findLoading;
  final String buildNeed;
  final BuiltDuaResponse? buildResult;
  final bool buildLoading;
  final int buildCurrentSection;
  final String? error;
  final List<SavedBuiltDua> savedBuiltDuas;
  final List<SavedRelatedDua> savedRelatedDuas;

  /// Set when build-a-dua attempt was blocked by the gating layer. UI reads
  /// this to render the right paywall sheet, then clears via
  /// [DuasNotifier.dismissBuildGate].
  final GateResult? buildGateResult;

  /// Non-null on the one-shot transition moment when the build call
  /// decremented the warmup counter from 1 to 0. Screen reads this to fire
  /// [WarmupExhaustedSheet] exactly once, then calls
  /// [DuasNotifier.dismissBuildWarmupExhausted] to clear.
  final GatedFeature? buildWarmupJustExhausted;

  /// True when saving a built dua was blocked by the free-tier journal limit.
  /// UI should show the upgrade sheet and call
  /// [DuasNotifier.dismissUpgradePrompt] when acknowledged.
  final bool needsUpgrade;

  /// True once the auto-save attempt for the current [buildResult] has been
  /// made, whether the save succeeded or was rejected by the cap. The Ameen
  /// screen reads this to avoid retrying the auto-save in a loop after the
  /// user dismisses the upgrade sheet. Reset to false when a new build
  /// starts.
  final bool buildResultSaveHandled;

  /// Progress theater value (0.0 – 1.0) shown during dua generation.
  final double buildProgress;

  const DuasState({
    this.activeTab,
    this.selectedCategory = 'all',
    this.browseQuery = '',
    this.savedDuaIds = const {},
    this.findNeed = '',
    this.findResult,
    this.findLoading = false,
    this.buildNeed = '',
    this.buildResult,
    this.buildLoading = false,
    this.buildCurrentSection = 0,
    this.error,
    this.savedBuiltDuas = const [],
    this.savedRelatedDuas = const [],
    this.buildGateResult,
    this.buildWarmupJustExhausted,
    this.needsUpgrade = false,
    this.buildResultSaveHandled = false,
    this.buildProgress = 0.0,
  });

  DuasState copyWith({
    DuasTab? Function()? activeTab,
    String? selectedCategory,
    String? browseQuery,
    Set<String>? savedDuaIds,
    String? findNeed,
    FindDuasResponse? Function()? findResult,
    bool? findLoading,
    String? buildNeed,
    BuiltDuaResponse? Function()? buildResult,
    bool? buildLoading,
    int? buildCurrentSection,
    String? Function()? error,
    List<SavedBuiltDua>? savedBuiltDuas,
    List<SavedRelatedDua>? savedRelatedDuas,
    GateResult? buildGateResult,
    GatedFeature? buildWarmupJustExhausted,
    bool? needsUpgrade,
    bool? buildResultSaveHandled,
    double? buildProgress,
    bool clearBuildGateResult = false,
    bool clearBuildWarmupJustExhausted = false,
  }) {
    return DuasState(
      activeTab: activeTab != null ? activeTab() : this.activeTab,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      browseQuery: browseQuery ?? this.browseQuery,
      savedDuaIds: savedDuaIds ?? this.savedDuaIds,
      findNeed: findNeed ?? this.findNeed,
      findResult: findResult != null ? findResult() : this.findResult,
      findLoading: findLoading ?? this.findLoading,
      buildNeed: buildNeed ?? this.buildNeed,
      buildResult: buildResult != null ? buildResult() : this.buildResult,
      buildLoading: buildLoading ?? this.buildLoading,
      buildCurrentSection: buildCurrentSection ?? this.buildCurrentSection,
      error: error != null ? error() : this.error,
      savedBuiltDuas: savedBuiltDuas ?? this.savedBuiltDuas,
      savedRelatedDuas: savedRelatedDuas ?? this.savedRelatedDuas,
      buildGateResult: clearBuildGateResult
          ? null
          : (buildGateResult ?? this.buildGateResult),
      buildWarmupJustExhausted: clearBuildWarmupJustExhausted
          ? null
          : (buildWarmupJustExhausted ?? this.buildWarmupJustExhausted),
      needsUpgrade: needsUpgrade ?? this.needsUpgrade,
      buildResultSaveHandled:
          buildResultSaveHandled ?? this.buildResultSaveHandled,
      buildProgress: buildProgress ?? this.buildProgress,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class DuasNotifier extends StateNotifier<DuasState> {
  DuasNotifier({
    DuasDependencies? dependencies,
    @visibleForTesting bool loadOnInit = true,
    @visibleForTesting
    Duration resultRevealDelay = const Duration(milliseconds: 400),
  })  : _dependencies = dependencies ?? _defaultDuasDependencies,
        _resultRevealDelay = resultRevealDelay,
        super(const DuasState()) {
    if (loadOnInit) {
      loadSavedDuas();
    }
  }

  Timer? _progressTimer;
  final DuasDependencies _dependencies;
  final Duration _resultRevealDelay;

  /// Reservation id held during a bypass-funded build. Set by
  /// [submitBuildWithBypass] before the AI call, cleared in success/failure
  /// paths inside [_doBuild]. Non-null means a reserve has fired and the
  /// token+counter mutations are in flight on the server.
  ///
  /// If a 4th gated feature is added, extract a BypassFlowMixin — three sites
  /// is the YAGNI threshold (plan 2026-05-23 line 305).
  String? _activeBypassReservationId;

  static const String _namesInvokedKey = 'sakina_names_invoked';

  Future<void> _trackNamesInvoked(List<String> names) async {
    final prefs = await SharedPreferences.getInstance();
    final scopedKey = supabaseSyncService.scopedKey(_namesInvokedKey);
    final existing = prefs.getStringList(scopedKey) ?? [];
    final set = existing.toSet();
    for (final name in names) {
      // Normalize: strip "Al-", lowercase for matching
      set.add(name.trim());
    }
    await prefs.setStringList(scopedKey, set.toList());
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    // P0-4: cancel any in-flight bypass reservation so the user's tokens
    // are refunded immediately instead of waiting up to 15 min for the
    // server-side orphan cron. Fire-and-forget — we're tearing down,
    // failures here are unrecoverable. Wrap in try/catch + .ignore() so
    // shutdown-time RPC throws don't escape into Flutter's unhandled-
    // error logger.
    final id = _activeBypassReservationId;
    _activeBypassReservationId = null;
    if (id != null) {
      try {
        GatingService().cancelBypass(id, GatedFeature.builtDua).ignore();
      } catch (_) {
        // Tearing down; orphan cron will refund.
      }
    }
    super.dispose();
  }

  // ── Navigation ──────────────────────────────────────────────

  void setActiveTab(DuasTab? tab) {
    state = state.copyWith(activeTab: () => tab, error: () => null);
  }

  // ── Browse ──────────────────────────────────────────────────

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void toggleSavedDua(String id) async {
    final updated = Set<String>.from(state.savedDuaIds);
    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }
    state = state.copyWith(savedDuaIds: updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      supabaseSyncService.scopedKey(_browseDuaIdsKey),
      updated.toList(),
    );
  }

  void setBrowseQuery(String query) {
    state = state.copyWith(browseQuery: query);
  }

  List<BrowseDua> get filteredBrowseDuas {
    final query = state.browseQuery.trim().toLowerCase();
    return browseDuasCatalog.where((d) {
      final categoryMatch = state.selectedCategory == 'all' ||
          d.category == state.selectedCategory;
      if (!categoryMatch) return false;
      if (query.isEmpty) return true;
      return d.title.toLowerCase().contains(query) ||
          d.translation.toLowerCase().contains(query) ||
          d.transliteration.toLowerCase().contains(query);
    }).toList();
  }

  // ── Find ────────────────────────────────────────────────────

  void setFindNeed(String value) {
    state = state.copyWith(findNeed: value);
  }

  Future<void> submitFind() async {
    if (state.findNeed.trim().isEmpty) return;
    state = state.copyWith(
      findLoading: true,
      error: () => null,
      findResult: () => null,
    );
    try {
      final result = await _dependencies.findDuas(state.findNeed);
      state = state.copyWith(findResult: () => result, findLoading: false);
      // No XP — only Muhasabah, quests, and streak milestones grant XP.
    } catch (e) {
      state = state.copyWith(
        findLoading: false,
        error: () => 'Something went wrong. Please try again.',
      );
    }
  }

  void resetFind() {
    state = state.copyWith(
      findNeed: '',
      findResult: () => null,
      findLoading: false,
      error: () => null,
    );
  }

  // ── Build ───────────────────────────────────────────────────

  void setBuildNeed(String value) {
    state = state.copyWith(buildNeed: value);
  }

  /// Synchronous re-entry flag. Flipped true at the very top of
  /// [submitBuild] / [submitBuildWithToken] BEFORE any `await`, so a second
  /// tap that lands while the first is still inside `GatingService.canUse()` is
  /// rejected. Using `state.buildLoading` for this is not enough: that flag
  /// is only set inside `_doBuild`, which runs after the async free-check —
  /// so two taps race past it and both increment the counter. Regression for
  /// §7 D-E5 (verified failing on sim 2026-04-26 with `built_dua_uses=2`).
  bool _submitInFlight = false;

  Future<void> submitBuild() async {
    if (_submitInFlight || state.buildLoading) return;
    if (state.buildNeed.trim().isEmpty) return;
    _submitInFlight = true;
    try {
      // Resolve premium status ONCE for the whole submit cycle so canUse and
      // the follow-on markUsed share a single RevenueCat round-trip.
      final premium = await PurchaseService().isPremium();
      final gate = await GatingService()
          .canUse(GatedFeature.builtDua, isPremiumHint: premium);
      if (!gate.allowed) {
        state = state.copyWith(buildGateResult: gate);
        return;
      }
      await _doBuild(consumeFreeUsage: true, isPremiumHint: premium);
    } finally {
      _submitInFlight = false;
    }
  }

  /// Build a dua using an AI bypass (token-spend path). Reserves on the
  /// server first, then runs the existing build flow. The empty-breakdown
  /// off-topic check inside [_doBuild] handles refund correctly because
  /// `_consumeFreeUsageOnSuccess` is false here — we lean on the explicit
  /// commit/cancel calls in [_doBuild] instead.
  Future<void> submitBuildWithBypass() async {
    if (_submitInFlight || state.buildLoading) return;
    if (state.buildNeed.trim().isEmpty) return;
    _submitInFlight = true;
    try {
      final reservation =
          await GatingService().reserveBypass(GatedFeature.builtDua);
      if (reservation == null) {
        state = state.copyWith(error: () => 'Bypass unavailable. Try again.');
        return;
      }
      _activeBypassReservationId = reservation.reservationId;
      // Bypass owns the daily-counter increment server-side; skip markUsed.
      await _doBuild(consumeFreeUsage: false, isPremiumHint: false);
    } finally {
      _submitInFlight = false;
    }
  }

  /// Day-1 freebie variant (PR 4 of plan 2026-05-23, EXP-2). See the
  /// matching `ReflectNotifier.submitWithFirstBypass` for rationale on
  /// why this is atomic (no commit/cancel flow needed — no tokens
  /// at stake).
  Future<void> submitBuildWithFirstBypass() async {
    if (_submitInFlight || state.buildLoading) return;
    if (state.buildNeed.trim().isEmpty) return;
    _submitInFlight = true;
    try {
      final claimed =
          await GatingService().claimFirstBypass(GatedFeature.builtDua);
      if (!claimed) {
        state = state.copyWith(
          error: () => 'Freebie unavailable. Try again.',
        );
        return;
      }
      await _doBuild(consumeFreeUsage: false, isPremiumHint: false);
    } finally {
      _submitInFlight = false;
    }
  }

  /// Clears the build gate-blocked flag after the paywall sheet is dismissed.
  void dismissBuildGate() {
    state = state.copyWith(clearBuildGateResult: true);
  }

  /// Clears the build warmup-just-exhausted signal after the
  /// WarmupExhaustedSheet has been shown and dismissed.
  void dismissBuildWarmupExhausted() {
    state = state.copyWith(clearBuildWarmupJustExhausted: true);
  }

  /// Called by the UI after the upgrade sheet is dismissed or acknowledged.
  void dismissUpgradePrompt() {
    state = state.copyWith(needsUpgrade: false);
  }

  bool _isDuaOffTopic(String text) {
    final lower = text.toLowerCase().trim();
    if (lower.length < 5) return true;
    // Greetings / nonsense
    final offTopicPatterns = [
      RegExp(
          r"^(hi|hello|hey|salam|assalam|salaam|yo|sup|whats up|what's up)\s*[!.?]*\s*$",
          caseSensitive: false),
      RegExp(r'^(test|testing|asdf|aaa|123|lol|haha)\s*$',
          caseSensitive: false),
      RegExp(r'^(what is|who is|where is|how do i|how to)\s+\w',
          caseSensitive: false),
      RegExp(r'^(tell me a joke|sing|write a poem|make me laugh)',
          caseSensitive: false),
    ];
    // Harmful intent
    final harmfulPatterns = [
      RegExp(
          r'(curse|destroy|destory|destruction|punish|harm|kill|hurt|damage|ruin|death|die)',
          caseSensitive: false),
      RegExp(
          r'(against|upon|on)\s+.*(enemy|enemies|person|people|someone|haters)',
          caseSensitive: false),
      RegExp(r'(revenge|vengeance|retribution|payback)', caseSensitive: false),
    ];
    if (offTopicPatterns.any((p) => p.hasMatch(lower))) return true;
    if (harmfulPatterns.any((p) => p.hasMatch(lower))) return true;
    return false;
  }

  Future<void> _doBuild({
    bool consumeFreeUsage = false,
    bool? isPremiumHint,
  }) async {
    // Check for off-topic or harmful input
    if (_isDuaOffTopic(state.buildNeed)) {
      // If this came in as a bypass attempt, refund — the user got no value.
      await _cancelActiveBypassIfAny();
      state = state.copyWith(
        error: () =>
            'This place is for your heart. Please describe a sincere need or intention for your dua.',
      );
      return;
    }

    state = state.copyWith(
      buildLoading: true,
      buildProgress: 0.0,
      error: () => null,
      buildResult: () => null,
      buildCurrentSection: 0,
      buildResultSaveHandled: false,
    );

    // Start progress theater — eases out so it decelerates naturally.
    // Approaches ~95% asymptotically over time, never freezes at a fixed value.
    _progressTimer?.cancel();
    const tickInterval = Duration(milliseconds: 100);
    var elapsed = 0;

    _progressTimer = Timer.periodic(tickInterval, (timer) {
      elapsed += tickInterval.inMilliseconds;
      // Asymptotic curve: fast start, gradual slowdown
      // Reaches ~50% at 3s, ~75% at 6s, ~90% at 12s, ~95% at 20s
      final progress = 1.0 - (1.0 / (1.0 + elapsed / 4000.0));
      if (mounted) {
        state = state.copyWith(buildProgress: progress.clamp(0.0, 0.98));
      }
    });

    try {
      final result = await _dependencies.buildDua(state.buildNeed);
      // Only consume free usage when we got a real, parseable dua back.
      // An empty breakdown means OpenAI either rejected the input as off-topic
      // or returned an unparseable response. Either way, the user got no value
      // and shouldn't be charged a free build. The off-topic UI in
      // duas_screen.dart `_buildStepViewer` keys off `breakdown.isEmpty`, so
      // this gate is the same signal — keep them in sync.
      UsageOutcome? outcome;
      if (consumeFreeUsage && result.breakdown.isNotEmpty) {
        outcome = await GatingService().markUsed(
          GatedFeature.builtDua,
          isPremiumHint: isPremiumHint,
        );
      }
      // Bypass commit/cancel mirror the same "got real value" gate. Empty
      // breakdown = off-topic = refund the bypass; non-empty = commit.
      if (result.breakdown.isEmpty) {
        await _cancelActiveBypassIfAny();
      } else {
        await _commitActiveBypassIfAny();
      }
      _progressTimer?.cancel();
      // Jump to 100%
      state = state.copyWith(buildProgress: 1.0);
      // Brief pause at 100% before showing result
      await Future.delayed(_resultRevealDelay);
      state = state.copyWith(
        buildResult: () => result,
        buildLoading: false,
        buildWarmupJustExhausted:
            outcome == UsageOutcome.warmupJustExhausted
                ? GatedFeature.builtDua
                : null,
      );
      // Track names invoked in this dua
      if (result.namesUsed.isNotEmpty) {
        await _trackNamesInvoked(result.namesUsed.map((n) => n.name).toList());
      }
      // No XP — only Muhasabah, quests, and streak milestones grant XP.
    } catch (e) {
      _progressTimer?.cancel();
      await _cancelActiveBypassIfAny();
      state = state.copyWith(
        buildLoading: false,
        buildProgress: 0.0,
        buildResult: () => null,
        buildCurrentSection: 0,
        error: () => 'Something went wrong. Please try again.',
      );
    }
  }

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
    await GatingService().cancelBypass(id, GatedFeature.builtDua);
  }

  void nextBuildSection() {
    if (state.buildCurrentSection < 4) {
      final next = state.buildCurrentSection + 1;
      final breakdownLen = state.buildResult?.breakdown.length ?? 0;
      // If next index exceeds available sections, jump straight to Ameen (4)
      state = state.copyWith(
        buildCurrentSection: next < breakdownLen ? next : 4,
      );
    }
  }

  void previousBuildSection() {
    if (state.buildCurrentSection > 0) {
      state =
          state.copyWith(buildCurrentSection: state.buildCurrentSection - 1);
    }
  }

  void resetBuild() {
    state = state.copyWith(
      buildNeed: '',
      buildResult: () => null,
      buildLoading: false,
      buildCurrentSection: 0,
      error: () => null,
    );
  }

  // ── Save Built Dua ─────────────────────────────────────────

  static const int freeJournalLimit = 5;

  Future<void> saveCurrentBuiltDua() async {
    final result = state.buildResult;
    if (result == null) return;

    // Check journal limit for free users
    final premium = await PurchaseService().isPremium();
    if (!premium && state.savedBuiltDuas.length >= freeJournalLimit) {
      // Mark the attempt as handled so the Ameen screen doesn't loop: after
      // the user dismisses the upgrade sheet, needsUpgrade goes back to false
      // — without this flag, the widget rebuild would re-enter the auto-save
      // path, re-hit this cap, and re-raise the sheet immediately.
      state = state.copyWith(
        needsUpgrade: true,
        buildResultSaveHandled: true,
      );
      return;
    }

    final duaId = _dependencies.createId();
    final dua = SavedBuiltDua(
      id: duaId,
      savedAt: _dependencies.now().toIso8601String(),
      need: state.buildNeed,
      arabic: result.arabic,
      transliteration: result.transliteration,
      translation: result.translation,
    );

    final updated = [...state.savedBuiltDuas, dua];
    state = state.copyWith(
      savedBuiltDuas: updated,
      buildResultSaveHandled: true,
    );
    await _persistBuiltDuas(updated);

    // Write to Supabase
    final userId = supabaseSyncService.currentUserId;
    if (userId != null) {
      await supabaseSyncService.insertRow(
        'user_built_duas',
        dua.toSupabaseRow(userId),
      );
    }
  }

  Future<void> removeSavedBuiltDua(String id) async {
    final previous = List<SavedBuiltDua>.from(state.savedBuiltDuas);
    final updated = previous.where((d) => d.id != id).toList();
    state = state.copyWith(savedBuiltDuas: updated, error: () => null);
    await _persistBuiltDuas(updated);

    final userId = supabaseSyncService.currentUserId;
    if (userId == null) return;

    try {
      await supabaseSyncService.deleteRow('user_built_duas', 'id', id);
    } catch (_) {
      state = state.copyWith(
        savedBuiltDuas: previous,
        error: () => "Couldn't delete the dua. Please try again.",
      );
      await _persistBuiltDuas(previous);
    }
  }

  bool isBuiltDuaSaved() {
    final result = state.buildResult;
    if (result == null) return false;
    return state.savedBuiltDuas.any((d) => d.arabic == result.arabic);
  }

  // ── Save Related Dua ───────────────────────────────────────

  void toggleSaveRelatedDua(FindDuasDuaEntry dua) async {
    final id = '${dua.title}_${dua.source}'.hashCode.toString();
    final existing = state.savedRelatedDuas.any((d) => d.id == id);

    List<SavedRelatedDua> updated;
    if (existing) {
      updated = state.savedRelatedDuas.where((d) => d.id != id).toList();
    } else {
      updated = [
        ...state.savedRelatedDuas,
        SavedRelatedDua(
          id: id,
          title: dua.title,
          arabic: dua.arabic,
          transliteration: dua.transliteration,
          translation: dua.translation,
          source: dua.source,
        ),
      ];
    }
    state = state.copyWith(savedRelatedDuas: updated);
    await _persistRelatedDuas(updated);
  }

  Future<void> removeSavedRelatedDua(String id) async {
    final updated = state.savedRelatedDuas.where((d) => d.id != id).toList();
    state = state.copyWith(savedRelatedDuas: updated);
    await _persistRelatedDuas(updated);
  }

  bool isRelatedDuaSaved(FindDuasDuaEntry dua) {
    final id = '${dua.title}_${dua.source}'.hashCode.toString();
    return state.savedRelatedDuas.any((d) => d.id == id);
  }

  // ── Load saved duas on init ────────────────────────────────

  Future<void> loadSavedDuas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final builtJson = await supabaseSyncService.migrateLegacyStringCache(
          prefs, _builtDuasKey);
      final relatedJson = await supabaseSyncService.migrateLegacyStringCache(
          prefs, _relatedDuasKey);
      final browseIds = await supabaseSyncService.migrateLegacyStringListCache(
          prefs, _browseDuaIdsKey);

      if (builtJson != null) {
        final list = (jsonDecode(builtJson) as List)
            .map((e) => SavedBuiltDua.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(savedBuiltDuas: list);
      }
      if (relatedJson != null) {
        final list = (jsonDecode(relatedJson) as List)
            .map((e) => SavedRelatedDua.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(savedRelatedDuas: list);
      }
      if (browseIds != null) {
        state = state.copyWith(savedDuaIds: browseIds.toSet());
      }
    } catch (_) {}
  }

  // ── Persistence helpers ────────────────────────────────────

  Future<void> _persistBuiltDuas(List<SavedBuiltDua> duas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      supabaseSyncService.scopedKey(_builtDuasKey),
      jsonEncode(duas.map((d) => d.toJson()).toList()),
    );
  }

  Future<void> _persistRelatedDuas(List<SavedRelatedDua> duas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      supabaseSyncService.scopedKey(_relatedDuasKey),
      jsonEncode(duas.map((d) => d.toJson()).toList()),
    );
  }

  void onCatalogRefreshed() {
    state = state.copyWith();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final duasProvider = StateNotifierProvider<DuasNotifier, DuasState>(
  (ref) {
    final notifier = DuasNotifier();
    ref.listen<int>(
      publicCatalogRegistryProvider.select((registry) => registry.revision),
      (_, __) {
        notifier.onCatalogRefreshed();
      },
    );
    return notifier;
  },
);
