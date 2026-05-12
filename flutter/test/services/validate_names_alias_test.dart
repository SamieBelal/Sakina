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

    test('all AI variants surfaced by knowledge_base.dart resolve correctly', () {
      // The /review adversarial pass surfaced these as live drift: knowledge_base.dart
      // teaching keys use non-canonical transliterations, the AI mirrors them in
      // its output, and unaliased they leak unnormalized into ReflectResponse.name
      // and downstream DB writes. Fixed by extending _transliterationAliases.
      const knownVariants = {
        'Al-Hakim': 'Al-Hakeem',
        'Al-Karim': 'Al-Kareem',
        'Al-Khabir': 'Al-Khabeer',
        'Al-Mujib': 'Al-Mujeeb',
        'Al-Basir': 'Al-Baseer',
        'Al-Matin': 'Al-Mateen',
        'As-Saboor': 'As-Sabur',
      };
      for (final pair in knownVariants.entries) {
        final r = findCanonicalName(pair.key);
        expect(r, isNotNull,
            reason: 'Variant "${pair.key}" should resolve to a canonical Name.');
        expect(r!.name, equals(pair.value),
            reason: 'Variant "${pair.key}" should resolve to "${pair.value}".');
      }
    });

    test('_canonicalMap initializes without throwing (alias-target smoke test)', () {
      // First access to findCanonicalName triggers lazy _canonicalMap init.
      // If any alias target is missing from allahNames, init throws StateError.
      // This smoke test fails fast in CI on any future bad alias addition.
      expect(() => findCanonicalName('Allah'), returnsNormally);
    });
  });
}
