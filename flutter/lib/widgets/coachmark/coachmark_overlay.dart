import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_colors.dart';
import 'coachmark_step.dart';

/// Renders a warm-ink scrim + cutout around `step.target` with a premium
/// gradient tooltip card. Single persistent overlay — when [step] changes,
/// the cutout and tooltip morph (rather than fade-out / fade-in).
///
/// Polish (post design + eng + live-test review):
///   - 4-rectangle absorber scrim (cutout is tap-through; underlying button
///     receives pointer events for interactive steps).
///   - Solid warm-ink overlay (alpha ~0.42). Removed the BackdropFilter
///     blur (2026-05-27) — it was too aggressive and made the surrounding
///     UI unreadable, losing the visual context the tour needs to teach.
///     Industry convention (Linear, Stripe, Notion, Calm coachmarks) is a
///     solid semi-transparent dim, not a blur.
///   - Cream-gradient tooltip with khatam watermark and emerald left stripe.
///   - Soft gold breathing pulse around cutout on interactive steps only.
///   - Hero-style morph between step positions (TweenAnimationBuilder
///     for the cutout, AnimatedSwitcher for the message).
///   - Reduced-motion accessibility: collapses all animations to single frame.
///
/// A11y: tooltip is a live region. Step progress dots have a Semantics label
/// describing "Step X of N". Skip / Next / Done buttons have button semantics.
class CoachmarkOverlay extends StatefulWidget {
  const CoachmarkOverlay({
    super.key,
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.onNext,
    required this.onSkip,
    this.hideUntilAnchorReady = false,
  });

  final CoachmarkStep step;
  final int stepIndex;
  final int totalSteps;

  /// Called when:
  ///   - user taps inside the cutout on an interactive step
  ///   - user taps the Continue / Done button on a teach step
  final VoidCallback onNext;

  /// Called when the user taps Skip. Closes the tour.
  final VoidCallback onSkip;

  /// When true, render `SizedBox.shrink()` instead of the full overlay.
  /// Used by the host while the next step's anchor hasn't yet registered,
  /// or while a blocking modal route is on top of the navigator.
  final bool hideUntilAnchorReady;

  @override
  State<CoachmarkOverlay> createState() => _CoachmarkOverlayState();
}

class _CoachmarkOverlayState extends State<CoachmarkOverlay>
    with TickerProviderStateMixin {
  /// Entry/exit animation. Runs once when this widget first mounts (tour
  /// starts) and reverses when the tour completes or skips (parent removes
  /// the OverlayEntry shortly after).
  late final AnimationController _entryCtrl;
  late final Animation<double> _scrimOpacity;
  late final Animation<double> _tooltipOpacity;
  late final Animation<Offset> _tooltipOffset;

  /// Breathing pulse around the cutout — interactive steps only.
  late final AnimationController _pulseCtrl;

  /// True while the soft keyboard is up. The overlay fades out (and stops
  /// absorbing pointers) so text-entry steps don't cram a cutout + tooltip
  /// into the sliver of screen above the keyboard. Driven from `build` off
  /// `MediaQuery.viewInsets.bottom`.
  bool _keyboardOpen = false;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scrimOpacity = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.47, curve: Curves.easeOut),
    );
    _tooltipOpacity = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.53, 1.0, curve: Curves.easeOut),
    );
    _tooltipOffset = Tween<Offset>(
      begin: const Offset(0, 16),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.53, 1.0, curve: Curves.easeOutCubic),
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

  /// Pulse should run iff:
  ///   - the step is interactive (teach steps don't pulse)
  ///   - the overlay is visible (not hidden by route-stack guard / anchor wait)
  ///
  /// Keeping it off during `hideUntilAnchorReady` matters for tests
  /// (`pumpAndSettle` deadlocks on a repeating animation) AND for battery
  /// (no point pulsing offscreen).
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

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

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
      // Grow the cutout beyond the bare anchor. `padTop` pulls the top edge up
      // (e.g. Duas Build includes the text field above the CTA); `padBottom` +
      // `padX` grow a small centered anchor into its container (e.g. a bottom-
      // nav icon into the full tab cell, so the tab's text label is highlighted
      // too). Every edge is clamped to the screen / safe area so the rect can
      // never invert (which would throw) or spill off-screen.
      final mq = MediaQuery.maybeOf(ctx);
      final safeTop = mq?.padding.top ?? 0.0;
      final size = mq?.size;
      final screenW = size?.width ?? raw.right;
      final screenH = size?.height ?? raw.bottom;
      // Top: don't extend under the status bar / Dynamic Island. Guard against
      // inversion when a top-docked anchor sits above the safe-area inset.
      final topLo = safeTop < raw.top ? safeTop : raw.top;
      final newTop = (raw.top - padTop).clamp(topLo, raw.top);
      // Bottom: extend down, never past the screen edge.
      final bottomHi = screenH > raw.bottom ? screenH : raw.bottom;
      final newBottom = (raw.bottom + padBottom).clamp(raw.bottom, bottomHi);
      // Horizontal: expand both sides, clamped within the screen.
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
    if (widget.hideUntilAnchorReady) {
      return const SizedBox.shrink();
    }
    final mq = MediaQuery.of(context);
    final reduceMotion = mq.disableAnimations || mq.accessibleNavigation;
    // Hide the coachmark while the soft keyboard is up (text-entry steps such
    // as the Duas "Build a Dua" step). With ~40% of the screen consumed by the
    // keyboard there's no room for both the highlight cutout and the tooltip
    // without covering the field the user is typing in — so we fade the whole
    // overlay out for an unobstructed view and fade it back when the keyboard
    // dismisses. The instruction has already been read by the time the field
    // is focused, and the interactive target tap still advances the tour
    // (detection lives in `TourAnchor`, independent of this overlay's
    // visibility), so the flow doesn't break while we're hidden.
    final keyboardOpen = mq.viewInsets.bottom > 1.0;
    if (keyboardOpen != _keyboardOpen) {
      _keyboardOpen = keyboardOpen;
      _syncPulse();
    }
    return OrientationBuilder(
      builder: (context, _) {
        return IgnorePointer(
          // Let taps reach the underlying text field + Build button while
          // hidden. Flips instantly (ahead of the fade) so the very tap that
          // raised the keyboard isn't swallowed by the absorber strips.
          ignoring: keyboardOpen,
          child: AnimatedOpacity(
            opacity: keyboardOpen ? 0.0 : 1.0,
            duration: Duration(milliseconds: reduceMotion ? 0 : 200),
            curve: Curves.easeOut,
            child: AnimatedBuilder(
              animation: _entryCtrl,
              builder: (context, _) =>
                  _build(context, reduceMotion: reduceMotion),
            ),
          ),
        );
      },
    );
  }

  Widget _build(BuildContext context, {required bool reduceMotion}) {
    final rect = _targetRect();
    final mq = MediaQuery.of(context);
    final smallScreen = mq.size.width < 360;
    final isLast = widget.stepIndex == widget.totalSteps - 1;
    final step = widget.step;

    final tooltip = _Tooltip(
      message: step.message,
      hint: step.hint,
      interactive: step.interactive,
      stepIndex: widget.stepIndex,
      totalSteps: widget.totalSteps,
      isLast: isLast,
      smallScreen: smallScreen,
      onNext: widget.onNext,
      onSkip: widget.onSkip,
    );

    final animatedTooltip = Transform.translate(
      offset: reduceMotion ? Offset.zero : _tooltipOffset.value,
      child: Opacity(
        opacity: reduceMotion ? 1.0 : _tooltipOpacity.value,
        child: tooltip,
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Scrim — solid warm-ink overlay + cutout hole. Wrapped in
          // IgnorePointer so the painter doesn't absorb gestures.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedScrim(
                cutout: rect,
                opacity: reduceMotion ? 1.0 : _scrimOpacity.value,
              ),
            ),
          ),
          // Absorbers: 4 rectangles around the cutout that consume taps
          // outside the highlighted target. The cutout area itself is
          // unblocked so the underlying button receives the user's tap.
          if (rect != null) ..._buildAbsorbers(rect, mq.size),
          // Breathing pulse outline — interactive steps only.
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
          // Note: tap detection lives in `TourAnchor` itself (the widget
          // wrapped around the anchor's target). The overlay used to host
          // a `Listener` here, but that approach was unreliable —
          // sometimes only the underlying button fired and the overlay
          // listener was skipped depending on overlay-entry hit-test
          // propagation. Listening at the anchor co-locates with the
          // target, so the pointer-up reliably fires for both.
          // Tooltip card.
          if (rect != null)
            _PositionedTooltip(
              targetRect: rect,
              mediaQuery: mq,
              preferBelow: widget.step.tooltipBelow,
              child: animatedTooltip,
            )
          else
            // Centered step (no anchor): constrain the tooltip width to match
            // the anchored steps (24pt minimum gutter, 460pt cap). Without
            // this the `_Tooltip` Container has no width constraint and
            // stretches edge-to-edge.
            Center(
              child: SizedBox(
                width: (mq.size.width - 48).clamp(0, 460).toDouble(),
                child: animatedTooltip,
              ),
            ),
        ],
      ),
    );
  }

  /// 4 absorber strips around the cutout. Each consumes taps so the user
  /// can't bypass the tour by tapping a different part of the UI. Wrapped
  /// in ExcludeSemantics so screen readers don't see 4 phantom regions.
  List<Widget> _buildAbsorbers(Rect cutout, Size screen) {
    // Pad the cutout by the same 8pt we use for the visual hole, so taps
    // very close to the cutout edge still hit the target.
    final padded = const EdgeInsets.all(8).inflateRect(cutout);
    final top = padded.top.clamp(0.0, screen.height);
    final bottom = padded.bottom.clamp(0.0, screen.height);
    final left = padded.left.clamp(0.0, screen.width);
    final right = padded.right.clamp(0.0, screen.width);
    // A degenerate or taller-than-screen cutout can make `bottom < top`;
    // `Positioned(height: <0)` asserts in debug, so floor the side-strip
    // heights at zero.
    final sideHeight = (bottom - top) < 0 ? 0.0 : bottom - top;
    return [
      // Top strip
      Positioned(
        left: 0,
        top: 0,
        right: 0,
        height: top,
        child: const _AbsorbTap(),
      ),
      // Bottom strip
      Positioned(
        left: 0,
        top: bottom,
        right: 0,
        bottom: 0,
        child: const _AbsorbTap(),
      ),
      // Left strip
      Positioned(
        left: 0,
        top: top,
        width: left,
        height: sideHeight,
        child: const _AbsorbTap(),
      ),
      // Right strip
      Positioned(
        left: right,
        top: top,
        right: 0,
        height: sideHeight,
        child: const _AbsorbTap(),
      ),
    ];
  }
}

/// Tap absorber strip. Consumes taps without forwarding so the user can't
/// bypass the tour by tapping unrelated UI.
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

/// Solid warm-ink scrim with a cutout hole. Animates the cutout rect via
/// `TweenAnimationBuilder<Rect>` so it morphs between steps.
class AnimatedScrim extends StatelessWidget {
  const AnimatedScrim({required this.cutout, required this.opacity, super.key});

  final Rect? cutout;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    // No anchor (centered tooltip case) → solid scrim, no morph.
    // TweenAnimationBuilder<Rect?> requires a non-null `end`, so we
    // bypass it for the null-cutout case.
    if (cutout == null) {
      return CustomPaint(
        painter: _ScrimWithHolePainter(cutout: null, opacity: opacity),
      );
    }
    // Animates the cutout between steps. Linear morph is fine here
    // because TweenAnimationBuilder lerps with Rect.lerp internally;
    // applying an extra curve creates jitter on the hole edge.
    //
    // Duration is intentionally short (120ms): the overlay host ticks
    // every frame to keep the cutout in sync with the anchor's live
    // position (scrolls, post-layout reflows). A longer morph would
    // make the cutout lag behind the anchor during those updates.
    return TweenAnimationBuilder<Rect?>(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      tween: RectTween(end: cutout),
      builder: (_, animatedCutout, __) => CustomPaint(
        painter: _ScrimWithHolePainter(
          cutout: animatedCutout,
          opacity: opacity,
        ),
      ),
    );
  }
}

/// Paints a warm-ink overlay with a rounded-rectangle hole for the cutout.
class _ScrimWithHolePainter extends CustomPainter {
  _ScrimWithHolePainter({required this.cutout, required this.opacity});

  final Rect? cutout;
  final double opacity;

  static const Color _ink = Color(0xFF1B1410);
  static const double _baseAlpha = 0.42;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()
      ..color = _ink.withValues(alpha: _baseAlpha * opacity);
    if (cutout == null) {
      canvas.drawRect(Offset.zero & size, scrim);
      return;
    }
    final padded = const EdgeInsets.all(8).inflateRect(cutout!);
    final rrect = RRect.fromRectAndRadius(
      padded,
      const Radius.circular(16),
    );
    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, scrim);
  }

  @override
  bool shouldRepaint(covariant _ScrimWithHolePainter old) =>
      old.cutout != cutout || old.opacity != opacity;
}

/// Soft gold breathing pulse stroke around the cutout. Painted in its own
/// CustomPaint + RepaintBoundary so the scrim's absorber strips don't
/// repaint at 60fps.
class _PulsePainter extends CustomPainter {
  _PulsePainter({required this.cutout, required this.progress});

  final Rect cutout;
  final double progress; // 0..1, controller value

  @override
  void paint(Canvas canvas, Size size) {
    // Ease the linear controller value via sine for breathing feel.
    final eased = (1 - (1 - progress) * (1 - progress)); // easeOut quad
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

/// Tooltip card — cream gradient + emerald left stripe + gold dot + khatam
/// watermark + body + hint + step dots + Skip / Continue|Done.
class _Tooltip extends StatelessWidget {
  const _Tooltip({
    required this.message,
    required this.hint,
    required this.interactive,
    required this.stepIndex,
    required this.totalSteps,
    required this.isLast,
    required this.smallScreen,
    required this.onNext,
    required this.onSkip,
  });

  final String message;
  final String? hint;
  final bool interactive;
  final int stepIndex;
  final int totalSteps;
  final bool isLast;
  final bool smallScreen;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  static const String _watermarkAsset =
      'assets/illustrations/tooltip_watermark.svg';

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
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              blurRadius: 24,
              color: Color(0x33000000),
              offset: Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Emerald left stripe with gold dot near top.
              SizedBox(
                width: 3,
                child: Container(color: AppColors.primary),
              ),
              Expanded(
                child: Stack(
                  children: [
                    // Khatam watermark in top-right corner. Wrapped in
                    // FutureBuilder-free try since SvgPicture handles
                    // missing assets gracefully if the file is absent.
                    Positioned(
                      top: 12,
                      right: 12,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: 0.06,
                          child: SvgPicture.asset(
                            _watermarkAsset,
                            width: 60,
                            height: 60,
                            // If asset missing, render nothing (matches
                            // the design intent — watermark is decorative).
                            placeholderBuilder: (_) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Gold dot at top of stripe (visually aligns
                          // with the watermark — illuminated-manuscript
                          // marginalia feel).
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                          Text(
                            message,
                            style: const TextStyle(
                              color: AppColors.textPrimaryLight,
                              fontSize: 15,
                              height: 1.35,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (interactive && hint != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              hint!,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _BottomBar(
                            stepIndex: stepIndex,
                            totalSteps: totalSteps,
                            interactive: interactive,
                            isLast: isLast,
                            smallScreen: smallScreen,
                            onNext: onNext,
                            onSkip: onSkip,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Step dots (gold prayer-bead style) + Skip + (Continue|Done if teach mode).
class _BottomBar extends StatefulWidget {
  const _BottomBar({
    required this.stepIndex,
    required this.totalSteps,
    required this.interactive,
    required this.isLast,
    required this.smallScreen,
    required this.onNext,
    required this.onSkip,
  });

  final int stepIndex;
  final int totalSteps;
  final bool interactive;
  final bool isLast;
  final bool smallScreen;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  State<_BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<_BottomBar> {
  // The dots row never accepts user scroll gestures, but we drive it
  // programmatically so the *active* dot is always fully visible. Without
  // this, an overflowing row (e.g. 13 dots + Skip + Done past the 320pt
  // tooltip) hard-clips its tail — and on the final step the tail dot IS the
  // active gold one, so it gets bisected (see screenshot from PR review).
  final ScrollController _dotsController = ScrollController();

  // Each dot is 7pt wide + 6pt right margin. Keep in sync with `_Dot`.
  static const double _dotExtent = 13;

  @override
  void initState() {
    super.initState();
    _scheduleScrollToActive();
  }

  @override
  void didUpdateWidget(covariant _BottomBar old) {
    super.didUpdateWidget(old);
    if (old.stepIndex != widget.stepIndex ||
        old.totalSteps != widget.totalSteps) {
      _scheduleScrollToActive();
    }
  }

  /// After layout, jump the dots so the active one sits fully inside the
  /// viewport. Earlier (completed) dots clip off the left when the row
  /// overflows — far better than clipping the current step's dot off the right.
  void _scheduleScrollToActive() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_dotsController.hasClients) return;
      final pos = _dotsController.position;
      final viewport = pos.viewportDimension;
      final activeStart = widget.stepIndex * _dotExtent;
      final activeEnd = activeStart + _dotExtent; // include trailing margin
      double target = pos.pixels;
      if (activeEnd > pos.pixels + viewport) {
        target = activeEnd - viewport;
      } else if (activeStart < pos.pixels) {
        target = activeStart;
      }
      target = target.clamp(0.0, pos.maxScrollExtent);
      if ((target - pos.pixels).abs() > 0.5) {
        _dotsController.jumpTo(target);
      }
    });
  }

  @override
  void dispose() {
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Flexible so the dots row shrinks when the action buttons need
        // more room (13 dots × 13pt = ~170pt would otherwise crowd the
        // Skip + Continue buttons in narrow tooltip widths).
        Flexible(
          child: Semantics(
            label: 'Step ${widget.stepIndex + 1} of ${widget.totalSteps}',
            container: true,
            child: ExcludeSemantics(
              child: SingleChildScrollView(
                controller: _dotsController,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                clipBehavior: Clip.hardEdge,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < widget.totalSteps; i++)
                      _Dot(active: i == widget.stepIndex),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        _SkipButton(
          smallScreen: widget.smallScreen,
          onSkip: widget.onSkip,
        ),
        if (!widget.interactive) ...[
          const SizedBox(width: 4),
          _ContinueButton(
            isLast: widget.isLast,
            stepIndex: widget.stepIndex,
            totalSteps: widget.totalSteps,
            onNext: widget.onNext,
          ),
        ],
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    if (active) {
      return Container(
        margin: const EdgeInsets.only(right: 6),
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.secondary,
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(right: 6),
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.textTertiaryLight.withValues(alpha: 0.5),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({
    required this.smallScreen,
    required this.onSkip,
  });

  final bool smallScreen;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Skip tour',
      child: TextButton(
        style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
        onPressed: onSkip,
        child: smallScreen
            ? const Icon(
                Icons.close,
                color: AppColors.textSecondaryLight,
                size: 20,
              )
            : const Text(
                'Skip tour',
                style: TextStyle(
                  color: AppColors.textSecondaryLight,
                  fontFamily: 'DM Sans',
                ),
              ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.isLast,
    required this.stepIndex,
    required this.totalSteps,
    required this.onNext,
  });

  final bool isLast;
  final int stepIndex;
  final int totalSteps;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isLast
          ? 'Done, end tour'
          : 'Continue, step ${stepIndex + 1} of $totalSteps',
      child: TextButton(
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
        ),
        onPressed: onNext,
        child: Text(
          isLast ? 'Done' : 'Continue →',
          style: const TextStyle(
            color: AppColors.primary,
            fontFamily: 'DM Sans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Positions the tooltip 14pt below or above the target rect, with auto-flip
/// when the preferred side doesn't have room. Conservatively reserves 220pt
/// for tooltip height when deciding flip; real height is ~140-180pt.
class _PositionedTooltip extends StatelessWidget {
  const _PositionedTooltip({
    required this.targetRect,
    required this.mediaQuery,
    required this.preferBelow,
    required this.child,
  });

  final Rect targetRect;
  final MediaQueryData mediaQuery;
  final bool preferBelow;
  final Widget child;

  static const double _gap = 14;
  static const double _estTooltipHeight = 220;
  static const double _safeTopPad = 8;
  static const double _safeBottomPad = 8;

  @override
  Widget build(BuildContext context) {
    final screenH = mediaQuery.size.height;
    final screenW = mediaQuery.size.width;
    final usableTop = mediaQuery.padding.top + _safeTopPad;
    final usableBottom = screenH - mediaQuery.padding.bottom - _safeBottomPad;
    // Card-width strategy: 24pt minimum gutter on each side, cap at 460pt.
    // Always compute `left` + `width` explicitly (NOT `left` + `right`) so
    // the Container reliably centers — `Positioned(left, right)` + a
    // Container without an explicit width has shown subtle asymmetry on
    // certain device widths.
    const double minGutter = 24;
    const double maxCardWidth = 460;
    final cardWidth = (screenW - 2 * minGutter).clamp(0, maxCardWidth).toDouble();
    final cardLeft = ((screenW - cardWidth) / 2).clamp(0, screenW).toDouble();

    final spaceBelow = usableBottom - (targetRect.bottom + _gap);
    final spaceAbove = (targetRect.top - _gap) - usableTop;
    final fitsBelow = spaceBelow >= _estTooltipHeight;
    final fitsAbove = spaceAbove >= _estTooltipHeight;

    final bool placeBelow;
    if (preferBelow && fitsBelow) {
      placeBelow = true;
    } else if (!preferBelow && fitsAbove) {
      placeBelow = false;
    } else if (fitsBelow) {
      placeBelow = true;
    } else if (fitsAbove) {
      placeBelow = false;
    } else {
      placeBelow = spaceBelow >= spaceAbove;
    }

    if (placeBelow) {
      // On a very short usable height the upper bound can fall below the
      // lower bound; collapse to the lower bound so `clamp` never throws.
      final lo = usableTop;
      final hi = usableBottom - _estTooltipHeight;
      final top = (targetRect.bottom + _gap).clamp(lo, hi < lo ? lo : hi);
      return Positioned(
        left: cardLeft,
        width: cardWidth,
        top: top,
        child: child,
      );
    }
    final blo = screenH - usableBottom;
    final bhi = screenH - usableTop - _estTooltipHeight;
    final bottom =
        (screenH - (targetRect.top - _gap)).clamp(blo, bhi < blo ? blo : bhi);
    return Positioned(
      left: cardLeft,
      width: cardWidth,
      bottom: bottom,
      child: child,
    );
  }
}
