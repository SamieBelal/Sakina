import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_session.dart';
import '../../../services/analytics_events.dart';
import '../../../services/analytics_provider.dart';
import '../../../widgets/achievement_toast.dart' show rootNavigatorKey;
import '../../../widgets/coachmark/coachmark_overlay.dart';
import '../../../widgets/coachmark/coachmark_step.dart';
import '../models/onboarding_tour_step.dart';
import '../providers/onboarding_tour_controller.dart';
import '../providers/tour_anchor_registry.dart';
import '../providers/tour_route_observer.dart';

/// Reveal-settle delay — keeps the coachmark (cutout + tooltip) hidden for a
/// short beat after the current step's anchor first becomes drawable, so it
/// doesn't pop in over a still-animating screen transition / entry animation /
/// auto-scroll. Measured from when the anchor APPEARS (not the logical step
/// change) because some steps activate while their anchor is still several
/// silent taps away (e.g. muhasabah "Ameen"); timing from step-change would
/// elapse before the anchor's entry transition even begins.
///
/// This is the whole reveal gate now — a single fixed delay, no frame-to-frame
/// motion detection, no max-settle ceiling, no sticky-reveal special-case. Once
/// it elapses the coachmark shows; the per-frame ticker keeps the cutout glued
/// to the anchor as it scrolls/animates, and `CoachmarkOverlay` degrades
/// gracefully (banner without ring) if the anchor rect is briefly null during a
/// host rebuild — so a transient `TourAnchor` re-register is invisible instead
/// of re-hiding the coachmark (the old flicker / re-hide bug, Bug 2).
///
/// Bypassed under reduce-motion (entries/route transitions are themselves
/// disabled, so there is nothing to wait for — reveal immediately).
const Duration _kRevealSettle = Duration(milliseconds: 400);

/// Substitutes the resolved display name into a step's `{name}` placeholder.
/// When the name is missing (resolution failed / not yet loaded) the
/// placeholder + its leading separator are stripped so the copy still reads
/// naturally (e.g. "Assalamu alaikum, {name} 👋" → "Assalamu alaikum 👋").
String _personalizeTourCopy(String template, String? name) {
  final n = name?.trim();
  if (n == null || n.isEmpty) {
    return template
        .replaceAll(', {name}', '')
        .replaceAll(' {name}', '')
        .replaceAll('{name}', '')
        .trim();
  }
  return template.replaceAll('{name}', n);
}

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
    _maybeArmSettleOnAnchorAppearance();
    _entry?.markNeedsBuild();
  }

  // --- Reveal-settle state (see _kRevealSettle docs above) --------------------
  /// The step id the settle state is currently tracking. When the active step
  /// changes we reset the gate and re-arm the timer.
  String? _settleStepId;

  /// True once the settle delay has elapsed for the current step — the
  /// coachmark may show. Sticky: once true it stays true for the step (the
  /// `hidden` gates in `_buildOverlay` still hide for a blocking modal / stale
  /// suppression, but we never re-run the settle).
  bool _revealReady = false;

  /// Fires `_kRevealSettle` after the anchor first appears.
  Timer? _settleTimer;

  /// Snapshot of MediaQuery.disableAnimations, refreshed each build. When true
  /// the settle is skipped so reduce-motion users reveal immediately.
  bool _reduceMotion = false;

  /// Resets the reveal gate when the active step changes. Idempotent per step
  /// (the `_settleStepId` guard), so the per-frame / post-frame churn that
  /// calls `_syncOverlay` doesn't restart it.
  void _resetSettleIfStepChanged(OnboardingTourState tour) {
    final id = tour.currentStep?.id;
    if (id == _settleStepId) return;
    final step = tour.currentStep;
    _settleStepId = id;
    _settleTimer?.cancel();
    _settleTimer = null;

    if (id == null) {
      _revealReady = false;
      return;
    }
    if (_reduceMotion) {
      // Nothing to settle — reveal immediately.
      _revealReady = true;
      return;
    }
    _revealReady = false;

    // Centered steps (the final `duaDetail.done` celebration) have NO anchor to
    // wait on. Arm the settle directly here from the step change (covers the
    // `DuaDetailPage` push transition); blocking modals are re-checked in
    // `build`.
    if (step != null && step.anchorId == 'centered') {
      _settleTimer = Timer(_kRevealSettle, () {
        if (!mounted) return;
        _revealReady = true;
        _entry?.markNeedsBuild();
      });
    }
    // For anchored steps the settle timer is armed lazily, the first frame the
    // anchor becomes drawable — see `_maybeArmSettleOnAnchorAppearance`.
  }

  /// Arms the fixed settle timer the first frame the current anchored step's
  /// anchor becomes drawable, so the delay measures the anchor's entry
  /// transition rather than the (possibly much earlier) logical step change.
  /// Called every frame from the ticker; a no-op once the timer is armed or the
  /// step is centered / reduce-motion / already revealed.
  void _maybeArmSettleOnAnchorAppearance() {
    if (_reduceMotion || _revealReady) return;
    if (_settleTimer != null) return; // already armed
    final step = ref.read(onboardingTourControllerProvider).currentStep;
    if (step == null || step.anchorId == 'centered') return;
    // Don't start the clock while the destination isn't on screen.
    if (_observer.isBlockingRouteOnTop || _suppressionHides(step)) return;
    if (!_anchorResolvable(step)) return;
    _settleTimer = Timer(_kRevealSettle, () {
      if (!mounted) return;
      _revealReady = true;
      _entry?.markNeedsBuild();
    });
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

  /// Advances a `navigate`-trigger step (a bottom-nav tab step) once the app's
  /// active route — published by `AppShell` into `tourActiveRouteProvider` —
  /// matches the step's `navigateRoute`. This is the advance mechanism for tab
  /// steps; the `TourAnchor`'s key only positions the spotlight (its pointer
  /// Listener can't reliably fire because tapping the tab disposes the icon
  /// anchor mid-gesture — Bug 1).
  void _maybeAdvanceOnNavigation(OnboardingTourState tour) {
    final step = tour.currentStep;
    if (step == null) return;
    final dest = step.navigateRoute;
    if (dest == null) return;
    final current = ref.read(tourActiveRouteProvider);
    if (current == dest) {
      ref
          .read(onboardingTourControllerProvider.notifier)
          .advance(via: 'navigate');
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
    // Watch the active route so a tab navigation advances `navigate` steps
    // even if no other input changed this frame.
    ref.watch(tourActiveRouteProvider);

    // Bridge tour COMPLETION to the session gate: flipping tourCompleted makes
    // the GoRouter redirect re-resolve the stage and advance the user to the
    // hard paywall (or straight to the app when the flow flag is off). Done
    // here (not in the controller) to keep the controller free of an
    // app_session import (would be a layering cycle).
    ref.listen<OnboardingTourState>(onboardingTourControllerProvider,
        (prev, next) {
      // Completed (normal) OR skipped (defensive — skip is hidden in gate mode,
      // but if it ever fires we still advance the user to the wall instead of
      // stranding them on home). Harmless in legacy mode (stage stays `app`).
      final wasResolved = prev?.status == TourStatus.completed ||
          prev?.status == TourStatus.skipped;
      final nowResolved = next.status == TourStatus.completed ||
          next.status == TourStatus.skipped;
      if (nowResolved && !wasResolved) {
        try {
          ref.read(appSessionProvider).markTourCompleted();
        } catch (_) {/* gate just advances on next hydrate */}
      }
    });

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
      if (_trackTicker.isActive) _trackTicker.stop();
      return;
    }

    // Re-arm the reveal-settle gate whenever the active step changes.
    _resetSettleIfStepChanged(tour);

    // Advance `navigate`-trigger steps (the bottom-nav tab steps) when the user
    // has actually reached the destination route. Robust to the tab
    // icon→activeIcon swap that disposes the anchor's pointer Listener
    // mid-gesture (Bug 1). Checked here (called every frame + on route change)
    // so it fires regardless of where on the tab cell the user tapped.
    _maybeAdvanceOnNavigation(tour);

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

  /// Whether `tourSuppressed` should hide [step]. Suppression is the Build-a-Dua
  /// flow's "wait — the next anchor isn't reachable yet" latch (written only by
  /// `DuasScreen`). It is honored ONLY while the step's anchor is absent — the
  /// real wait. Once the anchor is on screen, a lingering flag is stale and
  /// ignored, so the coachmark reveals instead of hanging (centered steps are
  /// always "resolvable", so they're never suppression-hidden — the F-06 case).
  /// See docs/qa/findings/2026-06-08-tour-suppression-stale-anchored-hang.md
  bool _suppressionHides(OnboardingTourStepDef step) =>
      ref.read(tourSuppressedProvider) && !_anchorResolvable(step);

  void _maybeScheduleAnchorTimeout() {
    _anchorTimeoutTimer?.cancel();
    final tour = ref.read(onboardingTourControllerProvider);
    final step = tour.currentStep;
    if (step == null) return;
    // While legitimately suppressed (mid Dua-build flow, anchor still absent),
    // do not arm the timeout — the step is intentionally pending until the host
    // screen surfaces the anchor. Cancelled above; re-armed once suppression
    // lifts (or goes stale) via the `tourSuppressedProvider` watch in `build`.
    if (_suppressionHides(step)) return;
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
    // Three gates, any of which hides the coachmark:
    //   1. a blocking modal route is on top (its content owns the screen);
    //   2. suppression is legitimately in effect (mid Dua-build, anchor still
    //      absent — `_suppressionHides` ignores a STALE flag once the anchor is
    //      on screen, so it can't hang an anchored step);
    //   3. the reveal-settle hasn't elapsed yet (don't pop in over a still-
    //      animating screen transition — see `_kRevealSettle`).
    //
    // Note we deliberately do NOT gate on `_anchorResolvable` here: once
    // `_revealReady` is set the reveal is sticky. The per-frame ticker rebuilds
    // this overlay constantly, and during a host rebuild the target's
    // `TourAnchor` can momentarily unregister (dispose a frame before the
    // remount's post-frame re-register). Re-gating on a live registry lookup
    // would re-hide an already-revealed coachmark for that window (Bug 2).
    // `CoachmarkOverlay` degrades gracefully on a briefly-null target rect
    // (banner without ring) and the ticker redraws the ring the instant the key
    // re-resolves, so the drop is invisible. Navigation away is handled by gate
    // 1 / the step changing / the tour going inactive.
    final suppressed = _suppressionHides(step);
    final hidden = blockingRouteUp || suppressed || !_revealReady;

    final coachmarkStep = CoachmarkStep(
      target: anchorKey,
      message: _personalizeTourCopy(step.message, tour.userName),
      interactive: step.interactive,
      hint: step.hint,
      autoAdvance: step.autoAdvance,
      cutoutPaddingTop: step.cutoutPaddingTop,
      cutoutPaddingBottom: step.cutoutPaddingBottom,
      cutoutPaddingX: step.cutoutPaddingX,
    );

    // No `key` — same CoachmarkOverlay instance persists across step
    // changes so AnimationController + TweenAnimationBuilder state survives,
    // enabling the hero-morph polish.
    // Hide "Skip tour" when the hard-paywall gate is forcing the tour — it must
    // run to completion before the wall (decision C2). The legacy/replay tour
    // (kill switch off) keeps skip. Read defensively: any failure → allow skip.
    bool forced = false;
    try {
      forced = ref.read(appSessionProvider).hardPaywallFlowEnabled;
    } catch (_) {}

    return CoachmarkOverlay(
      step: coachmarkStep,
      stepIndex: tour.index,
      totalSteps: kOnboardingTourLength,
      hideUntilAnchorReady: hidden,
      onNext: _onNext,
      onSkip: _onSkip,
      allowSkip: !forced,
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
