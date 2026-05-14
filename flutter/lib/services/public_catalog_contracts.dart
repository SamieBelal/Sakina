typedef PublicCatalogRowValidator = bool Function(Map<String, dynamic> row);

class PublicCatalogContract {
  final String table;
  final String orderBy;
  final String fileName;
  final int expectedCount;
  final List<String> requiredKeys;
  final String primaryKey;
  final PublicCatalogRowValidator? rowValidator;
  final bool requiresCanonicalPrimaryKeys;

  const PublicCatalogContract({
    required this.table,
    required this.orderBy,
    required this.fileName,
    required this.expectedCount,
    required this.requiredKeys,
    required this.primaryKey,
    this.rowValidator,
    this.requiresCanonicalPrimaryKeys = false,
  });

  String get assetPath => 'assets/content/$fileName';
}

const dailyQuestionsPublicCatalog = PublicCatalogContract(
  table: 'daily_questions',
  orderBy: 'id',
  fileName: 'daily_questions.json',
  expectedCount: 30,
  requiredKeys: ['id', 'question', 'options'],
  primaryKey: 'id',
  rowValidator: isValidDailyQuestionRow,
);

const browseDuasPublicCatalog = PublicCatalogContract(
  table: 'browse_duas',
  orderBy: 'id',
  fileName: 'browse_duas.json',
  // 121 entries after PR #12 (feat(duas): expand browse_duas 76 → 121).
  // Contract was missed in that PR and only surfaced when the test suite
  // ran cleanly; bumped here so PublicCatalogService.bootstrap doesn't
  // silently reject the catalog and keep the stale 76-row cache.
  expectedCount: 121,
  requiredKeys: [
    'id',
    'category',
    'title',
    'arabic',
    'transliteration',
    'translation',
    'source',
  ],
  primaryKey: 'id',
  rowValidator: isValidBrowseDuaRow,
);

const discoveryQuizQuestionsPublicCatalog = PublicCatalogContract(
  table: 'discovery_quiz_questions',
  orderBy: 'sort_order',
  fileName: 'discovery_quiz_questions.json',
  // Plan 3 (2026-05-12) expanded the quiz from 6 to 18 questions. The catalog
  // test pins this count to the JSON shipped in assets/content/.
  expectedCount: 18,
  requiredKeys: ['id', 'prompt', 'options', 'sort_order'],
  primaryKey: 'id',
  rowValidator: isValidDiscoveryQuizQuestionRow,
);

const nameAnchorsPublicCatalog = PublicCatalogContract(
  table: 'name_anchors',
  orderBy: 'name_key',
  fileName: 'name_anchors.json',
  // 98 = 99 canonical Names from collectible_names.json minus the proper Name
  // "Allah" (id=1), which has no attribute anchor. Plan 4 (2026-05-12)
  // backfilled this from 32 to 98 by dropping the 3 non-canonical anchors
  // (al-qarib, ar-rabb, al-jamil) and authoring 69 new entries.
  expectedCount: 98,
  requiredKeys: ['name_key', 'name', 'arabic', 'anchor', 'detail'],
  primaryKey: 'name_key',
);

const collectibleNamesPublicCatalog = PublicCatalogContract(
  table: 'collectible_names',
  orderBy: 'id',
  fileName: 'collectible_names.json',
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
  primaryKey: 'id',
  rowValidator: isValidCollectibleNameRow,
  requiresCanonicalPrimaryKeys: true,
);

const publicCatalogContracts = <PublicCatalogContract>[
  dailyQuestionsPublicCatalog,
  browseDuasPublicCatalog,
  discoveryQuizQuestionsPublicCatalog,
  nameAnchorsPublicCatalog,
  collectibleNamesPublicCatalog,
];

void validatePublicCatalogRows(
  PublicCatalogContract contract,
  List<Map<String, dynamic>> rows,
) {
  if (rows.length != contract.expectedCount) {
    throw StateError(
      'Expected ${contract.expectedCount} rows for ${contract.table}, '
      'got ${rows.length}.',
    );
  }

  for (final row in rows) {
    for (final key in contract.requiredKeys) {
      if (!row.containsKey(key) || row[key] == null) {
        throw StateError(
          'Row in ${contract.table} is missing required key "$key".',
        );
      }
    }

    final rowValidator = contract.rowValidator;
    if (rowValidator != null && !rowValidator(row)) {
      throw StateError('Row in ${contract.table} failed validation.');
    }
  }

  if (contract.requiresCanonicalPrimaryKeys &&
      !_hasCanonicalPrimaryKeys(contract, rows)) {
    throw StateError(
      '${contract.table} primary keys failed canonical validation.',
    );
  }
}

bool isValidDailyQuestionRow(Map<String, dynamic> row) {
  return row['question'] is String && row['options'] is List;
}

bool isValidBrowseDuaRow(Map<String, dynamic> row) {
  final emotionTags = row['emotion_tags'];
  return row['id'] is String &&
      row['title'] is String &&
      row['translation'] is String &&
      (emotionTags == null || emotionTags is List);
}

bool isValidDiscoveryQuizQuestionRow(Map<String, dynamic> row) {
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

bool isValidCollectibleNameRow(Map<String, dynamic> row) {
  return row['id'] is num &&
      row['arabic'] is String &&
      row['transliteration'] is String &&
      row['english'] is String;
}

bool _hasCanonicalPrimaryKeys(
  PublicCatalogContract contract,
  List<Map<String, dynamic>> rows,
) {
  if (contract.table != collectibleNamesPublicCatalog.table) return true;

  final ids = rows
      .map((row) => (row[contract.primaryKey] as num?)?.toInt())
      .whereType<int>()
      .toList()
    ..sort();
  final expectedIds = List<int>.generate(contract.expectedCount, (i) => i + 1);

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
