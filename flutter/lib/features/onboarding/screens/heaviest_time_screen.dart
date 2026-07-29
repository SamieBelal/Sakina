import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/intake_questions.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/reel_single_tap_question.dart';

/// H2 — "When is it heaviest?" (One Ship W2-H).
///
/// **This screen replaces the reminder-time ask; it does not sit beside it.**
/// "What time do you want reminders?" is a chore and an ask. Asking when the
/// weight is heaviest extracts the same information with the opposite emotional
/// valence, and lets the app say something true back on the plan screen — *"You
/// said nights are hardest. Your Name will be there at night."* Net-zero screen
/// count, entirely different feeling.
///
/// The derivation is not left to a later wave:
/// [OnboardingNotifier.setHeaviestTime] writes `reminderTime` in the same state
/// mutation, so the answer is already a scheduled hour by the time the user
/// reaches the next page.
///
/// Constructor-driven like the rest of the reel screens: Wave E owns the
/// PageView and passes [onNext]/[onBack].
class HeaviestTimeScreen extends ConsumerWidget {
  const HeaviestTimeScreen({
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
    final selected =
        ref.watch(onboardingProvider.select((s) => s.heaviestTime));
    return ReelSingleTapQuestion(
      headline: heaviestQuestionLabel,
      subline: heaviestSublineLabel,
      options: [
        for (final option in heaviestTimes)
          ReelOption(key: option.key, label: option.label),
      ],
      initialKey: selected,
      onBack: onBack,
      progressSegment: progressSegment,
      totalSegments: totalSegments,
      commitBeat: commitBeat,
      onAnswer: (key) =>
          ref.read(onboardingProvider.notifier).setHeaviestTime(key),
      onCommitted: (_) => onNext(),
    );
  }
}
