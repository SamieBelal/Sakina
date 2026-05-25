import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'coachmark_step.dart';

/// Cream value reused as `AppColors.cream` from the design spec. The
/// codebase exposes the warm cream as [AppColors.backgroundLight] (#FBF7F2);
/// alias it locally so the spec-named field works without polluting
/// app_colors.dart.
const Color _cream = AppColors.backgroundLight;

/// Renders a cream-warm scrim + cutout around [step.target] with an emerald
/// tooltip card. Fade + slide-up intro animation (~600ms total). Rebuilds on
/// rotation via OrientationBuilder.
///
/// A11y: tooltip is a live region (announced by VoiceOver/TalkBack on
/// insert). Skip/Next buttons labeled with step progress. Scrim painter
/// is excluded from semantics tree.
class CoachmarkOverlay extends StatefulWidget {
  const CoachmarkOverlay({
    super.key,
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.onNext,
    required this.onSkip,
  });

  final CoachmarkStep step;
  final int stepIndex;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  State<CoachmarkOverlay> createState() => _CoachmarkOverlayState();
}

class _CoachmarkOverlayState extends State<CoachmarkOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scrimOpacity;
  late final Animation<double> _cutoutGrowth;
  late final Animation<Offset> _tooltipOffset;
  late final Animation<double> _tooltipOpacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scrimOpacity = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.47, curve: Curves.easeOut),
    );
    _cutoutGrowth = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.3, 0.63, curve: Curves.easeOutBack),
    );
    _tooltipOpacity = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.53, 1.0, curve: Curves.easeOut),
    );
    _tooltipOffset = Tween<Offset>(
      begin: const Offset(0, 16),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.53, 1.0, curve: Curves.easeOut),
    ));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Rect? _targetRect() {
    final ctx = widget.step.target.currentContext;
    if (ctx == null || !ctx.mounted) return null;
    try {
      final box = ctx.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) return null;
      final offset = box.localToGlobal(Offset.zero);
      return offset & box.size;
    } catch (_) {
      // Element became defunct between the mounted check and lookup (e.g.
      // mid-disposal frame). Treat as missing — overlay falls back to
      // centered tooltip and the owning widget will tear us down shortly.
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, _) {
        // Rotation triggers a rebuild here, which re-computes _targetRect()
        // for the new layout.
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) => _build(context),
        );
      },
    );
  }

  Widget _build(BuildContext context) {
    final rect = _targetRect();
    final mq = MediaQuery.of(context);
    final smallScreen = mq.size.width < 360;
    final isLast = widget.stepIndex == widget.totalSteps - 1;

    final tooltip = _Tooltip(
      message: widget.step.message,
      stepIndex: widget.stepIndex,
      totalSteps: widget.totalSteps,
      isLast: isLast,
      smallScreen: smallScreen,
      onNext: widget.onNext,
      onSkip: widget.onSkip,
    );

    final animatedTooltip = Transform.translate(
      offset: _tooltipOffset.value,
      child: Opacity(opacity: _tooltipOpacity.value, child: tooltip),
    );

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: CustomPaint(
                painter: _ScrimPainter(
                  cutout: rect,
                  growth: _cutoutGrowth.value,
                  scrimOpacity: _scrimOpacity.value,
                ),
              ),
            ),
          ),
          if (rect != null)
            Positioned(
              left: 16,
              right: 16,
              top: widget.step.tooltipBelow
                  ? (rect.bottom + 14).clamp(0.0, mq.size.height - 240)
                  : null,
              bottom: widget.step.tooltipBelow
                  ? null
                  : (mq.size.height - rect.top + 14)
                      .clamp(0.0, mq.size.height - 240),
              child: animatedTooltip,
            )
          else
            Center(child: animatedTooltip),
        ],
      ),
    );
  }
}

class _Tooltip extends StatelessWidget {
  const _Tooltip({
    required this.message,
    required this.stepIndex,
    required this.totalSteps,
    required this.isLast,
    required this.smallScreen,
    required this.onNext,
    required this.onSkip,
  });

  final String message;
  final int stepIndex;
  final int totalSteps;
  final bool isLast;
  final bool smallScreen;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          border: const Border(
            top: BorderSide(color: AppColors.secondary, width: 1),
          ),
          boxShadow: const [
            BoxShadow(
              blurRadius: 24,
              color: Color(0x33000000),
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                color: _cream,
                fontSize: 15,
                height: 1.35,
                fontFamily: 'DM Sans',
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (var i = 0; i < totalSteps; i++)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == stepIndex
                          ? AppColors.secondary
                          : _cream.withValues(alpha: 0.35),
                    ),
                  ),
                const Spacer(),
                _SkipButton(
                  smallScreen: smallScreen,
                  onSkip: onSkip,
                  stepIndex: stepIndex,
                  totalSteps: totalSteps,
                ),
                const SizedBox(width: 4),
                Semantics(
                  button: true,
                  label: isLast
                      ? 'Done, end tour'
                      : 'Next, step ${stepIndex + 1} of $totalSteps',
                  child: TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(44, 44),
                    ),
                    onPressed: onNext,
                    child: Text(
                      isLast ? 'Done' : 'Next →',
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontFamily: 'DM Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({
    required this.smallScreen,
    required this.onSkip,
    required this.stepIndex,
    required this.totalSteps,
  });
  final bool smallScreen;
  final VoidCallback onSkip;
  final int stepIndex;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Skip tour',
      child: TextButton(
        style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
        onPressed: onSkip,
        child: smallScreen
            ? Icon(
                Icons.close,
                color: _cream.withValues(alpha: 0.85),
                size: 20,
              )
            : Text(
                'Skip tour',
                style: TextStyle(
                  color: _cream.withValues(alpha: 0.85),
                  fontFamily: 'DM Sans',
                ),
              ),
      ),
    );
  }
}

class _ScrimPainter extends CustomPainter {
  _ScrimPainter({
    required this.cutout,
    required this.growth,
    required this.scrimOpacity,
  });
  final Rect? cutout;
  final double growth; // 0..1 — interpolates cutout from center to full
  final double scrimOpacity; // 0..1 — fades scrim in

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()
      ..color = const Color(0xFF1B0E0E).withValues(alpha: 0.55 * scrimOpacity);
    if (cutout == null) {
      canvas.drawRect(Offset.zero & size, scrim);
      return;
    }
    final padded = const EdgeInsets.all(8).inflateRect(cutout!);
    final interpolated = Rect.lerp(
      Rect.fromCenter(center: padded.center, width: 0, height: 0),
      padded,
      growth,
    )!;
    final rrect = RRect.fromRectAndRadius(
      interpolated,
      const Radius.circular(16),
    );
    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, scrim);
  }

  @override
  bool shouldRepaint(covariant _ScrimPainter old) =>
      old.cutout != cutout ||
      old.growth != growth ||
      old.scrimOpacity != scrimOpacity;
}
