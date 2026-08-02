import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/ai_service.dart';

void main() {
  test('parseReflectResponse parses one approved verse', () {
    final parsed = parseReflectResponse('''
##NAME## As-Salam
##NAME_AR## السلام
##REFRAME## Calm can return.
##STORY## A story.
##VERSE_1_AR## أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ
##VERSE_1_EN## placeholder
##VERSE_1_REF## Ar-Ra'd 13:28
##DUA_AR## دعاء
##DUA_TR## dua
##DUA_EN## supplication
##DUA_SOURCE## source
##RELATED## Al-Lateef (اللطيف)
''');

    expect(parsed, isNotNull);
    expect(parsed!.verses, hasLength(1));
    expect(parsed.verses.single.reference, 'Ar-Ra\'d 13:28');
    expect(
      parsed.verses.single.translation,
      'Verily, in the remembrance of Allah do hearts find rest.',
    );
  });

  test('parseReflectResponse parses two approved verses', () {
    final parsed = parseReflectResponse('''
##NAME## Al-Ghaffar
##NAME_AR## الغفار
##REFRAME## Return to Allah.
##STORY## A story.
##VERSE_1_AR## placeholder
##VERSE_1_EN## placeholder
##VERSE_1_REF## Al-A'raf 7:23
##VERSE_2_AR## placeholder
##VERSE_2_EN## placeholder
##VERSE_2_REF## Al-Hashr 59:10
##DUA_AR## دعاء
##DUA_TR## dua
##DUA_EN## supplication
##DUA_SOURCE## source
##RELATED## Ar-Rahman (الرحمن)
''');

    expect(parsed, isNotNull);
    expect(parsed!.verses, hasLength(2));
    expect(parsed.verses.first.reference, "Al-A'raf 7:23");
    expect(parsed.verses.last.reference, 'Al-Hashr 59:10');
  });

  test('parseReflectResponse ignores partial verse markers safely', () {
    final parsed = parseReflectResponse('''
##NAME## As-Salam
##NAME_AR## السلام
##REFRAME## Calm can return.
##STORY## A story.
##VERSE_1_AR## أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ
##VERSE_1_EN## placeholder
##VERSE_2_AR## فَبِأَيِّ آلَاءِ رَبِّكُمَا تُكَذِّبَانِ
##VERSE_2_EN## placeholder
##VERSE_2_REF## Ar-Rahman 55:13
##DUA_AR## دعاء
##DUA_TR## dua
##DUA_EN## supplication
##DUA_SOURCE## source
##RELATED## Al-Lateef (اللطيف)
''');

    expect(parsed, isNotNull);
    expect(parsed!.verses, hasLength(1));
    expect(parsed.verses.single.reference, 'Ar-Rahman 55:13');
  });

  test(
      'parseReflectResponse substitutes verified Arabic when the model leaks transliteration into the dua Arabic slot',
      () {
    // Reproduces the reported bug: the model returned the transliteration of
    // the Ar-Rabb (Moses) dua in BOTH ##DUA_AR## and ##DUA_TR##.
    final parsed = parseReflectResponse('''
##NAME## Ar-Rabb
##NAME_AR## الرب
##REFRAME## He is nurturing you through this transition.
##STORY## A story.
##VERSE_1_AR## أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ
##VERSE_1_EN## placeholder
##VERSE_1_REF## Ar-Ra'd 13:28
##DUA_AR## Rabbi ishrah li sadri wa yassir li amri
##DUA_TR## Rabbi ishrah li sadri wa yassir li amri
##DUA_EN## My Lord, expand my chest for me and ease my affairs.
##DUA_SOURCE## Quran 20:25-26
##RELATED## Ar-Rahman (الرحمن)
''');

    expect(parsed, isNotNull);
    expect(parsed!.duaArabic, 'رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي');
    expect(
      RegExp(r'[؀-ۿ]').hasMatch(parsed.duaArabic),
      isTrue,
      reason: 'dua Arabic slot must contain Arabic script, not transliteration',
    );
    expect(parsed.duaTransliteration, 'Rabbi ishrah li sadri wa yassir li amri');
  });

  test(
      'parseReflectResponse blanks a non-Arabic dua with no canonical match (guard)',
      () {
    final parsed = parseReflectResponse('''
##NAME## As-Salam
##NAME_AR## السلام
##REFRAME## Calm can return.
##STORY## A story.
##VERSE_1_AR## أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ
##VERSE_1_EN## placeholder
##VERSE_1_REF## Ar-Ra'd 13:28
##DUA_AR## Some made-up transliteration not in our data
##DUA_TR## Some made-up transliteration not in our data
##DUA_EN## A translation
##DUA_SOURCE## A source
##RELATED## Al-Lateef (اللطيف)
''');

    expect(parsed, isNotNull);
    expect(parsed!.duaArabic, isEmpty);
    expect(parsed.duaTranslation, 'A translation');
  });

  test(
      'parseReflectResponse preserves a genuine Arabic dua already in the Arabic slot',
      () {
    final parsed = parseReflectResponse('''
##NAME## As-Salam
##NAME_AR## السلام
##REFRAME## Calm can return.
##STORY## A story.
##VERSE_1_AR## أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ
##VERSE_1_EN## placeholder
##VERSE_1_REF## Ar-Ra'd 13:28
##DUA_AR## دعاء صحيح
##DUA_TR## duaun saheeh
##DUA_EN## a valid supplication
##DUA_SOURCE## source
##RELATED## Al-Lateef (اللطيف)
''');

    expect(parsed, isNotNull);
    expect(parsed!.duaArabic, 'دعاء صحيح');
    expect(parsed.duaTransliteration, 'duaun saheeh');
  });

  group('inline parenthetical gloss stripping (disjointed-reflect fix)', () {
    // The model intermittently sprinkles translation/honorific glosses into
    // narrative beats ("Ayoub (Job) faced…"), which read as choppy asides on
    // the beat canvas. parseReflectResponse strips them from narrative fields.
    test('strips glosses from story beats, reframe, title, and takeaway', () {
      final parsed = parseReflectResponse('''
##NAME## As-Sabur
##NAME_AR## الصبور
##REFRAME_KEY## Patience (sabr) carries you through.
##REFRAME_BODY## Ayoub (Job) endured, and Allah (the Most Kind) restored him.
##STORY_TITLE## Ayoub (Job) and Patience
##STORY_BEAT_1## Ayoub (Job) faced immense loss.
##STORY_BEAT_2## The Prophet Muhammad (peace be upon him) taught patience.
##STORY_SOURCE## Qur'an (21:83-84)
##TAKEAWAY## Like Musa (Moses), turn to Allah in hardship.
##DUA_AR## دعاء
##DUA_TR## dua
##DUA_EN## supplication
##DUA_SOURCE## source
##RELATED## Al-Lateef (اللطيف)
''');

      expect(parsed, isNotNull);
      // Narrative fields: glosses removed, spacing repaired.
      expect(parsed!.reframeKey, 'Patience carries you through.');
      expect(parsed.reframeBody, 'Ayoub endured, and Allah restored him.');
      expect(parsed.storyTitle, 'Ayoub and Patience');
      expect(parsed.storyBeats, <String>[
        'Ayoub faced immense loss.',
        'The Prophet Muhammad taught patience.',
      ]);
      expect(parsed.takeaway, 'Like Musa, turn to Allah in hardship.');
      // Citation fields keep their parentheses — they are NOT narrative.
      expect(parsed.storySource, "Qur'an (21:83-84)");
      // Related "Name (Arabic)" parens are parsed, not gloss-stripped: the name
      // survives (Arabic is canonicalized to the diacritized catalog spelling).
      expect(parsed.relatedNames.single.name, 'Al-Lateef');
      expect(parsed.relatedNames.single.nameArabic, isNotEmpty);
    });

    test('numeric parenthetical refs inside a beat are preserved', () {
      final parsed = parseReflectResponse('''
##NAME## Al-Lateef
##NAME_AR## اللطيف
##REFRAME_KEY## He is gentle with you.
##REFRAME_BODY## Yusuf trusted Him (12:100) through every trial.
##STORY_BEAT_1## Every hardship was placed with care.
##DUA_AR## دعاء
##DUA_TR## dua
##DUA_EN## supplication
##DUA_SOURCE## source
##RELATED## As-Sabur (الصبور)
''');

      expect(parsed, isNotNull);
      // "(12:100)" starts with a digit → kept; only letter-led glosses go.
      expect(parsed!.reframeBody, 'Yusuf trusted Him (12:100) through every trial.');
    });

    test('gloss-free text is returned unmutated, incl. blank-line breaks', () {
      // The exact regression the `\s{2,}`→' ' collapse would have caused: a
      // gloss-free field containing a blank line must survive untouched (no
      // gloss => no-op; newlines are never collapsed).
      final parsed = parseReflectResponse('''
##NAME## As-Salam
##NAME_AR## السلام
##REFRAME_KEY## Peace can return.
##REFRAME_BODY## First thought here.

Second thought here.
##STORY_BEAT_1## A calm beat that is long enough.
##DUA_AR## دعاء
##DUA_TR## dua
##DUA_EN## supplication
##DUA_SOURCE## source
##RELATED## Al-Lateef (اللطيف)
''');

      expect(parsed, isNotNull);
      expect(parsed!.reframeBody, 'First thought here.\n\nSecond thought here.');
    });

    test('gloss removal on legacy prose strips the aside, keeps the sentence', () {
      final parsed = parseReflectResponse('''
##NAME## As-Sabur
##NAME_AR## الصبور
##REFRAME## Ayoub (Job) endured his trials.
##STORY## A story of patience unfolds.
##DUA_AR## دعاء
##DUA_TR## dua
##DUA_EN## supplication
##DUA_SOURCE## source
##RELATED## Al-Lateef (اللطيف)
''');

      expect(parsed, isNotNull);
      expect(parsed!.reframe, 'Ayoub endured his trials.');
    });
  });

  group('parseRelatedDuaRows', () {
    test('drops the echoed prompt legend row', () {
      // The buildDua prompt states the format as a literal line, and the model
      // echoed it back. It used to survive (title:"Title", arabic:"Arabic" are
      // both non-empty) and rendered as the first — expanded — related card.
      final rows = parseRelatedDuaRows('''
Title | Arabic | Transliteration | Translation | Source
Dua for Marriage | رَبَّنَا هَبْ لَنَا | Rabbana hab lana | Our Lord, grant us | Quran 25:74
''');

      expect(rows, hasLength(1));
      expect(rows.single.title, 'Dua for Marriage');
    });

    test('drops any row whose Arabic column holds no Arabic script', () {
      final rows = parseRelatedDuaRows('''
Some Dua | (Arabic goes here) | translit | translation | source
Real Dua | اللَّهُمَّ إِنِّي أَسْأَلُكَ | Allahumma inni as'aluka | O Allah, I ask You | Hadith
''');

      expect(rows, hasLength(1));
      expect(rows.single.title, 'Real Dua');
    });

    test('keeps well-formed rows and strips list numbering from the title', () {
      final rows = parseRelatedDuaRows('''
1. Dua for Patience | رَبَّنَا أَفْرِغْ عَلَيْنَا صَبْرًا | Rabbana afrigh | Our Lord, pour patience | Quran 2:250
- Dua for Light | اللَّهُمَّ اجْعَلْ لِي نُورًا | Allahumma ij'al li nooran | O Allah, make for me light | Hadith
''');

      expect(rows, hasLength(2));
      expect(rows[0].title, 'Dua for Patience');
      expect(rows[1].title, 'Dua for Light');
      expect(rows[0].source, 'Quran 2:250');
    });
  });
}
