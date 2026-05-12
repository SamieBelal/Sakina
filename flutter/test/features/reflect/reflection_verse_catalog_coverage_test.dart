import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/constants/allah_names.dart';
import 'package:sakina/features/reflect/data/reflection_verse_catalog.dart';

List<Map<String, dynamic>> _canonicalRows() {
  final raw = File('assets/content/collectible_names.json').readAsStringSync();
  return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
}

void main() {
  group('reflection verse catalog coverage', () {
    final canonical = _canonicalRows()
        .where((r) => r['id'] != 1) // skip "Allah" — proper Name, not attribute
        .map((r) => r['transliteration'] as String)
        .toList();

    test('allahNames mirrors collectible_names.json transliterations (excluding Allah)', () {
      final fromJson = canonical.toSet();
      final fromDart = allahNames.map((n) => n.transliteration).toSet();
      expect(fromDart, equals(fromJson),
          reason: 'allahNames and collectible_names.json must agree '
              '(excluding the proper Name "Allah"). Run Plan 0 first.');
    });

    test('every canonical attribute Name has >=2 approved verses', () {
      final missing = <String>[];
      for (final t in canonical) {
        final verses = approvedReflectVersesByName[t] ?? const [];
        if (verses.length < 2) missing.add(t);
      }
      expect(missing, isEmpty,
          reason: 'Names lacking >=2 verses: $missing');
    });

    test('every verse has non-empty arabic, translation, reference', () {
      for (final entry in approvedReflectVersesByName.entries) {
        for (final v in entry.value) {
          expect(v.arabic.trim(), isNotEmpty, reason: entry.key);
          expect(v.translation.trim(), isNotEmpty, reason: entry.key);
          expect(v.reference.trim(), isNotEmpty, reason: entry.key);
        }
      }
    });

    test('references start with a surah name, NOT "Quran"', () {
      // Five legacy entries (_repentanceVerse 7:23, _believersMercyVerse 59:10,
      // _goodWorldsVerse 2:201, _acceptanceVerse 2:127, _protectionVerse 2:255)
      // use "Quran N:N" prefix. They render as "Quran 2:201" in the UI when
      // they should render as "Al-Baqarah 2:201". Task 0.5 renames them.
      for (final entry in approvedReflectVersesByName.entries) {
        for (final v in entry.value) {
          expect(v.reference.startsWith('Quran '), isFalse,
              reason: '${entry.key} -> "${v.reference}" — use surah name, not the literal "Quran"');
        }
      }
    });

    test('references match "Surah N:N" format', () {
      final ref = RegExp(r"^[A-Za-z'\-]+(\s[A-Za-z'\-]+)*\s\d+:\d+(-\d+)?$");
      for (final entry in approvedReflectVersesByName.entries) {
        for (final v in entry.value) {
          expect(ref.hasMatch(v.reference), isTrue,
              reason: '${entry.key} -> "${v.reference}"');
        }
      }
    });

    test('normalizeApprovedVerses fallback returns >=2 for every Name', () {
      for (final t in canonical) {
        final out = normalizeApprovedVerses(t, const []);
        expect(out.length, greaterThanOrEqualTo(2),
            reason: 'fallback for $t');
      }
    });

    test('normalizeApprovedVerses with an unknown Name returns demo verses, not empty', () {
      // If the AI ever returns a hallucinated Name that survives canonical resolution,
      // the reflect card should still show at least 2 verses — never blank.
      final out = normalizeApprovedVerses('Al-FabricatedName', const []);
      expect(out.length, greaterThanOrEqualTo(2),
          reason: 'unknown-name fallback must produce verses; today returns []. '
              'Patch normalizeApprovedVerses to default to a small "always-safe" '
              'verse pair (e.g. _heartsRestVerse + _noBurdenVerse) when the name '
              'key is not in approvedReflectVersesByName.');
    });
  });
}
