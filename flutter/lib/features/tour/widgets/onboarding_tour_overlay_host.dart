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
    _entry?.markNeedsBuild();
  }

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
    // Watch controller + registry. When either changes we need to reconcile
    // the overlay entry (insert / remove / mark needs build).
    ref.watch(onboardingTourControllerProvider);
    ref.watch(tourAnchorRegistryProvider);

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
      if (_trackTicker.isActive) _trackTicker.stop();
      return;
    }

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

  void _maybeScheduleAnchorTimeout() {
    _anchorTimeoutTimer?.cancel();
    final tour = ref.read(onboardingTourControllerProvider);
    final step = tour.currentStep;
    if (step == null) return;
    final registry = ref.read(tourAnchorRegistryProvider);
    final isCentered = step.anchorId == 'centered';
    final anchorPresent =
        isCentered || registry.lookup(step.surface, step.anchorId) != null;
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
    final hidden = blockingRouteUp || (!isCentered && anchorKey == null);

    final coachmarkStep = CoachmarkStep(
      target: anchorKey,
      message: step.message,
      tooltipBelow: step.tooltipBelow,
      interactive: step.interactive,
      hint: step.hint,
      cutoutPaddingTop: step.cutoutPaddingTop,
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
