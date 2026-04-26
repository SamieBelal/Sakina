import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/journal/screens/dua_detail_page.dart';

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
}
