import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/screens/value_prop_screen.dart';

// Trimmed-flow refactor (2026-05-25, Option α): the aspirations field was
// removed from OnboardingState. The legacy screen now always renders the
// generic fallback headline. PR-2b will delete this screen + test.
void main() {
  Widget harness(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: ValuePropScreen(onNext: () {}, onBack: () {}),
      ),
    );
  }

  testWidgets('legacy value prop screen renders generic fallback headline',
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
