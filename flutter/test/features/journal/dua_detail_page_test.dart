import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/journal/screens/dua_detail_page.dart';
import 'package:sakina/features/reflect/models/reflect_verse.dart';
import 'package:sakina/widgets/share_card.dart';

void main() {
  testWidgets(
      'delete icon shows confirmation dialog and only fires onRemove on Delete',
      (tester) async {
    // Regression for finding 2026-04-26-journal-delete-no-confirm.
    var removeCallCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: DuaDetailPage(
          title: 'For peace of heart',
          arabic: 'دعاء',
          transliteration: 'dua',
          translation: 'supplication',
          source: 'Quran 2:286',
          onRemove: () => removeCallCount++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Delete this dua?'), findsOneWidget);
    expect(find.text("This can't be undone."), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(removeCallCount, 0, reason: 'onRemove must NOT fire before confirm');

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(removeCallCount, 0, reason: 'Cancel must abort the delete');
    expect(find.text('Delete this dua?'), findsNothing,
        reason: 'Dialog should dismiss on cancel');

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(removeCallCount, 1,
        reason: 'Delete must confirm and fire onRemove once');
  });

  testWidgets(
      'share button surfaces parity SnackBar when shareReflectionCard throws',
      (tester) async {
    // Regression: dua_detail_page reuses shareReflectionCard for Personal Dua
    // share. Catch block must invoke showShareErrorSnackBar — was a silent
    // debugPrint before share-parity fix.
    final original = shareReflectionCard;
    shareReflectionCard = ({
      required BuildContext context,
      required String nameArabic,
      required String nameEnglish,
      required String duaArabic,
      required String duaTransliteration,
      required String duaTranslation,
      required String duaSource,
      List<ReflectVerse> verses = const [],
      String? story,
      String? reframe,
      Rect? sharePositionOrigin,
    }) async {
      throw StateError('forced share failure');
    };
    addTearDown(() => shareReflectionCard = original);

    await tester.pumpWidget(
      const MaterialApp(
        home: DuaDetailPage(
          title: 'For peace of heart',
          arabic: 'دعاء',
          transliteration: 'dua',
          translation: 'supplication',
          source: 'Quran 2:286',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.share_outlined));
    await tester.pump();

    expect(
      find.text("Couldn't share. Please try again."),
      findsOneWidget,
      reason: 'share error must surface a parity SnackBar',
    );
  });
}
