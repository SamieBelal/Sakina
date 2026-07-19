import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/models/companion_state.dart';
import 'package:sakina/features/streaks/widgets/lantern_painter.dart';

// Render-smoke for the production painter (plan §5): every brightness state
// paints without throwing, and the frames land in /tmp for eyeballing. NOT a
// pixel golden (finding #11 — shader/blur output is GPU-flaky).
Future<void> _render(String name, double size, CompanionState state) async {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  final rect = Rect.fromLTWH(0, 0, size, size);
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, Radius.circular(size * 0.16)),
    Paint()
      ..shader = ui.Gradient.radial(Offset(size / 2, size * 0.4), size * 0.75,
          [const Color(0xFF0F3E2C), const Color(0xFF062017)]),
  );
  final p = state.params;
  LanternPainter(
    illumination: p.illum,
    glow: p.glow,
    wear: p.wear,
    dormant: p.dormant,
    protected: state.protected,
    pulse: 0.5,
  ).paint(canvas, Size(size, size));
  final img = await rec.endRecording().toImage(size.toInt(), size.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  final dir = Directory('/tmp/lantern-preview')..createSync(recursive: true);
  File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  test('every brightness state paints + writes a frame', () async {
    const s = 560.0;
    var i = 0;
    for (final b in Brightness.values) {
      await _render('${++i}-${b.name}',
          s, CompanionState(brightness: b, protected: false));
    }
    // The freeze shield composited over a radiant lamp.
    await _render('${++i}-protected',
        s, const CompanionState(brightness: Brightness.fullyLit, protected: true));

    expect(
        File('/tmp/lantern-preview/${Brightness.values.length + 1}-protected.png')
            .existsSync(),
        isTrue);
  });
}
