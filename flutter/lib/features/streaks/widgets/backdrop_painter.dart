// Draws a cosmetic backdrop — the scene behind the lantern on the Companion
// stage. Pure CustomPainter (code-drawn, ~0 KB) and deterministic (index-seeded,
// no RNG), so frames are stable and the static layer raster-caches.
//
// This file is now only the DISPATCHER plus the `plain` (no-backdrop) surface.
// Every real scene lives in its own self-contained file under `backdrops/`,
// each exposing a `paint…Static` / `paint…Animated` pair, so the scenes can be
// authored and tuned in parallel without cross-scene regressions.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:sakina/features/streaks/widgets/backdrops/desert_night_backdrop.dart';
import 'package:sakina/features/streaks/widgets/backdrops/emerald_mihrab_backdrop.dart';
import 'package:sakina/features/streaks/widgets/backdrops/fajr_courtyard_backdrop.dart';
import 'package:sakina/features/streaks/widgets/backdrops/laylat_night_backdrop.dart';

import '../models/backdrop.dart';

/// Which layer this painter renders. Splitting lets the static scene raster-
/// cache (painted once) while only the animated layer repaints per pulse.
enum BackdropLayer { static_, animated }

class BackdropPainter extends CustomPainter {
  BackdropPainter({
    required this.backdrop,
    this.pulse = 0.0,
    this.layer = BackdropLayer.static_,
  });

  final Backdrop backdrop;
  final double pulse;
  final BackdropLayer layer;

  @override
  void paint(Canvas canvas, Size size) {
    switch (backdrop.theme) {
      case BackdropTheme.plain:
        // Plain is fully static; the animated layer is a no-op.
        if (layer == BackdropLayer.static_) _plain(canvas, size);
      case BackdropTheme.laylatNight:
        // Repointed at the refined scene. The old in-painter version read soft
        // on device — every silhouette outline was a blurred stroke, the
        // buildings had no interior detail, and the whole star field lived in
        // the animated layer — so it was rebuilt alongside its siblings.
        layer == BackdropLayer.static_
            ? paintLaylatNightStatic(canvas, size)
            : paintLaylatNightAnimated(canvas, size, pulse);
      case BackdropTheme.emeraldSanctuary:
        // Repointed at the Emerald Mihrab interior. The old flat-wash scene
        // (base fill + one radial wash + one arch outline) was deleted along
        // with its now-orphaned `_mihrabArch` helper — it was rejected for
        // having no depth, so keeping it around would only invite its return.
        layer == BackdropLayer.static_
            ? paintEmeraldMihrabStatic(canvas, size)
            : paintEmeraldMihrabAnimated(canvas, size, pulse);
      case BackdropTheme.desertNight:
        layer == BackdropLayer.static_
            ? paintDesertNightStatic(canvas, size)
            : paintDesertNightAnimated(canvas, size, pulse);
      case BackdropTheme.fajrCourtyard:
        layer == BackdropLayer.static_
            ? paintFajrCourtyardStatic(canvas, size)
            : paintFajrCourtyardAnimated(canvas, size, pulse);
    }
  }

  // ── Plain ─────────────────────────────────────────────────────────────────
  // The genuine "no backdrop": the app's warm cream surface with a soft warm
  // pool where the lantern stands. No scene — quiet, so it reads as "none".
  void _plain(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    // Warm cream base (light-mode canvas), a touch deeper toward the floor.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w / 2, 0),
          Offset(w / 2, h),
          const [Color(0xFFFBF7F2), Color(0xFFF3ECE1)],
        ),
    );
    // A soft warm pool under the lantern (no blend-plus needed on a light base).
    final glowC = Offset(w / 2, h * 0.66);
    canvas.drawCircle(
      glowC,
      w * 0.46,
      Paint()
        ..shader = ui.Gradient.radial(glowC, w * 0.46, [
          const Color(0xFFE9C88A).withValues(alpha: 0.16),
          const Color(0xFFE9C88A).withValues(alpha: 0.0),
        ]),
    );
    // Faint floor sheen so the lantern feels grounded, not floating.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w / 2, h * 0.80), width: w * 0.5, height: h * 0.04),
      Paint()
        ..color = const Color(0xFFCBA76A).withValues(alpha: 0.10)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.05),
    );
  }

  @override
  bool shouldRepaint(BackdropPainter old) {
    if (old.backdrop != backdrop || old.layer != layer) return true;
    // The static layer is pulse-independent; only the animated layer cares.
    if (layer == BackdropLayer.static_) return false;
    // Plain has no animated content → never repaints on pulse.
    if (backdrop.theme == BackdropTheme.plain) return false;
    return old.pulse != pulse;
  }
}
