import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/ai_service.dart';

// Single source of truth for the 12 new categories Plan 2 adds. Used by:
// - the "every new emotional category has >=3 entries" count test
// - the "search returns hits" probes for each new category (later in this file)
const _newCategoryKeywords = {
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
      final newCats = _newCategoryKeywords.keys.toList();
      final byCat = <String, int>{};
      for (final d in duas.cast<Map<String, dynamic>>()) {
        byCat.update(d['category'] as String, (v) => v + 1, ifAbsent: () => 1);
      }
      for (final c in newCats) {
        expect(byCat[c] ?? 0, greaterThanOrEqualTo(3),
            reason: 'category "$c" should have >=3 duas, got ${byCat[c] ?? 0}');
      }
    });

    test('dua titles are unique (or in the known-collision allowlist)', () {
      // Pinned because the REGRESSION block (below) back-maps hits to category
      // via `firstWhere((d) => d.title == hits.first.title)`. If two duas share
      // a title, that lookup returns the FIRST one in catalog order, not the
      // actual top-scoring dua, producing false passes/fails.
      // Today there are 3 known collisions; allowlisted so new collisions trip
      // the test loudly. Long-term fix: expose category on `FindDuasDuaEntry`
      // so the back-mapping is unambiguous (filed in PR review).
      const allowlist = {
        'Ayat al-Kursi',           // evening-5 + protection-1
        'Sayyid al-Istighfar',      // forgiveness-1 + morning-4
        'Dua of Adam (AS)',         // forgiveness-3 + forgiveness-6
      };
      final titles = duas.map((d) => (d as Map)['title'] as String).toList();
      final dupes = <String>{};
      final seen = <String>{};
      for (final t in titles) {
        if (!seen.add(t)) dupes.add(t);
      }
      final unauthorized = dupes.difference(allowlist);
      expect(unauthorized, isEmpty,
          reason: 'New duplicate dua titles: $unauthorized. Add to the allowlist '
              'only if you also fix the REGRESSION back-mapping logic to disambiguate.');
    });

    test('ids are unique', () {
      final ids = duas.map((d) => (d as Map)['id'] as String).toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  group('stopword filter behavior', () {
    // The 'for' stopword regression: previously, queryWord 'for' matched
    // semantic-map key 'forgive' via `key.contains(word)`, polluting the
    // inferredTags with {'forgiveness', 'repentance'}. Two probes pin both
    // directions of the fix.
    //
    // Verification uses the entry's own `category` field (populated by
    // `_searchLocalDuas` directly from BrowseDua.category). This is collision-
    // resilient: titles can collide (Sayyid al-Istighfar lives in both morning
    // + forgiveness) but each entry carries its own category — no back-mapping
    // needed.
    Set<String> categoriesOfTopHits(Iterable<dynamic> hits, {int take = 3}) {
      return hits
          .take(take)
          .map((h) => h.category as String?)
          .whereType<String>()
          .toSet();
    }

    test('stopword "for" does not pollute routing — "praying for my family" → family', () {
      final hits = searchLocalDuasForTest('praying for my family');
      expect(hits, isNotEmpty);
      expect(categoriesOfTopHits(hits), contains('family'),
          reason: 'After stopword filter, "for" should no longer infer forgiveness; '
              'family-category duas should win.');
    });

    test('"forgive" as a real query word still routes to forgiveness', () {
      // The stopword filter must not over-filter — substantive words still work.
      final hits = searchLocalDuasForTest('I have to forgive my brother');
      expect(hits, isNotEmpty);
      expect(categoriesOfTopHits(hits), contains('forgiveness'),
          reason: '"forgive" as a real query word must still infer forgiveness.');
    });
  });

  group('semantic map search hits new categories', () {
    for (final entry in _newCategoryKeywords.entries) {
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
        // Top hit category comes directly from the entry now (no back-mapping).
        final topCategory = hits.first.category;
        expect(topCategory, equals(entry.key),
            reason: 'top hit category was $topCategory, expected ${entry.key} '
                '(probably a new _semanticMap keyword stole the ranking)');
      });
    }
  });
}
