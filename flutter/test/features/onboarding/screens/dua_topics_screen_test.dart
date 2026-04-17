import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/dua_topics_screen.dart';

void main() {
  testWidgets('continue enables after picking at least one topic',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    var advanced = 0;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: DuaTopicsScreen(onNext: () => advanced++, onBack: () {}),
      ),
    ));
    await tester.ensureVisible(find.text('Continue'));
    await tester.pump();
    await tester.tap(find.text('Continue'), warnIfMissed: false);
    await tester.pump();
    expect(advanced, 0);

    await tester.tap(find.text('Health'));
    await tester.pump();
    expect(container.read(onboardingProvider).duaTopics.contains('health'),
        isTrue);

    await tester.ensureVisible(find.text('Continue'));
    await tester.pump();
    await tester.tap(find.text('Continue'), warnIfMissed: false);
    await tester.pump();
    expect(advanced, 1);
  });

  testWidgets('free-text alone enables continue', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    var advanced = 0;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: DuaTopicsScreen(onNext: () => advanced++, onBack: () {}),
      ),
    ));
    await tester.enterText(find.byType(TextField), 'my sick mother');
    await tester.pump();
    await tester.ensureVisible(find.text('Continue'));
    await tester.pump();
    await tester.tap(find.text('Continue'), warnIfMissed: false);
    await tester.pump();
    expect(advanced, 1);
    expect(container.read(onboardingProvider).duaTopicsOther, 'my sick mother');
  });
}
