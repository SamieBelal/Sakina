// Frame-budget guard for the backdrop stage. The static layer must be
// pulse-independent (raster-cacheable); only the animated layer repaints.
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/models/backdrop.dart';
import 'package:sakina/features/streaks/widgets/backdrop_painter.dart';

void main() {
  const b = Backdrop.laylatNight;

  test('static layer ignores pulse (never repaints as it animates)', () {
    final a = BackdropPainter(backdrop: b, pulse: 0.0, layer: BackdropLayer.static_);
    final c = BackdropPainter(backdrop: b, pulse: 0.5, layer: BackdropLayer.static_);
    expect(a.shouldRepaint(c), isFalse); // pulse changed, static does not care
  });

  test('static layer repaints only when the backdrop identity changes', () {
    final a = BackdropPainter(
        backdrop: Backdrop.laylatNight, pulse: 0.0, layer: BackdropLayer.static_);
    final c = BackdropPainter(
        backdrop: Backdrop.emeraldSanctuary, pulse: 0.0, layer: BackdropLayer.static_);
    expect(a.shouldRepaint(c), isTrue);
  });

  test('animated layer repaints on pulse change, skips when unchanged', () {
    final a = BackdropPainter(backdrop: b, pulse: 0.0, layer: BackdropLayer.animated);
    final moved = BackdropPainter(backdrop: b, pulse: 0.5, layer: BackdropLayer.animated);
    final same = BackdropPainter(backdrop: b, pulse: 0.0, layer: BackdropLayer.animated);
    expect(a.shouldRepaint(moved), isTrue);
    expect(a.shouldRepaint(same), isFalse);
  });

  test('plain backdrop animated layer never repaints (nothing moves)', () {
    final a = BackdropPainter(
        backdrop: Backdrop.none, pulse: 0.0, layer: BackdropLayer.animated);
    final c = BackdropPainter(
        backdrop: Backdrop.none, pulse: 0.9, layer: BackdropLayer.animated);
    expect(a.shouldRepaint(c), isFalse); // plain has no animated content
  });
}
