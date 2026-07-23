import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/collection/widgets/emerald_ornate_card.dart';
import 'package:sakina/features/daily/models/reveal_spec.dart';
import 'package:sakina/features/streaks/models/companion_state.dart';
import 'package:sakina/features/streaks/widgets/companion_medallion.dart';
import 'package:sakina/services/card_collection_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CARD REVEAL OVERLAY — the tiered gacha hero moment (Bronze→Emerald).
//
// Self-contained, native (no new Lottie yet) so every beat is tunable live via
// the _seg() windows below. Choreography (single controller, D = _revealDuration):
//   idle          → unlit lantern, waits for a tap
//   ignite        → tier colour + god-rays gather around the lamp
//   burst         → flash + radial shafts + expanding rings + sparks (heavy haptic)
//   forge/spin    → card is forged white-hot from the nūr, cools, spins 360°×N
//   settle        → overshoot land, shine + lens-flare, TIER badge staggers in
//   rest          → breathing aurora + floating embers keep it alive
//
// The choreography (normalized 0→1 _seg windows) is SHARED across tiers; only
// the wall-clock `duration`, feature intensities/toggles, spin turns, spark
// count and haptics change — all driven by the injected [RevealSpec]. Emerald's
// spec sets every toggle to max (all 1.0, halo true, 30 sparks, 3 spins,
// legendary haptics) so it reproduces the approved Emerald spike exactly.
//
// In production the FX layers may move to authored Lottie; the CARD + spin stay
// native (data-driven Arabic). Tier colour lives only in OUR fx layers.
// ─────────────────────────────────────────────────────────────────────────────

// Tier-neutral shared warm accents + canvas.
const _gold = Color(0xFFC8985E);
const _goldBright = Color(0xFFEDD9A3);
const _canvas = Color(0xFF05100A);

class CardRevealOverlay extends StatefulWidget {
  const CardRevealOverlay({
    super.key,
    required this.card,
    required this.spec,
    this.onContinue,
    this.autoStart = false,
  });

  final CollectibleName card;
  final RevealSpec spec;
  final VoidCallback? onContinue;

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
  int get _spinTurns => widget.spec.spinTurns; // full Y rotations before settle

  // Tier signature colours (used only in OUR fx layers, never the lantern flame).
  Color get _tColor => widget.spec.palette.color;
  Color get _tBright => widget.spec.palette.bright;
  Color get _tGlow => widget.spec.palette.glow;

  late final AnimationController _reveal; // one-shot, driven on tap
  late final AnimationController _ambient; // looping (breathing + drift)

  bool _started = false;
  bool _dismissed = false;
  late final List<_Spark> _sparks = _buildSparks(widget.spec.sparkCount);
  final List<_Mote> _motes = _buildMotes(14);

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(vsync: this, duration: _revealDuration);
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    if (widget.autoStart) {
      // Loop the whole sequence so timed screenshots catch every beat.
      _reveal.addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          Future.delayed(const Duration(milliseconds: 1400), () {
            if (!mounted) return;
            _reveal.forward(from: 0);
            _scheduleHaptics();
          });
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _open();
      });
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    _ambient.dispose();
    super.dispose();
  }

  void _open() {
    if (_started) return;
    setState(() => _started = true);
    HapticFeedback.mediumImpact();
    _reveal.forward();
    _scheduleHaptics();
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
    if (_interactive) _continue();
    // taps mid-reveal are intentionally swallowed
  }

  void _continue() {
    if (_dismissed) return;
    _dismissed = true;
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
      backgroundColor: _canvas,
      body: GestureDetector(
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_reveal, _ambient]),
          builder: (context, _) {
            final t = _reveal.value;
            final breath = 0.5 + 0.5 * math.sin(_ambient.value * 2 * math.pi);
            final spin = _ambient.value * 2 * math.pi;
            final spec = widget.spec;
            return SizedBox.expand(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1 ── Atmosphere: darken + tier-coloured pool + focus vignette.
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _AtmospherePainter(
                          darken: _seg(t, 0.34, 0.58),
                          pool: _seg(t, 0.50, 0.92),
                          breath: breath,
                          color: _tColor,
                        ),
                      ),
                    ),
                  ),

                  // 2 ── Tier god-rays growing out of the lantern (the tease).
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _LanternRaysPainter(
                          grow: _seg(t, 0.05, 0.34) * spec.godRays,
                          fade: 1 - _seg(t, 0.40, 0.50),
                          rotation: spin,
                          color: _tGlow,
                        ),
                      ),
                    ),
                  ),

                  // 3 ── Aurora rays — bloom at the burst, then SETTLE to a
                  //      breathing floor (never fully dies → the rest stays alive).
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _AuroraPainter(
                          rotation: spin,
                          opacity: _seg(t, 0.42, 0.56) *
                              (1 - 0.55 * _seg(t, 0.88, 1.0)) *
                              (0.9 + 0.1 * breath) *
                              spec.aurora,
                          bright: _tBright,
                        ),
                      ),
                    ),
                  ),

                  // 4 ── Burst: flash + hard radial shafts + expanding rings.
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _BurstPainter(
                          rings: _seg(t, 0.38, 0.66),
                          flash: _bell(_seg(t, 0.38, 0.52)),
                          shafts: _bell(_seg(t, 0.40, 0.56)) * spec.radialShafts,
                          rotation: spin,
                          color: _tBright,
                          glow: _tGlow,
                        ),
                      ),
                    ),
                  ),

                  // 5 ── Sparks flung outward from the break.
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _SparkPainter(
                          sparks: _sparks,
                          progress: _seg(t, 0.40, 0.78),
                          bright: _tBright,
                        ),
                      ),
                    ),
                  ),

                  // 6 ── Halo ring behind the settled card (emerald-only flourish).
                  if (spec.halo && t > 0.80)
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: _HaloPainter(
                            rotation: spin,
                            opacity: _seg(t, 0.82, 0.96) * (0.85 + 0.15 * breath),
                            bright: _tBright,
                          ),
                        ),
                      ),
                    ),

                  // 7 ── Floating embers around the rested card (persistent life).
                  if (spec.restMotes > 0 && t > 0.80)
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: _MotePainter(
                            motes: _motes,
                            phase: _ambient.value,
                            opacity: _seg(t, 0.84, 0.97) * spec.restMotes,
                            bright: _tBright,
                          ),
                        ),
                      ),
                    ),

                  // 8 ── The vessel (lantern) OR the card.
                  if (t < 0.46)
                    _buildLantern(t)
                  else
                    _buildCard(t, breath),

                  // 9 ── Name + badge + continue (staggered in after settle).
                  if (t > 0.85) _buildCaption(t),

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
    final swell = _seg(t, 0.0, 0.30); // extended: tier colour + rays gather
    final flare = _seg(t, 0.34, 0.46); // erupts + dissolves into the burst
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
                          _tBright.withValues(alpha: 0.42 * charge),
                          _tGlow.withValues(alpha: 0.12 * charge),
                          _tGlow.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.32, 0.6, 1.0],
                      ),
                    ),
                  ),
                CompanionMedallion(
                  state: lampState,
                  size: 190,
                  ambient: false,
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

    final appear = Curves.easeOutBack.transform(_seg(t, 0.46, 0.58));
    final spinT = Curves.easeOutCubic.transform(_seg(t, 0.49, 0.86));

    // Settle overshoot — a small decaying wobble past 0 so the landing has weight.
    final land = _seg(t, 0.86, 1.0);
    final wobble = math.sin(land * math.pi * 2.4) * (1 - land) * 0.11;
    final angle = (1 - spinT) * _spinTurns * 2 * math.pi + wobble;

    // Landing scale pop + rise, then a gentle idle bob.
    final pop = _bell(_seg(t, 0.84, 0.94)) * 0.05;
    final settleY = -_seg(t, 0.84, 0.94) * 8;
    final bob = t >= 0.95 ? math.sin(_ambient.value * 2 * math.pi) * 4 : 0.0;

    // "Forged from light" — a white overexposure that cools into the emerald art.
    final birth = (1 - _seg(t, 0.47, 0.62)).clamp(0.0, 1.0);

    final facingFront = math.cos(angle) >= 0;
    final spinTilt = math.sin(angle); // -1..1, drives the specular sweep
    final foilPhase = ((angle / (2 * math.pi)) + _ambient.value) % 1.0;

    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0012) // perspective
      ..rotateY(angle);

    return Transform.translate(
      offset: Offset(0, settleY + bob),
      child: Opacity(
        opacity: appear.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: (0.2 + appear * 0.8).clamp(0.0, 1.1) + pop,
          child: Transform(
            alignment: Alignment.center,
            transform: matrix,
            child: SizedBox(
              width: cardW,
              height: cardH,
              child: facingFront
                  ? _CardFace(
                      card: widget.card,
                      shine: _seg(t, 0.87, 0.97),
                      birth: birth,
                      foilPhase: foilPhase,
                      spinTilt: spinTilt,
                      flare: _bell(_seg(t, 0.86, 0.95)),
                      glowBreath: breath,
                      glow: _tGlow,
                      bright: _tBright,
                    )
                  : _CardBack(glow: _tGlow, bright: _tBright),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaption(double t) {
    // Staggered reveal — badge, then name, then meaning.
    final aBadge = _seg(t, 0.85, 0.92);
    final aName = _seg(t, 0.89, 0.96);
    final aMeaning = _seg(t, 0.93, 1.0);
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
                  color: _tColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _gold.withValues(alpha: 0.5)),
                ),
                child: Text(
                  widget.spec.tier.label.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    color: _tBright,
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
              color: _goldBright.withValues(alpha: 0.55 + 0.4 * breath),
              boxShadow: [
                BoxShadow(
                  color: _tGlow.withValues(alpha: 0.5 * breath),
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
                color: _goldBright,
                letterSpacing: 4,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(color: _tGlow.withValues(alpha: 0.35), blurRadius: 18),
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
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Normalised 0→1 progress of `t` within the window [a, b], clamped.
double _seg(double t, double a, double b) =>
    ((t - a) / (b - a)).clamp(0.0, 1.0);

/// A 0→1→0 bell over a 0→1 input (for flashes).
double _bell(double x) => math.sin(x.clamp(0.0, 1.0) * math.pi);

class _Spark {
  const _Spark(this.angle, this.distance, this.size, this.speed);
  final double angle;
  final double distance;
  final double size;
  final double speed;
}

List<_Spark> _buildSparks(int n) {
  final rng = math.Random(7);
  return List.generate(n, (i) {
    final angle = (i / n) * 2 * math.pi + rng.nextDouble() * 0.5;
    return _Spark(
      angle,
      0.28 + rng.nextDouble() * 0.5,
      1.5 + rng.nextDouble() * 3.0,
      0.7 + rng.nextDouble() * 0.6,
    );
  });
}

class _Mote {
  const _Mote(this.x, this.y, this.size, this.speed, this.seed);
  final double x; // -1..1 around centre (fraction of half-width)
  final double y; // -1..1 around centre (fraction of half-height)
  final double size;
  final double speed;
  final double seed;
}

List<_Mote> _buildMotes(int n) {
  final rng = math.Random(19);
  return List.generate(
    n,
    (i) => _Mote(
      (rng.nextDouble() * 2 - 1) * 0.9,
      (rng.nextDouble() * 2 - 1) * 0.7,
      1.0 + rng.nextDouble() * 2.2,
      0.4 + rng.nextDouble() * 0.7,
      rng.nextDouble(),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Card face (front) — the real ornate tile (rasterised once via RepaintBoundary)
// under animated overlays: holographic foil, rotation-synced specular glint,
// diagonal shine sweep, a settle lens-flare, and a "forged" white overexposure.
// ─────────────────────────────────────────────────────────────────────────────

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.card,
    required this.shine,
    required this.birth,
    required this.foilPhase,
    required this.spinTilt,
    required this.flare,
    required this.glowBreath,
    required this.glow,
    required this.bright,
  });

  final CollectibleName card;
  final double shine; // 0→1 diagonal sweep
  final double birth; // 1→0 white overexposure at forge
  final double foilPhase; // 0→1 holographic hue drift
  final double spinTilt; // -1..1 specular position
  final double flare; // 0→1→0 lens-flare at land
  final double glowBreath; // 0..1 breathing outer glow
  final Color glow; // tier additive glow accent (outer shadow)
  final Color bright; // tier lighter accent (foil/flare)

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Static ornate tile — rasterised once so the spin only re-composites.
        RepaintBoundary(
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
            child: EmeraldOrnateTile(card: card),
          ),
        ),
        // Holographic foil + rotation-synced specular glint.
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CustomPaint(
              painter: _FoilPainter(
                  foilPhase: foilPhase, tilt: spinTilt, bright: bright),
            ),
          ),
        ),
        if (shine > 0 && shine < 1)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(painter: _ShineSweepPainter(shine)),
            ),
          ),
        if (flare > 0.01)
          Positioned.fill(
            child: CustomPaint(painter: _LensFlarePainter(flare, bright)),
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

// Holographic foil sheen (a travelling diagonal rainbow) + a specular band that
// tracks the card's Y-rotation, so a highlight sweeps across as it turns.
class _FoilPainter extends CustomPainter {
  _FoilPainter(
      {required this.foilPhase, required this.tilt, required this.bright});
  final double foilPhase;
  final double tilt;
  final Color bright;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final p = foilPhase;

    // Diagonal hue-shift sheen, band travels with the rotation phase.
    final sheen = LinearGradient(
      begin: Alignment(-1 + 2 * p, -1),
      end: Alignment(1, 1 - 2 * p),
      colors: [
        bright.withValues(alpha: 0.0),
        _goldBright.withValues(alpha: 0.16),
        Colors.white.withValues(alpha: 0.10),
        bright.withValues(alpha: 0.14),
        bright.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.38, 0.5, 0.62, 1.0],
    ).createShader(rect);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = sheen
        ..blendMode = BlendMode.plus,
    );

    // Specular band — brightest mid-turn, position tracks the tilt.
    final strength = tilt.abs();
    if (strength > 0.02) {
      final sx = (0.5 + tilt.clamp(-1.0, 1.0) * 0.55) * size.width;
      final band = size.width * 0.30;
      final spec = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.34 * strength),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(sx - band, 0, band * 2, size.height));
      canvas.drawRect(
        rect,
        Paint()
          ..shader = spec
          ..blendMode = BlendMode.plus,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FoilPainter old) =>
      old.foilPhase != foilPhase ||
      old.tilt != tilt ||
      old.bright != bright;
}

// A horizontal anamorphic lens-flare that flashes across the card as it lands.
class _LensFlarePainter extends CustomPainter {
  _LensFlarePainter(this.flare, this.bright);
  final double flare;
  final Color bright;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height * 0.42;
    final streak = LinearGradient(
      colors: [
        Colors.white.withValues(alpha: 0.0),
        bright.withValues(alpha: 0.5 * flare),
        Colors.white.withValues(alpha: 0.85 * flare),
        bright.withValues(alpha: 0.5 * flare),
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
    ).createShader(
        Rect.fromLTWH(-size.width * 0.4, 0, size.width * 1.8, size.height));
    final h = size.height * 0.10 * (0.6 + flare * 0.6);
    canvas.drawRect(
      Rect.fromLTWH(-size.width * 0.4, cy - h / 2, size.width * 1.8, h),
      Paint()
        ..shader = streak
        ..blendMode = BlendMode.plus
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.4),
    );
    // Bright core.
    canvas.drawCircle(
      Offset(size.width / 2, cy),
      size.width * 0.10 * flare,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: 0.9 * flare),
          Colors.white.withValues(alpha: 0.0),
        ]).createShader(Rect.fromCircle(
            center: Offset(size.width / 2, cy),
            radius: size.width * 0.10 * flare)),
    );
  }

  @override
  bool shouldRepaint(covariant _LensFlarePainter old) =>
      old.flare != flare || old.bright != bright;
}

// ─────────────────────────────────────────────────────────────────────────────
// Card back — symmetric emerald geometric motif (shown while facing away).
// ─────────────────────────────────────────────────────────────────────────────

class _CardBack extends StatelessWidget {
  const _CardBack({required this.glow, required this.bright});

  final Color glow; // tier additive glow accent (outer shadow)
  final Color bright; // tier lighter accent (motif strokes)

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const RadialGradient(
          center: Alignment(0, -0.1),
          radius: 1.1,
          colors: [Color(0xFF1A3328), Color(0xFF0F1F16)],
        ),
        border: Border.all(color: _gold.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.4),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      child: CustomPaint(painter: _CardBackPainter(bright)),
    );
  }
}

class _CardBackPainter extends CustomPainter {
  const _CardBackPainter(this.bright);

  final Color bright;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.30;

    final gold = Paint()
      ..color = _goldBright.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final accent = Paint()
      ..color = bright.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Two overlaid squares → 8-point star (khatam), plus concentric rings.
    for (final rot in [0.0, math.pi / 4]) {
      final p = Path();
      for (int i = 0; i < 4; i++) {
        final a = rot + i * math.pi / 2;
        final pt = c + Offset(math.cos(a), math.sin(a)) * r;
        if (i == 0) {
          p.moveTo(pt.dx, pt.dy);
        } else {
          p.lineTo(pt.dx, pt.dy);
        }
      }
      p.close();
      canvas.drawPath(p, gold);
    }
    canvas.drawCircle(c, r * 0.62, accent);
    canvas.drawCircle(c, r * 0.34, gold);
    canvas.drawCircle(c, 3, Paint()..color = bright);
  }

  @override
  bool shouldRepaint(covariant _CardBackPainter oldDelegate) => false;
}

class _ShineSweepPainter extends CustomPainter {
  const _ShineSweepPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final band = size.width * 0.4;
    final x = -band + progress * (size.width + band * 2);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.0),
        Colors.white.withValues(alpha: 0.38),
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: const [0.35, 0.5, 0.65],
    );
    final shader = gradient.createShader(
      Rect.fromLTWH(x - band, 0, band * 2, size.height),
    );
    canvas.drawRect(rect, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _ShineSweepPainter old) =>
      old.progress != progress;
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

// ─────────────────────────────────────────────────────────────────────────────
// Atmosphere — darken + a warm emerald pool the card rests in + focus vignette.
// ─────────────────────────────────────────────────────────────────────────────

class _AtmospherePainter extends CustomPainter {
  _AtmospherePainter({
    required this.darken,
    required this.pool,
    required this.breath,
    required this.color,
  });
  final double darken; // 0→1
  final double pool; // 0→1 tier-coloured glow behind the card
  final double breath;
  final Color color; // tier signature colour for the pool

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final c = Offset(size.width / 2, size.height / 2);

    canvas.drawRect(
      rect,
      Paint()..color = Color.lerp(_canvas, Colors.black, darken * 0.72)!,
    );

    if (pool > 0.01) {
      final r = size.shortestSide * (0.62 + 0.03 * breath);
      canvas.drawRect(
        rect,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: 0.16 * pool),
              color.withValues(alpha: 0.05 * pool),
              color.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    if (darken > 0.01) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.black.withValues(alpha: 0.0),
              Colors.black.withValues(alpha: 0.0),
              Colors.black.withValues(alpha: 0.5 * darken),
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(
              Rect.fromCircle(center: c, radius: size.longestSide * 0.72)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter old) =>
      old.darken != darken ||
      old.pool != pool ||
      old.breath != breath ||
      old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Halo — a slow, faint emerald/gold ring behind the settled card (emerald flex).
// ─────────────────────────────────────────────────────────────────────────────

class _HaloPainter extends CustomPainter {
  _HaloPainter(
      {required this.rotation, required this.opacity, required this.bright});
  final double rotation;
  final double opacity;
  final Color bright;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.01) return;
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.46;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = bright.withValues(alpha: 0.22 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2)
        ..blendMode = BlendMode.plus,
    );
    canvas.drawCircle(
      c,
      r * 1.08,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = _goldBright.withValues(alpha: 0.12 * opacity),
    );
    // A ring of ticks turning slowly around the card.
    const ticks = 16;
    final tick = Paint()
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = _goldBright.withValues(alpha: 0.28 * opacity)
      ..blendMode = BlendMode.plus;
    for (var i = 0; i < ticks; i++) {
      final a = i * 2 * math.pi / ticks + rotation * 0.3;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + dir * r * 1.02, c + dir * r * 1.06, tick);
    }
  }

  @override
  bool shouldRepaint(covariant _HaloPainter old) =>
      old.rotation != rotation ||
      old.opacity != opacity ||
      old.bright != bright;
}

// ─────────────────────────────────────────────────────────────────────────────
// Motes — floating embers/kirakira around the rested card (persistent life).
// ─────────────────────────────────────────────────────────────────────────────

class _MotePainter extends CustomPainter {
  _MotePainter(
      {required this.motes,
      required this.phase,
      required this.opacity,
      required this.bright});
  final List<_Mote> motes;
  final double phase;
  final double opacity;
  final Color bright; // tier accent (alternated with the warm gold accent)

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.01) return;
    final c = Offset(size.width / 2, size.height / 2);
    final spread = size.shortestSide * 0.5;

    for (final m in motes) {
      final rise = (phase * m.speed + m.seed) % 1.0; // 0→1 slow drift up
      final twinkle = 0.5 + 0.5 * math.sin(phase * 2 * math.pi * 2 + m.seed * 6);
      final x = c.dx + m.x * spread + math.sin(phase * 6 + m.seed * 6) * 6;
      final y = c.dy + m.y * spread - rise * size.shortestSide * 0.25;
      final a = opacity * (0.25 + 0.6 * twinkle) * (1 - rise * 0.6);
      canvas.drawCircle(
        Offset(x, y),
        m.size * (0.7 + 0.5 * twinkle),
        Paint()
          ..color = (m.seed > 0.5 ? _goldBright : bright)
              .withValues(alpha: a.clamp(0.0, 0.7))
          ..blendMode = BlendMode.plus
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MotePainter old) =>
      old.phase != phase ||
      old.opacity != opacity ||
      old.bright != bright;
}

// ─────────────────────────────────────────────────────────────────────────────
// Lantern god-rays — soft tier-coloured wedges that GROW out of the lantern
// during the extended ignite, then fade as the burst hits.
// ─────────────────────────────────────────────────────────────────────────────

class _LanternRaysPainter extends CustomPainter {
  _LanternRaysPainter({
    required this.grow,
    required this.fade,
    required this.rotation,
    required this.color,
  });
  final double grow;
  final double fade;
  final double rotation;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final vis = grow * fade;
    if (vis <= 0.01) return;
    final c = Offset(size.width / 2, size.height / 2);
    final maxLen = size.longestSide * 0.5;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rotation);

    const rays = 16;
    final reach = Curves.easeOutCubic.transform(grow);
    for (var i = 0; i < rays; i++) {
      final long = i.isEven;
      final len = maxLen * (long ? 0.95 : 0.62) * reach;
      final halfW = size.shortestSide * (long ? 0.05 : 0.035);
      canvas.save();
      canvas.rotate(i * 2 * math.pi / rays);
      final shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.28 * vis),
          color.withValues(alpha: 0.10 * vis),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(-halfW, 0, halfW * 2, len));
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(-halfW, len)
        ..lineTo(halfW, len)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = shader
          ..blendMode = BlendMode.plus
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, halfW * 0.7),
      );
      canvas.restore();
    }

    canvas.drawCircle(
      Offset.zero,
      size.shortestSide * 0.22 * reach,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.30 * vis),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(
              center: Offset.zero, radius: size.shortestSide * 0.22 * reach),
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LanternRaysPainter old) =>
      old.grow != grow ||
      old.fade != fade ||
      old.rotation != rotation ||
      old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Aurora rays — a rotating radial fan of emerald/gold light behind the card.
// ─────────────────────────────────────────────────────────────────────────────

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(
      {required this.rotation, required this.opacity, required this.bright});
  final double rotation;
  final double opacity;
  final Color bright; // tier accent, alternated with the warm gold accent

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final c = Offset(size.width / 2, size.height / 2);
    final len = size.longestSide;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rotation);

    const rays = 12;
    for (int i = 0; i < rays; i++) {
      final a = (i / rays) * 2 * math.pi;
      final color = i.isEven ? bright : _goldBright;
      final paint = Paint()
        ..shader = _gradientForRay(color, len, opacity)
        ..blendMode = BlendMode.plus;
      canvas.save();
      canvas.rotate(a);
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(-len * 0.06, len)
        ..lineTo(len * 0.06, len)
        ..close();
      canvas.drawPath(path, paint);
      canvas.restore();
    }
    canvas.restore();
  }

  Shader _gradientForRay(Color color, double len, double opacity) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withValues(alpha: 0.10 * opacity),
        color.withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromLTWH(-len * 0.06, 0, len * 0.12, len));
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) =>
      old.rotation != rotation ||
      old.opacity != opacity ||
      old.bright != bright;
}

// ─────────────────────────────────────────────────────────────────────────────
// Burst — central flash + hard radial shafts (percussive) + expanding rings.
// ─────────────────────────────────────────────────────────────────────────────

class _BurstPainter extends CustomPainter {
  _BurstPainter({
    required this.rings,
    required this.flash,
    required this.shafts,
    required this.rotation,
    required this.color,
    required this.glow,
  });
  final double rings;
  final double flash;
  final double shafts; // 0→1→0 sharp light shafts at the impact
  final double rotation;
  final Color color; // tier accent (flash + shafts)
  final Color glow; // tier additive glow accent (rings)

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final maxR = size.longestSide * 0.6;

    if (flash > 0) {
      final r = maxR * (0.1 + flash * 0.6);
      final paint = Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.9 * flash),
            color.withValues(alpha: 0.4 * flash),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r));
      canvas.drawCircle(c, r, paint);
    }

    // Hard, thin light-shafts snapping out at the impact — the "crack".
    if (shafts > 0.01) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(rotation * 0.5);
      const n = 20;
      final len = maxR * (0.4 + 0.7 * shafts);
      for (var i = 0; i < n; i++) {
        canvas.save();
        canvas.rotate(i * 2 * math.pi / n);
        final w = size.shortestSide * (i.isEven ? 0.012 : 0.006);
        final shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.55 * shafts),
            color.withValues(alpha: 0.25 * shafts),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromLTWH(-w, 0, w * 2, len));
        canvas.drawPath(
          Path()
            ..moveTo(0, 0)
            ..lineTo(-w, len)
            ..lineTo(w, len)
            ..close(),
          Paint()
            ..shader = shader
            ..blendMode = BlendMode.plus,
        );
        canvas.restore();
      }
      canvas.restore();
    }

    if (rings > 0 && rings < 1) {
      for (final delay in [0.0, 0.18, 0.36]) {
        final p = (rings - delay).clamp(0.0, 1.0);
        if (p <= 0) continue;
        final radius = maxR * p;
        final alpha = (1 - p) * 0.6;
        canvas.drawCircle(
          c,
          radius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5 * (1 - p) + 0.5
            ..color = glow.withValues(alpha: alpha)
            ..blendMode = BlendMode.plus,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) =>
      old.rings != rings ||
      old.flash != flash ||
      old.shafts != shafts ||
      old.rotation != rotation ||
      old.color != color ||
      old.glow != glow;
}

// ─────────────────────────────────────────────────────────────────────────────
// Sparks — small motes flung radially outward with a motion trail, fading out.
// ─────────────────────────────────────────────────────────────────────────────

class _SparkPainter extends CustomPainter {
  _SparkPainter(
      {required this.sparks, required this.progress, required this.bright});
  final List<_Spark> sparks;
  final double progress;
  final Color bright; // tier accent (alternated with the warm gold accent)

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final c = Offset(size.width / 2, size.height / 2);
    final half = size.longestSide * 0.5;

    for (final s in sparks) {
      final p = (progress * s.speed).clamp(0.0, 1.0);
      final dir = Offset(math.cos(s.angle), math.sin(s.angle));
      final dist = half * s.distance * Curves.easeOut.transform(p);
      final pos = c + dir * dist;
      final alpha = (1 - p) * 0.9;
      final color =
          (s.size > 3 ? _goldBright : bright).withValues(alpha: alpha);

      // Motion trail — a short streak behind the head, longer while fast.
      final trail = dir * (12 + 26 * (1 - p)) * s.size * 0.25;
      canvas.drawLine(
        pos - trail,
        pos,
        Paint()
          ..color = color.withValues(alpha: alpha * 0.5)
          ..strokeWidth = s.size * 0.6 * (1 - p * 0.4)
          ..strokeCap = StrokeCap.round
          ..blendMode = BlendMode.plus
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0),
      );
      canvas.drawCircle(
        pos,
        s.size * (1 - p * 0.5),
        Paint()
          ..color = color
          ..blendMode = BlendMode.plus
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.progress != progress || old.bright != bright;
}
