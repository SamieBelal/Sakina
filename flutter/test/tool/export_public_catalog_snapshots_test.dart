import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sakina/services/public_catalog_contracts.dart';

import '../../tool/export_public_catalog_snapshots.dart';

void main() {
  group('exportPublicCatalogSnapshots', () {
    test('writes validated snapshots fetched from Supabase', () async {
      final directory = await Directory.systemTemp.createTemp(
        'public-catalog-export-test',
      );
      addTearDown(() => directory.delete(recursive: true));

      final client = MockClient((request) async {
        final table = request.url.pathSegments.last;
        final definition = publicCatalogContracts.firstWhere(
          (item) => item.table == table,
        );

        expect(request.headers['apikey'], 'anon-key');
        expect(request.headers['Authorization'], 'Bearer anon-key');
        expect(
            request.url.queryParameters['order'], '${definition.orderBy}.asc');

        return http.Response(
          jsonEncode(_rowsForDefinition(definition)),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await exportPublicCatalogSnapshots(
        supabaseUrl: 'https://example.supabase.co/',
        anonKey: 'anon-key',
        outputDirectory: directory.path,
        client: client,
      );

      final exportedFiles = directory
          .listSync()
          .whereType<File>()
          .map((file) => file.path)
          .toSet();
      expect(exportedFiles, hasLength(publicCatalogContracts.length));

      final dailyQuestionsFile = File('${directory.path}/daily_questions.json');
      final dailyQuestions = jsonDecode(
        await dailyQuestionsFile.readAsString(),
      ) as List<dynamic>;
      expect(dailyQuestions, hasLength(30));
      expect(dailyQuestions.first['question'], 'Question 1');
    });

    test('refuses to overwrite snapshots when a catalog is incomplete',
        () async {
      final directory = await Directory.systemTemp.createTemp(
        'public-catalog-export-invalid',
      );
      addTearDown(() => directory.delete(recursive: true));

      final client = MockClient((request) async {
        final table = request.url.pathSegments.last;
        final definition = publicCatalogContracts.firstWhere(
          (item) => item.table == table,
        );

        final rows = _rowsForDefinition(definition);
        if (table == 'collectible_names') {
          rows.removeLast();
        }

        return http.Response(jsonEncode(rows), 200);
      });

      await expectLater(
        () => exportPublicCatalogSnapshots(
          supabaseUrl: 'https://example.supabase.co',
          anonKey: 'anon-key',
          outputDirectory: directory.path,
          client: client,
        ),
        throwsA(isA<StateError>()),
      );

      expect(
        File('${directory.path}/collectible_names.json').existsSync(),
        isFalse,
      );
    });
  });
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
          'category': 'calm',
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
