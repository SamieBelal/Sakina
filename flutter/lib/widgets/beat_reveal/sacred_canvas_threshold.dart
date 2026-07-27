import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Motion timings for crossing into and out of the emerald sacred canvas.
/// See docs/superpowers/specs/2026-07-27-sacred-canvas-threshold-design.md and
/// DESIGN.md §5.
abstract final class SacredCanvasThresholdDurations {
  /// Emerald bloom in. Long enough to read as a doorway; it plays over the AI
  /// wait on the muḥāsabah path, so it costs no perceived latency.
  static const enter = Duration(milliseconds: 700);

  /// Dissolve out. Deliberately not a contracting bloom — rewinding the
  /// entrance reads as an undo, which is wrong straight after "Ameen".
  static const exit = Duration(milliseconds: 400);

  /// Both directions when the platform asks for reduced motion.
  static const reduced = Duration(milliseconds: 150);
}

/// Animates between a surface tree (warm cream) and the emerald sacred canvas.
///
/// Entering, the canvas is revealed by a circle growing from [origin] while the
/// surface fades and settles beneath it. Leaving, the canvas simply dissolves
/// over the surface. Both trees stay mounted for the duration; the stale one is
/// dropped on completion.
///
/// [origin] is in **global** coordinates, so this widget must be the full-screen
/// root of its surface for them to coincide with its own local space — which is
/// how all three hosts use it (it wraps the whole `build()` return). Null means
/// "grow from the centre of the screen", which is correct for every entry that
/// isn't driven by a tap.
class SacredCanvasThreshold extends StatefulWidget {
  const SacredCanvasThreshold({
    super.key,
    required this.onCanvas,
    required this.child,
    this.origin,
  });

  /// Whether [child] is currently the sacred canvas. Flipping this drives the
  /// transition; the host keeps owning what [child] actually is.
  final bool onCanvas;

  /// Global centre of the bloom. Null → the centre of the screen.
  final Offset? origin;

  final Widget child;

  @override
  State<SacredCanvasThreshold> createState() => _SacredCanvasThresholdState();
}

class _SacredCanvasThresholdState extends State<SacredCanvasThreshold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// The tree being replaced — a frozen snapshot of the previous [widget.child],
  /// deliberately not rebuilt while it departs. Null whenever we're idle.
  Widget? _outgoing;

  /// Direction of the in-flight transition.
  bool _entering = false;

  /// Stable identities for the two trees. Each tree keeps its own key for its
  /// whole life, so moving between stack slots (and between the wrapped
  /// transition shape and the bare idle shape) preserves its element and state
  /// instead of remounting it.
  final GlobalKey _canvasKey = GlobalKey(debugLabel: 'sacredCanvas');
  final GlobalKey _surfaceKey = GlobalKey(debugLabel: 'sacredSurface');

  bool get _reducedMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _outgoing = null);
        }
      });
  }

  @override
  void didUpdateWidget(SacredCanvasThreshold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onCanvas == widget.onCanvas) return;

    _entering = widget.onCanvas;
    _outgoing = oldWidget.child;
    _controller
      ..duration = _reducedMotion
          ? SacredCanvasThresholdDurations.reduced
          : (_entering
              ? SacredCanvasThresholdDurations.enter
              : SacredCanvasThresholdDurations.exit)
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The key belonging to a tree, by what that tree *is* rather than where it
  /// currently sits.
  GlobalKey _keyFor({required bool isCanvas}) =>
      isCanvas ? _canvasKey : _surfaceKey;

  @override
  Widget build(BuildContext context) {
    final outgoing = _outgoing;

    // Idle: the child, bare. No clip, no opacity, no stack — an animation that
    // has finished must cost nothing.
    if (outgoing == null) {
      return KeyedSubtree(
        key: _keyFor(isCanvas: widget.onCanvas),
        child: widget.child,
      );
    }

    final incoming = KeyedSubtree(
      key: _keyFor(isCanvas: widget.onCanvas),
      child: widget.child,
    );
    final departing = KeyedSubtree(
      key: _keyFor(isCanvas: !widget.onCanvas),
      child: outgoing,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_controller.value);
        return _entering
            ? _enterStack(departing, incoming, t)
            : _exitStack(incoming, departing, t);
      },
    );
  }

  /// Surface beneath, fading and settling; canvas above, revealed by the bloom.
  Widget _enterStack(Widget surface, Widget canvas, double t) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: 1 - t,
          child: Transform.scale(scale: 1 - (0.02 * t), child: surface),
        ),
        if (_reducedMotion)
          Opacity(opacity: t, child: canvas)
        else
          ClipPath(
            clipper: _BloomClipper(origin: widget.origin, fraction: t),
            child: canvas,
          ),
      ],
    );
  }

  /// Surface beneath, already in place; canvas above, dissolving off it.
  Widget _exitStack(Widget surface, Widget canvas, double t) {
    return Stack(
      fit: StackFit.expand,
      children: [
        surface,
        Opacity(opacity: 1 - t, child: canvas),
      ],
    );
  }
}

/// Circular reveal: a disc centred on [origin] whose radius grows with
/// [fraction], reaching the farthest corner — and so covering every pixel — at 1.
class _BloomClipper extends CustomClipper<Path> {
  const _BloomClipper({required this.origin, required this.fraction});

  final Offset? origin;
  final double fraction;

  @override
  Path getClip(Size size) {
    final centre = origin ?? Offset(size.width / 2, size.height / 2);
    return Path()
      ..addOval(
        Rect.fromCircle(center: centre, radius: _coveringRadius(centre, size) * fraction),
      );
  }

  static double _coveringRadius(Offset centre, Size size) {
    final dx = math.max(centre.dx, size.width - centre.dx);
    final dy = math.max(centre.dy, size.height - centre.dy);
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  bool shouldReclip(_BloomClipper oldClipper) =>
      oldClipper.fraction != fraction || oldClipper.origin != origin;
}
