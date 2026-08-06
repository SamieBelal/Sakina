import 'package:flutter/animation.dart';

/// Shared motion vocabulary for the reel-first onboarding (2026-07-27).
///
/// Derived from a sourced motion review rather than taste. The load-bearing
/// findings, kept here so the next person doesn't re-litigate them:
///
/// * **Calm is curve shape and short travel, not long duration.** Material 3's
///   governing rule is that duration scales with the distance travelled, so a
///   10px move stretched over 600ms reads as impeded, not serene. Small
///   translate + a strongly front-loaded decelerate is what feels expensive.
/// * **Entrances overlap, they do not queue.** Waiting for one layer to finish
///   before starting the next produces a dead frame and doubles perceived
///   length. Layers start ~140-200ms apart while the previous is still
///   settling.
/// * **Feedback must be fast even when entrances are calm.** NN/g puts simple
///   feedback near 100ms; a slow confirm on an emotionally loaded answer reads
///   as the app deliberating over what the user just admitted.
/// * **Ceilings:** NN/g says most UI motion belongs in 100-500ms and "at 500ms
///   animations start to feel like a real drag"; a staggered reveal should
///   settle inside ~800-900ms total.
/// * **No bounce anywhere in the muhasabah path.** Overshoot has to be earned
///   by a flick, and there are no flicks in a tap-through flow — on "I keep
///   sinning and going back" it would be tonally offensive.
abstract final class AppMotion {
  // ── Durations ────────────────────────────────────────────────────────────
  /// Press / selection acknowledgement. Fast on purpose.
  static const Duration feedback = Duration(milliseconds: 140);

  /// Small UI state changes.
  static const Duration quick = Duration(milliseconds: 200);

  /// Content arriving on screen.
  static const Duration entrance = Duration(milliseconds: 440);

  /// A secondary layer trailing the primary one.
  static const Duration layer = Duration(milliseconds: 400);

  /// Staggered list items — shorter than [entrance] so the tail stays inside
  /// the ~900ms budget.
  static const Duration item = Duration(milliseconds: 340);

  /// Elements receding behind a committed choice. Deliberately slower than
  /// [feedback]: fast confirm, unhurried recede.
  static const Duration recede = Duration(milliseconds: 260);

  // ── Offsets ──────────────────────────────────────────────────────────────
  /// Gap between one layer starting and the next. Trailing offsets in this
  /// range are what make a sequence read organic instead of scripted.
  static const Duration beat = Duration(milliseconds: 180);

  /// When staggered options begin — mid-way through the question's settle, so
  /// they overlap it rather than queue behind it.
  static const Duration listStart = Duration(milliseconds: 320);

  /// Per-item stagger. 30-80ms is the published band; 40 keeps a seven-item
  /// span at 240ms.
  static const Duration stagger = Duration(milliseconds: 40);

  /// Reduced motion: one frame, not zero.
  ///
  /// `flutter_animate` treats a zero-duration effect as a degenerate case in
  /// places, and 1ms is already imperceptible — the value `beat_reveal_flow`
  /// independently settled on for the canvas. Read through
  /// `MotionContext.motion()` rather than used directly.
  static const Duration collapsed = Duration(milliseconds: 1);

  // ── Curves ───────────────────────────────────────────────────────────────
  /// Material 3 "emphasized" — more front-loaded than Flutter's `easeOutCubic`
  /// (`Cubic(0.215, 0.61, 0.355, 1.0)`), whose FIRST control point sits at
  /// y=0.61. (An earlier version of this comment said "second control point
  /// tops at 0.61"; the second is at y=1.0. The direction of the argument
  /// stands, the anatomy was wrong.) The stronger curve is what allows shorter
  /// durations without the motion feeling rushed.
  ///
  /// **`beat_reveal_flow` deliberately does NOT use this**, and that is not
  /// drift. Its 450ms `easeOutCubic` beat-advance is documented as canon in
  /// `DESIGN.md §5` with its own rationale — *"small travel, soft landing — it
  /// should feel like a page settling, not a slide deck"* — and it is the motion
  /// a reader meets nine times a night. Swapping the app's signature transition
  /// for consistency's sake is a taste decision, not a cleanup, and it has no
  /// bug behind it. Leave it alone unless the founder asks.
  static const Curve enter = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Exits accelerate away; entrances decelerate in.
  static const Curve exit = Cubic(0.3, 0.0, 0.8, 0.15);

  /// Ambient loops (glow, breath). Sine in/out, never a bounce.
  static const Curve ambient = Curves.easeInOutSine;

  // ── Geometry ─────────────────────────────────────────────────────────────
  /// Entrance travel for a hero line.
  static const double riseLarge = 14;

  /// Entrance travel for a trailing layer.
  static const double riseMedium = 12;

  /// Entrance travel for list items.
  static const double riseSmall = 10;
}
