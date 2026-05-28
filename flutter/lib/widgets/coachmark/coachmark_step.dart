import 'package:flutter/widgets.dart';

/// One step in a coachmark sequence. The target's render box is read at
/// overlay-build time; if the target hasn't been laid out yet, the overlay
/// falls back to a centered card with no cutout.
class CoachmarkStep {
  const CoachmarkStep({
    required this.target,
    required this.message,
    this.tooltipBelow = true,
    this.interactive = true,
    this.hint,
    this.cutoutPaddingTop = 0,
  });

  /// The widget the coachmark anchors to. Caller is responsible for the
  /// key's lifetime — per-screen ownership is the convention here.
  ///
  /// May be null on the final step when the tooltip is centered (no anchor).
  final GlobalKey? target;

  /// Body copy. Keep to ≤ 14 words.
  final String message;

  /// If true, tooltip card sits below the cutout. If false, above.
  final bool tooltipBelow;

  /// When true, the cutout is tap-through and the tour advances on the next
  /// pointer-up inside the cutout rect (no "Next" button is shown). When
  /// false, the tooltip renders a "Continue" button and taps inside the
  /// cutout are absorbed by the scrim — used for teach moments.
  final bool interactive;

  /// Optional secondary line under the message, e.g. "Tap to continue ↗".
  /// Renders in primary color (emerald) at smaller size.
  final String? hint;

  /// Pixels to extend the cutout rect upward beyond the target. Used when
  /// the cutout should highlight a related widget that lives above the
  /// tap target (e.g. Duas Build step extends upward to include the text
  /// field). Default 0 = cutout matches target exactly.
  final double cutoutPaddingTop;
}
