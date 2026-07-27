import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/cosmetic_catalog_ui.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/wardrobe_tile.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() {
  // CompanionMedallion wraps a VisibilityDetector whose default 500ms debounce
  // would outlive the test tree — fire callbacks synchronously instead.
  setUp(
      () => VisibilityDetectorController.instance.updateInterval = Duration.zero);

  Widget host(Widget child) => MaterialApp(
      home:
          Scaffold(body: SizedBox(width: 180, height: 220, child: child)));

  testWidgets('equipped tile shows the equipped badge', (tester) async {
    await tester.pumpWidget(host(const WardrobeTile(
      itemType: 'lantern_skin',
      itemId: 'classic_gold',
      name: 'Classic Brass',
      status: WardrobeTileStatus.equipped,
      onTap: _noop,
    )));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Equipped'), findsOneWidget);
  });

  testWidgets('locked premium tile shows the premium badge', (tester) async {
    await tester.pumpWidget(host(const WardrobeTile(
      itemType: 'lantern_skin',
      itemId: 'ramadan_royal',
      name: 'Ramadan Royal',
      status: WardrobeTileStatus.premiumLocked,
      onTap: _noop,
    )));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Premium'), findsOneWidget);
  });

  // The badge only invites a purchase once the SKUs are live; until then it
  // must not say "Buy" for something nothing can buy (see
  // wardrobe_iap_disabled_test.dart).
  testWidgets('à-la-carte tile badges Buy only while the skin IAP is live',
      (tester) async {
    await tester.pumpWidget(host(const WardrobeTile(
      itemType: 'lantern_skin',
      itemId: 'masjid_brass',
      name: 'Masjid Brass',
      status: WardrobeTileStatus.alaCarteLocked,
      onTap: _noop,
    )));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(kSkinIapEnabled ? 'Buy' : 'Soon'), findsOneWidget);
  });

  // Monetization ruling: a premium-exclusive item is equippable WHILE premium is
  // active — it is never converted to ownership, so the tile must never read as
  // "Owned"/"Equipped" just because it can be equipped right now.
  testWidgets('equippable tile carries no ownership badge', (tester) async {
    await tester.pumpWidget(host(const WardrobeTile(
      itemType: 'lantern_skin',
      itemId: 'ramadan_royal',
      name: 'Ramadan Royal',
      status: WardrobeTileStatus.equippable,
      onTap: _noop,
    )));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Owned'), findsNothing);
    expect(find.text('Equipped'), findsNothing);
    expect(find.text('Ramadan Royal'), findsOneWidget);
  });

  testWidgets('tap fires onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(host(WardrobeTile(
      itemType: 'lantern_skin',
      itemId: 'emerald_jade',
      name: 'Emerald Jade',
      status: WardrobeTileStatus.locked,
      onTap: () => tapped = true,
    )));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byType(WardrobeTile));
    expect(tapped, isTrue);
  });
}

void _noop() {}
