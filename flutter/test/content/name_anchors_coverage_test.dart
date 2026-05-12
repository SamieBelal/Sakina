import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Translation map from canonical transliteration → existing anchor slug.
/// Built empirically: existing anchors use shorter handcrafted spellings that
/// don't derive naively from `_slug(transliteration)`. Add entries when the
/// existing slug differs from `_naiveSlug(transliteration)`.
const Map<String, String> _transliterationToAnchorSlug = {
  'Al-Hakeem': 'al-hakim',
  'Al-Kareem': 'al-karim',
  'Al-Lateef': 'al-latif',
  'Al-Mujeeb': 'al-mujib',
  'Al-Wakeel': 'al-wakil',
  'Al-Mateen': 'al-matin',
  'Al-Baseer': 'al-basir',
  'Al-Khabeer': 'al-khabir',
  'Al-Qawiyy': 'al-qawi',
  'Ar-Raheem': 'ar-rahim',
  'Ash-Shaheed': 'ash-shahid',
  // Add new entries here when you discover spelling differences.
};

/// Slugs in `name_anchors.json` that have NO canonical Name in collectible_names.json.
/// Kept as "non-canonical anchors" so the test doesn't flag them as orphans,
/// but they're surfaced for migration in a future plan.
const Set<String> _nonCanonicalAnchorSlugs = {'al-qarib', 'ar-rabb', 'al-jamil'};

String _naiveSlug(String t) {
  return t.toLowerCase()
      .replaceAll(RegExp(r"['\u2018\u2019]"), '')
      .replaceAll(RegExp(r'\s+'), '-');
}

String _anchorSlug(String transliteration) {
  return _transliterationToAnchorSlug[transliteration]
      ?? _naiveSlug(transliteration);
}

void main() {
  group('name_anchors.json coverage', () {
    final anchorsRaw =
        File('assets/content/name_anchors.json').readAsStringSync();
    final namesRaw =
        File('assets/content/collectible_names.json').readAsStringSync();
    final anchors = (jsonDecode(anchorsRaw) as List).cast<Map<String, dynamic>>();
    final names = (jsonDecode(namesRaw) as List).cast<Map<String, dynamic>>();

    test('every canonical Name has an anchor (via translation map)', () {
      final anchorKeys = anchors.map((a) => a['name_key'] as String).toSet();
      final missing = <String>[];
      for (final n in names) {
        if (n['id'] == 1) continue; // skip "Allah" — proper Name, no attribute anchor
        final slug = _anchorSlug(n['transliteration'] as String);
        if (!anchorKeys.contains(slug)) {
          missing.add('${n['transliteration']} -> $slug');
        }
      }
      expect(missing, isEmpty, reason: 'Names without anchors: $missing');
    });

    test('every anchor slug either maps to a canonical Name or is in the deprecated set', () {
      final canonicalSlugs = <String>{};
      for (final n in names) {
        if (n['id'] == 1) continue;
        canonicalSlugs.add(_anchorSlug(n['transliteration'] as String));
      }
      final orphans = <String>[];
      for (final a in anchors) {
        final key = a['name_key'] as String;
        if (!canonicalSlugs.contains(key) && !_nonCanonicalAnchorSlugs.contains(key)) {
          orphans.add(key);
        }
      }
      expect(orphans, isEmpty,
          reason: 'Anchor slugs not mapped to any canonical Name (add to '
              '_transliterationToAnchorSlug or _nonCanonicalAnchorSlugs): $orphans');
    });

    test('every anchor has all required fields, non-empty', () {
      const required = ['name_key', 'name', 'arabic', 'anchor', 'detail'];
      for (final a in anchors) {
        for (final f in required) {
          expect(a[f], isA<String>(), reason: '${a['name_key']} -> $f');
          expect((a[f] as String).trim(), isNotEmpty,
              reason: '${a['name_key']} -> $f');
        }
      }
    });

    test('anchor text is <=110 characters', () {
      for (final a in anchors) {
        expect((a['anchor'] as String).length, lessThanOrEqualTo(110),
            reason: a['name_key']);
      }
    });

    test('detail text is 80–400 characters', () {
      for (final a in anchors) {
        final len = (a['detail'] as String).length;
        expect(len, inInclusiveRange(80, 400),
            reason: '${a['name_key']} -> $len');
      }
    });

    test('punctuation: em-dash (—) only, no en-dash or double-hyphen', () {
      for (final a in anchors) {
        final text = '${a['anchor']} ${a['detail']}';
        expect(text.contains('–'), isFalse,
            reason: '${a['name_key']} uses en-dash — use em-dash (—)');
        expect(text.contains(' -- '), isFalse,
            reason: '${a['name_key']} uses double-hyphen — use em-dash (—)');
      }
    });

    test('name_keys are unique', () {
      final keys = anchors.map((a) => a['name_key'] as String).toList();
      expect(keys.toSet().length, keys.length);
    });

    test('nameAnchorsPublicCatalog.expectedCount matches reality', () {
      // Reminder: when shipping the 99 anchors, bump
      // `lib/services/public_catalog_contracts.dart:69` expectedCount: 32 → 99
      // or the catalog service throws at runtime. This test pins the file count
      // so the contracts file is updated in the same PR.
      expect(anchors.length, equals(99),
          reason: 'When this passes, also update '
              'public_catalog_contracts.dart expectedCount to match.');
    });
  });
}
