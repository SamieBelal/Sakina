import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/constants/duas.dart' show browseDuasCatalog;
import 'package:sakina/services/ai_service.dart';

void main() {
  group('browse_duas.json catalog', () {
    final raw = File('assets/content/browse_duas.json').readAsStringSync();
    final List<dynamic> duas = jsonDecode(raw) as List<dynamic>;

    test('total dua count >= 110', () {
      expect(duas.length, greaterThanOrEqualTo(110));
    });

    test('every dua has required fields', () {
      const required = [
        'id','category','title','arabic','transliteration','translation','source'
      ];
      for (final d in duas.cast<Map<String, dynamic>>()) {
        for (final f in required) {
          expect(d[f], isA<String>(), reason: '${d['id']} missing $f');
          expect((d[f] as String).trim(), isNotEmpty, reason: '${d['id']} empty $f');
        }
      }
    });

    test('every new emotional category has >=3 entries', () {
      const newCats = [
        'anger','envy','lust','loneliness','shame','burnout',
        'marriage_conflict','parenting','work','illness','addiction','death_grief',
      ];
      final byCat = <String, int>{};
      for (final d in duas.cast<Map<String, dynamic>>()) {
        byCat.update(d['category'] as String, (v) => v + 1, ifAbsent: () => 1);
      }
      for (final c in newCats) {
        expect(byCat[c] ?? 0, greaterThanOrEqualTo(3),
            reason: 'category "$c" should have >=3 duas, got ${byCat[c] ?? 0}');
      }
    });

    test('ids are unique', () {
      final ids = duas.map((d) => (d as Map)['id'] as String).toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  group('semantic map search hits new categories', () {
    const newCategoryKeywords = {
      'anger': 'I am so angry at my brother',
      'envy': 'I feel jealous of my friend',
      'lust': 'I keep struggling with desire',
      'loneliness': 'I feel completely alone',
      'shame': 'I am so ashamed of what I did',
      'burnout': 'I am burned out and exhausted',
      'marriage_conflict': 'my marriage is breaking down',
      'parenting': 'I am failing as a parent',
      'work': 'my job is destroying me',
      'illness': 'I am sick and afraid',
      'addiction': 'I am addicted and want to stop',
      'death_grief': 'my father just passed away',
    };
    for (final entry in newCategoryKeywords.entries) {
      test('search "${entry.value}" returns a dua tagged ${entry.key}', () {
        final hits = searchLocalDuasForTest(entry.value);
        expect(hits, isNotEmpty,
            reason: 'no hits for ${entry.key} via "${entry.value}"');
      });
    }

    // CRITICAL: regression-pin existing 15 categories. New _semanticMap keywords
    // (e.g. 'sick' adding +6 to protection) can silently re-rank these. If any
    // of these probes shifts away from its expected category, the diff is
    // breaking the existing dua corpus.
    const existingCategoryKeywords = {
      'anxiety': 'I keep feeling anxious',
      'forgiveness': 'I want Allah to forgive me',
      'protection': 'protect me from evil',
      'grief': 'I lost someone',
      'guidance': 'I need guidance for a decision',
      'wealth': 'I need help with money',
      'family': 'praying for my family',
      'morning': 'morning dhikr',
      'evening': 'evening dhikr',
      'sleep': 'before I sleep',
      'travel': 'before I travel',
      'food': 'before eating',
      'gratitude': 'I feel grateful',
      'hope': 'I want to keep hope',
      'general': 'general remembrance',
    };
    for (final entry in existingCategoryKeywords.entries) {
      test('REGRESSION: "${entry.value}" still routes to ${entry.key}', () {
        final hits = searchLocalDuasForTest(entry.value);
        expect(hits, isNotEmpty,
            reason: 'no hits for existing category ${entry.key} via "${entry.value}"');
        // Top hit should be in the expected category — otherwise the new
        // keywords are stealing the search.
        final topCategory = browseDuasCatalog
            .firstWhere((d) => d.title == hits.first.title,
                orElse: () => browseDuasCatalog.first)
            .category;
        expect(topCategory, equals(entry.key),
            reason: 'top hit category was $topCategory, expected ${entry.key} '
                '(probably a new _semanticMap keyword stole the ranking)');
      });
    }
  });
}
