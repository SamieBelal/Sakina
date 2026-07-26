// E1 — the composed lantern stage as a shareable card.
//
// DB-free: the card is a pure StatelessWidget over Lane C's stage/medallion and
// the pure catalog resolver. The export path itself (RepaintBoundary → toImage →
// Share.shareXFiles) mirrors lib/widgets/share_card.dart and is not exercised
// here — a real platform share channel is out of reach in a widget test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/widgets/backdrop_stage.dart';
import 'package:sakina/features/streaks/widgets/companion_medallion.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/lantern_share_card.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() {
  setUp(() =>
      VisibilityDetectorController.instance.updateInterval = Duration.zero);

  testWidgets('renders the name + streak over the equipped skin and backdrop',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: LanternShareCard(
          skinId: 'emerald_jade',
          backdropId: 'laylat_night',
          lanternName: 'Noor',
          streak: 12,
          preview: true,
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Noor'), findsOneWidget);
    expect(find.textContaining('12'), findsOneWidget);
    expect(find.byType(CompanionStage), findsOneWidget);

    final medallion =
        tester.widget<CompanionMedallion>(find.byType(CompanionMedallion));
    expect(medallion.skin.id, 'emerald_jade');
    // Frozen for a deterministic export frame.
    expect(medallion.animate, isFalse);
  });

  testWidgets('an unknown skin id degrades to the default lantern',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: LanternShareCard(
          skinId: 'not_a_skin',
          backdropId: 'not_a_backdrop',
          lanternName: 'Noor',
          streak: 0,
          preview: true,
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));

    final medallion =
        tester.widget<CompanionMedallion>(find.byType(CompanionMedallion));
    expect(medallion.skin.id, 'classic_gold');
  });
}
