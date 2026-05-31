import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/paywall_screen.dart';

void main() {
  // Repeating breathing-CTA + SAVE-badge shimmer animations introduced
  // by the 2026-05-14 paywall rebuild would make pumpAndSettle hang
  // forever. The seam flips them off for the duration of this file.
  setUp(() {
    debugDisablePaywallAnimations = true;
  });

  tearDown(() {
    debugDisablePaywallAnimations = false;
  });

  Widget harness(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: PaywallScreen(onComplete: () {}),
      ),
    );
  }

  // Trimmed-flow refactor (2026-05-25, Option α): the aspirations field was
  // removed from OnboardingState. The paywall headline now always uses the
  // "your best self" fallback. The dynamic-aspiration variants of this test
  // are obsolete — only the fallback path remains.

  testWidgets('paywall headline uses commitment minutes', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(onboardingProvider.notifier).setDailyCommitmentMinutes(5);

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    expect(find.textContaining('your best self'), findsOneWidget);
    expect(find.textContaining('5 min'), findsOneWidget);
  });

  testWidgets('fallback headline when no aspiration selected', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('your best self'),
      findsOneWidget,
    );
    // Default commitment fallback.
    expect(find.textContaining('3 min'), findsOneWidget);
  });

  testWidgets('does not render MOST POPULAR badge (only SAVE 50%)',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    expect(find.text('MOST POPULAR'), findsNothing);
  });
}
