// The companion's visual state — two orthogonal axes (plan §1), not a flat enum:
//
//   CompanionState = ( brightness : CompanionBrightness , protected : bool )
//
// `brightness` is the streak-driven light level; `protected` is the forward-
// looking freeze shield, composited OVER any brightness. Keeping them orthogonal
// means a protected lamp can be dormant, dim, or radiant — the shield is a
// modifier, never a brightness value of its own.
//
// `illum` is pinned to 1.0 for every state: the full geometric khatam is always
// drawn. The streak drives `glow` (brightness), not a piece-by-piece reveal.

/// The streak-driven light level. Ordered dim → radiant, with the two "unlit
/// today" waiting states and the two zero-history states called out explicitly.
enum CompanionBrightness {
  /// Brand-new user, never acted (`lastActive == null && longestStreak == 0`).
  /// "Your light is lit" — faint but clean, NEVER a cold Day 0.
  endowedDim,

  /// Has history but `currentStreak == 0` — resting, *not lost*. The cold,
  /// snuffed-wick treatment (this is the only brightness the painter renders
  /// with its dead/dormant styling).
  dormant,

  /// Not done today, before the 8pm cutoff — waiting to be lit.
  pendingUnlit,

  /// Not done today, at/after 8pm — still time, gentle (never panic).
  atRiskUnlit,

  /// Done today, streak 1–3 — just lit, faint.
  dim,

  /// Done today, streak 4–29 — warm, at ease.
  glowing,

  /// Done today, streak 30+ — radiant (rays + sparkles).
  fullyLit,
}

/// A resolved companion state: a [CompanionBrightness] plus the orthogonal freeze shield.
class CompanionState {
  const CompanionState({required this.brightness, required this.protected});

  final CompanionBrightness brightness;
  final bool protected;

  CompanionState copyWith({CompanionBrightness? brightness, bool? protected}) =>
      CompanionState(
        brightness: brightness ?? this.brightness,
        protected: protected ?? this.protected,
      );

  /// The painter inputs for this state (illum pinned 1.0; streak drives glow;
  /// wear kept clean for faint-but-fresh states).
  CompanionParams get params => _paramsFor(brightness);

  @override
  bool operator ==(Object other) =>
      other is CompanionState &&
      other.brightness == brightness &&
      other.protected == protected;

  @override
  int get hashCode => Object.hash(brightness, protected);

  @override
  String toString() =>
      'CompanionState(${brightness.name}, protected: $protected)';
}

/// The four painter inputs a [CompanionBrightness] maps to. `illum` is always 1.0 (full
/// emblem drawn); `glow` is the streak brightness; `dormant` flips the cold-dead
/// styling; `wear` is dust/tarnish (0 = pristine … 1 = grimy/cobwebbed),
/// decoupled from glow so a faint-but-fresh lamp never looks neglected.
class CompanionParams {
  const CompanionParams({
    required this.glow,
    required this.dormant,
    required this.wear,
  });

  final double glow;
  final bool dormant;
  final double wear;

  double get illum => 1.0;
}

/// CompanionBrightness → painter params (plan §1 table). `wear` is chosen per-state:
/// endowed/pending/at-risk stay near-pristine (a fresh or merely-not-yet-lit
/// lamp isn't dusty); `dim` carries the approved worn look; `glowing`/`fullyLit`
/// are clean as the streak strengthens; `dormant` is fully grimy.
CompanionParams _paramsFor(CompanionBrightness b) => switch (b) {
      CompanionBrightness.endowedDim =>
        const CompanionParams(glow: 0.20, dormant: false, wear: 0.0),
      CompanionBrightness.dormant =>
        const CompanionParams(glow: 0.0, dormant: true, wear: 1.0),
      // "Waiting to be lit" — truly UNLIT (glow 0): no flame at all, so the lamp
      // reads dark-but-intact. MUST be 0, not a small value: the flame's on/off
      // threshold is g<0.04 and the breath animation modulates g by ±10%, so any
      // glow near 0.04 makes the flame blink on/off each breath. At 0 the khatam
      // emblem still stays faintly etched (its core renders even at glow 0) and
      // the housing stays warm gold (dormant:false) — a calm waiting lamp.
      CompanionBrightness.pendingUnlit =>
        const CompanionParams(glow: 0.0, dormant: false, wear: 0.12),
      CompanionBrightness.atRiskUnlit =>
        const CompanionParams(glow: 0.0, dormant: false, wear: 0.12),
      CompanionBrightness.dim =>
        const CompanionParams(glow: 0.26, dormant: false, wear: 0.68),
      CompanionBrightness.glowing =>
        const CompanionParams(glow: 0.55, dormant: false, wear: 0.22),
      CompanionBrightness.fullyLit =>
        const CompanionParams(glow: 0.95, dormant: false, wear: 0.0),
    };
