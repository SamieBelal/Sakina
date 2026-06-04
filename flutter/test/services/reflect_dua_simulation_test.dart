import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/constants/knowledge_base.dart';
import 'package:sakina/services/ai_service.dart';

/// End-to-end-ish simulation: drive realistic raw model completions through the
/// real `parseReflectResponse` and assert the dua surfaced to the UI is always
/// correct Arabic. This stands in for a live OpenAI call — it exercises the
/// exact parse + normalize path the app runs, across the WHOLE knowledge base
/// rather than a single hand-picked dua.

final RegExp _arabic = RegExp(r'[؀-ۿ]');

String _rawResponse({
  required String name,
  required String duaAr,
  required String duaTr,
  required String duaEn,
  required String duaSource,
}) =>
    '''
##NAME## $name
##NAME_AR## الاسم
##REFRAME## A warm reframe grounded in this Name.
##STORY## A prophetic story illustrating the Name.
##VERSE_1_AR## أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ
##VERSE_1_EN## placeholder
##VERSE_1_REF## Ar-Ra'd 13:28
##DUA_AR## $duaAr
##DUA_TR## $duaTr
##DUA_EN## $duaEn
##DUA_SOURCE## $duaSource
##RELATED## Ar-Rahman (الرحمن)
''';

void main() {
  test(
      'SIMULATION: transliteration-in-Arabic-slot is recovered to verified Arabic for EVERY teaching dua',
      () {
    // The set of every verified Arabic dua string in the knowledge base. A
    // recovered dua must be drawn from this set — proving it is real,
    // pre-verified content and never the model's transliteration.
    final verifiedArabic = nameTeachings.map((t) => t.dua.arabic).toSet();

    var checked = 0;
    final failures = <String>[];

    for (final teaching in nameTeachings) {
      // Worst case: model copies the transliteration into BOTH slots (the bug).
      final raw = _rawResponse(
        name: teaching.name.split(' / ').first,
        duaAr: teaching.dua.transliteration,
        duaTr: teaching.dua.transliteration,
        duaEn: teaching.dua.translation,
        duaSource: teaching.dua.source,
      );

      final parsed = parseReflectResponse(raw);
      checked++;

      if (parsed == null) {
        failures.add('${teaching.name}: parse returned null');
        continue;
      }
      // Core guarantee: the Arabic slot holds Arabic script, not transliteration.
      if (!_arabic.hasMatch(parsed.duaArabic)) {
        failures.add(
            '${teaching.name}: duaArabic not Arabic → "${parsed.duaArabic}"');
        continue;
      }
      // Anti-fabrication: recovered Arabic is a verified knowledge-base string.
      if (!verifiedArabic.contains(parsed.duaArabic)) {
        failures.add('${teaching.name}: duaArabic is not a verified dua string');
      }
    }

    // ignore: avoid_print
    print('SIMULATION: checked $checked teaching duas, '
        '${failures.length} failures.');
    expect(failures, isEmpty, reason: failures.join('\n'));
    expect(checked, greaterThan(30));
  });

  test('SIMULATION: a correct model response passes through unchanged', () {
    final raw = _rawResponse(
      name: 'Ar-Rabb',
      duaAr: 'رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي',
      duaTr: 'Rabbi ishrah li sadri wa yassir li amri',
      duaEn: 'My Lord, expand my chest for me and ease my affairs.',
      duaSource: 'Quran 20:25-26',
    );

    final parsed = parseReflectResponse(raw)!;
    expect(parsed.duaArabic, 'رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي');
    expect(_arabic.hasMatch(parsed.duaArabic), isTrue);
    // ignore: avoid_print
    print('SIMULATION: correct response → duaArabic="${parsed.duaArabic}"');
  });

  test('SIMULATION: unknown dua with leaked transliteration is blanked, not rendered',
      () {
    final raw = _rawResponse(
      name: 'As-Salam',
      duaAr: 'Allahumma inni as-aluka al-huda wat-tuqa',
      duaTr: 'Allahumma inni as-aluka al-huda wat-tuqa',
      duaEn: 'O Allah, I ask You for guidance and piety.',
      duaSource: 'Sahih Muslim',
    );

    final parsed = parseReflectResponse(raw)!;
    // Not in our knowledge base → no Arabic available → blanked (guard) so the
    // UI never shows transliteration in the Arabic display slot.
    expect(parsed.duaArabic, isEmpty);
    expect(parsed.duaTranslation, 'O Allah, I ask You for guidance and piety.');
    // ignore: avoid_print
    print('SIMULATION: unmatched non-Arabic dua → duaArabic blanked, '
        'translation preserved="${parsed.duaTranslation}"');
  });
}
