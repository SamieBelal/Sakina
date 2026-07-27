// Regenerates the pre-rendered lantern-companion frames the iOS home-screen
// widget composites (WidgetKit can't run a CustomPainter / animate). One PNG per
// CompanionBrightness, transparent background, high-res so it stays crisp on
// Small + Medium. Written straight into the widget extension's synced group so
// they auto-bundle.
//
//   flutter test test/widgets/gen_companion_widget_frames_test.dart
//
// Re-run whenever the lantern art changes. Frames land in ios/SakinaWidget/.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/models/companion_state.dart';
import 'package:sakina/features/streaks/widgets/lantern_painter.dart';

Future<void> _renderFrame(String outPath, CompanionBrightness b) async {
  const size = 660.0;
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  // Transparent background: the widget supplies its own cream container, and the
  // lantern composits cleanly on it.
  final p = CompanionState(brightness: b, protected: false).params;
  LanternPainter(
    illumination: p.illum,
    glow: p.glow,
    wear: p.wear,
    dormant: p.dormant,
    protected: false,
    pulse: 0.0, // neutral resting pose (no bob/sway extreme) for a static frame
  ).paint(canvas, const Size(size, size));
  final img = await rec.endRecording().toImage(size.toInt(), size.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  File(outPath).writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  test(
    'generate companion widget frames into ios/SakinaWidget/',
    () async {
      final dir = Directory('ios/SakinaWidget');
      expect(dir.existsSync(), isTrue,
          reason: 'run from the flutter/ project root');
      for (final b in CompanionBrightness.values) {
        final out = '${dir.path}/companion_${b.name}.png';
        await _renderFrame(out, b);
        expect(File(out).existsSync(), isTrue);
      }
    },
    // GATED, like gen_companion_skin_frames_test.dart. This is a GENERATOR, not
    // an assertion: it writes seven TRACKED files under ios/SakinaWidget/.
    // Ungated it ran on every `flutter test`, so the documented full-suite
    // command silently dirtied the working tree — and because the encoder's
    // output is not byte-stable run to run (companion_fullyLit.png moved
    // 194 KB -> 409 KB between runs with no code change), the diff looked like
    // real artwork churn and invited exactly the mistaken "refresh the stale
    // fallback frames" commit that prompted this fix.
    //
    // Its sibling was already gated this way; only this one was missed.
    skip: Platform.environment['GEN_WIDGET_FRAMES'] == null
        ? 'set GEN_WIDGET_FRAMES=1 to regenerate the widget frames'
        : false,
  );
}
