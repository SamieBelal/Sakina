import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sakina/services/public_catalog_contracts.dart';

import '../../tool/import_public_catalog_snapshots.dart';

void main() {
  group('importPublicCatalogSnapshots', () {
    test('upserts snapshots, deletes stale rows, and verifies anon read',
        () async {
      final directory = await _writeSnapshots(publicCatalogContracts);
      addTearDown(() => directory.delete(recursive: true));

      final remoteState = <String, List<Map<String, dynamic>>>{
        for (final definition in publicCatalogContracts)
          definition.table: List<Map<String, dynamic>>.from(
            _rowsForDefinition(definition),
          ),
      };
      remoteState[dailyQuestionsPublicCatalog.table] = [
        ...remoteState[dailyQuestionsPublicCatalog.table]!,
        {
          'id': 999,
          'question': 'Stale question',
          'options': ['A', 'B'],
        },
      ];

      var sawAnonRead = false;
      final client = MockClient((request) async {
        final table = request.url.pathSegments.last;
        final definition = publicCatalogContracts.firstWhere(
          (item) => item.table == table,
        );
        final apiKey = request.headers['apikey'];
        if (apiKey == 'anon-key') {
          sawAnonRead = true;
        }

        switch (request.method) {
          case 'GET':
            return http.Response(
              jsonEncode(_sortRows(definition, remoteState[table]!)),
              200,
              headers: {'content-type': 'application/json'},
            );
          case 'POST':
            expect(apiKey, 'service-role-key');
            expect(request.url.queryParameters['on_conflict'],
                definition.primaryKey);

            final incoming = (jsonDecode(request.body) as List<dynamic>)
                .map((row) => Map<String, dynamic>.from(row as Map))
                .toList();
            final merged = <String, Map<String, dynamic>>{
              for (final row in remoteState[table]!)
                '${row[definition.primaryKey]}': Map<String, dynamic>.from(row),
            };
            for (final row in incoming) {
              merged['${row[definition.primaryKey]}'] = row;
            }
            remoteState[table] = merged.values.toList();
            return http.Response('', 201);
          case 'DELETE':
            expect(apiKey, 'service-role-key');
            final filter = request.url.queryParameters[definition.primaryKey];
            expect(filter, isNotNull);
            final primaryKeyValue = filter!.replaceFirst('eq.', '');
            remoteState[table] = remoteState[table]!
                .where(
                    (row) => '${row[definition.primaryKey]}' != primaryKeyValue)
                .toList();
            return http.Response('', 204);
          default:
            fail('Unexpected method ${request.method}');
        }
      });

      await importPublicCatalogSnapshots(
        supabaseUrl: 'https://example.supabase.co',
        serviceRoleKey: 'service-role-key',
        anonKey: 'anon-key',
        inputDirectory: directory.path,
        verifyAnonRead: true,
        client: client,
      );

      expect(sawAnonRead, isTrue);
      expect(
        _sortRows(
          dailyQuestionsPublicCatalog,
          remoteState[dailyQuestionsPublicCatalog.table]!,
        ),
        _rowsForDefinition(dailyQuestionsPublicCatalog),
      );
    });

    test('fails before writing when a snapshot is incomplete', () async {
      final brokenRows = _rowsForDefinition(collectibleNamesPublicCatalog)
        ..removeLast();
      final directory = await _writeSnapshots(
        publicCatalogContracts,
        overrides: {
          collectibleNamesPublicCatalog.fileName: brokenRows,
        },
      );
      addTearDown(() => directory.delete(recursive: true));

      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount += 1;
        return http.Response('[]', 200);
      });

      await expectLater(
        () => importPublicCatalogSnapshots(
          supabaseUrl: 'https://example.supabase.co',
          serviceRoleKey: 'service-role-key',
          inputDirectory: directory.path,
          client: client,
        ),
        throwsA(isA<StateError>()),
      );

      expect(requestCount, 0);
    });

    test('fails when post-write verification does not match the snapshot',
        () async {
      final directory = await _writeSnapshots(publicCatalogContracts);
      addTearDown(() => directory.delete(recursive: true));

      final remoteState = <String, List<Map<String, dynamic>>>{
        for (final definition in publicCatalogContracts) definition.table: [],
      };

      final client = MockClient((request) async {
        final table = request.url.pathSegments.last;
        if (request.method == 'POST' &&
            table == dailyQuestionsPublicCatalog.table) {
          return http.Response('', 201);
        }
        if (request.method == 'POST') {
          remoteState[table] = (jsonDecode(request.body) as List<dynamic>)
              .map((row) => Map<String, dynamic>.from(row as Map))
              .toList();
          return http.Response('', 201);
        }
        if (request.method == 'GET') {
          return http.Response(jsonEncode(remoteState[table]), 200);
        }
        if (request.method == 'DELETE') {
          return http.Response('', 204);
        }
        fail('Unexpected method ${request.method}');
      });

      await expectLater(
        () => importPublicCatalogSnapshots(
          supabaseUrl: 'https://example.supabase.co',
          serviceRoleKey: 'service-role-key',
          inputDirectory: directory.path,
          client: client,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('dry run validates snapshots without remote writes', () async {
      final directory = await _writeSnapshots(publicCatalogContracts);
      addTearDown(() => directory.delete(recursive: true));

      final client = MockClient((request) async {
        fail('Dry run should not hit the network');
      });

      await importPublicCatalogSnapshots(
        supabaseUrl: 'https://example.supabase.co',
        serviceRoleKey: 'service-role-key',
        inputDirectory: directory.path,
        dryRun: true,
        client: client,
      );
    });
  });
}

Future<Directory> _writeSnapshots(
  List<PublicCatalogContract> definitions, {
  Map<String, List<Map<String, dynamic>>> overrides = const {},
}) async {
  final directory = await Directory.systemTemp.createTemp(
    'public-catalog-import-test',
  );

  for (final definition in definitions) {
    final rows =
        overrides[definition.fileName] ?? _rowsForDefinition(definition);
    final file = File('${directory.path}/${definition.fileName}');
    await file.writeAsString(jsonEncode(rows));
  }

  return directory;
}

List<Map<String, dynamic>> _sortRows(
  PublicCatalogContract definition,
  List<Map<String, dynamic>> rows,
) {
  final copy = rows.map(Map<String, dynamic>.from).toList();
  copy.sort((left, right) {
    final leftValue = left[definition.orderBy] as Comparable<dynamic>;
    final rightValue = right[definition.orderBy] as Comparable<dynamic>;
    return leftValue.compareTo(rightValue);
  });
  return copy;
}

List<Map<String, dynamic>> _rowsForDefinition(
  PublicCatalogContract definition,
) {
  switch (definition.table) {
    case 'daily_questions':
      return List.generate(
        definition.expectedCount,
        (index) => {
          'id': index,
          'question': 'Question ${index + 1}',
          'options': ['A', 'B', 'C'],
        },
      );
    case 'browse_duas':
      return List.generate(
        definition.expectedCount,
        (index) => {
          'id': 'dua-${index + 1}',
          'category': 'morning',
          'title': 'Dua ${index + 1}',
          'arabic': 'arabic-${index + 1}',
          'transliteration': 'Dua ${index + 1}',
          'translation': 'Translation ${index + 1}',
          'source': 'Source ${index + 1}',
          'emotion_tags': ['calm'],
          'when_to_recite': 'Anytime',
        },
      );
    case 'discovery_quiz_questions':
      return List.generate(
        definition.expectedCount,
        (index) => {
          'id': 'q${index + 1}',
          'prompt': 'Prompt ${index + 1}',
          'sort_order': index,
          'options': [
            {
              'text': 'Option A',
              'scores': {'ar-rahman': 1},
            },
          ],
        },
      );
    case 'name_anchors':
      return List.generate(
        definition.expectedCount,
        (index) => {
          'name_key': 'name-${index + 1}',
          'name': 'Name ${index + 1}',
          'arabic': 'arabic-${index + 1}',
          'anchor': 'Anchor ${index + 1}',
          'detail': 'Detail ${index + 1}',
        },
      );
    case 'collectible_names':
      return List.generate(
        definition.expectedCount,
        (index) => {
          'id': index + 1,
          'arabic': 'arabic-${index + 1}',
          'transliteration': 'Name ${index + 1}',
          'english': 'English ${index + 1}',
          'meaning': 'Meaning ${index + 1}',
          'lesson': 'Lesson ${index + 1}',
          'hadith': 'Hadith ${index + 1}',
          'dua_arabic': 'dua-arabic-${index + 1}',
          'dua_transliteration': 'Dua ${index + 1}',
          'dua_translation': 'Prayer ${index + 1}',
        },
      );
    default:
      throw StateError('Unhandled table ${definition.table}');
  }
}
