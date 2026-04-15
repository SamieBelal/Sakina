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
##VERSE_1_REF## Quran 7:23
##VERSE_2_AR## placeholder
##VERSE_2_EN## placeholder
##VERSE_2_REF## Quran 59:10
##DUA_AR## دعاء
##DUA_TR## dua
##DUA_EN## supplication
##DUA_SOURCE## source
##RELATED## Ar-Rahman (الرحمن)
''');

    expect(parsed, isNotNull);
    expect(parsed!.verses, hasLength(2));
    expect(parsed.verses.first.reference, 'Quran 7:23');
    expect(parsed.verses.last.reference, 'Quran 59:10');
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
}
