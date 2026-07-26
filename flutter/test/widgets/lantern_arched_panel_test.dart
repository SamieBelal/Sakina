// Verifies the arched-window skins render the glass as a SINGLE arch-topped
// shape (apex above the rectangle top), not a rectangle + an additive cap.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/widgets/lantern_glass_panel.dart';

void main() {
  const s = 400.0;
  const rect = Rect.fromLTRB(-s * 0.125, -s * 0.05, s * 0.125, s * 0.19);

  test('rectangular panel top edge == rect top (recolor skins)', () {
    final panel = GlassPanel(rect: rect, radius: s * 0.03, arched: false);
    // No arch: the path bounds top equals the rectangle top.
    expect(panel.path.getBounds().top, closeTo(rect.top, 0.5));
  });

  test('arched panel apex rises ABOVE the rectangle top (single shape)', () {
    final panel = GlassPanel(rect: rect, radius: s * 0.03, arched: true);
    final b = panel.path.getBounds();
    // The one continuous path extends above rect.top by the arch rise. The keel
    // arch's apex sits at top - h*0.24 with control points bowing to top - h*0.30
    // (h = rect.height = 0.24*s here → the bounds rise ~h*0.30 = 0.072*s above
    // the rect top). Assert a rise clearly above the flat top but within that
    // geometry (the plan's s*0.10 threshold overshoots the cap's own rise).
    expect(b.top, lessThan(rect.top - s * 0.05));
    // …while left/right/bottom still match the rectangle (it's the same window).
    expect(b.left, closeTo(rect.left, 0.5));
    expect(b.right, closeTo(rect.right, 0.5));
    expect(b.bottom, closeTo(rect.bottom, 0.5));
  });

  test('arched panel is a single closed contour (no seam sub-path)', () {
    final panel = GlassPanel(rect: rect, radius: s * 0.03, arched: true);
    // A single closed contour → exactly one metric in the path.
    final metrics = panel.path.computeMetrics().toList();
    expect(metrics.length, 1);
    expect(metrics.first.isClosed, isTrue);
  });
}
