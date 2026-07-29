import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/intake_questions.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/reel_single_tap_question.dart';

/// H4 — "How many of Allah's Names could you name right now?" (One Ship W2-H).
///
/// The projection baseline, and what makes the learning promise real. Nothing
/// else in the intake establishes what the user already knows, so *"you'll learn
/// 30 Names"* has nothing to be measured against. This is Duolingo's "How much
/// French do you know?" — load-bearing, because it is what lets the plan screen
/// say **"You know about five. In 30 days you'll know thirty-five."**
/// ([namesKnownProjectionLine] is that sentence.)
///
/// It stays the right side of the reverence line because it is a claim about the
/// **user's own knowledge** — never about what Allah will do. The subline is
/// doing real work: a user who feels caught out by this screen has just been
/// told they are not Muslim enough for the app, which is the exact failure the
/// corrected ICP forbids.
class NamesKnownScreen extends ConsumerWidget {
  const NamesKnownScreen({
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
    final selected = ref.watch(onboardingProvider.select((s) => s.namesKnown));
    return ReelSingleTapQuestion(
      headline: namesKnownQuestionLabel,
      subline: namesKnownSublineLabel,
      options: [
        for (final option in namesKnownOptions)
          ReelOption(key: option.key, label: option.label),
      ],
      initialKey: selected,
      onBack: onBack,
      progressSegment: progressSegment,
      totalSegments: totalSegments,
      commitBeat: commitBeat,
      onAnswer: (key) =>
          ref.read(onboardingProvider.notifier).setNamesKnown(key),
      onCommitted: (_) => onNext(),
    );
  }
}
