import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/validate_names.dart';

void main() {
  group('transliteration aliases resolve to canonical', () {
    for (final pair in [
      ('Al-Wakil', 'Al-Wakeel'),
      ('Al-Dhahir', 'Az-Zahir'),
      ('Al-Halim', 'Al-Haleem'),
      ('Al-Latif', 'Al-Lateef'),
    ]) {
      test('${pair.$1} -> ${pair.$2}', () {
        final r = findCanonicalName(pair.$1);
        expect(r, isNotNull, reason: 'alias ${pair.$1} should resolve');
        expect(r!.name, equals(pair.$2));
      });
    }
    test('non-canonical name returns null (Ar-Rabb is not in the 99)', () {
      expect(findCanonicalName('Ar-Rabb'), isNull);
    });
    test('Al-Majeed vs Al-Majid stay distinct (collision guard)', () {
      final majeed = findCanonicalName('Al-Majeed');
      final majid = findCanonicalName('Al-Majid');
      expect(majeed, isNotNull);
      expect(majid, isNotNull);
      expect(majeed!.name, equals('Al-Majeed'));
      expect(majid!.name, equals('Al-Majid'));
    });
  });
}
