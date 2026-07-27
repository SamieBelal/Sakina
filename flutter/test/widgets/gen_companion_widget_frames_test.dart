// Regenerates the pre-rendered lantern-companion frames the iOS home-screen
// widget composites (WidgetKit can't run a CustomPainter / animate). One PNG per
// CompanionBrightness, transparent background, high-res so it stays crisp on
// Small + Medium. Written straight into the widget extension's synced group so
// they auto-bundle.
//
// This is a GENERATOR, not a test: it writes tracked binary assets. It lives in
// the test/ tree only because rendering a CustomPainter needs the flutter_test
// harness — so it is skipped unless explicitly asked for. Without that guard the
// `flutter test` sweep documented in CLAUDE.md silently rewrote all seven PNGs
// (~470KB) on every full run, which showed up as mystery `M` entries in working
// trees nobody had touched.
//
// Re-run whenever the lantern art changes. Frames land in ios/SakinaWidget/:
//
//   REGEN_WIDGET_FRAMES=1 flutter test test/widgets/gen_companion_widget_frames_test.dart
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

/// Opt-in switch. Absent (the normal `flutter test` case) → the generator is
/// skipped and no tracked asset is touched.
final bool _regenRequested =
    Platform.environment['REGEN_WIDGET_FRAMES'] == '1';

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
    skip: _regenRequested
        ? null
        : 'generator, not a test — it rewrites tracked PNGs in '
            'ios/SakinaWidget/. Run with REGEN_WIDGET_FRAMES=1 to regenerate.',
  );
}
