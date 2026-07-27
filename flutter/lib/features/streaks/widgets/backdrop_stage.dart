// Composes a backdrop + a foreground child (the lantern medallion) with the
// perf split from spec §13.10: the STATIC backdrop layer is painted once inside
// its own RepaintBoundary (raster-cached), the small ANIMATED layer repaints per
// pulse inside a second RepaintBoundary, and the child sits on top. This is the
// production Companion-stage surface; Lane D's CompanionScreen wraps it.

import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:sakina/features/streaks/models/backdrop.dart';
import 'package:sakina/features/streaks/widgets/backdrop_painter.dart';

class CompanionStage extends StatefulWidget {
  const CompanionStage({
    super.key,
    required this.backdrop,
    required this.child,
    this.animate = true,
  });

  final Backdrop backdrop;

  /// Foreground (the lantern medallion + status line, supplied by the screen).
  final Widget child;

  /// When false the twinkle/drift never runs (static frame — tests / thumbnails).
  final bool animate;

  @override
  State<CompanionStage> createState() => _CompanionStageState();
}

class _CompanionStageState extends State<CompanionStage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6), // slow, ambient drift
  );
  bool _visible = true;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncPulse();
  }

  @override
  void didUpdateWidget(CompanionStage old) {
    super.didUpdateWidget(old);
    if (old.animate != widget.animate) _syncPulse();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncPulse();
  }

  void _syncPulse() {
    final run = widget.animate && _visible && _foreground;
    if (run) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      if (_pulse.isAnimating) _pulse.stop();
    }
  }

  void _onVisibility(VisibilityInfo info) {
    final v = info.visibleFraction > 0.05;
    if (v != _visible) {
      _visible = v;
      _syncPulse();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: ValueKey('companion-stage-${identityHashCode(this)}'),
      onVisibilityChanged: _onVisibility,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Static scene — painted once, cached.
          RepaintBoundary(
            child: CustomPaint(
              painter: BackdropPainter(
                backdrop: widget.backdrop,
                layer: BackdropLayer.static_,
              ),
            ),
          ),
          // Animated overlay — the only per-frame repaint.
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => CustomPaint(
                painter: BackdropPainter(
                  backdrop: widget.backdrop,
                  pulse: _pulse.value,
                  layer: BackdropLayer.animated,
                ),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}
