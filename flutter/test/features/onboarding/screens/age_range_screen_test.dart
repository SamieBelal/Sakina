import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/screens/age_range_screen.dart';

void main() {
  testWidgets('continue enabled after picking an age range', (tester) async {
    var advanced = 0;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: AgeRangeScreen(onNext: () => advanced++, onBack: () {}),
      ),
    ));
    await tester.ensureVisible(find.text('25-34'));
    await tester.tap(find.text('25-34'), warnIfMissed: false);
    await tester.pump();
    await tester.tap(find.text('Continue'), warnIfMissed: false);
    await tester.pump();
    expect(advanced, 1);
  });
}
