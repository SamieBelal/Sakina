// The lantern's glass window as ONE shape. Recolor skins get a plain rounded
// rectangle; arched-window (mihrab) skins get the SAME rectangle whose top edge
// is replaced by a pointed keel arch — a single continuous, closed contour, so
// the clip/fill/outline never leave a seam between "rect glass" and "cap glass".
//
// Replaces the old approach where the window was an RRect + a separate additive
// `_archedWindow` cap painted on top (the visible horizontal seam at panel.top).

import 'dart:ui';

/// A resolved glass-panel geometry. `rect` is the rectangular window bounds;
/// `radius` its corner radius; `arched` swaps the flat top for a keel arch.
class GlassPanel {
  GlassPanel({required this.rect, required this.radius, required this.arched})
      : path = _build(rect, radius, arched);

  final Rect rect;
  final double radius;
  final bool arched;

  /// The single closed contour of the window (rounded rect, or arch-topped).
  final Path path;

  /// Convenience: the rectangular window bounds (unchanged for both forms — the
  /// khatam light, flame, lattice and dust all key off THIS, not the arch rise).
  Rect get innerRect => rect;

  static Path _build(Rect r, double rad, bool arched) {
    if (!arched) {
      return Path()..addRRect(RRect.fromRectAndRadius(r, Radius.circular(rad)));
    }
    // Arch rise above the rectangle top — matches the old cap proportions
    // (apexY = top - height*0.24; shoulders bow via top - height*0.30).
    final h = r.height;
    final apexY = r.top - h * 0.24;
    final bowY = r.top - h * 0.30;
    // Walk: start below the top-left corner, up the left side, across the keel
    // arch to the apex and down to the top-right, down the right side, across
    // the (rounded) bottom, and close. One contour.
    return Path()
      ..moveTo(r.left, r.bottom - rad)
      ..lineTo(r.left, r.top)
      // left half of the keel arch → apex
      ..quadraticBezierTo(r.left, bowY, r.center.dx, apexY)
      // apex → right shoulder
      ..quadraticBezierTo(r.right, bowY, r.right, r.top)
      ..lineTo(r.right, r.bottom - rad)
      ..quadraticBezierTo(r.right, r.bottom, r.right - rad, r.bottom)
      ..lineTo(r.left + rad, r.bottom)
      ..quadraticBezierTo(r.left, r.bottom, r.left, r.bottom - rad)
      ..close();
  }
}
