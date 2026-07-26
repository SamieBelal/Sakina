// Golden regression for every lantern skin at its two material-defining states
// (fullyLit + dim). Static frame (animate:false) → deterministic pixels.
// Regenerate refs with:  flutter test --update-goldens test/widgets/goldens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:sakina/features/streaks/models/companion_state.dart';
import 'package:sakina/features/streaks/models/lantern_skin.dart';
import 'package:sakina/features/streaks/widgets/companion_medallion.dart';

const _fullyLit =
    CompanionState(brightness: CompanionBrightness.fullyLit, protected: false);
const _dim =
    CompanionState(brightness: CompanionBrightness.dim, protected: false);

Widget _harness(LanternSkin skin, CompanionState state) => MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF17140F),
        body: Center(
          child: SizedBox(
            width: 320,
            height: 320,
            child: CompanionMedallion(
              key: ValueKey('${skin.id}-golden'),
              state: state, // carries glow/wear/dormant
              skin: skin, // Lane C adds this passthrough (see NOTE)
              size: 320,
              animate: false, // static hero frame
              ambient: false, // draw only the object, transparent bg
            ),
          ),
        ),
      ),
    );

void main() {
  // CompanionMedallion uses a VisibilityDetector, whose default 500ms debounce
  // timer would linger past the test tree's disposal. Fire callbacks
  // synchronously so no timer outlives the frame.
  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  final skins = [...LanternSkin.all, ...LanternSkin.sculpted];

  for (final skin in skins) {
    testWidgets('skin ${skin.id} · fullyLit', (tester) async {
      await tester.pumpWidget(_harness(skin, _fullyLit));
      await tester.pump(const Duration(milliseconds: 16));
      await expectLater(
        find.byType(CompanionMedallion),
        matchesGoldenFile('skins/${skin.id}_fully_lit.png'),
      );
    });

    testWidgets('skin ${skin.id} · dim', (tester) async {
      await tester.pumpWidget(_harness(skin, _dim));
      await tester.pump(const Duration(milliseconds: 16));
      await expectLater(
        find.byType(CompanionMedallion),
        matchesGoldenFile('skins/${skin.id}_dim.png'),
      );
    });
  }
}
