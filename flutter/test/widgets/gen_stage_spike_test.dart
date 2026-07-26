// PROTOTYPE spike (2026-07-25): render the full Companion-screen "stage" —
// backdrop + lantern skin composed together, phone aspect — to judge whether the
// two axes come together at quality before we commit the design.
//
//   flutter test test/widgets/gen_stage_spike_test.dart
//
// Output: docs/superpowers/specs/skin-previews/stage_*.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/models/backdrop.dart';
import 'package:sakina/features/streaks/models/lantern_skin.dart';
import 'package:sakina/features/streaks/widgets/backdrop_painter.dart';
import 'package:sakina/features/streaks/widgets/lantern_painter.dart';

const _w = 1080.0;
const _h = 2040.0;

Future<void> _stage(String path, Backdrop backdrop, LanternSkin skin,
    {double glow = 1.0}) async {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);

  // Backdrop fills the stage.
  BackdropPainter(backdrop: backdrop, pulse: 0.0)
      .paint(canvas, const Size(_w, _h));

  // Lantern, composed centre-lower so it stands in the warm floor glow.
  const l = _w * 0.62;
  final cx = _w / 2, cy = _h * 0.585;
  final lanternRec = ui.PictureRecorder();
  final lc = Canvas(lanternRec);
  LanternPainter(
    illumination: 1.0,
    glow: glow,
    wear: 0.0,
    dormant: false,
    protected: false,
    pulse: 0.0,
    ambient: false,
    skin: skin,
  ).paint(lc, const Size(l, l));
  canvas.save();
  canvas.translate(cx - l / 2, cy - l / 2);
  canvas.drawPicture(lanternRec.endRecording());
  canvas.restore();

  final img = await rec.endRecording().toImage(_w.toInt(), _h.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  test('render companion-stage spikes', () async {
    final dir = Directory('docs/superpowers/specs/skin-previews');
    dir.createSync(recursive: true);

    await _stage('${dir.path}/stage_laylat_ramadan.png', Backdrop.laylatNight,
        LanternSkin.ramadanRoyal);
    await _stage('${dir.path}/stage_laylat_masjid.png', Backdrop.laylatNight,
        LanternSkin.masjidBrass);
    await _stage('${dir.path}/stage_emerald_jade.png',
        Backdrop.emeraldSanctuary, LanternSkin.emeraldJade);
    await _stage('${dir.path}/stage_emerald_classic.png',
        Backdrop.emeraldSanctuary, LanternSkin.classicGold);

    // Backdrops alone (no lantern) for inspection.
    for (final b in Backdrop.all) {
      final rec = ui.PictureRecorder();
      BackdropPainter(backdrop: b, pulse: 0.0)
          .paint(Canvas(rec), const Size(_w, _h));
      final img =
          await rec.endRecording().toImage(_w.toInt(), _h.toInt());
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File('${dir.path}/backdrop_${b.id}.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    }

    expect(File('${dir.path}/stage_laylat_ramadan.png').existsSync(), isTrue);
  });
}
