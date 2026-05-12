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
}
