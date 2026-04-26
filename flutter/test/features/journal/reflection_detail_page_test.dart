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

  testWidgets('delete icon shows confirmation dialog and only fires onRemove on Delete',
      (tester) async {
    // Regression for finding 2026-04-26-journal-delete-no-confirm.
    var removeCallCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ReflectionDetailPage(
          reflection: buildReflection(),
          onRemove: () => removeCallCount++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the delete (trash) icon in the header.
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();

    // Confirmation dialog must appear before any deletion happens.
    expect(find.text('Delete this reflection?'), findsOneWidget);
    expect(find.text("This can't be undone."), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(removeCallCount, 0, reason: 'onRemove must NOT fire before confirm');

    // Tap Cancel → onRemove is still not called.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(removeCallCount, 0, reason: 'Cancel must abort the delete');
    expect(find.text('Delete this reflection?'), findsNothing,
        reason: 'Dialog should dismiss on cancel');

    // Tap delete again → confirm Delete → onRemove fires exactly once.
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(removeCallCount, 1, reason: 'Delete must confirm and fire onRemove once');
  });
}
