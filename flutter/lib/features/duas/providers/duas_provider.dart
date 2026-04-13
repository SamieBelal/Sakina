import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/constants/duas.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/services/daily_usage_service.dart';
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

  /// True when build-a-dua hits the free daily limit and needs a token.
  final bool buildNeedsToken;

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
    this.buildNeedsToken = false,
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
    bool? buildNeedsToken,
    double? buildProgress,
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
      buildNeedsToken: buildNeedsToken ?? this.buildNeedsToken,
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

  Future<void> submitBuild() async {
    if (state.buildNeed.trim().isEmpty) return;
    final isFree = await canBuildDuaFree();
    if (!isFree) {
      state = state.copyWith(buildNeedsToken: true);
      return;
    }
    await _doBuild(consumeFreeUsage: true);
  }

  Future<void> submitBuildWithToken() async {
    state = state.copyWith(buildNeedsToken: false);
    await _doBuild();
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

  Future<void> _doBuild({bool consumeFreeUsage = false}) async {
    // Check for off-topic or harmful input
    if (_isDuaOffTopic(state.buildNeed)) {
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
      if (consumeFreeUsage) {
        await incrementBuiltDuaUsage();
      }
      _progressTimer?.cancel();
      // Jump to 100%
      state = state.copyWith(buildProgress: 1.0);
      // Brief pause at 100% before showing result
      await Future.delayed(_resultRevealDelay);
      state = state.copyWith(buildResult: () => result, buildLoading: false);
      // Track names invoked in this dua
      if (result.namesUsed.isNotEmpty) {
        await _trackNamesInvoked(result.namesUsed.map((n) => n.name).toList());
      }
      // No XP — only Muhasabah, quests, and streak milestones grant XP.
    } catch (e) {
      _progressTimer?.cancel();
      state = state.copyWith(
        buildLoading: false,
        buildProgress: 0.0,
        buildResult: () => null,
        buildCurrentSection: 0,
        error: () => 'Something went wrong. Please try again.',
      );
    }
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
      return; // silently skip — UI should show upgrade prompt
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
    state = state.copyWith(savedBuiltDuas: updated);
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
    final updated = state.savedBuiltDuas.where((d) => d.id != id).toList();
    state = state.copyWith(savedBuiltDuas: updated);
    await _persistBuiltDuas(updated);

    final userId = supabaseSyncService.currentUserId;
    if (userId != null) {
      await supabaseSyncService.deleteRow('user_built_duas', 'id', id);
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
