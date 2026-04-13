import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/validate_names.dart';

void main() {
  group('isValidAllahName', () {
    test('matches exact canonical transliteration', () {
      expect(isValidAllahName('Ar-Rahman'), isTrue);
      expect(isValidAllahName('Al-Malik'), isTrue);
    });

    test('matches case-insensitively', () {
      expect(isValidAllahName('ar-rahman'), isTrue);
      expect(isValidAllahName('AR-RAHMAN'), isTrue);
    });

    test('matches without prefix', () {
      expect(isValidAllahName('Rahman'), isTrue);
      expect(isValidAllahName('Malik'), isTrue);
    });

    test('rejects hallucinated names', () {
      expect(isValidAllahName('The-Great-One'), isFalse);
      expect(isValidAllahName('Zorbatron'), isFalse);
      expect(isValidAllahName(''), isFalse);
    });

    test('strips Arabic script before matching', () {
      // Mixed Arabic + transliteration should still match the Latin part.
      expect(isValidAllahName('الرحمن Rahman'), isTrue);
    });
  });

  group('findCanonicalName', () {
    test('returns canonical transliteration and Arabic for valid name', () {
      final result = findCanonicalName('ar-rahman');
      expect(result, isNotNull);
      expect(result!.name, 'Ar-Rahman');
      expect(result.nameArabic, contains('الرَّحْمَنُ'));
    });

    test('returns null for invalid name', () {
      expect(findCanonicalName('NotARealName'), isNull);
    });
  });

  group('filterValidNames', () {
    test('keeps valid names and replaces with canonical values', () {
      final input = [
        {'name': 'ar-rahman', 'nameArabic': 'wrong', 'extra': 'kept'},
        {'name': 'FakeName', 'nameArabic': 'fake'},
        {'name': 'Al-Malik', 'nameArabic': 'also wrong'},
      ];

      final result = filterValidNames(input);

      expect(result, hasLength(2));
      expect(result[0]['name'], 'Ar-Rahman');
      expect(result[0]['extra'], 'kept');
      expect(result[1]['name'], 'Al-Malik');
    });

    test('returns empty list when all names are invalid', () {
      final input = [
        {'name': 'Hallucinated', 'nameArabic': 'fake'},
      ];
      expect(filterValidNames(input), isEmpty);
    });
  });

  group('buildCanonicalNamesPromptList', () {
    test('contains one line per canonical name', () {
      final list = buildCanonicalNamesPromptList();
      final lines = list.split('\n');
      // Should match the number of entries in allahNames.
      expect(lines.length, greaterThan(0));
      expect(lines.length, lines.toSet().length, reason: 'no duplicates');
    });

    test('each line includes transliteration, Arabic, and English', () {
      final list = buildCanonicalNamesPromptList();
      final firstLine = list.split('\n').first;
      expect(firstLine, contains('Ar-Rahman'));
      expect(firstLine, contains('الرَّحْمَنُ'));
      expect(firstLine, contains('The Most Gracious'));
    });
  });
}
