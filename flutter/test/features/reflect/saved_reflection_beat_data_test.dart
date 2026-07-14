import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';

// Round-trips SavedReflection beat_data through local (toJson/fromJson) and
// Supabase (toSupabaseRow/fromSupabaseRow) shapes, and confirms legacy rows
// (no beat_data) survive as null → fallback path.
void main() {
  SavedReflection withBeats() => const SavedReflection(
        id: 'r1',
        date: '2026-07-14T10:00:00.000Z',
        userText: 'I feel unseen',
        name: 'Al-Lateef',
        nameArabic: 'اللطيف',
        reframePreview: 'Allah is subtle and near...',
        reframe: 'Allah is subtle and near. He tends to what you cannot.',
        story: 'Musa faced the sea. The army closed in. It parted.',
      ).copyWithBeats(
        reframeKey: 'Allah was gentle with you tonight',
        reframeBody: 'Even unseen, His kindness arranged what you could not.',
        storyTitle: 'Musa at the Sea',
        storyBeats: const [
          'The sea stood before him and the army behind.',
          'He said, my Lord is with me.',
          'The water parted at His command.',
        ],
        storySource: "Qur'an 26:62",
        takeaway: 'What feels like drowning may be the sea parting.',
      );

  test('hasBeats reflects presence of structured data', () {
    expect(withBeats().hasBeats, isTrue);
    const legacy = SavedReflection(
      id: 'r0',
      date: 'd',
      userText: 'u',
      name: 'n',
      nameArabic: 'a',
      reframePreview: 'p',
      reframe: 'some reframe',
      story: 'some story',
    );
    expect(legacy.hasBeats, isFalse);
  });

  test('local JSON round-trip preserves all beat fields', () {
    final restored = SavedReflection.fromJson(withBeats().toJson());
    expect(restored.hasBeats, isTrue);
    expect(restored.reframeKey, 'Allah was gentle with you tonight');
    expect(restored.storyTitle, 'Musa at the Sea');
    expect(restored.storyBeats, hasLength(3));
    expect(restored.storySource, "Qur'an 26:62");
    expect(restored.takeaway, 'What feels like drowning may be the sea parting.');
  });

  test('Supabase row round-trip preserves beat fields under beat_data', () {
    final row = withBeats().toSupabaseRow('user-1');
    expect(row['beat_data'], isA<Map>());
    final restored = SavedReflection.fromSupabaseRow(row);
    expect(restored.storyBeats, hasLength(3));
    expect(restored.reframeBody, contains('His kindness'));
  });

  test('legacy row (no beat_data) restores with null beats → fallback path', () {
    final row = <String, dynamic>{
      'id': 'old-1',
      'saved_at': '2026-01-01T00:00:00.000Z',
      'user_text': 'u',
      'name': 'Al-Lateef',
      'name_arabic': 'اللطيف',
      'reframe_preview': 'p',
      'reframe': 'legacy reframe text',
      'story': 'legacy story text',
      // no beat_data key at all
    };
    final restored = SavedReflection.fromSupabaseRow(row);
    expect(restored.hasBeats, isFalse);
    expect(restored.reframe, 'legacy reframe text');
  });

  test('beat_data is omitted (null) when there are no beats', () {
    const legacy = SavedReflection(
      id: 'r0',
      date: 'd',
      userText: 'u',
      name: 'n',
      nameArabic: 'a',
      reframePreview: 'p',
      reframe: 'r',
      story: 's',
    );
    expect(legacy.toSupabaseRow('u1')['beat_data'], isNull);
    expect(legacy.toJson()['beatData'], isNull);
  });
}
