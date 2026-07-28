import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/content/aspirations.dart';
import 'package:sakina/features/onboarding/content/carrying_durations.dart';
import 'package:sakina/features/onboarding/content/problem_chips.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/queue_plan_screen.dart';
import 'package:sakina/features/onboarding/widgets/journey_stamp_track.dart';
import 'package:sakina/features/onboarding/widgets/queue_name_row.dart';
import 'package:sakina/services/name_stories_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '_test_utils.dart';

/// One Ship W2-D2 — the plan screen renders the REAL queue: a real chip's
/// approved pair at 1-2, the aspiration's founder-reviewed ordering at 3-7.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // The lantern medallion (Wave G) wraps itself in a VisibilityDetector,
    // whose batching timer outlives the tree and trips the pending-timer
    // invariant. Zero makes its callbacks synchronous — the same convention
    // the card-reveal and cosmetics tests already use.
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  ProblemChipResolver resolver() => ProblemChipResolver(
        stories: NameStoriesService(
          loadAsset: (_) async =>
              File(NameStoriesService.assetPath).readAsStringSync(),
        ),
      );

  /// The pair a real chip resolves to, straight from the approved decks.
  Future<List<int>> realPair(String chipKey) =>
      resolver().pairNameIdsForChip(chipKey);

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    required List<int> pairNameIds,
    List<int>? revealedPairNameIds,
    String? aspiration,
    String? carryingDuration,
    VoidCallback? onNext,
    double textScale = 1.0,
  }) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(onboardingProvider.notifier);
    notifier.setOnboardingFlow(onboardingFlowReel);
    notifier.applyHookSelection(
      ChipSelection(
        contract: HookContract.problem,
        problemCategory: 'rizq',
        hookType: HookType.chip,
        chipKey: 'rizq',
        pairNameIds: pairNameIds,
      ),
    );
    if (aspiration != null) notifier.setAspiration(aspiration);
    if (carryingDuration != null) {
      notifier.setCarryingDuration(carryingDuration);
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(textScale),
              // The screen hosts the lantern medallion (Wave G), whose breath
              // pulse repeats forever — `pumpAndSettle` would never return.
              // Suppressing it here is also exactly what a reduce-motion user
              // gets, so the layout under test is a shipped configuration.
              disableAnimations: true,
            ),
            child: QueuePlanScreen(
              onNext: onNext ?? () {},
              revealedPairNameIds: revealedPairNameIds,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  String translit(int id) =>
      QueuePlanScreen.collectibleNameById(id)!.transliteration;

  testWidgets('met, sealed and veiled rows render from a real pair',
      (tester) async {
    final pair = await realPair('rizq');
    expect(pair, hasLength(2), reason: 'the ship gate guarantees a pair');
    await pump(tester, pairNameIds: pair, aspiration: 'peace');

    expect(find.byType(QueueNameRow), findsNWidgets(7));

    // Position 1: met, with the tier the reveal actually awarded.
    expect(find.text(translit(pair[0])), findsOneWidget);
    expect(find.text(QueueNameRow.metLabel), findsOneWidget);
    // The tier belongs to the CARD, never to the Name beside it.
    expect(find.text('Silver card'), findsOneWidget);
    expect(find.text('Silver'), findsNothing);

    // Position 2: named but sealed — tomorrow, and nothing more precise.
    expect(find.text(translit(pair[1])), findsOneWidget);
    expect(find.text(QueueNameRow.nextLabel), findsOneWidget);

    // Positions 3-7: veiled. The Names are real and already chosen, but this
    // screen must not spend the unseals.
    expect(find.text(QueueNameRow.veiledLabel), findsNWidgets(5));
    for (final id in aspirationQueueNameIds('peace')) {
      expect(find.text(translit(id)), findsNothing, reason: 'name $id');
    }
  });

  testWidgets('the stamp track is pre-stamped 2 of 8', (tester) async {
    await pump(
      tester,
      pairNameIds: await realPair('rizq'),
      aspiration: 'peace',
    );

    final track = tester.widget<JourneyStampTrack>(
      find.byType(JourneyStampTrack),
    );
    expect(track.totalStamps, 8);
    expect(track.earnedStamps, 2);
    expect(find.text('2 of 8'), findsOneWidget);
  });

  testWidgets('the rendered queue is the queue the seed will write',
      (tester) async {
    final pair = await realPair('rizq');
    final container =
        await pump(tester, pairNameIds: pair, aspiration: 'guidance');

    expect(
      QueuePlanScreen.plannedQueueNameIds(
        pairNameIds: pair,
        aspiration: 'guidance',
      ),
      await container.read(onboardingProvider.notifier).buildQueueNameIds(),
    );
  });

  testWidgets('the reveal\'s own pair wins when the hook resolved none',
      (tester) async {
    // The reveal falls back to the comfort pair, and so does the seed — the
    // plan screen must show the Names the queue will actually hold, not two
    // veiled rows.
    final comfort = await realPair(comfortChipKey);
    await pump(
      tester,
      pairNameIds: const [],
      revealedPairNameIds: comfort,
      aspiration: 'peace',
    );

    expect(find.text(translit(comfort[0])), findsOneWidget);
    expect(find.text(QueueNameRow.metLabel), findsOneWidget);
    expect(find.text(translit(comfort[1])), findsOneWidget);
    final track = tester.widget<JourneyStampTrack>(
      find.byType(JourneyStampTrack),
    );
    expect(track.totalStamps, 8);
    expect(track.earnedStamps, 2);
  });

  testWidgets('the carrying-duration answer sets the pacing line',
      (tester) async {
    await pump(
      tester,
      pairNameIds: await realPair('rizq'),
      aspiration: 'peace',
      carryingDuration: 'years',
    );

    expect(find.text(carryingPacingLine('years')), findsOneWidget);
    expect(find.text(carryingPacingLine('days')), findsNothing);
  });

  testWidgets('an unanswered aspiration shows the pair alone, not junk rows',
      (tester) async {
    await pump(tester, pairNameIds: await realPair('rizq'));

    expect(find.byType(QueueNameRow), findsNWidgets(2));
    final track = tester.widget<JourneyStampTrack>(
      find.byType(JourneyStampTrack),
    );
    expect(track.totalStamps, 3);
    expect(track.earnedStamps, 2);
  });

  testWidgets('an unresolved pair degrades to veiled rows, one stamp',
      (tester) async {
    await pump(tester, pairNameIds: const [], aspiration: 'peace');

    expect(find.byType(QueueNameRow), findsNWidgets(5));
    expect(find.text(QueueNameRow.veiledLabel), findsNWidgets(5));
    expect(find.text(QueueNameRow.metLabel), findsNothing);
    final track = tester.widget<JourneyStampTrack>(
      find.byType(JourneyStampTrack),
    );
    expect(track.earnedStamps, 1);
  });

  testWidgets('the screen survives the accessibility text scales',
      (tester) async {
    // The header and the stamp track scroll WITH the rows; pinned above a
    // scrolling list they took fixed vertical space that grows with the scale,
    // and at 2x-3x that left the rows nothing to render into. The tier pill is
    // the horizontal half of the same bug.
    for (final scale in const [2.0, 3.0]) {
      await pump(
        tester,
        pairNameIds: await realPair('rizq'),
        aspiration: 'peace',
        textScale: scale,
      );

      expect(tester.takeException(), isNull, reason: 'textScaler $scale');
      // Still reachable, which is why it is the one thing left pinned.
      expect(find.text('Continue'), findsOneWidget, reason: 'textScaler $scale');
      // Unmount and flush before the next iteration. `renderableLanternSkinProvider`
      // is autoDispose, so tearing down its Consumer schedules a Riverpod
      // dispose task on a zero-duration timer; the binding asserts none is
      // still pending when the test ends.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }
  });

  testWidgets('a veiled row announces its position, not just "sealed"',
      (tester) async {
    final pair = await realPair('rizq');
    await pump(tester, pairNameIds: pair, aspiration: 'peace');

    final handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Name 3 of 7, sealed'), findsOneWidget);
    expect(find.bySemanticsLabel('Name 7 of 7, sealed'), findsOneWidget);
    // …and the met row reads the tier it shows.
    expect(
      find.bySemanticsLabel('${translit(pair[0])}, '
          '${QueueNameRow.metLabel}, Silver card'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('continue advances', (tester) async {
    var advanced = 0;
    await pump(
      tester,
      pairNameIds: await realPair('rizq'),
      aspiration: 'peace',
      onNext: () => advanced++,
    );

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(advanced, 1);
  });
}
