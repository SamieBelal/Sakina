import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../services/analytics_events.dart';
import '../../../services/analytics_provider.dart';
import '../providers/dua_window_provider.dart';
import 'dua_times_card_body.dart';
import 'dua_times_copy.dart';

/// Route the whole card + every CTA deep-link to (Build-a-Duʿā). Mirrors the
/// widget deep link `sakina://widget/build-dua` which maps to `/duas`.
const String kDuaTimesBuildDuaRoute = '/duas';

/// The render-gated in-app duʿā-times card (spec §8).
///
/// Render gate (mirrors `RamadanGiftCard`): shown only when the schedule has an
/// active OR an imminent next window; otherwise `SizedBox.shrink()`. On the
/// emerald sacred canvas, CTA-first, with the copy + escalation ladder of §9.1:
///   comfortable · closing (live countdown) · lastCall (amber) · allDay
///   ("today only") · between ("Build your duʿā · {day}").
///
/// Tapping the card (and the gold CTA pill) navigates to Build-a-Duʿā.
class DuaTimesCard extends ConsumerStatefulWidget {
  const DuaTimesCard({super.key});

  @override
  ConsumerState<DuaTimesCard> createState() => _DuaTimesCardState();
}

class _DuaTimesCardState extends ConsumerState<DuaTimesCard> {
  bool _impressionFired = false;

  void _fireImpressionOnce(DuaWindowState s) {
    if (_impressionFired) return;
    _impressionFired = true;
    ref.read(analyticsProvider).track(
      AnalyticsEvents.duaTimesCardImpression,
      properties: {
        AnalyticsEvents.propActiveWindow: windowAnalyticsValue(s.active),
        AnalyticsEvents.propNextWindow: windowAnalyticsValue(s.next),
        AnalyticsEvents.propUrgency: s.urgency.name,
      },
    );
  }

  void _onCtaTap(DuaWindowState s) {
    HapticFeedback.lightImpact();
    ref.read(analyticsProvider).track(
      AnalyticsEvents.duaTimesCardCtaTap,
      properties: {
        AnalyticsEvents.propActiveWindow: windowAnalyticsValue(s.active),
        AnalyticsEvents.propUrgency: s.urgency.name,
      },
    );
    if (mounted) context.go(kDuaTimesBuildDuaRoute);
  }

  Future<void> _onEnablePreciseTap() async {
    ref.read(analyticsProvider).track(AnalyticsEvents.duaTimesLocationPrompt);
    final outcome = await ref.read(duaWindowProvider.notifier).promptLocation();
    if (!mounted) return;
    ref.read(analyticsProvider).track(
          outcome == LocationPromptOutcome.granted
              ? AnalyticsEvents.duaTimesLocationGranted
              : AnalyticsEvents.duaTimesLocationDenied,
        );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(duaWindowProvider);

    // Render gate: nothing worth showing → collapse (spec §8/§10). While the
    // very first build is still in flight the schedule is null → also collapse,
    // avoiding a flash-then-reflow on cold launch (mirrors RamadanGiftCard).
    if (!s.hasRenderableWindow) {
      return const SizedBox.shrink();
    }

    _fireImpressionOnce(s);

    final showEnablePrecise =
        !ref.read(duaWindowProvider.notifier).hasPreciseLocation &&
            s.active == null && // only nudge when we can't show a precise "now"
            !s.preciseBannerSnoozed; // and the user hasn't snoozed it

    return DuaTimesCardBody(
      state: s,
      onTap: () => _onCtaTap(s),
      onCta: () => _onCtaTap(s),
      onEnablePrecise: showEnablePrecise ? _onEnablePreciseTap : null,
      onDismissPrecise: showEnablePrecise
          ? () => ref.read(duaWindowProvider.notifier).snoozePreciseBanner()
          : null,
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .moveY(begin: 8, end: 0, duration: 400.ms);
  }
}
