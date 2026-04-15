import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/reflect/models/reflect_verse.dart';
import 'package:sakina/widgets/share_card.dart';

void main() {
  testWidgets(
      'reflection share card renders first verse and omits extra verses',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReflectionShareCard(
            nameArabic: 'السلام',
            nameEnglish: 'As-Salam',
            verses: [
              ReflectVerse(
                arabic: 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
                translation:
                    'Verily, in the remembrance of Allah do hearts find rest.',
                reference: 'Ar-Ra\'d 13:28',
              ),
              ReflectVerse(
                arabic: 'فَبِأَيِّ آلَاءِ رَبِّكُمَا تُكَذِّبَانِ',
                translation:
                    'So which of the favors of your Lord would you deny?',
                reference: 'Ar-Rahman 55:13',
              ),
            ],
            duaArabic: 'دعاء',
            duaTransliteration: 'dua',
            duaTranslation: 'supplication',
            duaSource: 'source',
            preview: true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Ar-Ra\'d 13:28'), findsOneWidget);
    expect(find.text('Ar-Rahman 55:13'), findsNothing);
    expect(find.text('"supplication"'), findsOneWidget);
  });
}
