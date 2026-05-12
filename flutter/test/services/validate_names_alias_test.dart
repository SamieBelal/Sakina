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

    test('common AI variants NOT yet in alias map return null (drift guard)', () {
      // These vowel-length variants are the same Arabic Names as canonical entries
      // but are NOT currently in `_transliterationAliases`. Pinning their
      // null-return behavior so future drift is visible: if any of these start
      // resolving, also add a positive test asserting the canonical target.
      // Plan 5 eng review surfaced these in `knowledge_base.dart` teaching keys.
      const variantsNotYetMapped = [
        'Al-Hakim',   // canonical: Al-Hakeem
        'Al-Karim',   // canonical: Al-Kareem
        'Al-Khabir',  // canonical: Al-Khabeer
        'Al-Mujib',   // canonical: Al-Mujeeb
        'Al-Basir',   // canonical: Al-Baseer
        'Al-Matin',   // canonical: Al-Mateen
      ];
      for (final v in variantsNotYetMapped) {
        expect(findCanonicalName(v), isNull,
            reason: 'If "$v" now resolves, also add a positive test asserting '
                'the canonical target it maps to.');
      }
    });
  });
}
