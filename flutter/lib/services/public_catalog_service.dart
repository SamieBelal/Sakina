import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/services/public_catalog_contracts.dart';
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

class _PublicCatalogDefinition {
  final String cacheKey;
  final PublicCatalogContract contract;

  const _PublicCatalogDefinition({
    required this.cacheKey,
    required this.contract,
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
    contract: dailyQuestionsPublicCatalog,
  ),
  _PublicCatalogDefinition(
    cacheKey: PublicCatalogKeys.browseDuas,
    contract: browseDuasPublicCatalog,
  ),
  _PublicCatalogDefinition(
    cacheKey: PublicCatalogKeys.discoveryQuizQuestions,
    contract: discoveryQuizQuestionsPublicCatalog,
  ),
  _PublicCatalogDefinition(
    cacheKey: PublicCatalogKeys.nameAnchors,
    contract: nameAnchorsPublicCatalog,
  ),
  _PublicCatalogDefinition(
    cacheKey: PublicCatalogKeys.collectibleNames,
    contract: collectibleNamesPublicCatalog,
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
      assetPath: catalog.contract.assetPath,
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
      catalog.contract.table,
      orderBy: catalog.contract.orderBy,
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
  try {
    validatePublicCatalogRows(catalog.contract, rows);
    return true;
  } catch (error) {
    debugPrint(
      '[PublicCatalogService] ${catalog.contract.table} validation failed: '
      '$error Keeping existing cache.',
    );
    return false;
  }
}
