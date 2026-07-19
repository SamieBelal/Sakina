import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:sakina/features/streaks/models/companion_state.dart';
import 'package:sakina/features/streaks/widgets/lantern_painter.dart';

/// The living lantern companion, driven by a resolved [CompanionState].
///
/// - Full khatam always drawn; the streak drives `glow`, which **lerps** on a
///   state change (a dim lamp brightens into a lit one, never a hard cut).
/// - Animation is **bounded** (plan finding #12): the breath pulse pauses when
///   the medallion scrolls offscreen (`VisibilityDetector`) or the app is
///   backgrounded (lifecycle), and everything is wrapped in a `RepaintBoundary`
///   so the blur+bloom+shader repaint never dirties siblings.
class CompanionMedallion extends StatefulWidget {
  const CompanionMedallion({
    super.key,
    required this.state,
    required this.size,
    this.animate = true,
  });

  final CompanionState state;
  final double size;

  /// When false the pulse never runs (a static frame — e.g. tests / thumbnails).
  final bool animate;

  @override
  State<CompanionMedallion> createState() => _CompanionMedallionState();
}

class _CompanionMedallionState extends State<CompanionMedallion>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // 2.6s breath — the calm cadence the states were tuned against.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  // Glow/wear cross-fade when the state changes.
  late final AnimationController _transition = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..value = 1;

  late double _fromGlow = widget.state.params.glow;
  late double _fromWear = widget.state.params.wear;

  ui.FragmentShader? _shader;
  bool _visible = true;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadShader();
    _syncPulse();
  }

  Future<void> _loadShader() async {
    try {
      final program =
          await ui.FragmentProgram.fromAsset('shaders/khatam_glow.frag');
      if (mounted) setState(() => _shader = program.fragmentShader());
    } catch (e) {
      // The painter renders fine without the ambient aura — best-effort.
      debugPrint('companion shader load failed: $e');
    }
  }

  @override
  void didUpdateWidget(CompanionMedallion old) {
    super.didUpdateWidget(old);
    if (old.state.params.glow != widget.state.params.glow ||
        old.state.params.wear != widget.state.params.wear) {
      // Start the cross-fade from wherever the current animated value sits, so
      // rapid re-targets don't jump.
      final t = Curves.easeOutCubic.transform(_transition.value);
      _fromGlow = ui.lerpDouble(_fromGlow, old.state.params.glow, t)!;
      _fromWear = ui.lerpDouble(_fromWear, old.state.params.wear, t)!;
      _transition.forward(from: 0);
    }
    if (old.animate != widget.animate) _syncPulse();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncPulse();
  }

  /// Run the pulse only when it can actually be seen — visible, foregrounded,
  /// and the caller wants motion. Otherwise stop it (no offscreen repaint).
  void _syncPulse() {
    final shouldRun = widget.animate && _visible && _foreground;
    if (shouldRun) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      if (_pulse.isAnimating) _pulse.stop();
    }
  }

  void _onVisibility(VisibilityInfo info) {
    final visible = info.visibleFraction > 0.05;
    if (visible != _visible) {
      _visible = visible;
      _syncPulse();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulse.dispose();
    _transition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.state.params;
    return VisibilityDetector(
      key: ValueKey('companion-medallion-${identityHashCode(this)}'),
      onVisibilityChanged: _onVisibility,
      child: RepaintBoundary(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulse, _transition]),
            builder: (context, _) {
              final t = Curves.easeOutCubic.transform(_transition.value);
              final glow = ui.lerpDouble(_fromGlow, target.glow, t)!;
              final wear = ui.lerpDouble(_fromWear, target.wear, t)!;
              return CustomPaint(
                painter: LanternPainter(
                  illumination: target.illum,
                  glow: glow,
                  wear: wear,
                  dormant: target.dormant,
                  protected: widget.state.protected,
                  pulse: _pulse.value,
                  ambientShader: _shader,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
