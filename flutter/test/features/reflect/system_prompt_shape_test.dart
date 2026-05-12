import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/ai_service.dart';

void main() {
  test('system prompt does not contain approved-verse enumeration', () {
    final prompt = buildSystemPrompt();
    expect(prompt.contains('## Approved Quran Verses'), isFalse,
        reason: 'verse list belongs in code, not prompt');
    expect(prompt.contains('VERSE_1_AR'), isFalse,
        reason: 'AI no longer returns verses');
  });

  test('parser response shape no longer requires verse fields', () {
    // Confirms that parseReflectResponse populates verses purely from catalog fallback.
    final response = parseReflectResponse(
      '##NAME## Al-Lateef\n'
      '##NAME_AR## اللطيف\n'
      '##REFRAME## Reframe text\n'
      '##STORY## Story text\n'
      '##DUA_AR## Dua\n'
      '##DUA_TR## Dua\n'
      '##DUA_EN## Dua\n'
      '##DUA_SOURCE## Source\n'
      '##RELATED## Al-Hakeem (الحكيم)',
    );
    expect(response, isNotNull);
    expect(response!.verses, isNotEmpty,
        reason: 'verses must come from catalog fallback');
  });
}
