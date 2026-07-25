import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/widgets/share_card.dart';

void main() {
  testWidgets('TakeawayShareCard renders name, key line and takeaway', (t) async {
    // Production always renders the card inside _SharePreviewScreen's scroll
    // view; the framed card is taller than the viewport, so mirror that here.
    await t.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TakeawayShareCard(
            nameArabic: 'اللطيف',
            nameEnglish: 'Al-Lateef',
            meaning: 'The Subtle One',
            reframeKey: 'Allah was gentle with you tonight',
            takeaway: 'What feels like drowning may be the sea parting.',
            preview: true,
          ),
        ),
      ),
    ));

    // Brand is now the calligraphic mark image, not the word "SAKINA".
    expect(find.text('SAKINA'), findsNothing);
    expect(find.byType(ShareBrandLockup), findsOneWidget);
    expect(find.text('Al-Lateef'), findsOneWidget);
    expect(find.text('اللطيف'), findsOneWidget);
    expect(find.text('The Subtle One'), findsOneWidget);
    expect(find.text('Allah was gentle with you tonight'), findsOneWidget);
    expect(
      find.text('What feels like drowning may be the sea parting.'),
      findsOneWidget,
    );
  });

  testWidgets('omits the key-line block when empty (no crash)', (t) async {
    await t.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TakeawayShareCard(
            nameArabic: 'اللطيف',
            nameEnglish: 'Al-Lateef',
            reframeKey: '',
            takeaway: 'You are not alone in the dark.',
            preview: true,
          ),
        ),
      ),
    ));
    expect(find.text('You are not alone in the dark.'), findsOneWidget);
  });
}
