import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/widgets/card_reveal_overlay.dart';
import 'package:sakina/features/daily/models/reveal_spec.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() {
  // The ornate card tile embeds the CompanionMedallion, which uses a
  // VisibilityDetector — its default 500ms debounce timer would linger past the
  // test. Fire updates synchronously so no timer outlives the widget tree.
  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  testWidgets('reduced motion resolves to the card + Continue quickly', (tester) async {
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
}
