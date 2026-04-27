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

  // Regression: every share button's catch block now routes through
  // showShareErrorSnackBar so all four entry points (reflect_screen,
  // reflection_detail_page, dua_detail_page, duas_screen built-dua result)
  // surface the same parity copy. Previously only reflect_screen showed any
  // toast on share failure; the other three silently swallowed the error.
  testWidgets('showShareErrorSnackBar renders parity copy', (tester) async {
    final scaffoldKey = GlobalKey<ScaffoldMessengerState>();

    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: scaffoldKey,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );

    showShareErrorSnackBar(scaffoldKey.currentState!);
    await tester.pump();

    expect(
      find.text("Couldn't share. Please try again."),
      findsOneWidget,
    );
  });

  testWidgets(
      'showShareErrorSnackBar replaces an existing snackbar (no stacking)',
      (tester) async {
    final scaffoldKey = GlobalKey<ScaffoldMessengerState>();

    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: scaffoldKey,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );

    scaffoldKey.currentState!.showSnackBar(
      const SnackBar(content: Text('previous toast')),
    );
    await tester.pump();
    expect(find.text('previous toast'), findsOneWidget);

    showShareErrorSnackBar(scaffoldKey.currentState!);
    await tester.pump();

    expect(find.text('previous toast'), findsNothing);
    expect(
      find.text("Couldn't share. Please try again."),
      findsOneWidget,
    );
  });
}
