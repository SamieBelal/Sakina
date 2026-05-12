import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/constants/duas.dart' show browseDuasCatalog;
import 'package:sakina/services/ai_service.dart';

void main() {
  group('findDuas smoke eval', () {
    const fixture = [
      ('I am so angry I could scream', 'anger'),
      ('I feel jealous of my friend\'s success', 'envy'),
      ('I am drowning in lust', 'lust'),
      ('I have nobody, I feel completely alone', 'loneliness'),
      ('I am ashamed of what I did last night', 'shame'),
      ('I am burned out and can\'t function', 'burnout'),
      ('my marriage is falling apart', 'marriage_conflict'),
      ('I am failing as a parent', 'parenting'),
      ('I just got fired and don\'t know what to do', 'work'),
      ('my father just died and I can\'t breathe', 'death_grief'),
    ];

    for (final (phrase, expectedCategory) in fixture) {
      test('"$phrase" → top hit is $expectedCategory', () {
        final hits = searchLocalDuasForTest(phrase);
        expect(hits, isNotEmpty, reason: phrase);
        final topCategory = browseDuasCatalog
            .firstWhere((d) => d.title == hits.first.title)
            .category;
        expect(topCategory, equals(expectedCategory),
            reason: '"$phrase" top hit was $topCategory, expected $expectedCategory');
      });
    }
  });
}
