// Regenerates the per-SKIN lantern frames the iOS companion widget composites.
// WidgetKit can't run LanternPainter, so each equippable skin ships as one PNG
// per widget-reachable brightness, written straight into the extension's
// file-system-synchronized group (ios/SakinaWidget/) so they auto-bundle.
//
//   GEN_WIDGET_FRAMES=1 flutter test test/widgets/gen_companion_skin_frames_test.dart
//
// Gated behind the env var on purpose: it writes ~54 binaries, and an ungated
// generator dirties them on every full `flutter test` run. Re-run it whenever a
// skin's palette/form changes, whenever kWidgetBundledSkinIds changes, and
// whenever LanternPainter's geometry changes; then commit the PNGs.
//
// Rendering deliberately mirrors gen_companion_widget_frames_test.dart (same
// painter, same params, pulse: 0.0 for a neutral resting pose, transparent
// background) so a skinned frame is pixel-comparable to the legacy default
// frame — only the size (360 vs 660) and the skin differ.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/models/companion_state.dart';
import 'package:sakina/features/streaks/models/lantern_skin.dart';
import 'package:sakina/features/streaks/widgets/lantern_painter.dart';
import 'package:sakina/services/widget_data_service.dart';

/// Widget-resolution export size (spec §5: ~360px). The in-app avatar stays
/// full-res because it is code-drawn; only these static frames are sized down.
const double _frameSize = 360.0;

Future<void> _renderFrame(
  String outPath,
  LanternSkin skin,
  CompanionBrightness brightness,
) async {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  final p = CompanionState(brightness: brightness, protected: false).params;
  LanternPainter(
    illumination: p.illum,
    glow: p.glow,
    wear: p.wear,
    dormant: p.dormant,
    protected: false,
    pulse: 0.0, // neutral resting pose (no bob/sway extreme) for a static frame
    skin: skin,
  ).paint(canvas, const Size(_frameSize, _frameSize));
  final img =
      await rec.endRecording().toImage(_frameSize.toInt(), _frameSize.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  File(outPath).writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  final skinsById = <String, LanternSkin>{
    for (final s in [...LanternSkin.all, ...LanternSkin.sculpted]) s.id: s,
  };

  test(
    'export companion widget frames for every bundled skin',
    () async {
      final dir = Directory('ios/SakinaWidget');
      expect(dir.existsSync(), isTrue,
          reason: 'run from the flutter/ project root');

      var written = 0;
      for (final skinId in kWidgetBundledSkinIds) {
        final skin = skinsById[skinId];
        expect(skin, isNotNull,
            reason: 'kWidgetBundledSkinIds names an unknown skin: $skinId');
        for (final brightness in kWidgetCompanionBrightnesses) {
          final out =
              '${dir.path}/${companionWidgetFrameAsset(skinId, brightness)}';
          await _renderFrame(out, skin!, brightness);
          expect(File(out).lengthSync(), greaterThan(0));
          written++;
        }
      }
      expect(written,
          kWidgetBundledSkinIds.length * kWidgetCompanionBrightnesses.length);
      // ignore: avoid_print
      print('wrote $written companion frames into ${dir.path}');
    },
    skip: Platform.environment['GEN_WIDGET_FRAMES'] == null
        ? 'set GEN_WIDGET_FRAMES=1 to regenerate the widget frames'
        : false,
  );
}
