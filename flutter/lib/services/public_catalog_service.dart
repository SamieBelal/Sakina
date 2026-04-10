import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PublicCatalogKeys {
  static const dailyQuestions = 'sakina_public_daily_questions_v1';
  static const browseDuas = 'sakina_public_browse_duas_v1';
  static const discoveryQuizQuestions =
      'sakina_public_discovery_quiz_questions_v1';
  static const nameAnchors = 'sakina_public_name_anchors_v1';
  static const collectibleNames = 'sakina_public_collectible_names_v1';
}

class PublicCatalogAssets {
  static const dailyQuestions = 'assets/content/daily_questions.json';
  static const browseDuas = 'assets/content/browse_duas.json';
  static const discoveryQuizQuestions =
      'assets/content/discovery_quiz_questions.json';
  static const nameAnchors = 'assets/content/name_anchors.json';
  static const collectibleNames = 'assets/content/collectible_names.json';
}

class _PublicCatalogDefinition {
  final String cacheKey;
  final String assetPath;
  final String table;
  final String orderBy;
  final int expectedCount;
  final List<String> requiredKeys;
  final bool Function(Map<String, dynamic> row)? rowValidator;

  const _PublicCatalogDefinition({
    required this.cacheKey,
    required this.assetPath,
    required this.table,
    required this.orderBy,
    required this.expectedCount,
    required this.requiredKeys,
    this.rowValidator,
  });
}

class PublicCatalogRegistry extends ChangeNotifier {
  int _revision = 0;

  int get revision => _revision;

  void markChanged() {
    _revision += 1;
    notifyListeners();
  }
}

PublicCatalogRegistry _publicCatalogRegistry = PublicCatalogRegistry();

final publicCatalogRegistryProvider =
    ChangeNotifierProvider<PublicCatalogRegistry>((ref) {
  return _publicCatalogRegistry;
});

const _publicCatalogs = <_PublicCatalogDefinition>[
  _PublicCatalogDefinition(
    cacheKey: PublicCatalogKeys.dailyQuestions,
    assetPath: PublicCatalogAssets.dailyQuestions,
    table: 'daily_questions',
    orderBy: 'id',
    expectedCount: 30,
    requiredKeys: ['id', 'question', 'options'],
    rowValidator: _isValidDailyQuestionRow,
  ),
  _PublicCatalogDefinition(
    cacheKey: PublicCatalogKeys.browseDuas,
    assetPath: PublicCatalogAssets.browseDuas,
    table: 'browse_duas',
    orderBy: 'id',
    expectedCount: 76,
    requiredKeys: [
      'id',
      'category',
      'title',
      'arabic',
      'transliteration',
      'translation',
      'source',
    ],
    rowValidator: _isValidBrowseDuaRow,
  ),
  _PublicCatalogDefinition(
    cacheKey: PublicCatalogKeys.discoveryQuizQuestions,
    assetPath: PublicCatalogAssets.discoveryQuizQuestions,
    table: 'discovery_quiz_questions',
    orderBy: 'sort_order',
    expectedCount: 6,
    requiredKeys: ['id', 'prompt', 'options', 'sort_order'],
    rowValidator: _isValidDiscoveryQuizQuestionRow,
  ),
  _PublicCatalogDefinition(
    cacheKey: PublicCatalogKeys.nameAnchors,
    assetPath: PublicCatalogAssets.nameAnchors,
    table: 'name_anchors',
    orderBy: 'name_key',
    expectedCount: 32,
    requiredKeys: ['name_key', 'name', 'arabic', 'anchor', 'detail'],
  ),
  _PublicCatalogDefinition(
    cacheKey: PublicCatalogKeys.collectibleNames,
    assetPath: PublicCatalogAssets.collectibleNames,
    table: 'collectible_names',
    orderBy: 'id',
    expectedCount: 99,
    requiredKeys: [
      'id',
      'arabic',
      'transliteration',
      'english',
      'meaning',
      'lesson',
      'hadith',
      'dua_arabic',
      'dua_transliteration',
      'dua_translation',
    ],
    rowValidator: _isValidCollectibleNameRow,
  ),
];

final Map<String, String> _catalogJsonByKey = {};
final Map<String, Object> _parsedCatalogCache = {};

/// Returns a cached parsed result for [cacheKey], or calls [parser] if the
/// underlying JSON has changed since the last parse. Avoids re-decoding on
/// every getter call.
T getParsedCatalog<T>(String cacheKey, T Function(String json) parser) {
  final json = _catalogJsonByKey[cacheKey];
  if (json == null || json.isEmpty) {
    _parsedCatalogCache.remove(cacheKey);
    throw StateError('No catalog JSON for $cacheKey');
  }
  final existing = _parsedCatalogCache[cacheKey];
  if (existing is _ParsedEntry<T>) return existing.value;
  final parsed = parser(json);
  _parsedCatalogCache[cacheKey] = _ParsedEntry<T>(parsed);
  return parsed;
}

class _ParsedEntry<T> {
  final T value;
  const _ParsedEntry(this.value);
}

Future<void> bootstrapPublicCatalogs() async {
  var didChange = false;
  for (final catalog in _publicCatalogs) {
    final json = await supabaseSyncService.ensurePublicCatalogCache(
      cacheKey: catalog.cacheKey,
      assetPath: catalog.assetPath,
    );
    if (json != null && json.isNotEmpty) {
      if (_catalogJsonByKey[catalog.cacheKey] != json) {
        _catalogJsonByKey[catalog.cacheKey] = json;
        _parsedCatalogCache.remove(catalog.cacheKey);
        didChange = true;
      }
    }
  }
  if (didChange) {
    _publicCatalogRegistry.markChanged();
  }
}

Future<void> refreshPublicCatalogsFromSupabase({
  bool skipClientCheck = false,
}) async {
  if (!skipClientCheck && !_hasSupabaseClient()) return;

  // Fetch all catalogs in parallel — one round trip each, no dependencies.
  final futures = _publicCatalogs.map((catalog) async {
    final rows = await supabaseSyncService.fetchPublicRows(
      catalog.table,
      orderBy: catalog.orderBy,
      ascending: true,
    );
    return (catalog, rows);
  });
  final results = await Future.wait(futures);

  var didChange = false;
  for (final (catalog, rows) in results) {
    if (rows.isEmpty) continue;
    if (!_isValidCatalogPayload(catalog, rows)) continue;

    final json = jsonEncode(rows);
    if (_catalogJsonByKey[catalog.cacheKey] == json) continue;

    await supabaseSyncService.setPublicCatalogCache(catalog.cacheKey, json);
    _catalogJsonByKey[catalog.cacheKey] = json;
    _parsedCatalogCache.remove(catalog.cacheKey);
    didChange = true;
  }

  if (didChange) {
    _publicCatalogRegistry.markChanged();
  }
}

String? getPublicCatalogJson(String cacheKey) {
  return _catalogJsonByKey[cacheKey];
}

Future<void> setPublicCatalogJsonForTesting(
  String cacheKey,
  String json,
) async {
  await supabaseSyncService.setPublicCatalogCache(cacheKey, json);
  _catalogJsonByKey[cacheKey] = json;
  _parsedCatalogCache.remove(cacheKey);
  _publicCatalogRegistry.markChanged();
}

@visibleForTesting
void debugResetPublicCatalogs() {
  _catalogJsonByKey.clear();
  _parsedCatalogCache.clear();
  _publicCatalogRegistry = PublicCatalogRegistry();
}

@visibleForTesting
int debugPublicCatalogRevision() {
  return _publicCatalogRegistry.revision;
}

bool _hasSupabaseClient() {
  try {
    Supabase.instance.client;
    return true;
  } catch (_) {
    return false;
  }
}

bool _isValidCatalogPayload(
  _PublicCatalogDefinition catalog,
  List<Map<String, dynamic>> rows,
) {
  if (rows.length != catalog.expectedCount) {
    debugPrint(
      '[PublicCatalogService] ${catalog.table} expected '
      '${catalog.expectedCount} rows, got ${rows.length}. Keeping existing cache.',
    );
    return false;
  }

  for (final row in rows) {
    for (final key in catalog.requiredKeys) {
      if (!row.containsKey(key) || row[key] == null) {
        debugPrint(
          '[PublicCatalogService] ${catalog.table} row missing required key '
          '"$key". Keeping existing cache.',
        );
        return false;
      }
    }

    final rowValidator = catalog.rowValidator;
    if (rowValidator != null && !rowValidator(row)) {
      debugPrint(
        '[PublicCatalogService] ${catalog.table} row failed validation. '
        'Keeping existing cache.',
      );
      return false;
    }
  }

  if (catalog.cacheKey == PublicCatalogKeys.collectibleNames &&
      !_hasStableCollectibleIds(rows)) {
    debugPrint(
      '[PublicCatalogService] ${catalog.table} ids failed canonical '
      'validation. Keeping existing cache.',
    );
    return false;
  }

  return true;
}

bool _hasStableCollectibleIds(List<Map<String, dynamic>> rows) {
  final ids = rows
      .map((row) => (row['id'] as num?)?.toInt())
      .whereType<int>()
      .toList()
    ..sort();
  final expectedIds = List<int>.generate(99, (index) => index + 1);
  if (ids.length != expectedIds.length) {
    return false;
  }

  for (var index = 0; index < expectedIds.length; index++) {
    if (ids[index] != expectedIds[index]) {
      return false;
    }
  }

  return true;
}

bool _isValidDailyQuestionRow(Map<String, dynamic> row) {
  return row['question'] is String && row['options'] is List;
}

bool _isValidBrowseDuaRow(Map<String, dynamic> row) {
  final emotionTags = row['emotion_tags'];
  return row['id'] is String &&
      row['title'] is String &&
      row['translation'] is String &&
      (emotionTags == null || emotionTags is List);
}

bool _isValidDiscoveryQuizQuestionRow(Map<String, dynamic> row) {
  final options = row['options'];
  if (options is! List || options.isEmpty) return false;

  for (final option in options) {
    if (option is! Map<String, dynamic>) return false;
    if (option['text'] is! String ||
        option['scores'] is! Map<String, dynamic>) {
      return false;
    }
  }

  return true;
}

bool _isValidCollectibleNameRow(Map<String, dynamic> row) {
  return row['id'] is num &&
      row['arabic'] is String &&
      row['transliteration'] is String &&
      row['english'] is String;
}
