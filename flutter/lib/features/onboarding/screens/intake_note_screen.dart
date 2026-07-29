import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../content/intake_questions.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/reel_continue_question.dart';

/// H7 — "Anything you want to add?" (One Ship W2-H).
///
/// **A payer-detection surface, not merely an input.** Payers do 3× the
/// reflections on near-identical check-in counts, so giving the depth-diver
/// somewhere to go deep on Day 0 targets the person who actually converts.
/// Skippable, so it costs everyone else nothing — and the skip is phrased as a
/// complete answer ("Nothing to add"), because most people have nothing to add
/// and must not feel they abandoned a step.
///
/// The text becomes AI context for Reflect and Build-a-Duʿā; the subline says so
/// rather than pleading for input.
class IntakeNoteScreen extends ConsumerStatefulWidget {
  const IntakeNoteScreen({
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
  ConsumerState<IntakeNoteScreen> createState() => _IntakeNoteScreenState();
}

class _IntakeNoteScreenState extends ConsumerState<IntakeNoteScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Seeded from state so a user who backs up meets their own words rather
    // than an empty field that looks like the note was lost.
    _controller = TextEditingController(
      text: ref.read(onboardingProvider).intakeNote ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Writes whatever is in the field and advances.
  ///
  /// Empty text clears the note rather than leaving an older one behind: on this
  /// screen, deleting what you wrote and skipping are the same intent.
  void _commit() {
    ref.read(onboardingProvider.notifier).setIntakeNote(_controller.text);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return ReelContinueQuestion(
      headline: intakeNoteQuestionLabel,
      subline: intakeNoteSublineLabel,
      continueLabel: intakeNoteSubmitLabel,
      // Always enabled. Gating Continue on typed text would turn an optional
      // question into a required one, and the skip link is the decline path —
      // not a second, quieter Continue.
      onContinue: _commit,
      skipLabel: intakeNoteSkipLabel,
      onSkip: _commit,
      onBack: widget.onBack,
      progressSegment: widget.progressSegment,
      totalSegments: widget.totalSegments,
      body: TextField(
        controller: _controller,
        minLines: 4,
        maxLines: 8,
        textCapitalization: TextCapitalization.sentences,
        // Newline, not done: this is the one screen in the flow where a user
        // may reasonably want a second paragraph.
        textInputAction: TextInputAction.newline,
        keyboardType: TextInputType.multiline,
        style: AppTypography.bodyLarge.copyWith(
          fontWeight: FontWeight.w300,
          color: AppColors.textPrimaryLight,
        ),
        decoration: InputDecoration(
          hintText: intakeNoteHintLabel,
          hintStyle: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w300,
            color: AppColors.textTertiaryLight,
          ),
          filled: true,
          fillColor: AppColors.surfaceLight,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          border: _border(AppColors.borderLight),
          enabledBorder: _border(AppColors.borderLight),
          focusedBorder: _border(AppColors.primary),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: BorderSide(color: color, width: 1.5),
      );
}
