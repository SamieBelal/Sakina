import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/widgets/share_card.dart';

void main() {
  testWidgets('TakeawayShareCard renders name, key line and takeaway', (t) async {
    await t.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: TakeawayShareCard(
          nameArabic: 'اللطيف',
          nameEnglish: 'Al-Lateef',
          reframeKey: 'Allah was gentle with you tonight',
          takeaway: 'What feels like drowning may be the sea parting.',
          preview: true,
        ),
      ),
    ));

    expect(find.text('SAKINA'), findsOneWidget);
    expect(find.text('Al-Lateef'), findsOneWidget);
    expect(find.text('اللطيف'), findsOneWidget);
    expect(find.text('Allah was gentle with you tonight'), findsOneWidget);
    expect(
      find.text('What feels like drowning may be the sea parting.'),
      findsOneWidget,
    );
  });

  testWidgets('omits the key-line block when empty (no crash)', (t) async {
    await t.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: TakeawayShareCard(
          nameArabic: 'اللطيف',
          nameEnglish: 'Al-Lateef',
          reframeKey: '',
          takeaway: 'You are not alone in the dark.',
          preview: true,
        ),
      ),
    ));
    expect(find.text('You are not alone in the dark.'), findsOneWidget);
  });
}
