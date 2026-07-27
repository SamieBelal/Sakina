import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      onCommitted: (key) {
        ref.read(onboardingProvider.notifier).setReelSource(key);
        onNext();
      },
    );
  }
}
