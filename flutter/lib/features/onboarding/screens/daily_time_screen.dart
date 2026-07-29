import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/intake_questions.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/reel_single_tap_question.dart';

/// H6 — "How much time feels right most days?" (One Ship W2-H).
///
/// **Deliberately NOT a commitment device** (founder call, 2026-07-28). The
/// streak, the lantern and the widget already own commitment, and this question
/// must not compete with them: Duolingo's "I'M COMMITTED" CTA is explicitly not
/// imported, and no option may read as the failure choice. "As long as I need"
/// replaces "Longer when I can" for exactly that reason — the latter implies a
/// scarcity the user should feel bad about.
///
/// What it buys is length, never frequency: [dailyTimePacingLine] on the plan
/// screen and [dailyTimeDeckLength] for W3. Every one of those lines describes
/// the same daily Name; none of them describes more or fewer days.
class DailyTimeScreen extends ConsumerWidget {
  const DailyTimeScreen({
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
    final selected = ref.watch(onboardingProvider.select((s) => s.dailyTime));
    return ReelSingleTapQuestion(
      headline: dailyTimeQuestionLabel,
      subline: dailyTimeSublineLabel,
      options: [
        for (final option in dailyTimeOptions)
          ReelOption(key: option.key, label: option.label),
      ],
      initialKey: selected,
      onBack: onBack,
      progressSegment: progressSegment,
      totalSegments: totalSegments,
      commitBeat: commitBeat,
      onAnswer: (key) =>
          ref.read(onboardingProvider.notifier).setDailyTime(key),
      onCommitted: (_) => onNext(),
    );
  }
}
