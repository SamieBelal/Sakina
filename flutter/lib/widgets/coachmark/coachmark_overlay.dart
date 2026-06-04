import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'coachmark_step.dart';

/// Coach-banner guided-tour overlay (2026-05-31 redesign).
///
/// Renders a bright gold OUTLINE RING around `step.target` (no full-screen dim,
/// so the page stays readable) plus a compact CREAM BANNER that slides in from
/// the left. The banner names what to do; the user advances by tapping the
/// outlined target. There is no "Continue" button on tap steps. Read-only steps
/// (`step.autoAdvance != null`) advance themselves after the given delay.
///
///   - Banner pins TOP-LEFT by default; on steps whose highlighted target is in
///     the top region (it would sit under the banner) the banner docks just
///     BELOW the target instead, so it never covers content.
///   - Invisible absorber strips around the target consume off-target taps so
///     the user can't wander off the tour (the target tap-through is handled by
///     `TourAnchor`, co-located with the anchor).
///   - Auto-advance is suppressed under a screen reader (`accessibleNavigation`)
///     — those steps instead show a small Continue so VoiceOver users advance
///     deliberately rather than having content change under them on a timer.
///   - Keyboard-up (Duas Build step) fades the overlay out so it never covers
///     the field. Reduce-motion collapses the slide/pulse to a single frame.
class CoachmarkOverlay extends StatefulWidget {
  const CoachmarkOverlay({
    super.key,
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.onNext,
    required this.onSkip,
    this.hideUntilAnchorReady = false,
    this.allowSkip = true,
  });

  final CoachmarkStep step;
  final int stepIndex;
  final int totalSteps;

  /// When false, the "Skip tour" affordance is hidden — used by the mandatory
  /// onboarding gate (the forced tour must run to completion before the hard
  /// paywall; decision C2). Defaults true so the legacy/replay tour keeps skip.
  final bool allowSkip;

  /// Called when the user taps the outlined target (tap steps) or when a
  /// read-only step's auto-advance timer fires.
  final VoidCallback onNext;

  /// Called when the user taps Skip. Closes the tour.
  final VoidCallback onSkip;

  /// When true, render `SizedBox.shrink()` instead of the full overlay — used
  /// by the host while the next step's anchor hasn't registered or a blocking
  /// modal route is on top.
  final bool hideUntilAnchorReady;

  @override
  State<CoachmarkOverlay> createState() => _CoachmarkOverlayState();
}

class _CoachmarkOverlayState extends State<CoachmarkOverlay>
    with TickerProviderStateMixin {
  /// Entry animation: ring fades in early, banner fades + slides in from the
  /// left slightly later. Runs once when this widget first mounts.
  late final AnimationController _entryCtrl;
  late final Animation<double> _ringOpacity;
  late final Animation<double> _bannerOpacity;
  late final Animation<double> _bannerSlide; // px, negative = from the left

  /// Breathing pulse around the ring — interactive steps only.
  late final AnimationController _pulseCtrl;

  bool _keyboardOpen = false;

  /// Auto-advance: at most one timer per step. `_autoAdvanceForIndex` guards
  /// the per-frame rebuild from restarting it.
  Timer? _autoAdvanceTimer;
  int? _autoAdvanceForIndex;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _ringOpacity = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _bannerOpacity = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );
    _bannerSlide = Tween<double>(begin: -40, end: 0).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    ));
    _entryCtrl.forward();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant CoachmarkOverlay old) {
    super.didUpdateWidget(old);
    _syncPulse();
  }

  /// Pulse runs iff the step is interactive, the overlay is visible, and the
  /// keyboard is down. (Repeating animations deadlock `pumpAndSettle`, so it
  /// must be off whenever the overlay is hidden.)
  void _syncPulse() {
    final shouldRun = widget.step.interactive &&
        !widget.hideUntilAnchorReady &&
        !_keyboardOpen;
    if (shouldRun && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!shouldRun && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }
  }

  /// Starts (once per step) or cancels the read-only-step auto-advance timer.
  /// Suppressed under a screen reader — those steps show a Continue instead.
  void _syncAutoAdvance({
    required int stepIndex,
    required Duration? autoAdvance,
    required bool accessible,
  }) {
    final shouldRun = autoAdvance != null && !accessible && !_keyboardOpen;
    if (!shouldRun) {
      _autoAdvanceTimer?.cancel();
      _autoAdvanceTimer = null;
      return;
    }
    if (_autoAdvanceForIndex == stepIndex) return; // already scheduled
    _autoAdvanceForIndex = stepIndex;
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer(autoAdvance, () {
      if (mounted) widget.onNext();
    });
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  /// Resolves the target's global rect, growing it by the step's cutout padding
  /// (clamped to the screen/safe-area so it can never invert or spill).
  Rect? _targetRect() {
    final target = widget.step.target;
    if (target == null) return null;
    final ctx = target.currentContext;
    if (ctx == null || !ctx.mounted) return null;
    try {
      final box = ctx.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) return null;
      final offset = box.localToGlobal(Offset.zero);
      final raw = offset & box.size;
      final padTop = widget.step.cutoutPaddingTop;
      final padBottom = widget.step.cutoutPaddingBottom;
      final padX = widget.step.cutoutPaddingX;
      if (padTop <= 0 && padBottom <= 0 && padX <= 0) return raw;
      final mq = MediaQuery.maybeOf(ctx);
      final safeTop = mq?.padding.top ?? 0.0;
      final size = mq?.size;
      final screenW = size?.width ?? raw.right;
      final screenH = size?.height ?? raw.bottom;
      final topLo = safeTop < raw.top ? safeTop : raw.top;
      final newTop = (raw.top - padTop).clamp(topLo, raw.top);
      final bottomHi = screenH > raw.bottom ? screenH : raw.bottom;
      final newBottom = (raw.bottom + padBottom).clamp(raw.bottom, bottomHi);
      final newLeft = (raw.left - padX).clamp(0.0, raw.left);
      final rightHi = screenW > raw.right ? screenW : raw.right;
      final newRight = (raw.right + padX).clamp(raw.right, rightHi);
      return Rect.fromLTRB(newLeft, newTop, newRight, newBottom);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (widget.hideUntilAnchorReady) {
      // Don't let a timer keep counting while hidden; allow a fresh schedule
      // when the step re-reveals.
      _autoAdvanceTimer?.cancel();
      _autoAdvanceTimer = null;
      _autoAdvanceForIndex = null;
      return const SizedBox.shrink();
    }
    final reduceMotion = mq.disableAnimations || mq.accessibleNavigation;
    // Hide while the soft keyboard is up (Duas Build step) — no room for the
    // ring + banner over the field. The target tap still advances the tour
    // (detection lives in `TourAnchor`), so the flow doesn't break.
    final keyboardOpen = mq.viewInsets.bottom > 1.0;
    if (keyboardOpen != _keyboardOpen) {
      _keyboardOpen = keyboardOpen;
      _syncPulse();
    }
    _syncAutoAdvance(
      stepIndex: widget.stepIndex,
      autoAdvance: widget.step.autoAdvance,
      accessible: mq.accessibleNavigation,
    );
    return OrientationBuilder(
      builder: (context, _) {
        return IgnorePointer(
          ignoring: keyboardOpen,
          child: AnimatedOpacity(
            opacity: keyboardOpen ? 0.0 : 1.0,
            duration: Duration(milliseconds: reduceMotion ? 0 : 200),
            curve: Curves.easeOut,
            child: AnimatedBuilder(
              animation: _entryCtrl,
              builder: (context, _) =>
                  _build(context, mq: mq, reduceMotion: reduceMotion),
            ),
          ),
        );
      },
    );
  }

  Widget _build(
    BuildContext context, {
    required MediaQueryData mq,
    required bool reduceMotion,
  }) {
    final rect = _targetRect();
    final step = widget.step;
    // Under a screen reader the auto-advance steps need a deliberate Continue
    // (no content-changes-on-a-timer); every other step advances by tapping.
    final showContinue = step.autoAdvance != null && mq.accessibleNavigation;

    final banner = _CoachBanner(
      message: step.message,
      onSkip: widget.onSkip,
      onContinue: showContinue ? widget.onNext : null,
      allowSkip: widget.allowSkip,
    );

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Static gold outline ring on the target (no dim).
          if (rect != null)
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _RingPainter(
                      cutout: rect,
                      opacity: reduceMotion ? 1.0 : _ringOpacity.value,
                      topInset: mq.padding.top,
                    ),
                  ),
                ),
              ),
            ),
          // Absorbers: consume off-target taps so the user stays on the tour.
          if (rect != null) ..._buildAbsorbers(rect, mq.size),
          // Breathing pulse — interactive steps only.
          if (step.interactive && rect != null && !reduceMotion)
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => CustomPaint(
                      painter: _PulsePainter(
                        cutout: rect,
                        progress: _pulseCtrl.value,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Coach banner.
          _PositionedBanner(
            targetRect: rect,
            mediaQuery: mq,
            opacity: reduceMotion ? 1.0 : _bannerOpacity.value,
            slideX: reduceMotion ? 0.0 : _bannerSlide.value,
            child: banner,
          ),
        ],
      ),
    );
  }

  /// 4 absorber strips around the cutout so off-target taps don't bypass the
  /// tour. The cutout itself is left open for the underlying target's tap.
  List<Widget> _buildAbsorbers(Rect cutout, Size screen) {
    final padded = const EdgeInsets.all(8).inflateRect(cutout);
    final top = padded.top.clamp(0.0, screen.height);
    final bottom = padded.bottom.clamp(0.0, screen.height);
    final left = padded.left.clamp(0.0, screen.width);
    final right = padded.right.clamp(0.0, screen.width);
    final sideHeight = (bottom - top) < 0 ? 0.0 : bottom - top;
    return [
      Positioned(left: 0, top: 0, right: 0, height: top, child: const _AbsorbTap()),
      Positioned(left: 0, top: bottom, right: 0, bottom: 0, child: const _AbsorbTap()),
      Positioned(left: 0, top: top, width: left, height: sideHeight, child: const _AbsorbTap()),
      Positioned(left: right, top: top, right: 0, height: sideHeight, child: const _AbsorbTap()),
    ];
  }
}

/// Tap absorber strip. Consumes taps without forwarding.
class _AbsorbTap extends StatelessWidget {
  const _AbsorbTap();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Positions the banner top-left by default; docks it just below the target on
/// steps whose target sits in the top region (so it never covers content).
/// Applies the entry slide/opacity here so the whole banner animates together.
class _PositionedBanner extends StatelessWidget {
  const _PositionedBanner({
    required this.targetRect,
    required this.mediaQuery,
    required this.opacity,
    required this.slideX,
    required this.child,
  });

  final Rect? targetRect;
  final MediaQueryData mediaQuery;
  final double opacity;
  final double slideX;
  final Widget child;

  static const double _margin = 12;
  static const double _topPad = 8;
  static const double _estBannerH = 112; // conservative, for collision + clamps

  @override
  Widget build(BuildContext context) {
    final screenW = mediaQuery.size.width;
    final screenH = mediaQuery.size.height;
    final safeTop = mediaQuery.padding.top;
    final safeBottom = mediaQuery.padding.bottom;
    final bannerW = (screenW * 0.82).clamp(0.0, 340.0);

    final defaultTop = safeTop + _topPad;
    var top = defaultTop;
    // Dock below the target only when the WHOLE target sits in the banner's
    // top-left footprint (a short, high element like the streak pill). For a
    // tall cutout (e.g. the Build step's 280pt upward extension) the bottom is
    // far down the screen, so we keep top-left — the banner sits over the
    // highlighted region's inert top (the form's header), not below the form.
    if (targetRect != null && targetRect!.bottom < defaultTop + _estBannerH) {
      final lo = defaultTop;
      final hi = screenH - safeBottom - _estBannerH;
      top = (targetRect!.bottom + _margin).clamp(lo, hi < lo ? lo : hi);
    }

    return Positioned(
      left: _margin,
      width: bannerW,
      top: top,
      child: Transform.translate(
        offset: Offset(slideX, 0),
        child: Opacity(opacity: opacity, child: child),
      ),
    );
  }
}

/// Compact cream banner: emerald stripe + gold dot + message + Skip (+ Continue
/// only when a screen reader needs a deliberate advance).
class _CoachBanner extends StatelessWidget {
  const _CoachBanner({
    required this.message,
    required this.onSkip,
    this.onContinue,
    this.allowSkip = true,
  });

  final String message;
  final VoidCallback onSkip;
  final VoidCallback? onContinue;
  final bool allowSkip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFBF7F2), Color(0xFFF5EFE6)],
          ),
          borderRadius: BorderRadius.circular(13),
          boxShadow: const [
            BoxShadow(blurRadius: 20, color: Color(0x2E000000), offset: Offset(0, 6)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 3, child: Container(color: AppColors.primary)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6, right: 9),
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.secondary,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              message,
                              style: const TextStyle(
                                color: AppColors.textPrimaryLight,
                                fontSize: 15,
                                height: 1.35,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (allowSkip || onContinue != null)
                        const SizedBox(height: 6),
                      if (allowSkip || onContinue != null)
                      Row(
                        children: [
                          if (allowSkip)
                          Semantics(
                            button: true,
                            label: 'Skip tour',
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: onSkip,
                              // F-05: guarantee a >=44pt touch target (was a
                              // ~24pt-tall text with 2pt h-padding). minHeight
                              // keeps the visible text compact while the tap
                              // area meets the accessibility minimum.
                              child: Container(
                                constraints: const BoxConstraints(
                                    minHeight: 44, minWidth: 44),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 8),
                                child: const Text(
                                  'Skip tour',
                                  style: TextStyle(
                                    color: AppColors.textTertiaryLight,
                                    fontSize: 12.5,
                                    fontFamily: 'DM Sans',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (onContinue != null) ...[
                            const Spacer(),
                            Semantics(
                              button: true,
                              label: 'Continue',
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: onContinue,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 6, horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Text(
                                    'Continue',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontFamily: 'DM Sans',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Static gold outline ring + soft glow around the cutout (no fill). Replaces
/// the old dim scrim — the page stays readable, the ring carries attention.
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.cutout,
    required this.opacity,
    this.topInset = 0,
  });

  final Rect cutout;
  final double opacity;
  final double topInset;

  @override
  void paint(Canvas canvas, Size size) {
    final padded = const EdgeInsets.all(8).inflateRect(cutout);
    // Soft glow (blurred stroke) so the target reads as a brightened region.
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = AppColors.secondary.withValues(alpha: 0.28 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final glowRaw = padded.inflate(2);
    final glowRect = Rect.fromLTRB(
      glowRaw.left,
      glowRaw.top < topInset ? topInset : glowRaw.top,
      glowRaw.right,
      glowRaw.bottom,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(glowRect, const Radius.circular(18)),
      glow,
    );
    // Crisp ring.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = AppColors.secondary.withValues(alpha: 0.95 * opacity);
    canvas.drawRRect(
      RRect.fromRectAndRadius(padded, const Radius.circular(16)),
      ring,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.cutout != cutout ||
      old.opacity != opacity ||
      old.topInset != topInset;
}

/// Soft gold breathing pulse stroke around the cutout (interactive steps only).
class _PulsePainter extends CustomPainter {
  _PulsePainter({required this.cutout, required this.progress});

  final Rect cutout;
  final double progress; // 0..1

  @override
  void paint(Canvas canvas, Size size) {
    final eased = (1 - (1 - progress) * (1 - progress));
    final t = Curves.easeInOutSine.transform(eased);
    final alpha = 0.18 + 0.22 * t; // 0.18..0.40
    final extra = 2.0 + 4.0 * t; // grow 2..6pt
    final ring = const EdgeInsets.all(8).inflateRect(cutout).inflate(extra);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = AppColors.secondary.withValues(alpha: alpha);
    final rrect = RRect.fromRectAndRadius(ring, const Radius.circular(20));
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _PulsePainter old) =>
      old.cutout != cutout || old.progress != progress;
}
