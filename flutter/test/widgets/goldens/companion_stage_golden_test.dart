// Composed-stage goldens: skin + backdrop together (static), the two pairings
// the spike judged strongest, so the composition (anchor, contrast) is guarded.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:sakina/features/streaks/models/backdrop.dart';
import 'package:sakina/features/streaks/models/companion_state.dart';
import 'package:sakina/features/streaks/models/lantern_skin.dart';
import 'package:sakina/features/streaks/widgets/backdrop_stage.dart';
import 'package:sakina/features/streaks/widgets/companion_medallion.dart';
import 'golden_platform.dart';

const _fullyLit =
    CompanionState(brightness: CompanionBrightness.fullyLit, protected: false);

Widget _stage(Backdrop b, LanternSkin skin, CompanionState state) => MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SizedBox(
        width: 360,
        height: 680,
        child: CompanionStage(
          backdrop: b,
          animate: false,
          child: Center(
            child: SizedBox(
              width: 240,
              height: 240,
              child: CompanionMedallion(
                state: state,
                skin: skin,
                size: 240,
                animate: false,
                ambient: false,
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  // CompanionStage + CompanionMedallion each use a VisibilityDetector, whose
  // default 500ms debounce timer would linger past the test tree's disposal.
  // Fire visibility callbacks synchronously so no timer outlives the frame.
  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  testWidgets('stage · masjid on laylat night', (tester) async {
    await tester.pumpWidget(
        _stage(Backdrop.laylatNight, LanternSkin.masjidBrass, _fullyLit));
    await expectLater(
        find.byType(CompanionStage), matchesGoldenFile('stages/laylat_masjid.png'));
  }, skip: skipGoldensOffPlatform);

  testWidgets('stage · jade on emerald sanctuary', (tester) async {
    await tester.pumpWidget(
        _stage(Backdrop.emeraldSanctuary, LanternSkin.emeraldJade, _fullyLit));
    await expectLater(
        find.byType(CompanionStage), matchesGoldenFile('stages/emerald_jade.png'));
  }, skip: skipGoldensOffPlatform);
}
