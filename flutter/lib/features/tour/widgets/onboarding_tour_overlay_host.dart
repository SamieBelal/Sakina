import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/analytics_events.dart';
import '../../../services/analytics_provider.dart';
import '../../../widgets/achievement_toast.dart' show rootNavigatorKey;
import '../../../widgets/coachmark/coachmark_overlay.dart';
import '../../../widgets/coachmark/coachmark_step.dart';
import '../models/onboarding_tour_step.dart';
import '../providers/onboarding_tour_controller.dart';
import '../providers/tour_anchor_registry.dart';
import '../providers/tour_route_observer.dart';

/// Reveal-settle tuning — keeps the coachmark (cutout + tooltip) hidden until
/// the destination screen's transition has visibly come to rest, instead of
/// popping in over a still-animating screen. Covers: root route push slides
/// (`/muhasabah`, `DuaDetailPage`), the muhasabah `AnimatedSwitcher`
/// cross-fade, `flutter_animate` fadeIn/slideY screen entries, and the
/// auto-scroll-into-view.
///
/// Two gates, BOTH must pass before reveal:
///   1. a minimum settle delay since the step became active — covers fade-only
///      transitions where the anchor never changes position; and
///   2. the anchor rect is no longer moving frame-to-frame — covers slides and
///      scrolls whose motion outlasts the floor (reveals one frame after the
///      motion stops).
/// Bypassed under reduce-motion (entries/route transitions are themselves
/// disabled, so there is nothing to wait for).
const Duration _kRevealMinSettle = Duration(milliseconds: 400);

/// Per-edge tolerance (logical px) for treating two successive anchor rects as
/// "the same" — absorbs sub-pixel jitter so we don't read it as motion.
const double _kAnchorRectEpsilon = 1.0;

/// Mounts the tour `CoachmarkOverlay` into the root navigator's `Overlay`
/// using `rootNavigatorKey.currentState?.overlay`. This is the same place
/// SnackBars, Dialogs, and Tooltips mount — it's the canonical "above all
/// routes but inside the navigator's hit-test region" position.
///
/// Why we don't use a Stack sibling: when CoachmarkOverlay is rendered as
/// a sibling above the app content, the `Listener` over the cutout reports
/// HIT in `translucent` mode, which makes Flutter's outer Stack stop hit-
/// testing the underlying app content. Result: tour advances on tap, but
/// the underlying button never fires. Mounting in the root overlay solves
/// this because hit testing for routes happens BELOW our OverlayEntry, and
/// the cutout's IgnorePointer'd scrim + the tap-through Listener correctly
/// let the underlying button receive the same tap.
///
/// The same `CoachmarkOverlay` widget instance persists across step
/// changes (no `key` swap) so its `AnimationController`s + `TweenAnimationBuilder`
/// state survive — required for the hero-morph polish between cutout rects.
class OnboardingTourOverlayHost extends ConsumerStatefulWidget {
  const OnboardingTourOverlayHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<OnboardingTourOverlayHost> createState() =>
      _OnboardingTourOverlayHostState();
}

class _OnboardingTourOverlayHostState
    extends ConsumerState<OnboardingTourOverlayHost>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _entry;
  Timer? _anchorTimeoutTimer;

  /// We listen on this stable observer instance (singleton in `tour_route_observer.dart`).
  late final TourRouteObserver _observer = tourRouteObserver;

  /// Ticks every frame while the tour is active so the cutout follows the
  /// anchor through scrolls, animations, and post-layout reflows. Without
  /// this, the rect is only captured on state-changes and can lag behind
  /// when `Scrollable.ensureVisible` shifts the anchor under us.
  late final Ticker _trackTicker = createTicker(_onTick);

  void _onTick(Duration _) {
    _updateRevealReadiness();
    _entry?.markNeedsBuild();
  }

  // --- Reveal-settle state (see _kRevealMinSettle docs above) -----------------
  /// The step id the settle state is currently tracking. When the active step
  /// changes we reset the gates and re-arm the timer.
  String? _settleStepId;

  /// True once the min-settle timer has fired for the current step.
  bool _minSettleElapsed = false;

  /// True once BOTH gates have passed — the coachmark may show.
  bool _revealReady = false;

  /// Fires `_kRevealMinSettle` after the step activates.
  Timer? _settleTimer;

  /// Last observed global anchor rect, for frame-to-frame motion detection.
  Rect? _lastAnchorRect;

  /// True once the current step's anchor has first become drawable. The
  /// min-settle floor is armed from THIS moment (not the logical step change)
  /// because some steps activate while their anchor is still several silent
  /// taps away (e.g. muhasabah "Ameen" — the tour advances on "Read the Story"
  /// but `ameenCta` only mounts after the later "See the Dua" tap). Timing the
  /// floor from step-change would let it elapse before the anchor's entry
  /// transition even begins, popping the coachmark in mid-animation.
  bool _anchorAppeared = false;

  /// Snapshot of MediaQuery.disableAnimations, refreshed each build. When true
  /// the settle gates are skipped so reduce-motion users reveal immediately.
  bool _reduceMotion = false;

  /// Resets the settle gates + re-arms the min-settle timer when the active
  /// step changes. Idempotent per step (the `_settleStepId` guard), so the
  /// per-frame / post-frame churn that calls `_syncOverlay` doesn't restart it.
  void _resetSettleIfStepChanged(OnboardingTourState tour) {
    final id = tour.currentStep?.id;
    if (id == _settleStepId) return;
    _settleStepId = id;
    _settleTimer?.cancel();
    _settleTimer = null;
    _lastAnchorRect = null;
    _anchorAppeared = false;
    _minSettleElapsed = false;

    if (id == null || _reduceMotion) {
      // Nothing to settle — reveal as soon as the anchor resolves.
      _revealReady = _reduceMotion;
      _minSettleElapsed = true;
      return;
    }

    _revealReady = false;
    // The min-settle timer is armed lazily in `_updateRevealReadiness`, when
    // the anchor first appears — see `_anchorAppeared`.
  }

  /// Per-frame readiness check (called from the tracking ticker). Flips
  /// `_revealReady` true once the min-settle floor has elapsed AND the anchor
  /// rect has stopped moving frame-to-frame. Reveal is sticky: once true it
  /// stays true for the step (a later modal/suppression still hides via the
  /// other `hidden` gates, but we don't re-run the settle).
  void _updateRevealReadiness() {
    if (_revealReady) return;
    if (_reduceMotion) {
      _revealReady = true;
      return;
    }
    final step = ref.read(onboardingTourControllerProvider).currentStep;
    if (step == null) return;
    // While a blocking modal is up or the step is suppressed, the destination
    // isn't on screen yet — don't accrue stability and drop any stale rect.
    if (_observer.isBlockingRouteOnTop || ref.read(tourSuppressedProvider)) {
      _lastAnchorRect = null;
      return;
    }
    final rect = _anchorRect(step);
    if (rect == null) {
      _lastAnchorRect = null;
      return;
    }
    // Arm the min-settle floor the first frame the anchor is drawable, so it
    // measures the anchor's entry transition rather than the (possibly much
    // earlier) logical step change.
    if (!_anchorAppeared) {
      _anchorAppeared = true;
      _settleTimer?.cancel();
      _settleTimer = Timer(_kRevealMinSettle, () {
        _minSettleElapsed = true;
        // Nudge a rebuild so `_revealReady` can flip on the next tick once the
        // anchor has also stopped moving.
        _entry?.markNeedsBuild();
      });
    }
    final last = _lastAnchorRect;
    _lastAnchorRect = rect;
    final moving = last != null && !_rectsClose(last, rect);
    if (!moving && _minSettleElapsed) {
      _revealReady = true;
    }
  }

  /// Global rect of the current step's anchor, or null if it can't be drawn
  /// yet. Centered steps have no anchor to track, so they return a constant
  /// (always "not moving") and are gated by the min-settle timer alone — which
  /// covers the `DuaDetailPage` push transition for the final step.
  Rect? _anchorRect(OnboardingTourStepDef step) {
    if (step.anchorId == 'centered') return Rect.zero;
    final key = ref
        .read(tourAnchorRegistryProvider)
        .lookup(step.surface, step.anchorId);
    final ctx = key?.currentContext;
    if (ctx == null || !ctx.mounted) return null;
    final ro = ctx.findRenderObject();
    if (ro is! RenderBox || !ro.attached || !ro.hasSize) return null;
    return ro.localToGlobal(Offset.zero) & ro.size;
  }

  bool _rectsClose(Rect a, Rect b) =>
      (a.left - b.left).abs() <= _kAnchorRectEpsilon &&
      (a.top - b.top).abs() <= _kAnchorRectEpsilon &&
      (a.width - b.width).abs() <= _kAnchorRectEpsilon &&
      (a.height - b.height).abs() <= _kAnchorRectEpsilon;

  @override
  void initState() {
    super.initState();
    _observer.onPop = _onRoutePopped;
    _observer.topRouteName.addListener(_onTopRouteChanged);
  }

  @override
  void dispose() {
    _observer.onPop = null;
    _observer.topRouteName.removeListener(_onTopRouteChanged);
    _anchorTimeoutTimer?.cancel();
    _settleTimer?.cancel();
    // Ticker.dispose() asserts !isActive in debug builds. Stop first so
    // a host disposed mid-tour (hot-reload, router rebuild) doesn't crash.
    if (_trackTicker.isActive) _trackTicker.stop();
    _trackTicker.dispose();
    _entry?.remove();
    _entry = null;
    super.dispose();
  }

  void _onTopRouteChanged() {
    if (!mounted) return;
    // Rebuild the overlay entry when a blocking modal pops on or off.
    _entry?.markNeedsBuild();
    // A blocking route cancels the anchor timeout. Reconcile after the
    // route transition so the timer is re-armed when that modal closes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncOverlay();
    });
  }

  void _onRoutePopped(Route<dynamic> route, Route<dynamic>? prev) {
    if (!mounted) return;
    final tour = ref.read(onboardingTourControllerProvider);
    if (!tour.isActive) return;
    final step = tour.currentStep;
    if (step == null) return;
    if (route.settings.name == 'DuaDetailPage' && step.id == 'duaDetail.done') {
      ref
          .read(onboardingTourControllerProvider.notifier)
          .advance(via: 'back_gesture');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch controller + registry + suppression flag. When any changes we
    // need to reconcile the overlay entry (insert / remove / mark needs
    // build) and re-evaluate the anchor-timeout.
    ref.watch(onboardingTourControllerProvider);
    ref.watch(tourAnchorRegistryProvider);
    ref.watch(tourSuppressedProvider);

    // Reduce-motion disables route transitions + entry animations, so there is
    // nothing to settle — skip the gates in that case.
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncOverlay();
    });

    return widget.child;
  }

  void _syncOverlay() {
    final tour = ref.read(onboardingTourControllerProvider);

    if (!tour.isActive) {
      _entry?.remove();
      _entry = null;
      _anchorTimeoutTimer?.cancel();
      _anchorTimeoutTimer = null;
      _lastScrolledStepId = null;
      _settleTimer?.cancel();
      _settleTimer = null;
      _settleStepId = null;
      _revealReady = false;
      _minSettleElapsed = false;
      _anchorAppeared = false;
      _lastAnchorRect = null;
      if (_trackTicker.isActive) _trackTicker.stop();
      return;
    }

    // Re-arm the reveal-settle gates whenever the active step changes.
    _resetSettleIfStepChanged(tour);

    final overlayState = rootNavigatorKey.currentState?.overlay;
    if (overlayState == null) {
      // Navigator not yet ready — retry next frame.
      return;
    }

    if (_entry == null) {
      _entry = OverlayEntry(builder: _buildOverlay);
      overlayState.insert(_entry!);
    } else {
      _entry!.markNeedsBuild();
    }
    if (!_trackTicker.isActive) _trackTicker.start();

    _maybeScheduleAnchorTimeout();
    _maybeScrollAnchorIntoView();
  }

  /// If the current step's anchor is registered but sits outside the visible
  /// viewport (e.g. below the fold inside a `ListView`), scroll the nearest
  /// `Scrollable` so the user can see what the tooltip is pointing at.
  ///
  /// Tracks the last-scrolled step id so we don't ping-pong if the user
  /// scrolls away again — auto-scroll fires ONCE per step activation.
  String? _lastScrolledStepId;
  void _maybeScrollAnchorIntoView() {
    final tour = ref.read(onboardingTourControllerProvider);
    final step = tour.currentStep;
    if (step == null) return;
    if (step.anchorId == 'centered') return;
    if (_observer.isBlockingRouteOnTop) return;
    if (_lastScrolledStepId == step.id) return;
    final registry = ref.read(tourAnchorRegistryProvider);
    final key = registry.lookup(step.surface, step.anchorId);
    final ctx = key?.currentContext;
    if (ctx == null || !ctx.mounted) return;
    _lastScrolledStepId = step.id;
    // Defer one frame so the anchor's RenderObject has its final layout
    // (especially mid-fadeIn/slideY animation).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!ctx.mounted) return;
      try {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
          alignment: 0.5, // center within viewport
        );
      } catch (_) {
        // No Scrollable ancestor — nothing to do.
      }
    });
  }

  /// True when the current step's anchor can actually be drawn — either it is
  /// a centered step, or its registered key resolves to an attached, sized
  /// `RenderBox`. A key that is registered but whose widget is detached or
  /// zero-size (e.g. lives in an off-screen / not-yet-built subtree) counts as
  /// NOT resolvable, so the anchor-timeout still arms and the step can't hang
  /// forever waiting on a rect that will never come.
  bool _anchorResolvable(OnboardingTourStepDef step) {
    if (step.anchorId == 'centered') return true;
    final key = ref
        .read(tourAnchorRegistryProvider)
        .lookup(step.surface, step.anchorId);
    final ctx = key?.currentContext;
    if (ctx == null || !ctx.mounted) return false;
    final ro = ctx.findRenderObject();
    return ro is RenderBox && ro.attached && ro.hasSize;
  }

  void _maybeScheduleAnchorTimeout() {
    _anchorTimeoutTimer?.cancel();
    final tour = ref.read(onboardingTourControllerProvider);
    final step = tour.currentStep;
    if (step == null) return;
    // While suppressed (e.g. mid Dua-build flow), do not arm the timeout —
    // the step is intentionally pending until the host screen surfaces the
    // anchor. Cancelled above; re-armed once suppression lifts via the
    // `tourSuppressedProvider` watch in `build`.
    if (ref.read(tourSuppressedProvider)) return;
    final anchorPresent = _anchorResolvable(step);
    if (anchorPresent) return;
    if (_observer.isBlockingRouteOnTop) return;
    final pinnedStepId = step.id;
    _anchorTimeoutTimer = Timer(const Duration(seconds: 60), () {
      if (!mounted) return;
      final current = ref.read(onboardingTourControllerProvider);
      if (!current.isActive) return;
      if (current.currentStep?.id != pinnedStepId) return;
      try {
        ref.read(analyticsProvider).track(
          AnalyticsEvents.tourAnchorTimeout,
          properties: {'step_id': pinnedStepId},
        );
      } catch (_) {}
      ref
          .read(onboardingTourControllerProvider.notifier)
          .advance(via: 'anchor_timeout');
    });
  }

  Widget _buildOverlay(BuildContext overlayContext) {
    final tour = ref.read(onboardingTourControllerProvider);
    final step = tour.currentStep;
    if (step == null) return const SizedBox.shrink();

    final registry = ref.read(tourAnchorRegistryProvider);
    final blockingRouteUp = _observer.isBlockingRouteOnTop;
    final isCentered = step.anchorId == 'centered';
    final anchorKey =
        isCentered ? null : registry.lookup(step.surface, step.anchorId);
    // Hide while a blocking modal is up, while explicitly suppressed (mid
    // Dua-build), until the anchor resolves to a real on-screen rect, or until
    // the reveal-settle gates pass (so the coachmark doesn't pop in over a
    // still-animating screen transition — see `_kRevealMinSettle`).
    final hidden = blockingRouteUp ||
        ref.read(tourSuppressedProvider) ||
        !_anchorResolvable(step) ||
        !_revealReady;

    final coachmarkStep = CoachmarkStep(
      target: anchorKey,
      message: step.message,
      tooltipBelow: step.tooltipBelow,
      interactive: step.interactive,
      hint: step.hint,
      cutoutPaddingTop: step.cutoutPaddingTop,
      cutoutPaddingBottom: step.cutoutPaddingBottom,
      cutoutPaddingX: step.cutoutPaddingX,
    );

    // No `key` — same CoachmarkOverlay instance persists across step
    // changes so AnimationController + TweenAnimationBuilder state survives,
    // enabling the hero-morph polish.
    return CoachmarkOverlay(
      step: coachmarkStep,
      stepIndex: tour.index,
      totalSteps: kOnboardingTourLength,
      hideUntilAnchorReady: hidden,
      onNext: _onNext,
      onSkip: _onSkip,
    );
  }

  void _onNext() {
    final tour = ref.read(onboardingTourControllerProvider);
    final step = tour.currentStep;
    if (step == null) return;
    final via = step.interactive ? 'target_tap' : 'continue';
    ref.read(onboardingTourControllerProvider.notifier).advance(via: via);
  }

  Future<void> _onSkip() async {
    await ref.read(onboardingTourControllerProvider.notifier).skip();
  }
}
