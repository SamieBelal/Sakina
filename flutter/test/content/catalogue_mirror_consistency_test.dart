import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/card_collection_service.dart';

/// The 99-Name catalogue is MIRRORED. The same religious content lives in:
///
///   1. `public.collectible_names`                  (Supabase — what the app
///                                                   actually serves at runtime)
///   2. `assets/content/collectible_names.json`     (bundled offline fallback,
///                                                   GENERATED from 1 by
///                                                   tool/export_public_catalog_snapshots.dart)
///   3. `allCollectibleNames`                       (Dart const, this repo)
///
/// Nothing enforced that they agree, and twice that has cost real content
/// integrity:
///
///   * 2026-08-02 (323ecd3) — a path-scoped `git add -A flutter/lib` staged the
///     Dart const and knowledge_base but NOT the JSON asset, because the asset
///     lives under `assets/`. HEAD carried a half-repaired catalogue: the Dart
///     const had a fabrication removed while the JSON still contained it.
///   * 2026-08-05 — the hadith repair (27 rows) was applied to 2 and 3 but
///     never to 1. Since `refreshPublicCatalogsFromSupabase()` overwrites the
///     bundled cache from the server, users were served the unrepaired text —
///     including statements attributed to the Prophet ﷺ that the audit had
///     deliberately emptied — for three days, with a green suite the whole time.
///
/// This test closes the gap it CAN close offline: 2 vs 3. It cannot reach the
/// database, so the DB↔asset half is still only verified by running
/// `dart run tool/export_public_catalog_snapshots.dart` and diffing. That
/// remains a manual step and is called out in the staged-SQL headers.
void main() {
  late List<Map<String, dynamic>> assetRows;

  setUpAll(() {
    final raw =
        File('assets/content/collectible_names.json').readAsStringSync();
    assetRows = (jsonDecode(raw) as List<dynamic>)
        .cast<Map<String, dynamic>>();
  });

  test('the JSON asset and the Dart const carry the same 99 ids', () {
    final assetIds = assetRows.map((r) => (r['id'] as num).toInt()).toSet();
    final dartIds = allCollectibleNames.map((n) => n.id).toSet();
    expect(assetIds.length, 99, reason: 'asset should hold 99 Names');
    expect(dartIds.length, 99, reason: 'Dart const should hold 99 Names');
    expect(dartIds.difference(assetIds), isEmpty,
        reason: 'ids in the Dart const that are missing from the JSON asset');
    expect(assetIds.difference(dartIds), isEmpty,
        reason: 'ids in the JSON asset that are missing from the Dart const');
  });

  test('MIRROR GATE: every catalogue content field is byte-identical', () {
    final byId = {
      for (final r in assetRows) (r['id'] as num).toInt(): r,
    };

    // Only the fields that RENDER. `created_at` is export metadata and is
    // deliberately not mirrored into the Dart const.
    const fields = <String, String>{
      'arabic': 'arabic',
      'transliteration': 'transliteration',
      'english': 'english',
      'meaning': 'meaning',
      'lesson': 'lesson',
      'hadith': 'hadith',
      'dua_arabic': 'duaArabic',
      'dua_transliteration': 'duaTransliteration',
      'dua_translation': 'duaTranslation',
    };

    final mismatches = <String>[];

    for (final n in allCollectibleNames) {
      final row = byId[n.id];
      if (row == null) continue; // covered by the id test above

      final dartValues = <String, String>{
        'arabic': n.arabic,
        'transliteration': n.transliteration,
        'english': n.english,
        'meaning': n.meaning,
        'lesson': n.lesson,
        'hadith': n.hadith,
        'dua_arabic': n.duaArabic,
        'dua_transliteration': n.duaTransliteration,
        'dua_translation': n.duaTranslation,
      };

      for (final jsonKey in fields.keys) {
        final assetValue = (row[jsonKey] as String?) ?? '';
        final dartValue = dartValues[jsonKey]!;
        if (assetValue != dartValue) {
          mismatches.add(
            'id ${n.id} (${n.transliteration}) field `$jsonKey`\n'
            '      asset: ${_clip(assetValue)}\n'
            '      dart : ${_clip(dartValue)}',
          );
        }
      }
    }

    expect(
      mismatches,
      isEmpty,
      reason: 'The catalogue mirrors have drifted. This is religious content '
          'duplicated across a Supabase table, a bundled JSON asset and a Dart '
          'const, and it is defined by CONTENT rather than by location — so a '
          'path-scoped stage or a repair applied to one mirror silently splits '
          'it. Fix ALL mirrors or none.\n\n'
          '${mismatches.join('\n')}',
    );
  });

  test('no catalogue field is null — the client contract requires non-null',
      () {
    // `lib/services/public_catalog_contracts.dart` requires these present on
    // all 99 rows, and the card UI degrades an EMPTY value to "Coming soon…".
    // NULL would break the contract instead of degrading gracefully.
    for (final r in assetRows) {
      for (final key in const [
        'arabic',
        'transliteration',
        'english',
        'meaning',
        'lesson',
        'hadith',
        'dua_arabic',
        'dua_transliteration',
        'dua_translation',
      ]) {
        expect(r[key], isNotNull,
            reason: 'id ${r['id']} has a null `$key` in the JSON asset');
      }
    }
  });
}

String _clip(String s) =>
    s.length <= 70 ? '"$s"' : '"${s.substring(0, 70)}…" (${s.length} chars)';
