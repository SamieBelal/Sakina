import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// One Ship W2-A2 — the deck SHIP GATE, enforced in CI rather than at runtime.
///
/// A chip may only render when BOTH its decks carry recorded founder sign-off
/// (plan-of-record ship gate). These assertions make an unapproved, malformed,
/// or scripture-unsafe deck a BUILD FAILURE, so the gate can never regress
/// silently. Content itself is transcribed verbatim from the approved files in
/// docs/superpowers/content/decks/ — this test checks structure and safety
/// invariants, never rewrites content.
void main() {
  // The 7 rendered chips (6 problem + sign). The sign pair doubles as the
  // comfort-pair fallback for unmatched free text.
  const chipKeys = {
    'anxiety',
    'far-from-allah',
    'guilt',
    'heavy',
    'rizq',
    'sign',
    'unseen',
  };

  const allowedKinds = {
    'bridge',
    'name_intro',
    'story',
    'verse',
    'dua',
    'takeaway',
    'recognition',
    'comfort_verse',
    'pair_synergy',
  };

  late List<dynamic> decks;
  late Set<int> catalogIds;
  late Map<int, String> catalogDuaArabic;

  setUpAll(() {
    decks = jsonDecode(
      File('assets/content/name_stories.json').readAsStringSync(),
    ) as List<dynamic>;
    final catalog = jsonDecode(
      File('assets/content/collectible_names.json').readAsStringSync(),
    ) as List<dynamic>;
    catalogIds = catalog.map<int>((n) => n['id'] as int).toSet();
    catalogDuaArabic = {
      for (final n in catalog) n['id'] as int: (n['dua_arabic'] ?? '') as String,
    };
  });

  test('every rendered chip maps to exactly two decks (positions 1 and 2)',
      () {
    for (final chip in chipKeys) {
      final forChip = decks
          .where((d) => (d['chip_keys'] as List).contains(chip))
          .toList();
      expect(forChip, hasLength(2), reason: 'chip "$chip" needs its pair');
      expect(
        forChip.map((d) => d['position_in_pair']).toSet(),
        {1, 2},
        reason: 'chip "$chip" pair must cover positions 1 and 2',
      );
    }
  });

  test('SHIP GATE: every deck carries recorded founder sign-off', () {
    for (final d in decks) {
      expect(d['review_verdict'], 'good',
          reason: '${d['deck_id']} is not approved — it MUST NOT ship');
      expect((d['reviewed_by'] as String).isNotEmpty, isTrue,
          reason: '${d['deck_id']} missing reviewer');
      expect((d['reviewed_at'] as String).isNotEmpty, isTrue,
          reason: '${d['deck_id']} missing review date');
    }
  });

  test('every deck name_id exists in the collectible_names catalog', () {
    for (final d in decks) {
      expect(catalogIds.contains(d['name_id']), isTrue,
          reason: '${d['deck_id']} name_id ${d['name_id']} not in catalog');
    }
  });

  test('no field mixes Arabic body text with Latin text (RTL-bleed rule)', () {
    // Arabic BODY blocks. Deliberately excludes Arabic Presentation Forms
    // (U+FB50-FDFF, U+FE70-FEFF): the ﷺ honorific (U+FDFA) appears inline in
    // English hadith renderings by design and is not Arabic body text.
    final arabicBody = RegExp(r'[؀-ۿݐ-ݿ]');
    final latin = RegExp(r'[A-Za-z]');
    for (final d in decks) {
      for (final b in d['beats'] as List) {
        for (final field in ['primary', 'translation', 'transliteration']) {
          final v = (b[field] ?? '') as String;
          expect(arabicBody.hasMatch(v), isFalse,
              reason:
                  '${d['deck_id']} $field contains Arabic body text — Arabic '
                  'belongs only in the arabic field (never mixed with Latin)');
        }
        final arabicField = (b['arabic'] ?? '') as String;
        expect(latin.hasMatch(arabicField), isFalse,
            reason: '${d['deck_id']} arabic field contains Latin text');
      }
    }
  });

  test('beat kinds are from the spec set; every deck ends dua-before-takeaway '
      'ordering rules hold', () {
    for (final d in decks) {
      final beats = d['beats'] as List;
      final kinds = beats.map((b) => b['kind'] as String).toList();
      for (final k in kinds) {
        expect(allowedKinds.contains(k), isTrue,
            reason: '${d['deck_id']} has unknown beat kind "$k"');
      }
      // Standard spine: bridge → name_intro → story×3 → verse → dua →
      // takeaway. The sign Name₁ deck prepends recognition + comfort_verse.
      final core = kinds
          .where((k) => k != 'recognition' && k != 'comfort_verse')
          .toList();
      expect(
        core,
        ['bridge', 'name_intro', 'story', 'story', 'story', 'verse', 'dua',
          'takeaway'],
        reason: '${d['deck_id']} core beat order deviates from the spec',
      );
      if (kinds.contains('recognition')) {
        expect(kinds.sublist(0, 2), ['recognition', 'comfort_verse'],
            reason: 'recognition beats must open the sign deck');
      }
    }
  });

  test('scripture beats carry the split script fields; duas match the '
      'verified catalog byte-for-byte', () {
    for (final d in decks) {
      for (final b in d['beats'] as List) {
        final kind = b['kind'] as String;
        if (kind == 'dua' || kind == 'name_intro') {
          expect(((b['arabic'] ?? '') as String).isNotEmpty, isTrue,
              reason: '${d['deck_id']} $kind beat missing arabic');
          expect(((b['transliteration'] ?? '') as String).isNotEmpty, isTrue,
              reason: '${d['deck_id']} $kind beat missing transliteration');
        }
        if (kind == 'dua') {
          // Duas are never authored — they come from the verified catalog.
          // (Provenance lives in the catalog + the deck's sources table, so
          // no inline source is required; identity with the catalog is the
          // real scripture-safety invariant.)
          expect(b['arabic'], catalogDuaArabic[d['name_id']],
              reason:
                  '${d['deck_id']} dua arabic diverges from the verified '
                  'catalog — decks must never carry non-catalog scripture');
        }
        if (kind == 'verse' || kind == 'comfort_verse') {
          expect(((b['source'] ?? '') as String).isNotEmpty, isTrue,
              reason: '${d['deck_id']} $kind beat missing source citation');
        }
      }
    }
  });

  test('exactly one pair-synergy beat per pair, carried by position 1', () {
    for (final chip in chipKeys) {
      final forChip =
          decks.where((d) => (d['chip_keys'] as List).contains(chip));
      for (final d in forChip) {
        final synergyBeats = (d['beats'] as List).where((b) =>
            ((b['label'] ?? '') as String).toLowerCase().contains('synergy') ||
            b['kind'] == 'pair_synergy');
        if (d['position_in_pair'] == 1) {
          expect(synergyBeats, hasLength(1),
              reason: '${d['deck_id']} (Name₁) must carry the synergy beat');
        } else {
          expect(synergyBeats, isEmpty,
              reason: '${d['deck_id']} (Name₂) must not carry a synergy beat');
        }
      }
    }
  });
}
