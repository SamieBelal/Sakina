// A code-drawn "backdrop" — the second cosmetic axis (the scene behind the
// lantern on the Companion stage). Like LanternSkin, it's pure parameters fed
// into a CustomPainter, so it costs ~0 KB and renders live. Backdrops appear on
// the Companion screen + wardrobe preview only (never the Home surfaces or the
// iOS widget), so they can be immersive without clashing with existing UI.
//
// PROTOTYPE (2026-07-25): spike to prove skin + backdrop compose at quality.

import 'package:flutter/material.dart';

enum BackdropTheme { plain, laylatNight, emeraldSanctuary }

@immutable
class Backdrop {
  const Backdrop({
    required this.id,
    required this.name,
    required this.blurb,
    required this.theme,
  });

  final String id;
  final String name;
  final String blurb;
  final BackdropTheme theme;

  /// The default "no backdrop" — a plain warm surface (used before any is owned).
  static const none = Backdrop(
    id: 'default',
    name: 'None',
    blurb: 'A plain, quiet surface.',
    theme: BackdropTheme.plain,
  );

  /// A mosque skyline beneath a crescent moon and a field of stars.
  static const laylatNight = Backdrop(
    id: 'laylat_night',
    name: 'Laylat Night',
    blurb: 'A mosque skyline beneath a crescent moon.',
    theme: BackdropTheme.laylatNight,
  );

  /// A quiet mihrab niche bathed in green sanctuary light.
  static const emeraldSanctuary = Backdrop(
    id: 'emerald_sanctuary',
    name: 'Emerald Sanctuary',
    blurb: 'A quiet mihrab bathed in sacred green light.',
    theme: BackdropTheme.emeraldSanctuary,
  );

  static const all = <Backdrop>[laylatNight, emeraldSanctuary];

  // Value equality (id + theme is the semantic identity) so that a Backdrop
  // constructed from wardrobe/server data compares equal to its value-twin.
  // Without this, BackdropPainter.shouldRepaint (which tests `old.backdrop !=
  // backdrop`) would fall back to identity equality and needlessly repaint the
  // static layer on every rebuild, defeating the raster cache.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Backdrop && other.id == id && other.theme == theme);

  @override
  int get hashCode => Object.hash(id, theme);
}
