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

  // `pair_synergy` is deliberately NOT a kind: the shipped convention is a
  // `takeaway` beat carrying a `synergy` label (see the pair-synergy test at the
  // bottom), and no deck has ever used the kind. Keeping it allowed would let a
  // second, unrendered spelling of the same beat into the asset.
  const allowedKinds = {
    'bridge',
    'name_intro',
    'story',
    'verse',
    'dua',
    'takeaway',
    'recognition',
    'comfort_verse',
  };

  // Duʿa provenance that RENDERS (`DuaTextBlock` shows the source line). Only
  // these decks cite the duʿa itself — their sources table names the exact
  // verse/hadith the words come from. Pinned so the attribution can never be
  // silently dropped. Every other duʿa is a catalog invocation with no citation
  // anywhere in its deck, and byte-identity with the verified catalog (below)
  // is its provenance.
  //
  // This map is EXHAUSTIVE, not a whitelist — see the assertion below. An
  // earlier version of this comment claimed "the gate will not accept an
  // invented one" while the check was `if (pinned != null)`, i.e. it asserted
  // nothing at all about the unpinned decks: a fabricated `source` on any of
  // them would have rendered on screen and passed CI silently. Adding a deck
  // that cites its duʿa means adding it here, and that is the point — a
  // citation nobody had to write down is a citation nobody verified.
  const renderedDuaSources = {
    'as-salam@1': 'Sahih Muslim 591',
    'al-wakeel@1': "Qur'an 3:173",
    'ash-shafi@1': 'cf. Sahih al-Bukhari 5743',
    // Batch 1 + 2, transcribed 2026-08-03. Each pin was read off the deck's own
    // duʿa beat by the agent that transcribed it, never copied from a report —
    // al-waliyy@1's was reported stale twice, and a pin that happens to match
    // for the wrong reason ships a wrong citation silently rather than loudly.
    'ar-raheem@1': "Qur'an 18:10",
    'al-ghafur@1': 'Sunan Abi Dawud 1516',
    'al-afuw@1': 'Sunan Ibn Majah 3850',
    'al-mujeeb@1': "Qur'an 21:87",
    'al-waliyy@1': 'Sahih Muslim 1342',
    // Deliberately absent, and each verified as absent rather than assumed:
    // al-haleem@1, al-kareem@1, al-qayyum@1, al-qadir@1, al-muid@1 render NO
    // duʿa citation. Their duʿa is the catalogue's own authored invocation, so
    // a pin here would assert a provenance the text does not have — which is
    // the exact fabrication this map's other direction exists to catch.
  };

  late List<dynamic> decks;
  late Set<int> catalogIds;
  late Map<int, String> catalogDuaArabic;
  late Map<int, String> catalogDuaTransliteration;
  late Map<int, String> catalogDuaTranslation;

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
    catalogDuaTransliteration = {
      for (final n in catalog)
        n['id'] as int: (n['dua_transliteration'] ?? '') as String,
    };
    catalogDuaTranslation = {
      for (final n in catalog)
        n['id'] as int: (n['dua_translation'] ?? '') as String,
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
    // Full Arabic coverage: Arabic (U+0600-06FF), Supplement (U+0750-077F),
    // Extended-A (U+08A0-08FF) and BOTH Presentation Forms blocks (U+FB50-FDFF,
    // U+FE70-FEFF) — a deck pasted from a source that uses presentation forms
    // would otherwise slip Arabic body text into a Latin field unnoticed.
    // The three composite honorifics are stripped first: ﷺ (U+FDFA), ﷻ
    // (U+FDFB) and ﷽ (U+FDFD) appear inline in English renderings by design.
    final arabicBody = RegExp(r'[؀-ۿݐ-ݿࢠ-ࣿﭐ-﷿ﹰ-﻿]');
    String strip(String s) => s.replaceAll(RegExp(r'[ﷺﷻ﷽]'), '');
    final latin = RegExp(r'[A-Za-z]');
    for (final d in decks) {
      for (final b in d['beats'] as List) {
        // `source` renders; `label` renders for story beats and is read by
        // reviewers everywhere else — both must stay single-script.
        for (final field in [
          'primary',
          'translation',
          'transliteration',
          'label',
          'source',
        ]) {
          final v = strip((b[field] ?? '') as String);
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
          // Duas are never authored — all three scripts come from the verified
          // catalog, byte for byte. The deck holds the translation on `primary`
          // (see the field table on NameStoryBeat), so that is what the catalog
          // translation is compared against.
          expect(b['arabic'], catalogDuaArabic[d['name_id']],
              reason:
                  '${d['deck_id']} dua arabic diverges from the verified '
                  'catalog — decks must never carry non-catalog scripture');
          expect(b['transliteration'],
              catalogDuaTransliteration[d['name_id']],
              reason: '${d['deck_id']} dua transliteration diverges from the '
                  'verified catalog');
          expect(b['primary'], catalogDuaTranslation[d['name_id']],
              reason: '${d['deck_id']} dua translation diverges from the '
                  'verified catalog');
          // Both directions, because each failure is real and they are
          // different failures:
          //   * a pinned deck losing its citation is a content regression —
          //     the attribution renders, so dropping it silently unattributes
          //     words the sources table says came from somewhere specific;
          //   * an UNPINNED deck growing one is worse. It renders a provenance
          //     claim under `DuaTextBlock` that no sources table backs and no
          //     human ever verified. That is the fabrication this whole gate
          //     exists to make impossible, and until now it was the one shape
          //     of it the gate could not see.
          final pinned = renderedDuaSources[d['deck_id']] ?? '';
          expect(((b['source'] ?? '') as String), pinned,
              reason: pinned.isEmpty
                  ? '${d['deck_id']} renders a duʿa citation that is not in '
                      'renderedDuaSources. Either it is invented — in which '
                      'case delete it — or it is real, in which case verify it '
                      'and pin it here.'
                  : '${d['deck_id']} dropped the duʿa citation its own sources '
                      'table carries — attribution renders, so losing it is a '
                      'content regression');
        }
        if (kind == 'verse' || kind == 'comfort_verse') {
          expect(((b['source'] ?? '') as String).isNotEmpty, isTrue,
              reason: '${d['deck_id']} $kind beat missing source citation');
        }
      }
    }
  });

  test('every beat carries body text', () {
    // `primary` is the one field every kind renders. An empty one ships a blank
    // screen the user has to tap past.
    for (final d in decks) {
      for (final b in d['beats'] as List) {
        expect(((b['primary'] ?? '') as String).trim().isNotEmpty, isTrue,
            reason: '${d['deck_id']} ${b['kind']} beat has no primary text');
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
