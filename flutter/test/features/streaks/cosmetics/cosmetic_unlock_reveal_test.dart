// E2 — the cosmetic unlock reveal (OQ-D1 option A).
//
// CardRevealOverlay is hard-coupled to CollectibleName + CardTier (it renders a
// Name-of-Allah card face) and cannot render a LanternSkin, so this is a thin
// sibling that reuses Lane C's CompanionMedallion for the same ignite→settle
// feel. That widget is deliberately NOT touched by this lane.
//
// DB-free: the reveal is pure UI over the pure catalog resolver.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/widgets/companion_medallion.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/cosmetic_unlock_reveal.dart';
import 'package:sakina/services/cosmetics_service.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() {
  setUp(() =>
      VisibilityDetectorController.instance.updateInterval = Duration.zero);

  Widget harness(String itemType, String itemId) => MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => Center(
              child: ElevatedButton(
                onPressed: () => showCosmeticUnlockReveal(ctx, itemType, itemId),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );

  testWidgets('a skin unlock forges the just-earned lantern', (tester) async {
    await tester.pumpWidget(harness(itemTypeLanternSkin, 'emerald_jade'));
    await tester.tap(find.text('go'));
    await tester.pump(); // push the route
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(CompanionMedallion), findsOneWidget);
    expect(find.text('Unlocked'), findsOneWidget);
    expect(find.text('Emerald Jade'), findsOneWidget);

    final medallion =
        tester.widget<CompanionMedallion>(find.byType(CompanionMedallion));
    expect(medallion.skin.id, 'emerald_jade');
  });

  testWidgets('a backdrop unlock reveals the backdrop behind a classic lantern',
      (tester) async {
    await tester.pumpWidget(harness(itemTypeBackdrop, 'laylat_night'));
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final medallion =
        tester.widget<CompanionMedallion>(find.byType(CompanionMedallion));
    expect(medallion.skin.id, defaultLanternSkin);
    expect(find.text('Laylat Night'), findsOneWidget);
  });

  testWidgets('tapping dismisses the reveal', (tester) async {
    await tester.pumpWidget(harness(itemTypeLanternSkin, 'emerald_jade'));
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Unlocked'), findsOneWidget);

    await tester.tap(find.text('Unlocked'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Unlocked'), findsNothing);
  });
}
