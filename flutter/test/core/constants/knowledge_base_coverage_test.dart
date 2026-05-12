import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/constants/knowledge_base.dart';
import 'package:sakina/services/validate_names.dart';

/// Canonical names that have no `NameTeaching` AND legitimately don't need one
/// (e.g. "Allah" the proper Name vs. the 98 attributes). Add as needed.
const Set<String> _intentionallyUncovered = {'Allah'};

List<String> _canonicalTransliterations() {
  final raw = File('assets/content/collectible_names.json').readAsStringSync();
  return (jsonDecode(raw) as List)
      .cast<Map<String, dynamic>>()
      .map((n) => n['transliteration'] as String)
      .toList();
}

String? _canonicalize(String s) {
  final hit = findCanonicalName(s);
  return hit?.name;
}

void main() {
  group('knowledge_base NameTeaching coverage', () {
    final teachings = nameTeachings;
    final canonical = _canonicalTransliterations();

    test('every canonical Name (except intentionally uncovered) appears in some teaching key, normalized', () {
      // A teaching key may be a single Name ("Al-Lateef") or a compound
      // ("Al-Wahid / Al-Ahad" or "Al-Dhahir & Al-Batin"). Split on both separators.
      final keyedCanonical = <String>{};
      final unresolvedKeys = <String>[];
      for (final t in teachings) {
        for (final part in t.name.split(RegExp(r'\s*[/&]\s*'))) {
          final p = part.trim();
          final c = _canonicalize(p);
          if (c != null) {
            keyedCanonical.add(c);
          } else {
            unresolvedKeys.add(p);
          }
        }
      }

      // Surface any teaching key parts that don't resolve to a canonical Name —
      // either they're misspelled or they're non-99 honorifics (Ar-Rabb, Al-Qarib).
      // We don't fail on these; we report them so they can be migrated.
      if (unresolvedKeys.isNotEmpty) {
        // ignore: avoid_print
        print('NOTE: ${unresolvedKeys.length} teaching key parts do not resolve to '
            'a canonical Name: $unresolvedKeys. Consider migrating or removing.');
      }

      final missing = <String>[];
      for (final t in canonical) {
        if (_intentionallyUncovered.contains(t)) continue;
        if (!keyedCanonical.contains(t)) missing.add(t);
      }
      expect(missing, isEmpty,
          reason: 'Canonical Names without a NameTeaching: $missing');
    });

    test('each teaching has emotionalContext >=3', () {
      for (final t in teachings) {
        expect(t.emotionalContext.length, greaterThanOrEqualTo(3),
            reason: t.name);
      }
    });

    test('each teaching has non-empty arabic, coreTeaching, propheticStory, dua', () {
      for (final t in teachings) {
        expect(t.arabic.trim(), isNotEmpty, reason: t.name);
        expect(t.coreTeaching.trim(), isNotEmpty, reason: t.name);
        expect(t.propheticStory.trim(), isNotEmpty, reason: t.name);
        expect(t.dua.arabic.trim(), isNotEmpty, reason: t.name);
        expect(t.dua.transliteration.trim(), isNotEmpty, reason: t.name);
        expect(t.dua.translation.trim(), isNotEmpty, reason: t.name);
        expect(t.dua.source.trim(), isNotEmpty, reason: t.name);
      }
    });

    test('every emotionalContext entry is lowercase (matcher uses .toLowerCase())', () {
      // Step 0 (lowercase pre-pass) keeps this green.
      for (final t in teachings) {
        for (final e in t.emotionalContext) {
          expect(e, equals(e.toLowerCase()), reason: '${t.name} -> $e');
        }
      }
    });
  });

  group('getRelevantTeachings surfaces formerly-uncovered Names', () {
    // Probes whose expected Name HAS a teaching in the existing corpus today
    // and routes there as top-1. Phrases avoid bare "feel" / "feeling" prefixes
    // because many teachings share "feel..." emotional contexts and the
    // emotionalContext-first-word matcher (+1 each) can sway top-1 toward
    // Al-Qabid & Al-Basit (which has many "feel..." starters).
    //
    // Picked by tracing `getRelevantTeachings`:
    // - "unloved" hits keywordMap idx 14 (Al-Wadud) +2 unique.
    // - "scattered" hits keywordMap idx 17 (Al-Jami) +2 unique.
    // - "never appreciated" hits Al-Shakur's emotionalContext.
    // - "undeserving not worthy" hits Al-Karim's emotionalContext.
    //
    // Probes that depend on yet-to-be-authored teachings (Al-Muqtadir, Al-Mani,
    // Adh-Dharr, etc.) are commented out until Task 3 lands.
    const probes = {
      'unloved': 'Al-Wadud',
      'scattered': 'Al-Jami',
      'never appreciated': 'Al-Shakur',
      'undeserving not worthy': 'Al-Karim',
      // 'feeling powerless': 'Al-Muqtadir',
      // 'i feel cut off from everyone': 'Al-Mani',
    };
    probes.forEach((phrase, expectedName) {
      // Tightened: expected Name must be the TOP-1 returned teaching, not just
      // anywhere in the top-N list. Catches over-broad emotionalContext entries
      // that route a phrase to a different Name with similar tags.
      test('"$phrase" surfaces $expectedName as top-1', () {
        final teachings = getRelevantTeachings(phrase);
        expect(teachings, isNotEmpty,
            reason: 'phrase "$phrase" returned no teachings at all');
        expect(teachings.first.name.contains(expectedName), isTrue,
            reason: 'phrase "$phrase" top-1 was ${teachings.first.name}, expected $expectedName');
      });
    });
  });
}
