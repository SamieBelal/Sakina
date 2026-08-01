import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/features/onboarding/content/problem_chips.dart';
import 'package:sakina/features/onboarding/screens/onboarding_screen.dart';
import 'package:sakina/features/onboarding/widgets/problem_chip_card.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/app_config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/_test_utils.dart';

/// W6 Wave A / D3 / D4 — `contract` and `acquisition_problem_category` are
/// stamped as super properties the moment the hook screen's tap (or typed
/// sentence) resolves — `contract` is the primary reel-of-origin dimension,
/// near-total coverage, and `acquisition_problem_category` is deliberately
/// NOT named `problem_category`: that name is already a live EVENT property
/// meaning "today's answer" (`check_in_completed`, `daily_question_answered`),
/// and a super property of the same name would put two meanings behind one
/// key (D4's collision).
///
/// **MUTATION THAT MUST FAIL THIS TEST:** delete the `setSuperProperties`
/// call from `_onHookCommitted` in `onboarding_screen.dart`. Verified by
/// hand — with the call removed, `analytics.calls` stayed empty and the
/// `isNotEmpty` assertion below failed.
class _SuperPropSpy extends AnalyticsService {
  final List<Map<String, dynamic>> calls = [];

  @override
  void setSuperProperties(Map<String, dynamic> props) =>
      calls.add(Map<String, dynamic>.from(props));

  @override
  void track(String event, {Map<String, dynamic>? properties}) {}

  @override
  void timeEvent(String event) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mirrors hook_deep_link_prefill_test.dart's own `pumpOnboarding` shape
  // exactly (`UncontrolledProviderScope` + an explicit `ProviderContainer`,
  // not a nested `ProviderScope`) — this is load-bearing, not stylistic.
  // Reaching `OnboardingRevealScreen` via a chip tap + `runAsync` (needed
  // because the resolve behind the commit beat is real asset I/O) races an
  // unrelated pre-existing gap in this offline suite: GoogleFonts has no
  // bundled/cached Outfit font and no real network, so the FIRST test in a
  // fresh isolate to reach it throws an uncaught async exception. Verified by
  // hand, repeatedly isolating both shapes: three `pumpOnboarding`-shaped
  // warm-up pumps ahead of the real assertions, using this exact container
  // pattern, is what makes it reliably clean (3/3 runs); a nested
  // `ProviderScope` in the same slot reliably fails (3/3 runs) even with the
  // same warm-ups. Not this test's concern to fix — just to not trip.
  Future<ProviderContainer> pumpOnboarding(
    WidgetTester tester, {
    AnalyticsService? analytics,
  }) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer(
      overrides: [
        appConfigServiceProvider.overrideWithValue(FlowStubAppConfig.reel()),
        appSessionProvider.overrideWithValue(buildTestAppSession()),
        if (analytics != null) analyticsProvider.overrideWithValue(analytics),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 700));
    return container;
  }

  testWidgets('(warm-up, not a real test)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpOnboarding(tester);
  });

  testWidgets('(warm-up 2, not a real test)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpOnboarding(tester);
  });

  testWidgets('(warm-up 3, not a real test)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpOnboarding(tester);
  });

  Future<_SuperPropSpy> pumpAndTapChip(
    WidgetTester tester, {
    required Finder cardFinder,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final analytics = _SuperPropSpy();
    await pumpOnboarding(tester, analytics: analytics);

    await tester.tap(cardFinder);
    // The commit beat runs on the fake clock; the deck resolve behind it is
    // real asset I/O, which only progresses inside `runAsync`.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();

    return analytics;
  }

  testWidgets('a problem chip stamps contract=problem and its category',
      (tester) async {
    final anxietyChip = problemChips.firstWhere((c) => c.chipKey == 'anxiety');
    final analytics = await pumpAndTapChip(
      tester,
      cardFinder: find
          .byWidgetPredicate(
            (w) => w is ProblemChipCard && w.chip.chipKey == 'anxiety',
          )
          .first,
    );

    expect(analytics.calls, isNotEmpty,
        reason: 'hook selection never registered a super property');
    final registered = analytics.calls.firstWhere(
      (c) => c.containsKey(AnalyticsEvents.propContract),
      orElse: () => const {},
    );
    expect(registered, isNotEmpty);
    expect(registered[AnalyticsEvents.propContract], HookContract.problem);
    expect(
      registered[AnalyticsEvents.propAcquisitionProblemCategory],
      anxietyChip.problemCategory,
    );
  });

  testWidgets('the sign chip stamps contract=sign', (tester) async {
    final signChip = problemChips.firstWhere((c) => c.chipKey == 'sign');
    final analytics = await pumpAndTapChip(
      tester,
      cardFinder: find
          .byWidgetPredicate(
            (w) => w is ProblemChipCard && w.chip.chipKey == 'sign',
          )
          .first,
    );

    final registered = analytics.calls.firstWhere(
      (c) => c.containsKey(AnalyticsEvents.propContract),
      orElse: () => const {},
    );
    expect(registered, isNotEmpty);
    expect(registered[AnalyticsEvents.propContract], HookContract.sign);
    expect(
      registered[AnalyticsEvents.propAcquisitionProblemCategory],
      signChip.problemCategory,
    );
  });
}
