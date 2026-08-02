import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_motion.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/services/first_visit_hint_service.dart';

/// A quiet aside beside the thing it describes — the first-visit hint (F3).
///
/// **Not a coachmark and not a tour step.** Drop it inline into a screen's
/// layout, next to the feature it explains. It:
///
///   * dims nothing and absorbs nothing — it is an ordinary widget in the
///     layout, so every control on the screen stays live behind and around it;
///   * shows no step counter, no "next", no "skip" — there is no sequence to
///     be in;
///   * dismisses on **any** tap anywhere on screen, or fades itself out after
///     [firstVisitHintAutoFade];
///   * appears at most once, ever, and only when
///     [FirstVisitHintService.claim] allows it.
///
/// The "any tap anywhere" dismiss is implemented with a **global pointer
/// route** rather than a full-screen catcher. A full-screen widget — even a
/// translucent one — sits at the top of the hit-test stack and swallows the
/// tap, which is the tap-absorber behaviour we are specifically not building.
/// A global route observes every pointer without consuming any of them, so the
/// tap that dismisses the hint also lands on whatever the user actually meant
/// to press.
class FirstVisitHintBanner extends StatefulWidget {
  const FirstVisitHintBanner({
    super.key,
    required this.hint,
    this.padding = const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    FirstVisitHintService? service,
  }) : _service = service;

  /// Which hint this is — carries both the once-ever pref key and the copy.
  final FirstVisitHintId hint;

  /// Outer padding, so the banner can sit correctly in whatever column it is
  /// dropped into. Collapses with the banner, so an unshown hint costs no space.
  final EdgeInsetsGeometry padding;

  final FirstVisitHintService? _service;

  FirstVisitHintService get service =>
      _service ?? FirstVisitHintService.instance;

  @override
  State<FirstVisitHintBanner> createState() => _FirstVisitHintBannerState();
}

class _FirstVisitHintBannerState extends State<FirstVisitHintBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curve;

  Timer? _autoFadeTimer;
  bool _visible = false;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.entrance,
      reverseDuration: AppMotion.recede,
    );
    _curve = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.enter,
      reverseCurve: AppMotion.exit,
    );
    unawaited(_claim());
  }

  Future<void> _claim() async {
    final allowed = await widget.service.claim(widget.hint);
    if (!mounted || !allowed) return;

    setState(() => _visible = true);
    _autoFadeTimer = Timer(firstVisitHintAutoFade, _dismiss);

    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      // Reduce-motion drops the entrance, never the dismissal: an aside that
      // cannot leave is worse than one that arrives abruptly.
      _controller.value = 1;
      _listen();
      return;
    }
    await _controller.forward();
    // Armed only once the banner has finished arriving, so the pointer-up
    // ripple of the very tap that navigated here cannot dismiss it unread.
    if (mounted) _listen();
  }

  void _listen() {
    if (_listening) return;
    _listening = true;
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
  }

  void _stopListening() {
    if (!_listening) return;
    _listening = false;
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
  }

  void _onPointer(PointerEvent event) {
    if (event is PointerDownEvent) _dismiss();
  }

  Future<void> _dismiss() async {
    _autoFadeTimer?.cancel();
    _autoFadeTimer = null;
    _stopListening();
    if (!mounted || !_visible) return;

    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      setState(() => _visible = false);
      return;
    }
    await _controller.reverse();
    if (mounted) setState(() => _visible = false);
  }

  @override
  void dispose() {
    _autoFadeTimer?.cancel();
    _stopListening();
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = dark ? AppColors.borderDark : AppColors.borderLight;
    final ink =
        dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return SizeTransition(
      sizeFactor: _curve,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: _curve,
        child: Padding(
          padding: widget.padding,
          child: Semantics(
            container: true,
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: surface,
                // Hairline border, zero elevation — separation comes from the
                // border, never a shadow (DESIGN §1).
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gold as a non-text fill only — a 6px marker, never gold
                  // type on cream (DESIGN §2.3).
                  Container(
                    // Optically centred on the first line of `bodyMedium`
                    // (15 / 1.5 = 22.5pt line box).
                    margin: const EdgeInsets.only(top: 8),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                  Expanded(
                    child: Text(
                      widget.hint.message,
                      style: AppTypography.bodyMedium.copyWith(color: ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
