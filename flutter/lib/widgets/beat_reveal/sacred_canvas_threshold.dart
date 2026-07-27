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

  /// The two trees, tracked by what each one *is* rather than derived from the
  /// current [widget.onCanvas]. A transition must keep animating the same pair
  /// even when the flag flips underneath it mid-flight — deriving the roles
  /// from the live flag would swap them halfway and clip the wrong tree.
  /// Whichever tree the host isn't currently handing us stays frozen at the
  /// frame the transition began.
  Widget? _canvasChild;
  Widget? _surfaceChild;

  /// True while a transition is in flight, including one that is unwinding.
  bool _transitioning = false;

  /// Which direction the in-flight transition *began* in. A reversal does not
  /// change it: a reversed enter is still an enter, played backwards.
  bool _entering = false;

  /// Reduced motion, latched for the duration of one transition. The controller's
  /// duration is fixed when the transition starts, so re-reading the live value
  /// at render time could pair a 700ms controller with the 150ms cross-fade
  /// shape if the OS setting flips mid-animation.
  bool _transitionReduced = false;

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
        if (!mounted) return;
        // `completed` is a transition that landed; `dismissed` is one that was
        // reversed all the way back to where it started. Both are resting
        // states — settling on either drops us to the cheap idle path.
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          setState(() => _transitioning = false);
        }
      });
  }

  @override
  void didUpdateWidget(SacredCanvasThreshold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onCanvas == widget.onCanvas) return;

    // Flipped mid-flight (e.g. the user backs out while the bloom is still
    // growing): change the direction of the animation we're already playing
    // instead of starting a new one. Restarting would snap a half-grown circle
    // to a full-screen canvas and only then fade it. The reversal rides the
    // duration it started with rather than swapping enter's 700ms for exit's
    // 400ms — swapping would visibly change speed halfway through one gesture.
    if (_transitioning) {
      if (widget.onCanvas == _entering) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
      return;
    }

    _entering = widget.onCanvas;
    _transitioning = true;
    _transitionReduced = _reducedMotion;
    _controller
      ..duration = _transitionReduced
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
    // Record whichever tree the host is handing us this frame. The other slot
    // keeps the last tree of its kind, frozen — that's what we animate against.
    if (widget.onCanvas) {
      _canvasChild = widget.child;
    } else {
      _surfaceChild = widget.child;
    }

    // Idle: the child, bare. No clip, no opacity, no stack — an animation that
    // has finished must cost nothing.
    if (!_transitioning) {
      return KeyedSubtree(
        key: _keyFor(isCanvas: widget.onCanvas),
        child: widget.child,
      );
    }

    final canvas = KeyedSubtree(
      key: _canvasKey,
      child: _canvasChild ?? const SizedBox.shrink(),
    );
    final surface = KeyedSubtree(
      key: _surfaceKey,
      child: _surfaceChild ?? const SizedBox.shrink(),
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_controller.value);
        return _entering
            ? _enterStack(surface, canvas, t)
            : _exitStack(surface, canvas, t);
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
        if (_transitionReduced)
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
  ///
  /// The dissolving canvas is wrapped in [IgnorePointer] because `Opacity` does
  /// not gate hit-testing: a canvas faded to invisible would still sit on top of
  /// the surface and swallow every tap for the whole exit. It is on its way out
  /// and should never take input. (The enter path needs no equivalent — the
  /// growing canvas is under a `ClipPath`, which *does* restrict hit-testing to
  /// the clipped region, so the surface stays live outside the bloom.)
  Widget _exitStack(Widget surface, Widget canvas, double t) {
    return Stack(
      fit: StackFit.expand,
      children: [
        surface,
        IgnorePointer(child: Opacity(opacity: 1 - t, child: canvas)),
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
