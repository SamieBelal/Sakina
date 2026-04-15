import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/journal/screens/reflection_detail_page.dart';
import 'package:sakina/features/reflect/models/reflect_verse.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';

void main() {
  SavedReflection buildReflection({List<ReflectVerse> verses = const []}) {
    return SavedReflection(
      id: 'reflection-1',
      date: '2026-04-15T12:00:00Z',
      userText: 'I need peace',
      name: 'As-Salam',
      nameArabic: 'السلام',
      reframePreview: 'Peace can return.',
      reframe: 'Peace can return.',
      story: 'A story.',
      verses: verses,
      duaArabic: 'دعاء',
      duaTransliteration: 'dua',
      duaTranslation: 'supplication',
      duaSource: 'source',
    );
  }

  testWidgets('renders verse section when verses are present', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReflectionDetailPage(
          reflection: buildReflection(
            verses: const [
              ReflectVerse(
                arabic: 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
                translation:
                    'Verily, in the remembrance of Allah do hearts find rest.',
                reference: 'Ar-Ra\'d 13:28',
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Quran Verse'), findsOneWidget);
    expect(find.text('Ar-Ra\'d 13:28'), findsOneWidget);
  });

  testWidgets('hides verse section for legacy reflections', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReflectionDetailPage(reflection: buildReflection()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Quran Verse'), findsNothing);
    expect(find.text('Ar-Ra\'d 13:28'), findsNothing);
  });
}
