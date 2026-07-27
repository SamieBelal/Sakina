import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/source_question_screen.dart';
import 'package:sakina/features/onboarding/widgets/reel_option_card.dart';
import 'package:sakina/features/onboarding/widgets/reel_skip_link.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '_test_utils.dart';

/// One Ship W2-D3 — "Where did you find us?" (measurement only, skippable).
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    VoidCallback? onNext,
  }) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: SourceQuestionScreen(
            onNext: onNext ?? () {},
            commitBeat: Duration.zero,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('renders the question and all four sources', (tester) async {
    await pump(tester);

    expect(find.text(SourceQuestionScreen.headlineLabel), findsOneWidget);
    expect(find.byType(ReelOptionCard), findsNWidgets(4));
    expect(find.text('TikTok'), findsOneWidget);
    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('A friend told me'), findsOneWidget);
    expect(find.text('Somewhere else'), findsOneWidget);
  });

  testWidgets('a single tap stores the source key and advances once',
      (tester) async {
    var advanced = 0;
    final container = await pump(tester, onNext: () => advanced++);

    await tester.tap(find.text('Instagram'));
    await tester.pumpAndSettle();

    expect(container.read(onboardingProvider).reelSource, 'instagram');
    expect(advanced, 1);
  });

  testWidgets('"Rather not say" advances without storing anything',
      (tester) async {
    var advanced = 0;
    final container = await pump(tester, onNext: () => advanced++);

    expect(find.byType(ReelSkipLink), findsOneWidget);
    await tester.ensureVisible(find.text(SourceQuestionScreen.skipLabel));
    await tester.tap(find.text(SourceQuestionScreen.skipLabel));
    await tester.pumpAndSettle();

    expect(advanced, 1);
    expect(container.read(onboardingProvider).reelSource, isNull);
  });

  testWidgets('the skip link is a 44pt target', (tester) async {
    await pump(tester);

    final size = tester.getSize(find.byType(ReelSkipLink));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  test('source keys are stable snake_case and unique', () {
    final keys = SourceQuestionScreen.options.map((o) => o.key).toList();
    expect(keys, ['tiktok', 'instagram', 'friend', 'other']);
    expect(keys.toSet(), hasLength(keys.length));
  });
}
