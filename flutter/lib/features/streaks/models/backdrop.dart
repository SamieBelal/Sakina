// A code-drawn "backdrop" — the second cosmetic axis (the scene behind the
// lantern on the Companion stage). Like LanternSkin, it's pure parameters fed
// into a CustomPainter, so it costs ~0 KB and renders live. Backdrops appear on
// the Companion screen + wardrobe preview only (never the Home surfaces or the
// iOS widget), so they can be immersive without clashing with existing UI.
//
// PROTOTYPE (2026-07-25): spike to prove skin + backdrop compose at quality.

import 'package:flutter/material.dart';

/// `emeraldSanctuary` keeps its id for continuity with rows already in
/// `cosmetic_catalog` and `user_cosmetics`, but now paints the far richer
/// Emerald Mihrab interior — the original flat wash was rejected for having no
/// depth. Renaming the enum would orphan live ownership rows for no gain.
enum BackdropTheme { plain, laylatNight, emeraldSanctuary, desertNight, fajrCourtyard }

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

  /// The prayer-hall interior. Keeps the `emerald_sanctuary` id (live rows
  /// reference it) but is now a receding arcade with muqarnas and hanging
  /// lamps rather than the flat wash it replaced.
  static const emeraldSanctuary = Backdrop(
    id: 'emerald_sanctuary',
    name: 'Emerald Mihrab',
    blurb: 'Lamplight in a still prayer hall.',
    theme: BackdropTheme.emeraldSanctuary,
  );

  /// Vast, architecture-free counterpoint to the city skyline.
  static const desertNight = Backdrop(
    id: 'desert_night',
    name: 'Desert Night',
    blurb: 'The Milky Way over silent dunes.',
    theme: BackdropTheme.desertNight,
  );

  /// Dawn — the emotional counterpart to Laylat Night.
  static const fajrCourtyard = Backdrop(
    id: 'fajr_courtyard',
    name: 'Fajr Courtyard',
    blurb: 'First light behind the arcade.',
    theme: BackdropTheme.fajrCourtyard,
  );

  static const all = <Backdrop>[
    laylatNight,
    emeraldSanctuary,
    desertNight,
    fajrCourtyard,
  ];

  /// True when this backdrop paints a LIGHT surface, so foreground text and
  /// icons need dark ink.
  ///
  /// `AppColors.sacredInk` is CREAM — it is "primary text on canvas", correct
  /// against the emerald/night scenes and invisible against the plain warm
  /// cream surface. Anything drawing chrome over a backdrop must branch on
  /// this rather than assuming a dark canvas.
  bool get isLightSurface => theme == BackdropTheme.plain;

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
