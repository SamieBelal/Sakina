import 'package:flutter/widgets.dart';

/// One step in a coachmark sequence. The target's render box is read at
/// overlay-build time; if the target hasn't been laid out yet, the overlay
/// falls back to a centered card with no cutout.
class CoachmarkStep {
  const CoachmarkStep({
    required this.target,
    required this.message,
    this.interactive = true,
    this.hint,
    this.autoAdvance,
    this.cutoutPaddingTop = 0,
    this.cutoutPaddingBottom = 0,
    this.cutoutPaddingX = 0,
  });

  /// The widget the coachmark anchors to. Caller is responsible for the
  /// key's lifetime — per-screen ownership is the convention here.
  ///
  /// May be null on the final step when the tooltip is centered (no anchor).
  final GlobalKey? target;

  /// Body copy. Keep to ≤ 14 words.
  final String message;

  /// When true, the cutout is tap-through and the tour advances on the next
  /// pointer-up inside the cutout rect (no "Next" button is shown). When
  /// false, the tooltip renders a "Continue" button and taps inside the
  /// cutout are absorbed by the scrim — used for teach moments.
  final bool interactive;

  /// Optional secondary line under the message, e.g. "Tap to continue ↗".
  /// Renders in primary color (emerald) at smaller size.
  final String? hint;

  /// When non-null, this is a read-only step with nothing to tap — the overlay
  /// advances itself after this delay (e.g. the streak beat, the final wrap-up).
  /// Suppressed under a screen reader, where the banner shows a Continue instead.
  final Duration? autoAdvance;

  /// Pixels to extend the cutout rect upward beyond the target. Used when
  /// the cutout should highlight a related widget that lives above the
  /// tap target (e.g. Duas Build step extends upward to include the text
  /// field). Default 0 = cutout matches target exactly.
  final double cutoutPaddingTop;

  /// Pixels to extend the cutout rect downward beyond the target — used to
  /// grow a small anchor (e.g. a bottom-nav icon) into its full cell so the
  /// label below is included. Default 0.
  final double cutoutPaddingBottom;

  /// Pixels to expand the cutout on both horizontal sides beyond the target.
  /// Pairs with [cutoutPaddingBottom] for a full tab-cell highlight. Default 0.
  final double cutoutPaddingX;
}
