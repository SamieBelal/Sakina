import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/widget_deep_link.dart';

import 'package:sakina/features/dua_times/providers/dua_window_provider.dart';
import 'package:sakina/features/dua_times/widgets/dua_times_card_body.dart';
import 'package:sakina/features/dua_times/widgets/dua_times_copy.dart';
import 'package:sakina/features/dua_times/widgets/precise_paused_notice.dart';
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
        AnalyticsEvents.propPreciseState: s.preciseState.wireName,
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

  Future<void> _onEnablePreciseTap(DuaWindowState s) async {
    final stateAtTap = s.preciseState;
    ref.read(analyticsProvider).track(
      AnalyticsEvents.duaTimesLocationPrompt,
      properties: {AnalyticsEvents.propPreciseState: stateAtTap.wireName},
    );
    final outcome = await ref.read(duaWindowProvider.notifier).promptLocation();
    if (!mounted) return;
    // The Settings round-trip is NOT a denial — reporting it as one is why the
    // granted:denied ratio was meaningless before this change.
    final event = switch (outcome) {
      LocationPromptOutcome.granted => AnalyticsEvents.duaTimesLocationGranted,
      LocationPromptOutcome.denied => AnalyticsEvents.duaTimesLocationDenied,
      LocationPromptOutcome.openedSettings ||
      LocationPromptOutcome.servicesOff =>
        AnalyticsEvents.duaTimesLocationSettingsOpened,
    };
    ref.read(analyticsProvider).track(
      event,
      properties: {AnalyticsEvents.propPreciseState: stateAtTap.wireName},
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(duaWindowProvider);

    // Still building (schedule not yet computed) → collapse, no cold-launch flash.
    if (s.schedule == null) {
      return const SizedBox.shrink();
    }

    // The loud, first-run pitch. ONLY for a user we have never asked — that is
    // what ends the re-nag. Anyone who has already answered (granted, denied, or
    // "Allow Once") is past this forever; they get the one-time notice below.
    // The carve-out below is kept for them alone because this banner is the
    // product's on-ramp of last resort.
    final showPitch = s.preciseState == PreciseTimesState.neverAsked &&
        !s.preciseBannerSnoozed;

    // A transition report. It is its own widget, so it can appear even on a day
    // the card itself has nothing to say — and it CLAIMS itself, so mounting it
    // costs nothing when the notice has already been spent (it just stays at
    // zero height). `messageFor` returns null for every state that deserves
    // silence, which is what keeps `unresolved` and `declined` quiet.
    final noticeState = PrecisePausedNotice.messageFor(s.preciseState) != null
        ? s.preciseState
        : null;

    // Narrow render gate: show the card only while a window is ACTIVE — i.e.
    // exactly when the widget is showing a live window/countdown, not the
    // perpetual "next window" between-state.
    final showCard = s.active != null || showPitch;
    if (!showCard && noticeState == null) {
      return const SizedBox.shrink();
    }

    if (showCard) _fireImpressionOnce(s);

    final showEnablePrecise = showPitch && s.active == null;

    // Each child owns its own bottom margin, INSIDE its own collapsing subtree
    // (like RamadanGiftCard / the nudge cards). Wrapping the whole Column
    // instead would leave a permanent empty band above ReferralNudgeCard once
    // the notice retires itself.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showCard)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: DuaTimesCardBody(
              state: s,
              onTap: () => _onCtaTap(s),
              onCta: () => _onCtaTap(s),
              onEnablePrecise:
                  showEnablePrecise ? () => _onEnablePreciseTap(s) : null,
              onDismissPrecise: showEnablePrecise
                  ? () =>
                      ref.read(duaWindowProvider.notifier).snoozePreciseBanner()
                  : null,
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .moveY(begin: 8, end: 0, duration: 400.ms),
          ),
        if (noticeState != null)
          PrecisePausedNotice(
            key: kPrecisePausedNoticeKey,
            state: noticeState,
            // Navigates to the steps; it does NOT open the system dialog.
            // The notice carries a ✕, and Apple's pre-alert rules name location
            // and forbid a close control on a view that fronts the OS prompt.
            // PreciseTimesScreen is the pre-alert view — it has one button.
            onOpenDetails: () => context.push(kFixLocationRoute),
          ),
      ],
    );
  }
}
