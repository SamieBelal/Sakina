import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/constants/app_motion.dart';
import '../../streaks/models/lantern_skin.dart';
import '../../streaks/widgets/lantern_ambient_shader.dart';
import '../../streaks/widgets/lantern_painter.dart';

/// The lantern catching light for the first time (One Ship W2 Wave G, spec §5).
///
/// This is the one moment in the whole app where the lamp goes from dark to
/// lit, and it happens *because of what the user just said* on the hook screen.
/// Everywhere else the companion reflects a streak it already has; here it is
/// being given.
///
/// **Why this is not a `CompanionMedallion`.** The medallion cross-fades glow
/// between two resolved [CompanionState]s on a fixed 1100ms easeOutCubic. This
/// beat needs a shaped ramp with a flare (§[kindleGlow]) and needs to cross the
/// flame threshold on a schedule the medallion's lerp cannot express. It drives
/// [LanternPainter] directly instead, reusing the shared program cache so it
/// costs no extra shader compile.
class LanternKindle extends StatefulWidget {
  const LanternKindle({
    required this.size,
    this.skin = LanternSkin.classicGold,
    this.onKindled,
    super.key,
  });

  final double size;

  /// The equipped skin. Onboarding is pre-auth, so this resolves to
  /// `classicGold` in practice — correct, since a brand-new user owns nothing.
  final LanternSkin skin;

  /// Fires once when the flame has settled, for a caller that wants to time
  /// copy or a hand-off against the light rather than a fixed delay.
  final VoidCallback? onKindled;

  @override
  State<LanternKindle> createState() => _LanternKindleState();
}

/// The glow curve, as a pure function of ramp progress `t` (0→1).
///
/// Extracted and public so it can be asserted directly rather than through
/// pumped frames — the threshold behaviour below is the kind of thing a widget
/// test samples too coarsely to catch.
///
/// Shape: a strongly front-loaded rise to [kindleFlarePeak] at
/// [kindleFlareAt], then a settle back to [kindleRestGlow]. The flare is a
/// **luminance** overshoot only — nothing moves, nothing scales — so the
/// standing "no bounce anywhere in the muḥāsabah path" rule is not in play. A
/// flame flaring as it catches is physically true; a lantern lurching in space
/// would not be. (Founder-confirmed 2026-07-28.)
///
/// ⚠️ **The flame threshold.** `LanternPainter` draws no flame below `g = 0.04`
/// and the breath pulse modulates `g` by ±10%, so a flame is only reliably lit
/// above `0.04 / 0.9 ≈ 0.0445`. A ramp that *lingers* anywhere near there makes
/// the flame blink on and off once per breath — this is exactly why
/// `pendingUnlit` is pinned to a hard `0.0` rather than a small value. The
/// front-loaded curve below clears the band in the first few milliseconds;
/// `lantern_kindle_test.dart` pins that it never dwells there.
double kindleGlow(double t) {
  final clamped = t.clamp(0.0, 1.0);
  // Pre-roll: the lamp is genuinely dark. A hard zero, never "nearly zero" —
  // the flame is off below 0.04 and anything hovering there flickers.
  if (clamped < kindleIgnitionAt) return 0;
  if (clamped <= kindleFlareAt) {
    // Catch. Starts AT [kindleIgnitionGlow] rather than easing up from zero:
    // ignition is a step change, not a fade. A wick either has taken or it has
    // not. This is both the physically true reading and the only shape that
    // clears the flame-threshold band in zero time — an eased rise out of zero
    // spent ~46ms inside it, which is nearly three frames of guttering right
    // under copy that says the lantern is lit.
    final local =
        (clamped - kindleIgnitionAt) / (kindleFlareAt - kindleIgnitionAt);
    return ui.lerpDouble(
      kindleIgnitionGlow,
      kindleFlarePeak,
      // M3 "emphasized" — far more front-loaded than easeOutCubic, so the
      // brightness surges the way a catching flame does.
      AppMotion.enter.transform(local),
    )!;
  }
  // Settle. Decelerating, so the light comes to rest rather than stopping dead.
  final local = (clamped - kindleFlareAt) / (1 - kindleFlareAt);
  return ui.lerpDouble(
    kindleFlarePeak,
    kindleRestGlow,
    Curves.easeOutCubic.transform(local),
  )!;
}

/// Where the flame settles — `endowedDim`'s glow, the true state of a user who
/// has just arrived and not yet acted.
const double kindleRestGlow = 0.34;

/// Peak of the catch, before it settles back.
const double kindleFlarePeak = 0.45;

/// Fraction of the ramp held dark before the wick takes.
///
/// Short, but not nothing: the eye needs to register an unlit lamp for the
/// lighting to read as a change rather than as the screen simply appearing.
const double kindleIgnitionAt = 0.08;

/// The glow the flame takes at, in one step.
///
/// Must clear `0.04 / 0.9 ≈ 0.0445` — the flame threshold at the bottom of the
/// breath cycle — by a wide enough margin that no phase of the pulse can dip it
/// back under. 0.10 is a little over twice that.
const double kindleIgnitionGlow = 0.10;

/// Fraction of the ramp spent rising to the peak.
const double kindleFlareAt = 0.55;

/// Total ramp duration. Deliberately longer than a normal entrance: this is
/// the beat the screen exists for, not a transition between two others.
const Duration kindleDuration = Duration(milliseconds: 900);

class _LanternKindleState extends State<LanternKindle>
    with TickerProviderStateMixin {
  late final AnimationController _kindle = AnimationController(
    vsync: this,
    duration: kindleDuration,
  );

  // Matches the companion's 2.6s breath so the lamp reads as the same object
  // the user will meet on the home screen.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  ui.FragmentShader? _shader;
  bool _kindledFired = false;

  @override
  void initState() {
    super.initState();
    _loadShader();
    _pulse.repeat();
    _kindle.addStatusListener(_onKindleStatus);
    // Start on the next frame, not in initState: the canvas threshold's bloom
    // is still landing, and a flame that catches underneath it is a moment the
    // user never sees.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _kindle.forward();
    });
  }

  void _onKindleStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _kindledFired) return;
    _kindledFired = true;
    widget.onKindled?.call();
  }

  Future<void> _loadShader() async {
    final shader = await LanternAmbientShader.shader();
    if (shader != null && mounted) setState(() => _shader = shader);
  }

  @override
  void dispose() {
    _kindle.removeStatusListener(_onKindleStatus);
    _kindle.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reduce motion drops the flare and the breath, not the lighting itself:
    // the state change is information, and removing it would leave the user
    // looking at a dark lamp with copy claiming it is lit. The vestibular risk
    // lives in movement, and there is none here either way.
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: Listenable.merge([_kindle, _pulse]),
          builder: (context, _) {
            final glow = reduceMotion
                ? kindleRestGlow * Curves.easeOut.transform(_kindle.value)
                : kindleGlow(_kindle.value);
            return CustomPaint(
              painter: LanternPainter(
                illumination: 1,
                glow: glow,
                // Pristine, never `dormant: true`. The cold snuffed-wick
                // treatment is for a lapsed streak; a lamp about to be lit for
                // the very first time must never read as neglected (the
                // "never a cold Day 0" guardrail from the companion plan).
                wear: 0,
                dormant: false,
                protected: false,
                pulse: reduceMotion ? 0.5 : _pulse.value,
                ambientShader: _shader,
                // The kindling beat lives on the dark sacred canvas, so the
                // aura belongs here (it would render as a grey box on cream).
                ambient: true,
                skin: widget.skin,
              ),
            );
          },
        ),
      ),
    );
  }
}
