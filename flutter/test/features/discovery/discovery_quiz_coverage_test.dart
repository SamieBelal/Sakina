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

    // NOTE: target is 32 (the current `name_anchors.json` ceiling). Plan 4
    // backfills anchors to all 99 Names — once that lands, lift this floor to
    // >=55 (per `2026-05-11-discovery-quiz-expansion.md`). The slug-membership
    // test below guards against scoring un-anchored Names that would render
    // as raw slug text on the result screen.
    test('union of scored Name keys covers >=32 distinct anchored Names', () {
      final names = <String>{};
      for (final q in qs.cast<Map<String, dynamic>>()) {
        for (final o in (q['options'] as List).cast<Map<String, dynamic>>()) {
          (o['scores'] as Map).forEach((k, _) => names.add(k as String));
        }
      }
      expect(names.length, greaterThanOrEqualTo(32),
          reason: 'reachable Names = ${names.length}: $names');
    });

    test('every option has 3-6 scored Names with weights in {1, 2, 3}', () {
      for (final q in qs.cast<Map<String, dynamic>>()) {
        for (final o in (q['options'] as List).cast<Map<String, dynamic>>()) {
          final scores = (o['scores'] as Map).cast<String, dynamic>();
          expect(scores.length, inInclusiveRange(3, 6),
              reason:
                  '${q['id']} option "${o['text']}" should score 3-6 Names (got ${scores.length})');
          for (final entry in scores.entries) {
            final w = (entry.value as num).toInt();
            expect(w, inInclusiveRange(1, 3),
                reason:
                    '${q['id']} option "${o['text']}" -> ${entry.key} weight=$w (must be 1, 2, or 3)');
          }
        }
      }
    });

    test('every question prompt and option text is non-empty', () {
      for (final q in qs.cast<Map<String, dynamic>>()) {
        expect((q['prompt'] as String).trim(), isNotEmpty, reason: q['id'] as String);
        for (final o in (q['options'] as List).cast<Map<String, dynamic>>()) {
          expect((o['text'] as String).trim(), isNotEmpty,
              reason: '${q['id']} has empty option text');
        }
      }
    });

    test('no single Name scores top-weight on majority of options (variety guard)', () {
      // Prevents collapse: a Name receiving weight 3 on >50% of options would
      // dominate every result regardless of answer path.
      final topWeightCount = <String, int>{};
      var totalOptions = 0;
      for (final q in qs.cast<Map<String, dynamic>>()) {
        for (final o in (q['options'] as List).cast<Map<String, dynamic>>()) {
          totalOptions++;
          final scores = (o['scores'] as Map).cast<String, dynamic>();
          for (final entry in scores.entries) {
            if ((entry.value as num).toInt() >= 3) {
              topWeightCount[entry.key] = (topWeightCount[entry.key] ?? 0) + 1;
            }
          }
        }
      }
      final half = totalOptions ~/ 2;
      for (final entry in topWeightCount.entries) {
        expect(entry.value, lessThanOrEqualTo(half),
            reason:
                'Name "${entry.key}" carries weight 3 on ${entry.value}/$totalOptions options — would collapse variety.');
      }
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

  group('aggregator returns reachable Names', () {
    // Derive question count from the JSON so this never drifts.
    final qsRaw = File('assets/content/discovery_quiz_questions.json')
        .readAsStringSync();
    final qsCount = (jsonDecode(qsRaw) as List).length;

    test('answering every Q with option 0 returns a non-empty anchor list',
        () {
      final result = calculateQuizResults(List<int>.filled(qsCount, 0));
      expect(result, isNotEmpty);
    });
    test('three distinct answer paths produce distinct top anchors', () {
      final a = calculateQuizResults(List<int>.filled(qsCount, 0));
      final b = calculateQuizResults(List<int>.filled(qsCount, 1));
      final c = calculateQuizResults(List<int>.filled(qsCount, 2));
      expect({a.first.name, b.first.name, c.first.name}.length,
          greaterThanOrEqualTo(2),
          reason: 'expected at least 2 distinct top anchors across 3 paths');
    });
  });
}
