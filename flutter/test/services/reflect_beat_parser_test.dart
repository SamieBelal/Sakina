import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/ai_service.dart';

// Locks the beat parser ladder (ai_service.parseReflectResponse):
//   Rung 1   — all beat markers present.
//   Rung 1.5 — some beat markers present; gaps backfilled, missing screens drop.
//   Rung 3   — no beat markers, legacy ##REFRAME##/##STORY## present.
void main() {
  const dua = '''
##DUA_AR## رَبِّ اشْرَحْ لِي صَدْرِي
##DUA_TR## Rabbi-shrah li sadri
##DUA_EN## My Lord, expand for me my breast.
##DUA_SOURCE## Qur'an 20:25
##RELATED## Ar-Rahman (الرحمن)
''';

  group('parseReflectResponse — beat ladder', () {
    test('rung 1: full structured beats parse into fields', () {
      final r = parseReflectResponse('''
##NAME## Al-Lateef
##NAME_AR## اللطيف
##REFRAME_KEY## Allah was gentle with you tonight
##REFRAME_BODY## Even unseen, His kindness was arranging what you could not.
##STORY_TITLE## Musa at the Sea
##STORY_BEAT_1## The sea stood before him and the army behind.
##STORY_BEAT_2## He said, indeed my Lord is with me.
##STORY_BEAT_3## The water parted at his Lord's command.
##STORY_SOURCE## Qur'an 26:62
##TAKEAWAY## What feels like drowning may be the sea parting.
$dua
''')!;

      expect(r.hasBeats, isTrue);
      expect(r.reframeKey, 'Allah was gentle with you tonight');
      expect(r.storyTitle, 'Musa at the Sea');
      expect(r.storyBeats, hasLength(3));
      expect(r.storySource, "Qur'an 26:62");
      expect(r.takeaway, 'What feels like drowning may be the sea parting.');
      // Derived legacy fields are regenerated from the beats.
      expect(r.reframe, contains('Allah was gentle'));
      expect(r.story, contains('The sea stood before him'));
    });

    test('rung 1: a 2-beat story yields exactly 2 beats', () {
      final r = parseReflectResponse('''
##NAME## Al-Lateef
##NAME_AR## اللطيف
##REFRAME_KEY## He never left your side
##STORY_TITLE## The Cave
##STORY_BEAT_1## Two men hid as their pursuers drew near.
##STORY_BEAT_2## Do not grieve, Allah is with us, he said.
##TAKEAWAY## You are not alone in the dark.
$dua
''')!;
      expect(r.storyBeats, hasLength(2));
    });

    test('rung 1.5: partial — missing takeaway/title drop, story still splits', () {
      final r = parseReflectResponse('''
##NAME## Al-Lateef
##NAME_AR## اللطيف
##REFRAME_KEY## Allah sees what no one else does
##REFRAME_BODY## Your quiet patience is not invisible to Him.
##STORY_SOURCE## Sahih al-Bukhari 3477
$dua
''')!;
      expect(r.hasBeats, isTrue);
      expect(r.reframeKey, 'Allah sees what no one else does');
      expect(r.storyBeats, isEmpty); // no story markers → no story screens
      expect(r.takeaway, isEmpty); // missing → screen simply drops
      expect(r.storyTitle, isEmpty);
    });

    test('rung 3: legacy markers only → prose split into beats, no key line', () {
      final r = parseReflectResponse('''
##NAME## Al-Lateef
##NAME_AR## اللطيف
##REFRAME## You feel unseen, but Al-Lateef is subtle and near. He tends to what you cannot.
##STORY## Musa faced the sea before him. The army closed in behind. Allah told him to strike the water.
$dua
''')!;
      expect(r.hasBeats, isTrue); // beats exist via the fallback split
      expect(r.reframeKey, isEmpty); // never promote a fragment to a pull quote
      expect(r.reframeBody, contains('Al-Lateef is subtle'));
      expect(r.storyBeats.length, greaterThanOrEqualTo(2));
    });

    test('blank content returns null (caller falls back to demo)', () {
      final r = parseReflectResponse('##NAME## Al-Lateef\n##NAME_AR## اللطيف\n');
      expect(r, isNull);
    });
  });
}
