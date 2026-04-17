import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/screens/prayer_frequency_screen.dart';

void main() {
  testWidgets('picking a frequency enables continue', (tester) async {
    var advanced = 0;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: PrayerFrequencyScreen(
          onNext: () => advanced++, onBack: () {}),
      ),
    ));
    await tester.tap(find.text('Some days'));
    await tester.pump();
    await tester.ensureVisible(find.text('Continue'));
    await tester.pump();
    await tester.tap(find.text('Continue'), warnIfMissed: false);
    await tester.pump();
    expect(advanced, 1);
  });
}
