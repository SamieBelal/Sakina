import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/carrying_durations.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/reel_single_tap_question.dart';

/// "How long have you been carrying this?" (One Ship W2-D1a) — the first
/// question after the reveal.
///
/// Single-tap: the answer is one word about time, and asking for a tap plus a
/// Continue would make it feel like a form. What it buys is visible on the very
/// next screen — [carryingPacingLine] sets the queue plan's pacing copy — which
/// is the §G4 contract every reel-flow question has to keep.
///
/// Constructor-driven like the rest of the reel screens: Wave E owns the
/// PageView and passes [onNext]/[onBack].
class CarryingDurationScreen extends ConsumerWidget {
  const CarryingDurationScreen({
    required this.onNext,
    this.onBack,
    this.progressSegment,
    this.commitBeat = const Duration(milliseconds: 450),
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback? onBack;

  /// Forwarded to the shared question surface; null renders no progress bar.
  final int? progressSegment;

  /// Zero in tests.
  final Duration commitBeat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected =
        ref.watch(onboardingProvider.select((s) => s.carryingDuration));
    return ReelSingleTapQuestion(
      headline: carryingDurationQuestionLabel,
      subline: carryingDurationSublineLabel,
      options: [
        for (final duration in carryingDurations)
          ReelOption(key: duration.key, label: duration.label),
      ],
      initialKey: selected,
      onBack: onBack,
      progressSegment: progressSegment,
      commitBeat: commitBeat,
      onCommitted: (key) {
        ref.read(onboardingProvider.notifier).setCarryingDuration(key);
        onNext();
      },
    );
  }
}
