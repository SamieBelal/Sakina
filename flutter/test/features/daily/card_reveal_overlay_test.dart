import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/widgets/card_reveal_overlay.dart';
import 'package:sakina/features/daily/reveal/reveal_spec.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() {
  // The ornate card tile embeds the CompanionMedallion, which uses a
  // VisibilityDetector — its default 500ms debounce timer would linger past the
  // test. Fire updates synchronously so no timer outlives the widget tree.
  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  // Pumps a normal-motion overlay via the production TAP entry (no autoStart).
  Future<List<(String, Map<String, Object?>)>> pumpOverlay(
    WidgetTester tester, {
    required VoidCallback onContinue,
    bool disableAnimations = false,
    CardTier tier = CardTier.emerald,
  }) async {
    final events = <(String, Map<String, Object?>)>[];
    await tester.pumpWidget(MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: MaterialApp(
        home: CardRevealOverlay(
          card: allCollectibleNames.first,
          spec: revealSpecFor(tier),
          onContinue: onContinue,
          onEvent: (name, props) => events.add((name, props)),
        ),
      ),
    ));
    await tester.pump();
    return events;
  }

  testWidgets('reduced motion (autoStart) resolves to the card + Continue quickly',
      (tester) async {
    var continued = false;
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: MaterialApp(
        home: CardRevealOverlay(
          card: allCollectibleNames.first,
          spec: revealSpecFor(CardTier.emerald),
          autoStart: true,
          onContinue: () => continued = true,
        ),
      ),
    ));
    // Under reduced motion the sequence collapses to <= 600ms.
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Tap to continue'), findsOneWidget);
    await tester.tap(find.byType(CardRevealOverlay));
    await tester.pump();
    expect(continued, isTrue);
  });

  testWidgets('tap-to-skip then continue fires onContinue exactly once',
      (tester) async {
    var continueCount = 0;
    // Silver has the shortest spin duration (3600ms), so its haptic ratchet
    // Future.delayed timers drain fastest at the end of the test.
    await pumpOverlay(
        tester, onContinue: () => continueCount++, tier: CardTier.silver);

    // tap1: opens the reveal (does not continue).
    await tester.tap(find.byType(CardRevealOverlay));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Tap to continue'), findsNothing,
        reason: 'mid-reveal, Continue must not be shown yet');
    expect(continueCount, 0);

    // tap2: mid-reveal skip → snaps to the settle (Continue now shows).
    await tester.tap(find.byType(CardRevealOverlay));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('Tap to continue'), findsOneWidget,
        reason: 'skip should jump straight to the settled/interactive frame');
    expect(continueCount, 0, reason: 'skip must NOT continue');

    // tap3: interactive → continues exactly once.
    await tester.tap(find.byType(CardRevealOverlay));
    await tester.pump();
    expect(continueCount, 1);

    // A stray extra tap must not double-fire (_dismissed guard).
    await tester.tap(find.byType(CardRevealOverlay));
    await tester.pump();
    expect(continueCount, 1, reason: '_dismissed must guard against double-fire');

    // Drain the scheduled haptic Future.delayed timers (guarded by mounted) so
    // none outlive the widget tree. Silver's ratchet spans its 3600ms duration.
    await tester.pump(const Duration(milliseconds: 3600));
  });

  testWidgets('analytics fire once: shown on open, completed on continue',
      (tester) async {
    final events = await pumpOverlay(
      tester,
      onContinue: () {},
      tier: CardTier.gold,
    );

    // Nothing fires before the first tap.
    expect(events, isEmpty);

    // tap1: opens → card_reveal_shown fires once.
    await tester.tap(find.byType(CardRevealOverlay));
    await tester.pump(const Duration(milliseconds: 200));
    final shown =
        events.where((e) => e.$1 == AnalyticsEvents.cardRevealShown).toList();
    expect(shown, hasLength(1));
    expect(shown.single.$2['tier'], 'Gold');
    expect(shown.single.$2['auto'], false);
    expect(
        events.where((e) => e.$1 == AnalyticsEvents.cardRevealCompleted), isEmpty);

    // tap2: skip to settle; tap3: continue → card_reveal_completed fires once.
    await tester.tap(find.byType(CardRevealOverlay));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.tap(find.byType(CardRevealOverlay));
    await tester.pump();

    final completed = events
        .where((e) => e.$1 == AnalyticsEvents.cardRevealCompleted)
        .toList();
    expect(completed, hasLength(1));
    expect(completed.single.$2['tier'], 'Gold');
    expect(completed.single.$2['auto'], false);

    // A stray tap must not emit a second completed event.
    await tester.tap(find.byType(CardRevealOverlay));
    await tester.pump();
    expect(
        events.where((e) => e.$1 == AnalyticsEvents.cardRevealCompleted),
        hasLength(1));

    // Exactly one shown across the whole flow, too.
    expect(events.where((e) => e.$1 == AnalyticsEvents.cardRevealShown),
        hasLength(1));

    // Drain the scheduled haptic Future.delayed timers (Gold spans 5000ms) so
    // none outlive the widget tree.
    await tester.pump(const Duration(milliseconds: 5000));
  });

  testWidgets('reduced motion via TAP entry snaps straight to Continue',
      (tester) async {
    var continued = false;
    await pumpOverlay(
      tester,
      onContinue: () => continued = true,
      disableAnimations: true,
    );

    // tap1: opens under reduced motion → snaps _reveal.value to 1.0 immediately.
    await tester.tap(find.byType(CardRevealOverlay));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Tap to continue'), findsOneWidget,
        reason: 'reduced motion should skip the spectacle and settle at once');

    // tap2: interactive → continues.
    await tester.tap(find.byType(CardRevealOverlay));
    await tester.pump();
    expect(continued, isTrue);
  });
}
