import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:sakina/features/streaks/models/companion_state.dart';
import 'package:sakina/features/streaks/models/lantern_skin.dart';
import 'package:sakina/features/streaks/widgets/lantern_ambient_shader.dart';
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
    this.skin = LanternSkin.classicGold,
    this.animate = true,
    this.ambient = true,
  });

  final CompanionState state;
  final double size;

  /// The cosmetic material palette + form. Defaults to the production classic
  /// gold so existing call sites (which omit it) render exactly as before.
  final LanternSkin skin;

  /// When false the pulse never runs (a static frame — e.g. tests / thumbnails).
  final bool animate;

  /// Whether to paint the full-canvas ambient background (lit aura / dormant
  /// vignette). Leave true on dark/immersive surfaces; set false on light cards
  /// (e.g. the rescue sheet) so the dormant vignette doesn't show as a grey box.
  final bool ambient;

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
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadShader();
    // The pulse is started from didChangeDependencies, not here: _syncPulse
    // reads MediaQuery (for reduce-motion), and an inherited-widget lookup
    // during initState is illegal.
  }

  /// The program compile is shared process-wide (see [LanternAmbientShader]);
  /// this instance still owns its own shader, which carries per-frame uniforms.
  Future<void> _loadShader() async {
    final shader = await LanternAmbientShader.shader();
    if (shader != null && mounted) setState(() => _shader = shader);
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cached, not read inside _syncPulse: that method is also driven by the
    // visibility and lifecycle callbacks, which can fire after this State is
    // unmounted — and touching `context` there throws. Re-read here so a user
    // toggling reduce-motion in Settings still takes effect live.
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _syncPulse();
  }

  /// Run the pulse only when it can actually be seen — visible, foregrounded,
  /// the caller wants motion, and the platform hasn't asked for less of it.
  ///
  /// The reduce-motion clause matters twice over. It is the correct
  /// accessibility behaviour — a glow that breathes forever is exactly the
  /// ambient, unprompted motion the setting exists to suppress — and it is what
  /// makes any screen hosting the companion testable at all: an unbounded
  /// `repeat()` means `pumpAndSettle` never returns.
  void _syncPulse() {
    final shouldRun =
        widget.animate && _visible && _foreground && !_reduceMotion;
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
                  ambient: widget.ambient,
                  skin: widget.skin,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
