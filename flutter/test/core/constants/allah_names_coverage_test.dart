import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/constants/allah_names.dart';
import 'package:sakina/services/validate_names.dart';

void main() {
  group('allahNames canonical coverage', () {
    final raw = File('assets/content/collectible_names.json').readAsStringSync();
    final canonical = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();

    test('allahNames has 98 entries (99 canonical minus "Allah" the proper Name)', () {
      expect(allahNames.length, equals(98));
    });

    test('every collectible_names.json entry EXCEPT "Allah" is in allahNames', () {
      final present = allahNames.map((n) => n.transliteration).toSet();
      final missing = <String>[];
      for (final c in canonical) {
        if (c['id'] == 1) continue; // intentionally excluded — see Task 2
        if (!present.contains(c['transliteration'])) {
          missing.add(c['transliteration'] as String);
        }
      }
      expect(missing, isEmpty);
    });

    test('"Allah" is intentionally NOT in allahNames (proper name, not attribute)', () {
      final present = allahNames.map((n) => n.transliteration).toSet();
      expect(present.contains('Allah'), isFalse,
          reason: 'Allah is the proper Name; allahNames is the 98 attributes');
    });

    test('findCanonicalName resolves every canonical transliteration (except "Allah")', () {
      for (final c in canonical) {
        if (c['id'] == 1) continue; // "Allah" intentionally excluded from allahNames
        final resolved = findCanonicalName(c['transliteration'] as String);
        expect(resolved, isNotNull,
            reason: 'findCanonicalName returned null for ${c['transliteration']}');
      }
    });

    test('arabic field matches the JSON 1:1', () {
      final byTransliteration = {
        for (final n in allahNames) n.transliteration: n.arabic,
      };
      for (final c in canonical) {
        if (c['id'] == 1) continue; // "Allah" intentionally excluded from allahNames
        expect(byTransliteration[c['transliteration']], equals(c['arabic']),
            reason: c['transliteration'] as String);
      }
    });
  });
}
