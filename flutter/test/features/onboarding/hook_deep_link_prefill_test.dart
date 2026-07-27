import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/features/onboarding/content/problem_chips.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/onboarding_screen.dart';
import 'package:sakina/features/onboarding/widgets/problem_chip_card.dart';
import 'package:sakina/services/app_config_service.dart';
import 'package:sakina/services/reel_deep_link_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/_test_utils.dart';

/// One Ship W2-E4 — the two reel deep links, driven END TO END through
/// `OnboardingScreen` rather than through `HookProblemScreen`'s constructor.
///
/// The constructor is exactly what the shipped app does NOT use: the drain
/// (`consumePendingFeelChip`) reads SharedPreferences, so it always resolves
/// AFTER the hook's first build. A test that hands `initialChipKey` in at
/// construction passes against a screen where the link does nothing at all —
/// which is what shipped until the `didUpdateWidget` adoption below.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> pumpOnboarding(
    WidgetTester tester, {
    OnboardingState? restored,
  }) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer(
      overrides: [
        appConfigServiceProvider.overrideWithValue(FlowStubAppConfig.reel()),
        appSessionProvider.overrideWithValue(buildTestAppSession()),
        if (restored != null)
          cachedOnboardingStateProvider.overrideWithValue(restored),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    // Flow resolution, then the deep-link drain — both async, both a frame or
    // more behind the first build. That gap IS the bug this file pins.
    for (var i = 0; i < 6; i++) {
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 700));
    return container;
  }

  ProblemChipCard selectedCard(WidgetTester tester) => tester
      .widgetList<ProblemChipCard>(find.byType(ProblemChipCard))
      .firstWhere((card) => card.selected);

  testWidgets('a sakina://feel link pre-selects its card once the drain lands',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      pendingFeelChipPrefsKey: 'anxiety',
    });

    await pumpOnboarding(tester);

    expect(
      selectedCard(tester).chip.chipKey,
      'anxiety',
      reason: 'the link arrives after the first build, so the hook has to '
          'adopt it as a widget update — reading it in initState alone left '
          'sakina://feel with no visible effect',
    );
    expect(
      tester
          .widgetList<ProblemChipCard>(find.byType(ProblemChipCard))
          .where((card) => card.selected),
      hasLength(1),
      reason: 'exactly one card is claimed on the user\'s behalf',
    );
  });

  testWidgets('no link means no card is pre-selected', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await pumpOnboarding(tester);

    expect(
      tester
          .widgetList<ProblemChipCard>(find.byType(ProblemChipCard))
          .where((card) => card.selected),
      isEmpty,
    );
  });

  testWidgets('an off-taxonomy emotion selects nothing', (tester) async {
    // `consumePendingFeelChip` drops a key that has left the taxonomy;
    // pre-selecting the comfort chip instead would answer for the user.
    SharedPreferences.setMockInitialValues({
      pendingFeelChipPrefsKey: 'retired-chip-key',
    });

    await pumpOnboarding(tester);

    expect(
      tester
          .widgetList<ProblemChipCard>(find.byType(ProblemChipCard))
          .where((card) => card.selected),
      isEmpty,
    );
  });

  testWidgets('a name_ids override drained on an EARLIER launch still applies',
      (tester) async {
    // The override rides `OnboardingState` (persisted), not a field on the
    // screen: the link is drained once, at launch, and the hook may not be
    // answered until several app kills later. Restoring state with the
    // override — and NO pending link left in prefs — is exactly that user.
    SharedPreferences.setMockInitialValues({});
    final container = await pumpOnboarding(
      tester,
      restored: const OnboardingState(
        reelId: 'r-1234',
        hookType: HookType.reel,
        reelPairOverride: [2, 36],
      ),
    );

    await tester.tap(find.byType(ProblemChipCard).first);
    // The commit beat runs on the fake clock; the deck resolve behind it is
    // real asset I/O, which only progresses inside `runAsync`.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();

    expect(
      container.read(onboardingProvider).pairNameIds,
      [2, 36],
      reason: 'the reel named these two Names on camera; the hook resolved a '
          'different pair and the override is what the reveal must show',
    );
  });

  testWidgets('the drain persists the override for the launch that follows',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      pendingReelArrivalPrefsKey:
          jsonEncode({'reel_id': 'r-1234', 'name_ids': [2, 36]}),
    });

    final container = await pumpOnboarding(tester);

    final state = container.read(onboardingProvider);
    expect(state.reelId, 'r-1234');
    expect(state.reelPairOverride, [2, 36]);
    final stored = (await SharedPreferences.getInstance())
        .getString('onboarding_state');
    expect(
      jsonDecode(stored!)['reelPairOverride'],
      [2, 36],
      reason: 'a kill before the hook is answered must not lose the pair',
    );
  });
}
