import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

const Duration kOrnateCardShimmerDuration = Duration(milliseconds: 2200);

class OrnateCardShimmer {
  const OrnateCardShimmer({
    this.enabled = true,
    this.controller,
    this.duration = kOrnateCardShimmerDuration,
  });

  final bool enabled;
  final AnimationController? controller;
  final Duration duration;
}

Widget applyOrnateCardShimmer({
  required Widget child,
  required Color color,
  required bool legacyEnabled,
  OrnateCardShimmer? shimmer,
}) {
  final bool shouldShimmer = shimmer?.enabled ?? legacyEnabled;
  if (!shouldShimmer) return child;

  final AnimationController? controller = shimmer?.controller;
  final Duration duration = shimmer?.duration ?? kOrnateCardShimmerDuration;

  return child
      .animate(
        autoPlay: controller == null,
        controller: controller,
        onPlay: controller == null ? (c) => c.repeat(reverse: true) : null,
      )
      .shimmer(
        duration: duration,
        color: color,
      );
}
