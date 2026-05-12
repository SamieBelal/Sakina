import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/constants/transliteration_slug_map.dart';
import 'package:sakina/services/validate_names.dart';

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
/// As of Plan 4 backfill (2026-05-12), the three previously non-canonical anchors
/// (`al-qarib`, `ar-rabb`, `al-jamil`) were dropped from the JSON because they
/// have no entry in `collectible_names.json`. This set is intentionally empty;
/// add a slug here ONLY if a future anchor must remain without a canonical
/// counterpart, and document the reason inline.
const Set<String> _nonCanonicalAnchorSlugs = <String>{};

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

    test('transliterationToAnchorSlug covers every transliteration in collectible_names.json', () {
      final missing = <String>[];
      for (final n in names) {
        final t = n['transliteration'] as String;
        if (!transliterationToAnchorSlug.containsKey(t)) {
          missing.add(t);
        }
      }
      expect(missing, isEmpty,
          reason: 'transliterationToAnchorSlug missing entries for: $missing');
    });

    test('every transliterationToAnchorSlug value points at a real anchor (except "allah")', () {
      final anchorKeys = anchors.map((a) => a['name_key'] as String).toSet();
      final dangling = <String>[];
      for (final entry in transliterationToAnchorSlug.entries) {
        if (entry.value == 'allah') continue; // proper Name, no attribute anchor
        if (!anchorKeys.contains(entry.value)) {
          dangling.add('${entry.key} -> ${entry.value}');
        }
      }
      expect(dangling, isEmpty,
          reason: 'transliterationToAnchorSlug values do not resolve to '
              'existing name_anchors entries: $dangling');
    });

    test('every collectible_names transliteration round-trips through findCanonicalName', () {
      // Guardrail: an anchor lookup that goes
      //   transliteration -> findCanonicalName -> canonical transliteration
      //   -> transliterationToAnchorSlug -> name_key
      // must end at a real anchor entry. If a Name is missing from
      // `allahNames` (the source `findCanonicalName` searches), the round-trip
      // breaks and Plan 0 has not finished — surface that here.
      final anchorKeys = anchors.map((a) => a['name_key'] as String).toSet();
      final broken = <String>[];
      for (final n in names) {
        if (n['id'] == 1) continue; // skip "Allah"
        final t = n['transliteration'] as String;
        final canonical = findCanonicalName(t);
        if (canonical == null) {
          broken.add('$t (findCanonicalName returned null — Plan 0 backfill incomplete?)');
          continue;
        }
        final slug = transliterationToAnchorSlug[canonical.name];
        if (slug == null) {
          broken.add('$t -> ${canonical.name} (no slug in transliterationToAnchorSlug)');
          continue;
        }
        if (!anchorKeys.contains(slug)) {
          broken.add('$t -> ${canonical.name} -> $slug (slug not in name_anchors.json)');
        }
      }
      expect(broken, isEmpty,
          reason: 'Transliteration round-trip failures: $broken');
    });

    test('nameAnchorsPublicCatalog.expectedCount matches reality', () {
      // After Plan 4 backfill (2026-05-12): 29 originally-canonical anchors
      // + 69 new anchors = 98 entries. (Three non-canonical anchors —
      // al-qarib, ar-rabb, al-jamil — were dropped because they have no
      // entry in collectible_names.json.) Bump
      // `lib/services/public_catalog_contracts.dart:69` expectedCount in
      // lockstep with this count, or the catalog service throws at runtime.
      expect(anchors.length, equals(98),
          reason: 'When this passes, also update '
              'public_catalog_contracts.dart expectedCount to match.');
    });
  });
}
