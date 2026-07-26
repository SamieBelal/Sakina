// Golden for every backdrop (incl. the plain 'none'), static layer only.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/models/backdrop.dart';
import 'package:sakina/features/streaks/widgets/backdrop_painter.dart';

Widget _harness(Backdrop b) => MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RepaintBoundary(
        child: CustomPaint(
          size: const Size(360, 680),
          painter: BackdropPainter(backdrop: b, layer: BackdropLayer.static_),
        ),
      ),
    );

void main() {
  final backdrops = [Backdrop.none, ...Backdrop.all];
  for (final b in backdrops) {
    testWidgets('backdrop ${b.id}', (tester) async {
      await tester.pumpWidget(_harness(b));
      await expectLater(
        find.byType(CustomPaint).first,
        matchesGoldenFile('backdrops/${b.id}.png'),
      );
    });
  }
}
