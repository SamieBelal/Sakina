import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_motion.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/dua_times/providers/dua_window_provider.dart';
import 'package:sakina/features/dua_times/widgets/dua_times_copy.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';

/// Key for widget tests — the notice is otherwise identified only by its copy.
const Key kPrecisePausedNoticeKey = Key('dua_times_precise_paused_notice');

/// Key for the explicit dismiss control.
const Key kPrecisePausedNoticeDismissKey =
    Key('dua_times_precise_paused_notice_dismiss');

/// A one-time aside telling a user who already opted in that precise times have
/// stopped, and what actually turns them back on.
///
/// **This is a notice, not a status line.** The original bug was the app
/// re-running an unprompted pitch on every launch; a permanent "paused" row
/// would be the same mistake in quieter clothes. So it is bounded — one episode
/// gets at most [DuaWindowNotifier.lapseNoticeMaxShows] opens, after which
/// Settings holds the state alone.
///
/// **It waits for the user rather than fading (founder decision, 2026-08-03).**
/// It previously followed `FirstVisitHintService` exactly — 6s auto-fade,
/// dismiss on any tap anywhere, no ✕. That doctrine is right for a hint that
/// merely *decorates* a screen the user is already using, and wrong here: this
/// notice is the only in-app surface that explains why precise times stopped,
/// and a fade spends it whether or not anyone was looking. During device QA a
/// tester actively hunting for it still missed it, then found "Paused" in
/// Settings and reasonably concluded the feature was broken.
///
/// So: no timer, no global pointer route, and an explicit ✕. The bound moved
/// from *time* (6 seconds) to *count* (three opens), which is the part of the
/// doctrine that actually prevents the Clippy failure mode.
///
/// **Why the ✕ is safe here.** Apple's pre-alert rules name location and forbid
/// a close control on a view that fronts the system dialog. This notice does
/// not front it: tapping navigates to [PreciseTimesScreen], which is the
/// pre-alert view and carries exactly one button. Keep it that way — wiring
/// this tap straight to `promptLocation()` would re-create the 5.1.1(iv)
/// exposure that the ✕ on the old `_EnablePreciseBanner` had.
///
/// It claims itself (one claim per open, capped per episode), so the card can
/// mount it unconditionally — a spent notice simply stays at zero height.
class PrecisePausedNotice extends ConsumerStatefulWidget {
  const PrecisePausedNotice({
    required this.state,
    required this.onOpenDetails,
    super.key,
  });

  /// Either [PreciseTimesState.permissionLapsed] or
  /// [PreciseTimesState.servicesOff]; anything else renders nothing (see
  /// [messageFor]).
  final PreciseTimesState state;

  /// Navigate to the re-enable steps. NOT a permission prompt — see the class
  /// doc on why that distinction is load-bearing.
  final VoidCallback onOpenDetails;

  /// The one line this state deserves, or null when it deserves silence.
  ///
  /// `declined` returns null on purpose: that user pressed Don't Allow, and
  /// telling them "iOS reset location access" would be false. `working` and
  /// `unresolved` are silent because nothing is wrong.
  static String? messageFor(PreciseTimesState state) => switch (state) {
        PreciseTimesState.permissionLapsed =>
          DuaTimesCopy.precisePausedPermission,
        PreciseTimesState.servicesOff => DuaTimesCopy.precisePausedServices,
        PreciseTimesState.working ||
        PreciseTimesState.neverAsked ||
        PreciseTimesState.declined ||
        PreciseTimesState.unresolved =>
          null,
      };

  @override
  ConsumerState<PrecisePausedNotice> createState() =>
      _PrecisePausedNoticeState();
}

class _PrecisePausedNoticeState extends ConsumerState<PrecisePausedNotice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curve;

  /// Starts hidden: the notice only becomes visible if the claim succeeds, so
  /// claim and visibility are one event.
  bool _visible = false;
  bool _claimAttempted = false;

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Gate the claim on actually being on screen.
    //
    // `TickerMode` is false while this sits under an opaque route — which is the
    // normal cold-start situation here, because `DailyLaunchOverlay` covers the
    // home screen on exactly the launches where a lapse gets detected. Claiming
    // then would spend one of the three opens on a frame nobody sees.
    //
    // TickerMode is inherited, so this rebuilds when the overlay goes away — no
    // polling, no route observer.
    if (_claimAttempted || !TickerMode.valuesOf(context).enabled) return;
    _claimAttempted = true;
    unawaited(_appear());
  }

  Future<void> _appear() async {
    final allowed = await ref
        .read(duaWindowProvider.notifier)
        .claimLapseNotice(widget.state);
    if (!mounted || !allowed) return;
    setState(() => _visible = true);
    // Emitted here rather than at the claim, so the event means "a human could
    // see this" and not merely "a claim succeeded".
    ref.read(analyticsProvider).track(
      AnalyticsEvents.duaTimesPreciseNoticeShown,
      properties: {AnalyticsEvents.propPreciseState: widget.state.wireName},
    );
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
      return;
    }
    await _controller.forward();
  }

  void _track(String action) {
    ref.read(analyticsProvider).track(
      AnalyticsEvents.duaTimesPreciseNoticeAction,
      properties: {
        AnalyticsEvents.propPreciseState: widget.state.wireName,
        AnalyticsEvents.propAction: action,
      },
    );
  }

  /// Close this episode and go to the steps.
  void _open() {
    _track('opened');
    _acknowledge();
    widget.onOpenDetails();
  }

  Future<void> _dismiss() async {
    if (!mounted || !_visible) return;
    _track('dismissed');
    // Persist WITHOUT awaiting, and hide regardless. A dismiss handler that
    // awaits its own bookkeeping before hiding dies silently when the write
    // throws — and a ✕ that does nothing is the worst failure an escape hatch
    // can have. Worst case here is a re-show on the next open, which is exactly
    // what the three-open cap already tolerates.
    _acknowledge();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      setState(() => _visible = false);
      return;
    }
    await _controller.reverse();
    if (mounted) setState(() => _visible = false);
  }

  void _acknowledge() => unawaited(
        ref
            .read(duaWindowProvider.notifier)
            .acknowledgeLapseNotice(widget.state),
      );

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = PrecisePausedNotice.messageFor(widget.state);
    if (!_visible || message == null) return const SizedBox.shrink();

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
          // Inside the SizeTransition, so a retired notice leaves zero gap.
          padding:
              const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.md),
          child: Semantics(
            container: true,
            liveRegion: true,
            child: Container(
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
                  Expanded(
                    child: Semantics(
                      button: true,
                      child: GestureDetector(
                        onTap: _open,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: AppSpacing.md,
                            top: AppSpacing.md,
                            bottom: AppSpacing.md,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Gold as a non-text fill only — a 6px marker,
                              // never gold type on cream (DESIGN §2.3).
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.secondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(
                                  width: AppSpacing.sm + AppSpacing.xs),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message,
                                      style: AppTypography.bodyMedium
                                          .copyWith(color: ink),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      DuaTimesCopy.precisePausedCta,
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: dark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimaryLight,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // The escape hatch. Sized to the 44pt minimum so it is
                  // genuinely hittable next to the tap-through target.
                  Semantics(
                    button: true,
                    label: 'Dismiss',
                    child: InkResponse(
                      key: kPrecisePausedNoticeDismissKey,
                      onTap: _dismiss,
                      radius: 22,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.close_rounded, size: 16, color: ink),
                      ),
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
