import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/utils/beat_splitter.dart';

void main() {
  group('splitIntoBeats', () {
    test('empty / whitespace returns empty list', () {
      expect(splitIntoBeats(''), isEmpty);
      expect(splitIntoBeats('   \n  '), isEmpty);
    });

    test('splits a multi-sentence paragraph into one beat per sentence', () {
      final beats = splitIntoBeats(
        'Musa faced the sea before him. The army closed in behind him. '
        'Then Allah told him to strike the water.',
      );
      expect(beats, hasLength(3));
      expect(beats[0], 'Musa faced the sea before him.');
      expect(beats[1], 'The army closed in behind him.');
      expect(beats[2], 'Then Allah told him to strike the water.');
    });

    test('does not split inside honorifics or abbreviations', () {
      final beats = splitIntoBeats(
        'The Prophet s.a.w. taught us patience in every hardship. '
        'He showed mercy, e.g. to those who wronged him early on.',
      );
      expect(beats, hasLength(2));
      expect(beats[0], contains('s.a.w.'));
      expect(beats[1], contains('e.g.'));
    });

    test('merges a short trailing fragment into the previous beat', () {
      final beats = splitIntoBeats(
        'Allah was always near you through the long night of waiting. He knew.',
      );
      // "He knew." is < 4 words → folded into the previous beat.
      expect(beats, hasLength(1));
      expect(beats.first, endsWith('He knew.'));
    });

    test('merges a short leading fragment forward', () {
      final beats = splitIntoBeats(
        'He wept. Then he turned his whole heart back toward his Lord in hope.',
      );
      expect(beats, hasLength(1));
      expect(beats.first, startsWith('He wept.'));
    });

    test('handles question and exclamation marks as sentence ends', () {
      final beats = splitIntoBeats(
        'Do you feel abandoned right now? You are not, and you never were!',
      );
      expect(beats, hasLength(2));
      expect(beats[0], endsWith('?'));
      expect(beats[1], endsWith('!'));
    });

    test('a single sentence with no terminal punctuation is one beat', () {
      final beats = splitIntoBeats('Allah is nearer to you than your own breath');
      expect(beats, hasLength(1));
      expect(beats.first, 'Allah is nearer to you than your own breath');
    });
  });
}
