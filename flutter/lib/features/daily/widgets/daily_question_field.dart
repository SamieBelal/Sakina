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
    required this.enabled,
    required this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;

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
        // **No hint, and no helper either** (W4 Wave 2 review F1).
        //
        // The answer-set line that used to live here as `hintText` now renders
        // as a caption under this field, owned by `DailyQuestionPrompt`. It is
        // the only thing telling the user a grateful answer is permitted (spec
        // M4), and neither slot on a `TextField` can hold it safely:
        //
        //  * A HINT disappears the moment the field is non-empty — so the line
        //    vanished on the first keystroke, and was never shown at all on an
        //    off-topic re-ask, where the field opens pre-filled with the user's
        //    own words. That is precisely when someone needs to know what kind
        //    of answer is permitted.
        //  * `hintMaxLines: 3` plus `InputDecorator`'s ellipsis truncated it to
        //    "A worry, a thanks, a ques…" at large Dynamic Type, silently
        //    reverting the question to meaning "what's wrong".
        //  * A HELPER persists, but `InputDecorator` sizes the helper slot from
        //    `helperMaxLines` and clips to it — measured at one line, 20pt for
        //    a 100pt string. Trading a hint's threshold for a helper's is not a
        //    fix.
        //
        // A plain caption below has no line budget at anyone's discretion, so
        // there is no font-dependent threshold left to get wrong.
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
