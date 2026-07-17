import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/core/constants/app_spacing.dart';

import 'package:sakina/features/dua_times/providers/dua_window_provider.dart';
import 'package:sakina/features/dua_times/widgets/dua_times_card_body.dart';
import 'package:sakina/features/dua_times/widgets/dua_times_copy.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';

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

    // Still building (schedule not yet computed) → collapse, no cold-launch flash.
    if (s.schedule == null) {
      return const SizedBox.shrink();
    }

    final hasPreciseLocation =
        ref.read(duaWindowProvider.notifier).hasPreciseLocation;
    // Narrow render gate: show the card only while a window is ACTIVE — i.e.
    // exactly when the widget is showing a live window/countdown, not the
    // perpetual "next window" between-state. Carve-out: when location is off and
    // the enable nudge isn't snoozed, keep showing so the "Turn on precise times"
    // banner still has a home (once granted → active-only; the ✕ snoozes it).
    final canNudgeEnable = !hasPreciseLocation && !s.preciseBannerSnoozed;
    if (s.active == null && !canNudgeEnable) {
      return const SizedBox.shrink();
    }

    _fireImpressionOnce(s);

    final showEnablePrecise = canNudgeEnable && s.active == null;

    // Own a bottom margin so the card self-spaces from the content below (like
    // RamadanGiftCard / the nudge cards) — and leaves zero dead space when the
    // gate collapses it above.
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: DuaTimesCardBody(
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
          .moveY(begin: 8, end: 0, duration: 400.ms),
    );
  }
}
