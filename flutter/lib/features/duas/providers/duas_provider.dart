import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/constants/duas.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/services/daily_usage_service.dart';
import 'package:sakina/services/xp_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Tab enum
// ---------------------------------------------------------------------------

enum DuasTab { browse, find, build }

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

  factory SavedRelatedDua.fromJson(Map<String, dynamic> json) => SavedRelatedDua(
    id: json['id'] as String,
    title: json['title'] as String,
    arabic: json['arabic'] as String,
    transliteration: json['transliteration'] as String,
    translation: json['translation'] as String,
    source: json['source'] as String,
  );
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class DuasState {
  final DuasTab? activeTab;
  final String selectedCategory;
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

  const DuasState({
    this.activeTab,
    this.selectedCategory = 'anxiety',
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
  });

  DuasState copyWith({
    DuasTab? Function()? activeTab,
    String? selectedCategory,
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
  }) {
    return DuasState(
      activeTab: activeTab != null ? activeTab() : this.activeTab,
      selectedCategory: selectedCategory ?? this.selectedCategory,
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
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class DuasNotifier extends StateNotifier<DuasState> {
  DuasNotifier() : super(const DuasState()) {
    loadSavedDuas();
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
    await prefs.setStringList('saved_browse_dua_ids', updated.toList());
  }

  List<BrowseDua> get filteredBrowseDuas {
    return browseDuas
        .where((d) => d.category == state.selectedCategory)
        .toList();
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
      final result = await findDuas(state.findNeed);
      state = state.copyWith(findResult: () => result, findLoading: false);
      await awardXp(10); // dua read
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
    await incrementBuiltDuaUsage();
    await _doBuild();
  }

  Future<void> submitBuildWithToken() async {
    state = state.copyWith(buildNeedsToken: false);
    await _doBuild();
  }

  Future<void> _doBuild() async {
    state = state.copyWith(
      buildLoading: true,
      error: () => null,
      buildResult: () => null,
      buildCurrentSection: 0,
    );
    try {
      final result = await buildDua(state.buildNeed);
      state = state.copyWith(buildResult: () => result, buildLoading: false);
      await awardXp(15); // built dua completed
    } catch (e) {
      state = state.copyWith(
        buildLoading: false,
        error: () => 'Something went wrong. Please try again.',
      );
    }
  }

  void nextBuildSection() {
    if (state.buildCurrentSection < 4) {
      state = state.copyWith(
        buildCurrentSection: state.buildCurrentSection + 1,
      );
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

  Future<void> saveCurrentBuiltDua() async {
    final result = state.buildResult;
    if (result == null) return;

    final dua = SavedBuiltDua(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      savedAt: DateTime.now().toIso8601String(),
      need: state.buildNeed,
      arabic: result.arabic,
      transliteration: result.transliteration,
      translation: result.translation,
    );

    final updated = [...state.savedBuiltDuas, dua];
    state = state.copyWith(savedBuiltDuas: updated);
    await _persistBuiltDuas(updated);
  }

  Future<void> removeSavedBuiltDua(String id) async {
    final updated = state.savedBuiltDuas.where((d) => d.id != id).toList();
    state = state.copyWith(savedBuiltDuas: updated);
    await _persistBuiltDuas(updated);
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
      final builtJson = prefs.getString('saved_built_duas');
      final relatedJson = prefs.getString('saved_related_duas');
      final browseIds = prefs.getStringList('saved_browse_dua_ids');

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
      'saved_built_duas',
      jsonEncode(duas.map((d) => d.toJson()).toList()),
    );
  }

  Future<void> _persistRelatedDuas(List<SavedRelatedDua> duas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'saved_related_duas',
      jsonEncode(duas.map((d) => d.toJson()).toList()),
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final duasProvider = StateNotifierProvider<DuasNotifier, DuasState>(
  (ref) => DuasNotifier(),
);
