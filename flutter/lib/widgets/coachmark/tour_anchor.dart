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
        // the tap. We only intercept the raw pointer-up to detect "user
        // tapped this anchor's child" — no gesture arena participation.
        behavior: HitTestBehavior.translucent,
        onPointerUp: _onPointerUp,
        child: widget.child,
      ),
    );
  }

  void _onPointerUp(PointerUpEvent _) {
    final tour = ref.read(onboardingTourControllerProvider);
    if (!tour.isActive) return;
    final step = tour.currentStep;
    if (step == null) return;
    // Only advance if THIS anchor matches the current step's target AND
    // the step is interactive (teach steps advance via Continue button).
    if (step.surface != widget.surface) return;
    if (step.anchorId != widget.anchorId) return;
    if (!step.interactive) return;
    ref
        .read(onboardingTourControllerProvider.notifier)
        .advance(via: 'target_tap');
  }
}
