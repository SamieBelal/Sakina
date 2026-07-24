// lib/features/daily/reveal/reveal_spec.dart
//
// Deliberately NOT a Freezed model: these are compile-time `const` reveal
// *config* (one immutable spec per tier, built by revealSpecFor), not runtime
// data. They never need JSON (de)serialization, and value `==`/`copyWith` add
// no value for a fixed const table — so this lives under reveal/ rather than
// models/, which is reserved for Freezed data models (see CLAUDE.md).
import 'package:flutter/material.dart';
import 'package:sakina/services/card_collection_service.dart';

/// Escalating haptic richness. Resolved to a concrete schedule in the overlay.
enum HapticProfile { light, medium, rich, legendary }

/// A tier's signature colours (used only in OUR fx layers, never the lantern flame).
class TierPalette {
  const TierPalette({required this.color, required this.bright, required this.glow});
  final Color color; // base signature (CardTier.colorValue)
  final Color bright; // lighter accent
  final Color glow; // additive glow accent
}

TierPalette tierPalette(CardTier tier) {
  // `color` is derived from CardTier.colorValue (single source of truth) so the
  // base signature can never drift from the collection tier colour. `bright` and
  // `glow` stay hand-specified — they're reveal-fx-only accents.
  switch (tier) {
    case CardTier.bronze:
      return TierPalette(
        color: Color(tier.colorValue), bright: const Color(0xFFE8A154), glow: const Color(0xFFF0B36A));
    case CardTier.silver:
      return TierPalette(
        color: Color(tier.colorValue), bright: const Color(0xFFD8DBE0), glow: const Color(0xFFEDEFF3));
    case CardTier.gold:
      return TierPalette(
        color: Color(tier.colorValue), bright: const Color(0xFFEDD9A3), glow: const Color(0xFFE8C56D));
    case CardTier.emerald:
      return TierPalette(
        color: Color(tier.colorValue), bright: const Color(0xFF7EEAAF), glow: const Color(0xFF4AE68A));
  }
}

/// Data-driven description of a tier's reveal. The overlay reads this to toggle
/// and scale every fx layer; the normalized timeline windows are shared.
class RevealSpec {
  const RevealSpec({
    required this.tier,
    required this.duration,
    required this.burstAt,
    required this.spinTurns,
    required this.godRays,
    required this.radialShafts,
    required this.aurora,
    required this.halo,
    required this.foil,
    required this.restMotes,
    required this.lensFlare,
    required this.shineSweep,
    required this.forgeBirth,
    required this.sparkCount,
    required this.godRayCount,
    required this.shaftCount,
    required this.moteCount,
    required this.haptics,
  });

  final CardTier tier;
  final Duration duration;

  /// Normalized t where the burst fires / lantern→card swap happens. Lower
  /// tiers ignite earlier (snappier build) so more of their short runtime is
  /// spent on burst+land+rest; Emerald keeps the original 0.46 so its feel is
  /// unchanged. Every window that pivots around the swap in the overlay and in
  /// revealCardMotion is expressed RELATIVE to this value.
  final double burstAt;
  final int spinTurns; // 0 = fade/scale in (no rotation)
  final double godRays; // 0-1 lantern ignite ray intensity
  final double radialShafts; // 0-1 burst shafts
  final double aurora; // 0-1 sustained aurora
  final bool halo; // rest halo ring (emerald flex)
  final double foil; // 0-1 holographic foil
  final double restMotes; // 0-1 floating embers
  final double lensFlare; // 0-1 settle flare
  final bool shineSweep;
  final bool forgeBirth; // white-hot "forged from light" entrance
  final int sparkCount;
  final int godRayCount; // lantern-ignite ray wedges (Emerald 16)
  final int shaftCount; // burst radial shafts (Emerald 20)
  final int moteCount; // floating rest embers (Emerald 14)
  final HapticProfile haptics;

  bool get spins => spinTurns > 0;
  TierPalette get palette => tierPalette(tier);
  Color get tierColor => palette.color;
}

RevealSpec revealSpecFor(CardTier tier) {
  switch (tier) {
    case CardTier.bronze:
      return const RevealSpec(
        tier: CardTier.bronze,
        duration: Duration(milliseconds: 2400),
        burstAt: 0.34,
        spinTurns: 0, godRays: 0.25, radialShafts: 0.0, aurora: 0.0,
        halo: false, foil: 0.0, restMotes: 0.15, lensFlare: 0.0,
        shineSweep: true, forgeBirth: false, sparkCount: 8,
        godRayCount: 8, shaftCount: 10, moteCount: 6,
        haptics: HapticProfile.light,
      );
    case CardTier.silver:
      return const RevealSpec(
        tier: CardTier.silver,
        duration: Duration(milliseconds: 3600),
        burstAt: 0.42,
        spinTurns: 1, godRays: 0.5, radialShafts: 0.0, aurora: 0.25,
        halo: false, foil: 0.0, restMotes: 0.4, lensFlare: 0.3,
        shineSweep: true, forgeBirth: true, sparkCount: 14,
        godRayCount: 10, shaftCount: 12, moteCount: 8,
        haptics: HapticProfile.medium,
      );
    case CardTier.gold:
      return const RevealSpec(
        tier: CardTier.gold,
        duration: Duration(milliseconds: 5000),
        burstAt: 0.46,
        spinTurns: 2, godRays: 0.75, radialShafts: 0.6, aurora: 0.6,
        halo: false, foil: 0.5, restMotes: 0.7, lensFlare: 0.7,
        shineSweep: true, forgeBirth: true, sparkCount: 22,
        godRayCount: 14, shaftCount: 16, moteCount: 12,
        haptics: HapticProfile.rich,
      );
    case CardTier.emerald:
      return const RevealSpec(
        tier: CardTier.emerald,
        duration: Duration(milliseconds: 7000),
        burstAt: 0.46, // KEEP at today's value — Emerald pacing unchanged.
        spinTurns: 3, godRays: 1.0, radialShafts: 1.0, aurora: 1.0,
        halo: true, foil: 1.0, restMotes: 1.0, lensFlare: 1.0,
        shineSweep: true, forgeBirth: true, sparkCount: 30,
        godRayCount: 16, shaftCount: 20, moteCount: 14,
        haptics: HapticProfile.legendary,
      );
  }
}
