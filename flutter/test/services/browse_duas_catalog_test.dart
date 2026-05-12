import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

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
}
