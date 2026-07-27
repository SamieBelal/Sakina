import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/aspirations.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/reel_single_tap_question.dart';

/// The aspiration question in the reel flow (One Ship W2-D1b) — the answer that
/// fills queue positions 3-7.
///
/// Two registers, one question: a user who tapped the sign card described a
/// state, not a project, so they are asked what would help rather than what
/// they are reaching for. Both come from [aspirations] — same keys, same
/// orderings — so the register never changes which Names they get, only how the
/// question sounds. See `aspirations.dart` for the sequences (founder-reviewed
/// content).
///
/// The legacy `aspirations_screen.dart` is untouched and still serves the
/// kill-switch flows.
class AspirationScreenReel extends ConsumerWidget {
  const AspirationScreenReel({
    required this.onNext,
    this.onBack,
    this.progressSegment,
    this.commitBeat = const Duration(milliseconds: 450),
    super.key,
  });

  /// Shown under both registers: the sequences are all approved orderings of
  /// approved Names, so there is no wrong tap to warn anyone about.
  static const String sublineLabel = 'Whichever is closest.';

  final VoidCallback onNext;
  final VoidCallback? onBack;

  /// Forwarded to the shared question surface; null renders no progress bar.
  final int? progressSegment;

  /// Zero in tests.
  final Duration commitBeat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contract = ref.watch(onboardingProvider.select((s) => s.contract));
    final selected = ref.watch(onboardingProvider.select((s) => s.aspiration));
    return ReelSingleTapQuestion(
      headline: aspirationQuestionFor(contract),
      subline: sublineLabel,
      options: [
        for (final aspiration in aspirations)
          ReelOption(
            key: aspiration.key,
            label: aspirationLabelFor(aspiration, contract),
          ),
      ],
      initialKey: selected,
      onBack: onBack,
      progressSegment: progressSegment,
      commitBeat: commitBeat,
      onCommitted: (key) {
        ref.read(onboardingProvider.notifier).setAspiration(key);
        onNext();
      },
    );
  }
}
