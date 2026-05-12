import 'package:flutter_test/flutter_test.dart';
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
        // Category comes directly from FindDuasDuaEntry.category — no
        // back-mapping by title, so collisions don't produce false passes.
        expect(hits.first.category, equals(expectedCategory),
            reason: '"$phrase" top hit was ${hits.first.category}, expected $expectedCategory');
      });
    }
  });
}
