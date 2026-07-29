import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../content/help_chips.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/intake_chip_cloud.dart';
import '../widgets/reel_continue_question.dart';

/// H5 — "What would help most right now?" (One Ship W2-H, spec §5).
///
/// Replaces the single-select aspiration question. A multi-select chip cloud,
/// capped at [helpChipsMaxSelections]; Continue enables at one selection, and
/// the ordered answer seeds queue rows 3-7 through [helpChipsQueueNameIds].
///
/// **The inconsistency with the hook screen is deliberate.** The hook is
/// single-select, full-width, tap-to-commit — one exposing question where the
/// tap *is* the commitment. H5 is lower-stakes, later and reversible, so it is
/// physically lighter under the thumb. Flattening the two to one treatment would
/// lose the signal that they carry different stakes; do not "fix" it.
///
/// The subline's second sentence is load-bearing copy, not filler: this ICP's
/// fear ranking puts *failing at another thing* near the top, and saying the
/// choice is reversible is most of what makes a seven-option screen feel light.
///
/// The legacy `aspirations_screen.dart` and `aspiration_screen_reel.dart` are
/// untouched — the kill-switch flows still use them.
class HelpChipsScreen extends ConsumerWidget {
  const HelpChipsScreen({
    required this.onNext,
    this.onBack,
    this.progressSegment,
    this.totalSegments,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback? onBack;

  /// Forwarded to the shared question surface; null renders no progress bar.
  final int? progressSegment;

  /// Length of that bar; null keeps the wrapper's default.
  final int? totalSegments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingProvider.select((s) => s.helpWith));
    return ReelContinueQuestion(
      headline: helpChipsQuestionLabel,
      subline: helpChipsSublineLabel,
      continueLabel: AppStrings.continueButton,
      // Gated at one selection, disabled rather than hidden: a button that
      // appears on the first tap moves the thing the user is about to press.
      onContinue: selected.isEmpty ? null : onNext,
      onBack: onBack,
      progressSegment: progressSegment,
      totalSegments: totalSegments,
      body: IntakeChipCloud(
        chips: [
          for (final chip in helpChips)
            IntakeChipData(key: chip.key, label: chip.label),
        ],
        selectedKeys: selected,
        maxSelections: helpChipsMaxSelections,
        onToggle: (key) {
          // The notifier refuses a fourth without disturbing the three already
          // held; the cloud dims the unselected chips at the cap, so the refusal
          // is legible before the tap rather than as a silent no-op after it.
          HapticFeedback.selectionClick();
          ref.read(onboardingProvider.notifier).toggleHelpWith(key);
        },
      ),
    );
  }
}
