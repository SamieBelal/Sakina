import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/constants/discovery_quiz.dart';

void main() {
  group('discovery_quiz_questions.json', () {
    final raw = File('assets/content/discovery_quiz_questions.json')
        .readAsStringSync();
    final List<dynamic> qs = jsonDecode(raw) as List<dynamic>;

    test('>=18 questions', () {
      expect(qs.length, greaterThanOrEqualTo(18));
    });

    test('every question has >=3 options each with a scores map', () {
      for (final q in qs.cast<Map<String, dynamic>>()) {
        final opts = q['options'] as List<dynamic>;
        expect(opts.length, greaterThanOrEqualTo(3), reason: q['id'] as String);
        for (final o in opts.cast<Map<String, dynamic>>()) {
          expect(o['text'], isA<String>());
          final scores = o['scores'] as Map<String, dynamic>;
          expect(scores, isNotEmpty,
              reason: '${q['id']} option "${o['text']}"');
          for (final entry in scores.entries) {
            expect(entry.value, isA<num>(), reason: entry.key);
          }
        }
      }
    });

    test('union of scored Name keys covers >=40 distinct Names', () {
      final names = <String>{};
      for (final q in qs.cast<Map<String, dynamic>>()) {
        for (final o in (q['options'] as List).cast<Map<String, dynamic>>()) {
          (o['scores'] as Map).forEach((k, _) => names.add(k as String));
        }
      }
      expect(names.length, greaterThanOrEqualTo(40),
          reason: 'reachable Names = ${names.length}: $names');
    });

    test('every scored Name key is a slug of a canonical Name', () {
      // Slugs are pure ASCII lowercase with dashes; no apostrophes, no unicode.
      final keyRe = RegExp(r'^[a-z]+(-[a-z]+)+$');
      // Membership check: every scored slug should have a render-time display
      // entry in nameAnchorsCatalog, or it renders as the literal slug.
      // Until Plan 4 lands (99-anchor backfill), this gates Plan 3 to slugs
      // that already have anchors. After Plan 4, this is a no-op safeguard.
      final anchorKeys = nameAnchorsCatalog.keys.toSet();
      for (final q in qs.cast<Map<String, dynamic>>()) {
        for (final o in (q['options'] as List).cast<Map<String, dynamic>>()) {
          for (final k in (o['scores'] as Map).keys) {
            final key = k as String;
            expect(keyRe.hasMatch(key), isTrue, reason: key);
            expect(anchorKeys, contains(key),
                reason:
                    'slug "$key" has no entry in nameAnchorsCatalog — will render as the literal slug until Plan 4 (anchor backfill) adds it.');
          }
        }
      }
    });
  });
}
