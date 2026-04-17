import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/value_prop_screen.dart';

void main() {
  Widget harness(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: ValuePropScreen(onNext: () {}, onBack: () {}),
      ),
    );
  }

  testWidgets('uses top aspiration (morePatient) in headline',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(onboardingProvider.notifier)
        .toggleAspiration('morePatient');

    await tester.pumpWidget(harness(container));

    expect(
      find.text('Sakina helps you become more patient.'),
      findsOneWidget,
    );
  });

  testWidgets('uses different aspiration (closerToAllah) in headline',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(onboardingProvider.notifier)
        .toggleAspiration('closerToAllah');

    await tester.pumpWidget(harness(container));

    expect(
      find.text('Sakina helps you become closer to Allah.'),
      findsOneWidget,
    );
    // Confirm the other variant is NOT present.
    expect(find.textContaining('more patient'), findsNothing);
  });

  testWidgets('falls back to generic phrase when no aspiration selected',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(harness(container));

    expect(
      find.text('Sakina helps you become who you want to be.'),
      findsOneWidget,
    );
  });

  testWidgets('renders the three value rows', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(harness(container));

    expect(find.text('Daily check-in'), findsOneWidget);
    expect(find.text('99 Names'), findsOneWidget);
    expect(find.text('Your journal'), findsOneWidget);
  });

  test('aspirationPhrase maps known ids and falls back gracefully', () {
    expect(ValuePropScreen.aspirationPhrase('morePatient'), 'more patient');
    expect(ValuePropScreen.aspirationPhrase('moreGrateful'), 'more grateful');
    expect(
      ValuePropScreen.aspirationPhrase('closerToAllah'),
      'closer to Allah',
    );
    expect(ValuePropScreen.aspirationPhrase('morePresent'), 'more present');
    expect(
      ValuePropScreen.aspirationPhrase('strongerFaith'),
      'stronger in faith',
    );
    expect(
      ValuePropScreen.aspirationPhrase('moreConsistent'),
      'more consistent',
    );
    expect(ValuePropScreen.aspirationPhrase(null), 'who you want to be');
    expect(ValuePropScreen.aspirationPhrase('unknown'), 'who you want to be');
  });
}
