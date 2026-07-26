// PROTOTYPE render harness (2026-07-25): renders every LanternSkin at its
// hero `fullyLit` state into a single comparison sheet + one PNG each, so we can
// eyeball whether code-drawn skins look premium before committing to the feature.
//
//   flutter test test/widgets/gen_skin_showcase_test.dart
//
// Output: docs/superpowers/specs/skin-previews/
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/models/lantern_skin.dart';
import 'package:sakina/features/streaks/widgets/lantern_painter.dart';

const _tile = 560.0;
const _label = 78.0;
const _pad = 44.0;
const _cols = 3;

// Warm charcoal showcase tile (not pure black — matches the app's dark surface).
const _bg = Color(0xFF17140F);
const _tileTop = Color(0xFF241E16);
const _tileBot = Color(0xFF120F0A);

ui.Picture _lantern(LanternSkin skin, {double glow = 1.0, double wear = 0.0}) {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  LanternPainter(
    illumination: 1.0,
    glow: glow,
    wear: wear,
    dormant: false,
    protected: false,
    pulse: 0.0, // resting hero pose
    ambient: false, // we draw our own tile background
    skin: skin,
  ).paint(canvas, const Size(_tile, _tile));
  return rec.endRecording();
}

void _label3(Canvas canvas, String text, Offset center, double maxW,
    {double size = 30, Color color = const Color(0xFFF3E9D8), bool bold = true}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        letterSpacing: 0.2,
      ),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: maxW);
  tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy));
}

void _tileBgPaint(Canvas canvas, Rect r) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(28));
  canvas.drawRRect(
    rr,
    Paint()
      ..shader = ui.Gradient.linear(
          r.topCenter, r.bottomCenter, [_tileTop, _tileBot]),
  );
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF3A2F20).withValues(alpha: 0.6),
  );
}

Future<void> _writePng(ui.Picture pic, int w, int h, String path) async {
  final img = await pic.toImage(w, h);
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  test('render lantern skin showcase sheet', () async {
    final outDir = Directory('docs/superpowers/specs/skin-previews');
    outDir.createSync(recursive: true);

    final skins = LanternSkin.all;
    final rows = (skins.length / _cols).ceil();
    final sheetW = (_cols * _tile + (_cols + 1) * _pad).toInt();
    final cellH = _tile + _label;
    final sheetH = (rows * cellH + (rows + 1) * _pad + 96).toInt();

    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, sheetW.toDouble(), sheetH.toDouble()),
        Paint()..color = _bg);

    // Header.
    _label3(canvas, 'Lantern Skins  ·  fully-lit hero state',
        Offset(sheetW / 2, 30), sheetW.toDouble(),
        size: 40, color: const Color(0xFFE8C97A));

    for (var i = 0; i < skins.length; i++) {
      final row = i ~/ _cols, col = i % _cols;
      final x = _pad + col * (_tile + _pad);
      final y = 96 + _pad + row * (cellH + _pad);
      final tileRect = Rect.fromLTWH(x, y, _tile, _tile);
      _tileBgPaint(canvas, tileRect);

      canvas.save();
      canvas.translate(x, y);
      canvas.clipRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, _tile, _tile), const Radius.circular(28)));
      canvas.drawPicture(_lantern(skins[i]));
      canvas.restore();

      _label3(canvas, skins[i].name, Offset(x + _tile / 2, y + _tile + 14), _tile,
          size: 30);
      _label3(canvas, skins[i].blurb, Offset(x + _tile / 2, y + _tile + 50), _tile,
          size: 20, color: const Color(0xFFB6A98F), bold: false);
    }

    await _writePng(rec.endRecording(), sheetW, sheetH,
        '${outDir.path}/_showcase_sheet.png');

    // Sculpted hero skins on their own sheet (geometry + ornament).
    final hero = LanternSkin.sculpted;
    final hCols = hero.length;
    final hSheetW = (hCols * _tile + (hCols + 1) * _pad).toInt();
    final hSheetH = (_tile + _label + 2 * _pad + 96).toInt();
    final hRec = ui.PictureRecorder();
    final hCanvas = Canvas(hRec);
    hCanvas.drawRect(Rect.fromLTWH(0, 0, hSheetW.toDouble(), hSheetH.toDouble()),
        Paint()..color = _bg);
    _label3(hCanvas, 'Sculpted hero skins  ·  geometry + ornament',
        Offset(hSheetW / 2, 30), hSheetW.toDouble(),
        size: 40, color: const Color(0xFFE8C97A));
    for (var i = 0; i < hero.length; i++) {
      final x = _pad + i * (_tile + _pad);
      final y = 96 + _pad;
      final tileRect = Rect.fromLTWH(x, y, _tile, _tile);
      _tileBgPaint(hCanvas, tileRect);
      hCanvas.save();
      hCanvas.translate(x, y);
      hCanvas.clipRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, _tile, _tile), const Radius.circular(28)));
      hCanvas.drawPicture(_lantern(hero[i]));
      hCanvas.restore();
      _label3(hCanvas, hero[i].name, Offset(x + _tile / 2, y + _tile + 14), _tile,
          size: 30);
      _label3(hCanvas, hero[i].blurb, Offset(x + _tile / 2, y + _tile + 50),
          _tile,
          size: 20, color: const Color(0xFFB6A98F), bold: false);
    }
    await _writePng(hRec.endRecording(), hSheetW, hSheetH,
        '${outDir.path}/_sculpted_sheet.png');

    // Also one hero PNG per skin (for close inspection / iteration).
    for (final skin in [...skins, ...hero]) {
      final rec2 = ui.PictureRecorder();
      final c2 = Canvas(rec2);
      _tileBgPaint(c2, const Rect.fromLTWH(0, 0, _tile, _tile));
      c2.clipRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, _tile, _tile), const Radius.circular(28)));
      c2.drawPicture(_lantern(skin));
      await _writePng(rec2.endRecording(), _tile.toInt(), _tile.toInt(),
          '${outDir.path}/${skin.id}.png');
    }

    expect(File('${outDir.path}/_showcase_sheet.png').existsSync(), isTrue);
  });
}
