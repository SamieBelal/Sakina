// The Store → wardrobe cross-link (spec §6 store integration). Cosmetics do NOT
// clutter the token/scroll tabs — this banner is the only store touchpoint.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/wardrobe_cross_link_banner.dart';

void main() {
  testWidgets('renders the invitation and reports taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WardrobeCrossLinkBanner(onTap: () => taps++),
      ),
    ));

    expect(find.text('Personalize your lantern'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    await tester.tap(find.byType(WardrobeCrossLinkBanner));
    expect(taps, 1);
  });
}
