import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/constants/knowledge_base.dart';

/// The canonical Ar-Rabb (Moses) dua — present in `nameTeachings`. Used as the
/// reference fixture because it's the exact dua from the reported bug
/// (transliteration "Rabbi ishrah li sadri wa yassir li amri" was rendered in
/// the Arabic display slot).
const _rabbiIshrahArabic = 'رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي';
const _rabbiIshrahTranslit = 'Rabbi ishrah li sadri wa yassir li amri';

void main() {
  group('containsArabicScript', () {
    test('returns true for Arabic script', () {
      expect(containsArabicScript(_rabbiIshrahArabic), isTrue);
      expect(containsArabicScript('دعاء'), isTrue);
    });

    test('returns false for transliteration / latin text', () {
      expect(containsArabicScript(_rabbiIshrahTranslit), isFalse);
      expect(containsArabicScript('My Lord, expand my chest'), isFalse);
      expect(containsArabicScript(''), isFalse);
    });
  });

  group('teachingDuaByTransliteration', () {
    test('matches a known teaching dua by exact transliteration', () {
      final dua = teachingDuaByTransliteration(_rabbiIshrahTranslit);
      expect(dua, isNotNull);
      expect(dua!.arabic, _rabbiIshrahArabic);
    });

    test('match tolerates case, punctuation, and spacing differences', () {
      final dua = teachingDuaByTransliteration(
        '  RABBI  ISHRAH, li-sadri wa yassir li amri.  ',
      );
      expect(dua, isNotNull);
      expect(dua!.arabic, _rabbiIshrahArabic);
    });

    test('returns null for null / empty / unknown transliteration', () {
      expect(teachingDuaByTransliteration(null), isNull);
      expect(teachingDuaByTransliteration(''), isNull);
      expect(teachingDuaByTransliteration('not a real dua at all'), isNull);
    });
  });

  group('normalizeReflectDua — robust substitution', () {
    test(
        'substitutes verified Arabic when transliteration leaked into the Arabic slot (the reported bug)',
        () {
      // Reproduces the screenshot: the model put the transliteration in BOTH
      // the Arabic slot and the transliteration slot.
      final result = normalizeReflectDua(
        arabic: _rabbiIshrahTranslit,
        transliteration: _rabbiIshrahTranslit,
        translation: 'My Lord, expand my chest for me and ease my affairs.',
        source: 'Quran 20:25-26',
      );

      expect(result.arabic, _rabbiIshrahArabic);
      expect(containsArabicScript(result.arabic), isTrue);
      expect(result.transliteration, _rabbiIshrahTranslit);
    });

    test(
        'recovers when transliteration leaked ONLY into the Arabic slot (DUA_TR empty)',
        () {
      final result = normalizeReflectDua(
        arabic: _rabbiIshrahTranslit,
        transliteration: '',
        translation: '',
        source: '',
      );

      expect(result.arabic, _rabbiIshrahArabic);
      expect(result.transliteration, _rabbiIshrahTranslit);
    });

    test('substitutes the full verified record even when model Arabic differs',
        () {
      final result = normalizeReflectDua(
        arabic: 'رب اشرح', // partial / typo'd Arabic
        transliteration: _rabbiIshrahTranslit,
        translation: 'wrong translation',
        source: 'wrong source',
      );

      expect(result.arabic, _rabbiIshrahArabic);
      expect(result.translation,
          'My Lord, expand my chest for me and ease my affairs.');
    });
  });

  group('normalizeReflectDua — guard (no canonical match)', () {
    test('keeps a valid model dua that is not in the knowledge base', () {
      const arabic = 'اللَّهُمَّ الْطُفْ بِي فِي تَيْسِيرِ كُلِّ عَسِيرٍ';
      final result = normalizeReflectDua(
        arabic: arabic,
        transliteration: "Allahumma-ltuf bi fi taysiri kulli 'aseer",
        translation: 'O Allah, be gentle with me in easing every hardship.',
        source: 'Common supplication based on the Name Al-Lateef',
      );

      expect(result.arabic, arabic);
      expect(result.transliteration, "Allahumma-ltuf bi fi taysiri kulli 'aseer");
    });

    test(
        'blanks the Arabic slot when it holds non-Arabic text with no canonical match',
        () {
      final result = normalizeReflectDua(
        arabic: 'Some unknown transliteration not in our data',
        transliteration: 'Some unknown transliteration not in our data',
        translation: 'A translation',
        source: 'A source',
      );

      expect(result.arabic, isEmpty);
      // Textual fields preserved so the card still conveys the dua.
      expect(result.transliteration, 'Some unknown transliteration not in our data');
      expect(result.translation, 'A translation');
      expect(result.source, 'A source');
    });

    test('empty model dua stays empty (no crash, no fabrication)', () {
      final result = normalizeReflectDua(
        arabic: '',
        transliteration: '',
        translation: '',
        source: '',
      );

      expect(result.arabic, isEmpty);
      expect(result.transliteration, isEmpty);
    });
  });
}
