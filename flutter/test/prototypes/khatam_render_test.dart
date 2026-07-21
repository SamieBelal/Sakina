// Renders the code-drawn khatam companion to PNGs (one per streak state) — this
// both PROVES the painter renders without error and produces the exact
// pre-rendered frames the home-screen widget would show. Output → /tmp/khatam-preview/.
//
// Run: flutter test test/prototypes/khatam_render_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/prototypes/khatam_companion_prototype.dart';

Future<void> _render(
  String name,
  double size, {
  required double illumination,
  required double glow,
  bool dormant = false,
  bool protected = false,
  double pulse = 0.6,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final rect = Rect.fromLTWH(0, 0, size, size);

  // Widget-card background (deep emerald radial), matching the prototype.
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, Radius.circular(size * 0.16)),
    Paint()
      ..shader = ui.Gradient.radial(
        Offset(size / 2, size * 0.4),
        size * 0.7,
        [const Color(0xFF0F3E2C), const Color(0xFF062017)],
      ),
  );

  KhatamPainter(
    illumination: illumination,
    glow: glow,
    dormant: dormant,
    protected: protected,
    pulse: pulse,
  ).paint(canvas, Size(size, size));

  final img = await recorder.endRecording().toImage(size.toInt(), size.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  final dir = Directory('/tmp/khatam-preview')..createSync(recursive: true);
  File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  test('renders each khatam streak state to a PNG frame', () async {
    const s = 512.0;
    await _render('1-dormant', s, illumination: 1.0, glow: 0.0, dormant: true, pulse: 0);
    await _render('2-dim', s, illumination: 0.42, glow: 0.22, pulse: 0);
    await _render('3-glowing', s, illumination: 0.72, glow: 0.5, pulse: 0);
    await _render('4-fully-lit', s, illumination: 1.0, glow: 0.9);
    await _render('5-protected', s, illumination: 1.0, glow: 0.9, protected: true);
    // A mid-reveal frame to show the "light fills from the centre" animation.
    await _render('6-mid-reveal', s, illumination: 0.55, glow: 0.4, pulse: 0);

    for (final n in ['1-dormant', '3-glowing', '4-fully-lit', '5-protected']) {
      expect(File('/tmp/khatam-preview/$n.png').existsSync(), isTrue);
    }
  });
}
