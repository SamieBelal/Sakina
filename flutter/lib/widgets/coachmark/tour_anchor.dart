import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/tour/models/onboarding_tour_step.dart';
import '../../features/tour/providers/onboarding_tour_controller.dart';
import '../../features/tour/providers/tour_anchor_registry.dart';

/// Wraps a child widget with a `GlobalKey`, registers it with the
/// `TourAnchorRegistry`, and detects pointer-ups on the child to advance
/// the tour when this anchor is the active step's target.
///
/// The pointer detection uses a non-blocking `Listener` wrapped around the
/// child. It does NOT consume the event — taps continue to the underlying
/// `GestureDetector`/button below.
///
/// Why this (vs. a Listener over the cutout in the overlay): mounting the
/// listener in the OverlayEntry above all routes is unreliable because of
/// hit-test propagation between overlay entries — sometimes only the
/// underlying button fires and the overlay listener is skipped. Listening
/// at the anchor itself is always co-located with the target, so the
/// pointer-up reliably fires for both.
class TourAnchor extends ConsumerStatefulWidget {
  const TourAnchor({
    required this.surface,
    required this.anchorId,
    required this.child,
    super.key,
  });

  final TourSurface surface;
  final String anchorId;
  final Widget child;

  @override
  ConsumerState<TourAnchor> createState() => _TourAnchorState();
}

class _TourAnchorState extends ConsumerState<TourAnchor> {
  late final GlobalKey _key = GlobalKey(
    debugLabel: 'tour.${widget.surface.name}.${widget.anchorId}',
  );

  /// Position where the active pointer first went down. If the pointer-up
  /// lands far from here we treat it as a scroll/drag release, NOT a tap,
  /// and do not advance the tour. Without this guard, anchors inside a
  /// `Scrollable` (e.g. the `firstRelatedHeart` heart in the Duas list)
  /// auto-advance when the user scrolls to bring them into view — the
  /// scroll release lands on the anchor's bounds and the translucent
  /// `Listener` fires `onPointerUp` regardless of gesture-arena outcome.
  Offset? _downPosition;

  /// Max distance (logical pixels) between pointer-down and pointer-up
  /// that we still consider a tap. Matches Flutter's `kTouchSlop` (18pt)
  /// loosely — slightly tighter so a deliberate tap still wins but a
  /// scroll-release release does not.
  static const double _tapSlop = 12;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(tourAnchorRegistryProvider)
          .register(widget.surface, widget.anchorId, _key);
    });
  }

  @override
  void dispose() {
    try {
      ref
          .read(tourAnchorRegistryProvider)
          .unregister(widget.surface, widget.anchorId, _key);
    } catch (_) {
      // ProviderScope tear-down or app shutdown — registry already gone.
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: Listener(
        // Translucent so the child's GestureDetector/InkWell still receives
        // the tap. We only intercept the raw pointer events to detect
        // "user tapped this anchor's child" — no gesture arena participation.
        behavior: HitTestBehavior.translucent,
        onPointerDown: (e) => _downPosition = e.position,
        onPointerUp: _onPointerUp,
        onPointerCancel: (_) => _downPosition = null,
        child: widget.child,
      ),
    );
  }

  void _onPointerUp(PointerUpEvent event) {
    final down = _downPosition;
    _downPosition = null;
    // Tap-vs-scroll filter: if pointer-up landed > _tapSlop from
    // pointer-down, treat as scroll/drag and do NOT advance. Anchors
    // inside a `Scrollable` (e.g. duas firstRelatedHeart) would otherwise
    // advance when the user scrolls to bring them into view.
    if (down == null) return;
    if ((event.position - down).distance > _tapSlop) return;
    final tour = ref.read(onboardingTourControllerProvider);
    if (!tour.isActive) return;
    final step = tour.currentStep;
    if (step == null) return;
    // Only advance if THIS anchor matches the current step's target AND
    // the step is interactive (teach steps advance via Continue button).
    if (step.surface != widget.surface) return;
    if (step.anchorId != widget.anchorId) return;
    if (!step.interactive) return;
    // `navigate` steps (the bottom-nav tab steps) advance when the user reaches
    // the destination route, observed in the overlay host — NOT via this
    // pointer Listener. Tapping a tab swaps the icon for its active variant,
    // disposing this anchor mid-gesture, so the pointer-up may never arrive
    // (Bug 1). Skip the tap-advance for them; the host owns their advancement.
    if (step.trigger == TourAdvanceTrigger.navigate) return;
    ref
        .read(onboardingTourControllerProvider.notifier)
        .advance(via: 'target_tap');
  }
}
