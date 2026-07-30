import 'package:flutter/material.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';

/// The daily question's free-text field — the PRIMARY input (spec M2).
///
/// On the sacred canvas, so none of the cream-surface field styling
/// (`free_text_dialog.dart`) carries over: the fill is 8% cream on emerald and
/// every stroke is a cream/gold accent rather than `borderLight`.
class DailyQuestionField extends StatelessWidget {
  const DailyQuestionField({
    required this.controller,
    required this.hintText,
    required this.enabled,
    required this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;

  /// The approved placeholder. Passed in rather than owned here so the copy has
  /// exactly one home (`DailyQuestionPrompt.placeholderLabel`).
  final String hintText;

  final bool enabled;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      minLines: 3,
      maxLines: 6,
      textCapitalization: TextCapitalization.sentences,
      // Deliberately NOT `keyboardType.multiline` — that turns the return key
      // into a newline and removes the only way forward for anyone on an
      // external keyboard or dictation (same reasoning as free_text_dialog).
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => onSubmitted(),
      cursorColor: AppColors.sacredInk,
      style: AppTypography.bodyLarge.copyWith(color: AppColors.sacredInk),
      decoration: InputDecoration(
        // Rides `hintText` so VoiceOver reads it as the field's hint straight
        // after the header. At 80% cream rather than `sacredInkFaint`:
        // DESIGN.md puts functional text on this canvas at >=80%, and this line
        // is the only thing telling the user a grateful answer is permitted.
        hintText: hintText,
        hintMaxLines: 3,
        hintStyle: AppTypography.bodyLarge.copyWith(
          color: AppColors.sacredInk.withValues(alpha: 0.80),
          fontWeight: FontWeight.w300,
          height: 1.35,
        ),
        filled: true,
        fillColor: AppColors.sacredInk.withValues(alpha: 0.08),
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        border: _border(AppColors.sacredTrack),
        enabledBorder: _border(AppColors.sacredTrack),
        disabledBorder: _border(AppColors.sacredTrack),
        // Gold as a non-text accent only — never as a label colour.
        focusedBorder: _border(AppColors.secondary),
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        borderSide: BorderSide(color: color, width: 1.5),
      );
}
