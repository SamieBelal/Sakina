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

  testWidgets('continue button is not lifted by keyboard insets',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: DuaTopicsScreen(onNext: () {}, onBack: () {}),
      ),
    ));
    await tester.pump();

    final continueButton = find.widgetWithText(ElevatedButton, 'Continue');
    expect(continueButton, findsOneWidget);
    final closedKeyboardPosition = tester.getTopLeft(continueButton);

    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    await tester.pump();

    expect(tester.getTopLeft(continueButton), closedKeyboardPosition);
  });

  testWidgets('free-text input scrolls above keyboard insets', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: DuaTopicsScreen(onNext: () {}, onBack: () {}),
      ),
    ));
    await tester.pump();

    await tester.tap(find.byType(TextField));
    await tester.pump();

    tester.view.viewInsets = const FakeViewPadding(bottom: 336);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    final keyboardTop = tester.view.physicalSize.height -
        tester.view.viewInsets.bottom / tester.view.devicePixelRatio;
    final inputBottom = tester.getRect(find.byType(TextField)).bottom;

    expect(inputBottom, lessThanOrEqualTo(keyboardTop));
    expect(keyboardTop - inputBottom, lessThanOrEqualTo(56));
  });
}
