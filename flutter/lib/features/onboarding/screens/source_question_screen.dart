import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/analytics_event_names.dart';
import '../../../services/analytics_provider.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/reel_single_tap_question.dart';

/// "Where did you find us?" (One Ship W2-D3) — measurement only.
///
/// The hook screen is the ONLY routing intake (plan of record §V6.8.A2): this
/// answer never touches `contract`, never touches Name selection, and is never
/// echoed back at the user. It exists so "did we keep the reel's promise, per
/// audience" is answerable at all — organic reels carry no attributed click, so
/// the tap is the only source we get.
///
/// Because it buys the user nothing, it is skippable. "Rather not say" writes
/// **nothing** — declining is an answer about being measured, and recording a
/// value for it would quietly overrule the decline. W5 can still tell a decline
/// from an unseen screen through the screen-view event.
class SourceQuestionScreen extends ConsumerWidget {
  const SourceQuestionScreen({
    required this.onNext,
    this.onBack,
    this.progressSegment,
    this.totalSegments,
    this.commitBeat = const Duration(milliseconds: 450),
    super.key,
  });

  /// Analytics dispatch hook. This screen is a plain `ConsumerWidget` and the
  /// answer never reaches a service, so — like `OnboardingRevealScreen` —
  /// `main.dart` bridges the emission rather than the screen reaching for a
  /// provider. Null in tests unless the test sets it.
  static void Function(String name, Map<String, Object?> props)?
      onAnalyticsEvent;

  static const String headlineLabel = 'Where did you find us?';
  static const String sublineLabel = 'It helps us know who we are reaching.';
  static const String skipLabel = 'Rather not say';

  /// Stable snake_case keys — persisted to `OnboardingState.reelSource` and
  /// used as the analytics value (W5 lands the event constant). Copy may
  /// change; these may not.
  static const List<ReelOption> options = [
    ReelOption(key: 'tiktok', label: 'TikTok'),
    ReelOption(key: 'instagram', label: 'Instagram'),
    ReelOption(key: 'friend', label: 'A friend told me'),
    ReelOption(key: 'other', label: 'Somewhere else'),
  ];

  final VoidCallback onNext;
  final VoidCallback? onBack;

  /// Forwarded to the shared question surface; null renders no progress bar.
  final int? progressSegment;

  /// Length of that bar; null keeps the wrapper's default.
  final int? totalSegments;

  /// Zero in tests.
  final Duration commitBeat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingProvider.select((s) => s.reelSource));
    return ReelSingleTapQuestion(
      headline: headlineLabel,
      subline: sublineLabel,
      options: options,
      initialKey: selected,
      onBack: onBack,
      progressSegment: progressSegment,
      totalSegments: totalSegments,
      commitBeat: commitBeat,
      skipLabel: skipLabel,
      onSkip: onNext,
      onAnswer: (key) {
        ref.read(onboardingProvider.notifier).setReelSource(key);
        // W6 Wave A: upgrade `reel_hook` / `reel_hook_source` to the
        // self-reported answer, at the SAME call site as the
        // `reel_source_selected` emit below — one site, so the two can never
        // disagree.
        //
        // **It upgrades `unknown`; it never downgrades a `deep_link` (D2).**
        // A deep link is CONFIRMED — the OS handed us the reel id on arrival.
        // This screen sits at index 13, after the payoff and every ask, and
        // asks the user to RECALL where they came from. Overwriting the
        // confirmed value with the recalled one throws away the better datum
        // and relabels its provenance as the weaker one — which is the precise
        // failure the two-property design exists to prevent: "a super property
        // that silently mixes a confirmed deep link with a half-remembered tap
        // looks authoritative and is not."
        //
        // `reel_source_selected` below still fires either way: what the user
        // *believes* is worth knowing even when we already know better, and
        // comparing the two is how the self-report's reliability gets measured
        // at all.
        final arrivedByDeepLink =
            (ref.read(onboardingProvider).reelId ?? '').isNotEmpty;
        if (!arrivedByDeepLink) {
          ref.read(analyticsProvider).setSuperProperties({
            AnalyticsEvents.propReelHook: key,
            AnalyticsEvents.propReelHookSource:
                AnalyticsEvents.reelHookSourceSelfReport,
          });
        }
        onAnalyticsEvent?.call(AnalyticsEvents.reelSourceSelected, {
          AnalyticsEvents.propSource: key,
        });
      },
      onCommitted: (_) => onNext(),
    );
  }
}
