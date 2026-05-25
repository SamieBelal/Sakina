import 'package:flutter/widgets.dart';

/// One step in a coachmark sequence. The target's render box is read at
/// overlay-build time; if the target hasn't been laid out yet, the overlay
/// falls back to a centered card with no cutout.
class CoachmarkStep {
  const CoachmarkStep({
    required this.target,
    required this.message,
    this.tooltipBelow = true,
  });

  /// The widget the coachmark anchors to. Caller is responsible for the
  /// key's lifetime — per-screen ownership is the convention here.
  final GlobalKey target;

  /// Body copy. Keep to ≤ 14 words.
  final String message;

  /// If true, tooltip card sits below the cutout. If false, above.
  final bool tooltipBelow;
}
