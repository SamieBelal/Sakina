// P2-5 client-side clamp tests. Pins that `SavedReflection.toSupabaseRow`
// truncates oversized fields and arrays to match the server CHECKs in
// `supabase/migrations/20260526000000_user_reflections_length_caps.sql`.
//
// Bugs these tests catch:
//   - Clamp helper drifts from codepoint counting (ENG-REVIEW Finding 1).
//   - Verses array passed through un-truncated (would trip server CHECK).
//   - Per-verse field clamps missing (would trip the shape trigger).
//   - Null inputs crash (would surface as save errors on offline-only path).
//
// See docs/qa/findings/2026-05-24-ai-bypass-p1-p2-review.md (P2-5).

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/reflect/models/reflect_verse.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';

SavedReflection _build({
  String reframe = 'short',
  String story = 'short story',
  String userText = 'ok',
  String name = 'Ar-Rahman',
  String nameArabic = 'الرحمن',
  String reframePreview = 'preview',
  String duaArabic = 'd',
  String duaTransliteration = 'd',
  String duaTranslation = 'd',
  String duaSource = 'src',
  List<SavedVerse> verses = const [],
  List<Map<String, String>> relatedNames = const [],
}) =>
    SavedReflection(
      id: 'r-1',
      date: '2026-05-26T12:00:00Z',
      userText: userText,
      name: name,
      nameArabic: nameArabic,
      reframePreview: reframePreview,
      reframe: reframe,
      story: story,
      verses: verses,
      duaArabic: duaArabic,
      duaTransliteration: duaTransliteration,
      duaTranslation: duaTranslation,
      duaSource: duaSource,
      relatedNames: relatedNames,
    );

void main() {
  test('P2-5: toSupabaseRow clamps reframe to 4096 chars', () {
    final row = _build(reframe: 'A' * 5000).toSupabaseRow('user-1');
    expect((row['reframe'] as String).length, 4096);
  });

  test('P2-5: toSupabaseRow clamps story to 4096 chars', () {
    final row = _build(story: 'S' * 5000).toSupabaseRow('user-1');
    expect((row['story'] as String).length, 4096);
  });

  test('P2-5: toSupabaseRow truncates verses[] to 8 elements', () {
    final verses = List<SavedVerse>.generate(
      15,
      (i) => ReflectVerse(
        arabic: 'a$i',
        translation: 't$i',
        reference: 'r$i',
      ),
    );
    final row = _build(verses: verses).toSupabaseRow('user-1');
    final outVerses = row['verses'] as List;
    expect(outVerses.length, 8);
    // Pin order: first 8 preserved, not arbitrary subset.
    expect((outVerses.first as Map)['arabic'], 'a0');
    expect((outVerses.last as Map)['arabic'], 'a7');
  });

  test('P2-5: toSupabaseRow preserves honest payloads unchanged', () {
    const verses = [
      ReflectVerse(
        arabic: 'بسم الله',
        translation: 'In the name of Allah',
        reference: 'Quran 1:1',
      ),
      ReflectVerse(
        arabic: 'الحمد لله',
        translation: 'Praise be to Allah',
        reference: 'Quran 1:2',
      ),
    ];
    final relatedNames = [
      {'name': 'Ar-Raheem', 'nameArabic': 'الرحيم'},
    ];
    final reflection = _build(
      reframe: 'a' * 500,
      story: 's' * 800,
      userText: 'i feel grateful',
      verses: verses,
      relatedNames: relatedNames,
    );
    final row = reflection.toSupabaseRow('user-1');
    expect(row['reframe'], 'a' * 500);
    expect(row['story'], 's' * 800);
    expect(row['user_text'], 'i feel grateful');
    expect(row['name'], 'Ar-Rahman');
    expect(row['name_arabic'], 'الرحمن');
    final outVerses = row['verses'] as List;
    expect(outVerses, hasLength(2));
    expect((outVerses.first as Map)['arabic'], 'بسم الله');
    expect((outVerses.first as Map)['translation'], 'In the name of Allah');
    expect((outVerses.first as Map)['reference'], 'Quran 1:1');
    expect(row['related_names'], relatedNames);
  });

  test('P2-5: toSupabaseRow truncates related_names[] to 8 elements', () {
    final related = List<Map<String, String>>.generate(
      20,
      (i) => {'name': 'name-$i', 'nameArabic': 'arabic-$i'},
    );
    final row = _build(relatedNames: related).toSupabaseRow('user-1');
    final out = row['related_names'] as List;
    expect(out.length, 8);
    // Order preserved.
    expect((out.first as Map)['name'], 'name-0');
    expect((out.last as Map)['name'], 'name-7');
  });

  test('P2-5: toSupabaseRow clamps per-verse field lengths', () {
    final verses = [
      ReflectVerse(
        arabic: 'A' * 3000,
        translation: 'T' * 3000,
        reference: 'R' * 500,
      ),
    ];
    final row = _build(verses: verses).toSupabaseRow('user-1');
    final outVerses = row['verses'] as List;
    final first = outVerses.first as Map;
    expect((first['arabic'] as String).length, 2048);
    expect((first['translation'] as String).length, 2048);
    expect((first['reference'] as String).length, 200);
  });

  test('P2-5: toSupabaseRow handles SavedReflection with empty defaults', () {
    // SavedReflection itself has non-null defaults ('' / const []), but
    // toSupabaseRow must not crash on empty inputs and must surface explicit
    // empty strings (the schema requires NOT NULL on every text column).
    const reflection = SavedReflection(
      id: 'r-empty',
      date: '2026-05-26T12:00:00Z',
      userText: '',
      name: '',
      nameArabic: '',
      reframePreview: '',
    );
    final row = reflection.toSupabaseRow('user-1');
    expect(row['reframe'], '');
    expect(row['story'], '');
    expect(row['user_text'], '');
    expect(row['name'], '');
    expect(row['name_arabic'], '');
    expect(row['reframe_preview'], '');
    expect(row['dua_arabic'], '');
    expect(row['dua_transliteration'], '');
    expect(row['dua_translation'], '');
    expect(row['dua_source'], '');
    expect(row['verses'], isEmpty);
    expect(row['related_names'], isEmpty);
  });
}
