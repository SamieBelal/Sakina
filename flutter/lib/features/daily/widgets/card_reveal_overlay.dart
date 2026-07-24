import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/daily/reveal/painters/background_painters.dart';
import 'package:sakina/features/daily/reveal/painters/card_fx_painters.dart';
import 'package:sakina/features/daily/reveal/reveal_card_tile.dart';
import 'package:sakina/features/daily/reveal/reveal_geometry.dart';
import 'package:sakina/features/daily/reveal/reveal_spec.dart';
import 'package:sakina/features/streaks/models/companion_state.dart';
import 'package:sakina/features/streaks/widgets/companion_medallion.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/card_collection_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CARD REVEAL OVERLAY — the tiered gacha hero moment (Bronze→Emerald).
//
// Self-contained, native (no new Lottie yet) so every beat is tunable live via
// the seg() windows in reveal_geometry.dart. Choreography (single controller,
// D = _revealDuration):
//   idle          → unlit lantern, waits for a tap
//   ignite        → tier colour + god-rays gather around the lamp
//   burst         → flash + radial shafts + expanding rings + sparks (heavy haptic)
//   forge/spin    → card is forged white-hot from the nūr, cools, spins 360°×N
//   settle        → overshoot land, shine + lens-flare, TIER badge staggers in
//   rest          → breathing aurora + floating embers keep it alive
//
// The choreography (normalized 0→1 seg windows) is SHARED across tiers; only the
// wall-clock `duration`, feature intensities/toggles, spin turns, spark count
// and haptics change — all driven by the injected [RevealSpec]. Emerald's spec
// sets every toggle to max (all 1.0, halo true, 30 sparks, 3 spins, legendary
// haptics) so it reproduces the approved Emerald spike exactly.
//
// The pure choreography math (card motion, seg/bell, phase constants, the
// ray-fan idiom, the particle field) lives in reveal_geometry.dart; the FX
// painters live in reveal/painters/. This file keeps only the widget, its State,
// and the caption/card-face/shimmer sub-widgets.
//
// In production the FX layers may move to authored Lottie; the CARD + spin stay
// native (data-driven Arabic). Tier colour lives only in OUR fx layers.
// ─────────────────────────────────────────────────────────────────────────────

class CardRevealOverlay extends StatefulWidget {
  /// Route name used both for the push `RouteSettings` and the tour's
  /// `blockingRouteNames` guard. Keep these in lockstep via this single const —
  /// a mismatch silently breaks the guided-tour "don't punch through" guard.
  static const String routeName = 'CardRevealOverlay';

  const CardRevealOverlay({
    super.key,
    required this.card,
    required this.spec,
    this.onContinue,
    this.onEvent,
    this.autoStart = false,
  });

  final CollectibleName card;
  final RevealSpec spec;
  final VoidCallback? onContinue;

  /// Analytics dispatch hook (no Riverpod in this pushed-route widget). The
  /// muḥāsabah caller wires this to the app's analytics track; dev/preview
  /// callers pass nothing, so no events fire from the debug loop.
  final void Function(String name, Map<String, Object?> props)? onEvent;

  /// Debug/verification only: begin the sequence without a tap, and loop it so
  /// screenshots can catch every beat. Never set from the real reveal flow.
  final bool autoStart;

  @override
  State<CardRevealOverlay> createState() => _CardRevealOverlayState();
}

class _CardRevealOverlayState extends State<CardRevealOverlay>
    with TickerProviderStateMixin {
  // Total length of the reveal — spectacle length IS the rarity signal
  // (Clash Royale principle); Emerald is the longest by design.
  Duration get _revealDuration => widget.spec.duration;

  late final AnimationController _reveal; // one-shot, driven on tap
  late final AnimationController _ambient; // looping (breathing + drift)

  bool _started = false;
  bool _dismissed = false;
  // OS "reduce animation" — resolved in _open() (MediaQuery isn't safe in
  // initState). When true the spectacle collapses to an instant settle and the
  // long haptic ratchet / autoStart restart loop are skipped (no timers linger).
  bool _reduceMotion = false;
  // Measures dwell (shown → continued) for the reveal telemetry. Started in
  // _open(); read in _continue().
  final Stopwatch _dwell = Stopwatch();
  late final List<Spark> _sparks = buildSparks(widget.spec.sparkCount);
  late final List<Mote> _motes = buildMotes(widget.spec.moteCount);

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(vsync: this, duration: _revealDuration);
    // NOT started here: the ambient loop is kicked off in _open() (once
    // _reduceMotion is resolved) and — critically — STOPPED again the moment the
    // reveal settles, so the full-screen blurred/additive FX stack stops
    // repainting at rest (real on-device battery/GPU win). See #001.
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    // Rest-state freeze: once the reveal has fully settled we no longer need the
    // ambient ticker for the interactive path — freeze breath/rotation/motes at
    // their current values (the settled frame is calm). autoStart's debug loop
    // restarts both controllers, so it keeps animating.
    _reveal.addStatusListener(_onRevealStatus);

    if (widget.autoStart && kDebugMode) {
      // Debug/verification only: open without a tap.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _open();
      });
    }
  }

  void _onRevealStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    if (widget.autoStart && kDebugMode && !_reduceMotion) {
      // Loop the whole sequence so timed screenshots catch every beat. Restart
      // BOTH controllers (the ambient was stopped at the previous settle).
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        if (!_ambient.isAnimating) _ambient.repeat();
        _reveal.forward(from: 0);
        _scheduleHaptics();
      });
    } else {
      // Interactive / reduced-motion path: settle → stop the ambient loop so the
      // rested FX stack no longer repaints every frame.
      _ambient.stop();
    }
  }

  @override
  void dispose() {
    _reveal.removeStatusListener(_onRevealStatus);
    _reveal.dispose();
    _ambient.dispose();
    super.dispose();
  }

  void _open() {
    if (_started) return;
    // Reduced motion (OS "reduce animation"): collapse the whole normalized
    // timeline into a short fade so it resolves straight to the settled card +
    // Continue, skipping the long spin/particle spectacle. All seg() windows
    // still resolve — just fast. MediaQuery is safe to read here (called from a
    // tap or a post-frame callback, never initState). The default
    // (disableAnimations false) path is untouched.
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    // Ambient loop (breath/drift/rotation) only runs under normal motion. Under
    // reduced motion the reveal snaps to a static settle, so there's nothing to
    // drive (and starting it would contradict the a11y intent + leave a ticker
    // running). See #001 / #014.
    if (!_reduceMotion) {
      _ambient.repeat();
    }
    setState(() => _started = true);
    _dwell
      ..reset()
      ..start();
    widget.onEvent?.call(AnalyticsEvents.cardRevealShown, {
      'tier': widget.spec.tier.label,
      'dwell_ms': 0,
      'auto': widget.autoStart,
    });
    HapticFeedback.mediumImpact();
    if (_reduceMotion) {
      // Reduced motion: skip the spin/particle spectacle AND the long haptic
      // ratchet. Snap the shared timeline to the settle so the card + "Tap to
      // continue" are present immediately (a plain cut to the settled card,
      // wrapped in the overlay's own route fade). No dependence on ticker
      // elapsed time and no lingering timers.
      _reveal.value = 1.0;
    } else {
      _reveal.forward();
      _scheduleHaptics();
    }
  }

  // Haptic tattoo tuned to the beats, escalating with the tier's [HapticProfile].
  // The `legendary` (Emerald) case fires a RATCHET of clicks that widen as the
  // spin decelerates (fast→slow), so it feels mechanical/weighty even though
  // we're haptics-only — unchanged from the approved spike. Guarded by mounted.
  void _scheduleHaptics() {
    void at(double frac, VoidCallback fn) {
      Future.delayed(_revealDuration * frac, () {
        if (mounted) fn();
      });
    }

    switch (widget.spec.haptics) {
      case HapticProfile.light:
        at(0.30, HapticFeedback.selectionClick);
        at(0.55, HapticFeedback.mediumImpact); // small pop
        at(0.90, HapticFeedback.lightImpact);
        break;
      case HapticProfile.medium:
        at(0.25, HapticFeedback.selectionClick);
        at(0.48, HapticFeedback.heavyImpact); // burst
        at(0.70, HapticFeedback.selectionClick);
        at(0.90, HapticFeedback.lightImpact);
        break;
      case HapticProfile.rich:
        at(0.22, HapticFeedback.selectionClick);
        at(0.44, HapticFeedback.heavyImpact);
        for (final f in [0.56, 0.64, 0.72, 0.80]) {
          at(f, HapticFeedback.selectionClick);
        }
        at(0.88, HapticFeedback.heavyImpact);
        at(0.96, HapticFeedback.lightImpact);
        break;
      case HapticProfile.legendary:
        // the tuned Emerald ratchet (unchanged from the approved spike)
        at(0.18, HapticFeedback.selectionClick); // rays gathering
        at(0.30, HapticFeedback.selectionClick);
        at(0.42, HapticFeedback.heavyImpact); // the burst
        // Ratchet across the spin — widening gaps as it slows.
        for (final f in [0.50, 0.56, 0.62, 0.68]) {
          at(f, HapticFeedback.selectionClick);
        }
        at(0.74, HapticFeedback.lightImpact);
        at(0.80, HapticFeedback.lightImpact);
        at(0.86, HapticFeedback.heavyImpact); // card lands
        at(0.96, HapticFeedback.lightImpact); // name settles
        break;
    }
  }

  bool get _interactive => _reveal.value >= 0.95;

  void _handleTap() {
    if (!_started) {
      _open();
      return;
    }
    if (_interactive) {
      _continue();
      return;
    }
    // Tap-to-skip (all tiers): a mid-reveal tap snaps the timeline to the
    // settle so the card + Continue appear immediately. A subsequent tap (now
    // _interactive) continues — so this never double-fires onContinue.
    _reveal
      ..stop()
      ..value = 1.0;
  }

  void _continue() {
    if (_dismissed) return;
    _dismissed = true;
    final dwellMs = _dwell.elapsedMilliseconds;
    _dwell.stop();
    widget.onEvent?.call(AnalyticsEvents.cardRevealCompleted, {
      'tier': widget.spec.tier.label,
      'dwell_ms': dwellMs,
      'auto': widget.autoStart,
    });
    HapticFeedback.lightImpact();
    if (widget.onContinue != null) {
      widget.onContinue!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: revealCanvas,
      body: GestureDetector(
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_reveal, _ambient]),
          builder: (context, _) {
            final t = _reveal.value;
            final breath = 0.5 + 0.5 * math.sin(_ambient.value * 2 * math.pi);
            final spin = _ambient.value * 2 * math.pi;
            final spec = widget.spec;
            final palette = spec.palette;
            return SizedBox.expand(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1 ── Atmosphere: darken + tier-coloured pool + focus vignette.
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: AtmospherePainter(
                          darken: seg(t, 0.34, 0.58),
                          pool: seg(t, 0.50, 0.92),
                          breath: breath,
                          color: palette.color,
                        ),
                      ),
                    ),
                  ),

                  // 2 ── Tier god-rays growing out of the lantern (the tease).
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: LanternRaysPainter(
                          grow: seg(t, 0.05, 0.34) * spec.godRays,
                          fade: 1 - seg(t, 0.40, 0.50),
                          rotation: spin,
                          color: palette.glow,
                          rayCount: spec.godRayCount,
                        ),
                      ),
                    ),
                  ),

                  // 3 ── Aurora rays — bloom at the burst, then SETTLE to a
                  //      breathing floor (never fully dies → the rest stays alive).
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: AuroraPainter(
                          rotation: spin,
                          opacity: seg(t, 0.42, 0.56) *
                              (1 - 0.55 * seg(t, 0.88, 1.0)) *
                              (0.9 + 0.1 * breath) *
                              spec.aurora,
                          bright: palette.bright,
                        ),
                      ),
                    ),
                  ),

                  // 4 ── Burst: flash + hard radial shafts + expanding rings.
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: BurstPainter(
                          rings: seg(t, 0.38, 0.66),
                          flash: bell(seg(t, 0.38, 0.52)),
                          shafts: bell(seg(t, 0.40, 0.56)) * spec.radialShafts,
                          rotation: spin,
                          color: palette.bright,
                          glow: palette.glow,
                          shaftCount: spec.shaftCount,
                        ),
                      ),
                    ),
                  ),

                  // 5 ── Sparks flung outward from the break.
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: SparkPainter(
                          sparks: _sparks,
                          progress: seg(t, 0.40, 0.78),
                          bright: palette.bright,
                        ),
                      ),
                    ),
                  ),

                  // 6 ── Halo ring behind the settled card (emerald-only flourish).
                  if (spec.halo && t > 0.80)
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: HaloPainter(
                            rotation: spin,
                            opacity: seg(t, 0.82, 0.96) * (0.85 + 0.15 * breath),
                            bright: palette.bright,
                          ),
                        ),
                      ),
                    ),

                  // 7 ── Floating embers around the rested card (persistent life).
                  if (spec.restMotes > 0 && t > 0.80)
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: MotePainter(
                            motes: _motes,
                            phase: _ambient.value,
                            opacity: seg(t, 0.84, 0.97) * spec.restMotes,
                            bright: palette.bright,
                          ),
                        ),
                      ),
                    ),

                  // 8 ── The vessel (lantern) OR the card.
                  if (t < kCardSwap)
                    _buildLantern(t)
                  else
                    _buildCard(t, breath),

                  // 9 ── Name + badge + continue (staggered in after settle).
                  if (t > kCaptionIn) _buildCaption(t),

                  // 10 ── Idle hint.
                  if (!_started) _buildHint(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── The vessel: the real illustrated lantern companion (CompanionMedallion).
  // Starts UNLIT (no flame, no aura, no colour); on tap the tier colour floods
  // in AROUND it, the flame catches, and it erupts + dissolves into the burst.
  Widget _buildLantern(double t) {
    final palette = widget.spec.palette;
    final swell = seg(t, 0.0, 0.30); // extended: tier colour + rays gather
    final flare = seg(t, 0.34, kCardSwap); // erupts + dissolves into the burst
    final shiver = _started ? math.sin(t * 70) * swell * 2.2 : 0.0;
    final scale = 1.0 + swell * 0.12 + flare * 0.6;
    final opacity = (1.0 - flare).clamp(0.0, 1.0);
    final charge = (swell * 0.7 + flare).clamp(0.0, 1.4);

    final lampState = _started
        ? const CompanionState(
            brightness: CompanionBrightness.glowing, protected: false)
        : const CompanionState(
            brightness: CompanionBrightness.pendingUnlit, protected: false);

    return Transform.translate(
      offset: Offset(shiver, 0),
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: SizedBox(
            width: 260,
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (charge > 0.01)
                  Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.45 * charge),
                          palette.bright.withValues(alpha: 0.42 * charge),
                          palette.glow.withValues(alpha: 0.12 * charge),
                          palette.glow.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.32, 0.6, 1.0],
                      ),
                    ),
                  ),
                // Illustrated geometry is static; only the outer Transform /
                // Opacity animate, so cache its raster (#014).
                RepaintBoundary(
                  child: CompanionMedallion(
                    state: lampState,
                    size: 190,
                    ambient: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── The Emerald card: forged white-hot from the nūr → decelerating 360°×N
  // Y-spin with a settle overshoot → holographic foil + rotation-synced glint →
  // lands with a lens-flare and a breathing glow.
  Widget _buildCard(double t, double breath) {
    final size = MediaQuery.of(context).size;
    final cardW = math.min(248.0, size.width * 0.64);
    final cardH = cardW / 0.72;

    final spec = widget.spec;
    final palette = spec.palette;

    // All timeline-driven transform inputs come from the pure choreography fn.
    final m = revealCardMotion(spec, t, _ambient.value);

    // Idle bob depends only on the ambient loop (not the reveal timeline), so it
    // stays here rather than in the pure motion fn.
    final bob = t >= 0.95 ? math.sin(_ambient.value * 2 * math.pi) * 4 : 0.0;

    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0012) // perspective
      ..rotateY(m.angle);

    return Transform.translate(
      offset: Offset(0, m.settleY + bob),
      child: Opacity(
        opacity: m.appear.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: (0.2 + m.appear * 0.8).clamp(0.0, 1.1) + m.pop,
          child: Transform(
            alignment: Alignment.center,
            transform: matrix,
            child: SizedBox(
              width: cardW,
              height: cardH,
              child: m.facingFront
                  ? _CardFace(
                      card: widget.card,
                      tier: spec.tier,
                      shine: spec.shineSweep ? seg(t, 0.87, 0.97) : 0,
                      birth: spec.forgeBirth
                          ? (1 - seg(t, 0.47, 0.62)).clamp(0.0, 1.0)
                          : 0,
                      foil: spec.foil,
                      foilPhase: m.foilPhase,
                      spinTilt: m.spinTilt,
                      flare: bell(seg(t, 0.86, 0.95)) * spec.lensFlare,
                      glowBreath: breath,
                      glow: palette.glow,
                      bright: palette.bright,
                    )
                  : RevealCardBack(tier: spec.tier),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaption(double t) {
    final palette = widget.spec.palette;
    // Staggered reveal — badge, then name, then meaning. The badge window opens
    // at kCaptionIn (the same gate that mounts this whole caption).
    final aBadge = seg(t, kCaptionIn, 0.92);
    final aName = seg(t, 0.89, 0.96);
    final aMeaning = seg(t, 0.93, 1.0);
    final shimmer = _ambient.value; // drives the wordmark sheen

    Widget rise(double a, Widget child) => Opacity(
          opacity: a,
          child: Transform.translate(
            offset: Offset(0, (1 - a) * 16),
            child: child,
          ),
        );

    return Positioned(
      left: 24,
      right: 24,
      bottom: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          rise(
            aBadge,
            _ShimmerText(
              phase: shimmer,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: palette.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: gold.withValues(alpha: 0.5)),
                ),
                child: Text(
                  widget.spec.tier.label.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    color: palette.bright,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3.5,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          rise(
            aName,
            Text(
              widget.card.transliteration,
              style: AppTypography.headlineMedium
                  .copyWith(color: Colors.white, fontSize: 26),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          rise(
            aMeaning,
            Text(
              widget.card.english,
              style: AppTypography.bodyMedium
                  .copyWith(color: Colors.white.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 22),
          if (_interactive)
            Opacity(
              opacity: 0.5 + 0.3 * math.sin(_ambient.value * 2 * math.pi),
              child: Text(
                'Tap to continue',
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                  letterSpacing: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHint() {
    final palette = widget.spec.palette;
    final breath = 0.5 + 0.5 * math.sin(_ambient.value * 2 * math.pi);
    return Positioned(
      bottom: 128,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: goldBright.withValues(alpha: 0.55 + 0.4 * breath),
              boxShadow: [
                BoxShadow(
                  color: palette.glow.withValues(alpha: 0.5 * breath),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Opacity(
            opacity: 0.55 + 0.35 * breath,
            child: Text(
              'Tap to unveil',
              style: AppTypography.labelLarge.copyWith(
                color: goldBright,
                letterSpacing: 4,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                      color: palette.glow.withValues(alpha: 0.35),
                      blurRadius: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card face (front) — the real ornate tile (rasterised once via RepaintBoundary)
// under animated overlays: holographic foil, rotation-synced specular glint,
// diagonal shine sweep, a settle lens-flare, and a "forged" white overexposure.
// ─────────────────────────────────────────────────────────────────────────────

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.card,
    required this.tier,
    required this.shine,
    required this.birth,
    required this.foil,
    required this.foilPhase,
    required this.spinTilt,
    required this.flare,
    required this.glowBreath,
    required this.glow,
    required this.bright,
  });

  final CollectibleName card;
  final CardTier tier; // selects the ornate face tile
  final double shine; // 0→1 diagonal sweep (0 = skip)
  final double birth; // 1→0 white overexposure at forge (0 = skip)
  final double foil; // 0-1 holographic foil intensity (0 = skip)
  final double foilPhase; // 0→1 holographic hue drift
  final double spinTilt; // -1..1 specular position
  final double flare; // 0→1→0 lens-flare at land (0 = skip)
  final double glowBreath; // 0..1 breathing outer glow
  final Color glow; // tier additive glow accent (outer shadow)
  final Color bright; // tier lighter accent (foil/flare)

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Breathing outer glow — kept OUTSIDE the tile's RepaintBoundary so its
        // per-frame alpha animation (glowBreath) doesn't invalidate the cached
        // ornate-tile raster. Drawn behind the (opaque, rounded) tile, so the
        // visual is identical to a shadow on the tile's own decoration.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: glow.withValues(alpha: 0.42 + 0.16 * glowBreath),
                  blurRadius: 48,
                  spreadRadius: 6,
                ),
              ],
            ),
          ),
        ),
        // Static ornate tile — rasterised once (its inputs don't animate) so the
        // spin only re-composites the cached raster instead of re-painting the
        // Arabic/geometry each frame.
        RepaintBoundary(
          child: revealCardTile(card, tier),
        ),
        // Holographic foil + rotation-synced specular glint. Skipped entirely on
        // tiers with no foil AND no spin (nothing would draw).
        if (foil > 0 || spinTilt != 0)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(
                painter: FoilPainter(
                  foilPhase: foilPhase,
                  tilt: spinTilt,
                  bright: bright,
                  intensity: foil,
                ),
              ),
            ),
          ),
        if (shine > 0 && shine < 1)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(painter: ShineSweepPainter(shine)),
            ),
          ),
        if (flare > 0.01)
          Positioned.fill(
            child: CustomPaint(painter: LensFlarePainter(flare, bright)),
          ),
        if (birth > 0.01)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(
                color: Colors.white.withValues(alpha: 0.92 * birth),
              ),
            ),
          ),
      ],
    );
  }
}

// A gold sheen that travels across a child (used on the EMERALD wordmark).
class _ShimmerText extends StatelessWidget {
  const _ShimmerText({required this.child, required this.phase});
  final Widget child;
  final double phase; // 0..1

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (rect) {
        final x = -1 + 3 * phase; // travels left→right and off
        return LinearGradient(
          begin: Alignment(x - 0.3, 0),
          end: Alignment(x + 0.3, 0),
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.6),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect);
      },
      child: child,
    );
  }
}
