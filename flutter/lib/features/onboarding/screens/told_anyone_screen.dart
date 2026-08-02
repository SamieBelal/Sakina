import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/analytics_events.dart';
import '../../../services/analytics_provider.dart';
import '../content/intake_questions.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/reel_single_tap_question.dart';

/// H3 — "Have you been able to tell anyone?" (One Ship W2-H).
///
/// The most ICP-resonant thing we can ask, and the highest-variance question in
/// the set: 40% of young Muslim men in the MYH data told nobody about their last
/// problem, and answering "No one" to an app is itself the moment of being seen.
/// The founder approved it **on the condition that we act on it** — an answer
/// that changes nothing visible is voyeurism, not intake. Both consequences live
/// in `intake_questions.dart`: [toldAnyonePlanLine] and
/// [toldAnyoneFirstNotificationBody].
///
/// "Rather not say" is a real option here rather than a skip link. On the source
/// question a decline writes nothing, because declining to be measured is an
/// answer about being measured; here, declining to say whether anyone knows is a
/// state worth honouring, and it routes to the same neutral register an
/// unanswered screen gets — so recording it never puts words in anyone's mouth.
class ToldAnyoneScreen extends ConsumerWidget {
  const ToldAnyoneScreen({
    required this.onNext,
    this.onBack,
    this.progressSegment,
    this.totalSegments,
    this.commitBeat = const Duration(milliseconds: 450),
    super.key,
  });

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
    final selected = ref.watch(onboardingProvider.select((s) => s.toldAnyone));
    return ReelSingleTapQuestion(
      headline: toldAnyoneQuestionLabel,
      subline: toldAnyoneSublineLabel,
      options: [
        for (final option in toldAnyoneOptions)
          ReelOption(key: option.key, label: option.label),
      ],
      initialKey: selected,
      onBack: onBack,
      progressSegment: progressSegment,
      totalSegments: totalSegments,
      commitBeat: commitBeat,
      onAnswer: (key) =>
          ref.read(onboardingProvider.notifier).setToldAnyone(key),
      onCommitted: (key) {
        ref
            .read(analyticsProvider)
            .trackOnboardingAnswerWithRef(ref, 'told_anyone', key);
        onNext();
      },
    );
  }
}
