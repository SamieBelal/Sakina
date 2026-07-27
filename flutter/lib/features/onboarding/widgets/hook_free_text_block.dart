import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// The demoted free-text path on the hook screen (One Ship W2-B2, spec ⑤).
///
/// A quiet link that expands a field **below** the cards on demand. It never
/// hides them, is never required, and never competes for the primary position
/// the shipped `first_checkin_screen` gave it.
///
/// Unlike a card tap, typed text needs an explicit submit — so a quiet
/// "Continue" appears only once there is something to send. The mock is silent
/// on this; relying on the keyboard's return key alone would hide the only way
/// forward from anyone using an external keyboard or dictation.
class HookFreeTextBlock extends StatelessWidget {
  const HookFreeTextBlock({
    required this.expanded,
    required this.controller,
    required this.focusNode,
    required this.onExpand,
    required this.onSubmit,
    required this.enabled,
    super.key,
  });

  static const String promptLabel = 'Or say it in your own words…';
  static const String hintLabel = 'Whatever it is, you can name it here.';
  static const String submitLabel = 'Continue';

  final bool expanded;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onExpand;
  final ValueChanged<String> onSubmit;

  /// False once a commit is in flight, so the beat cannot be interrupted.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!expanded) {
      return Center(
        child: Semantics(
          button: true,
          label: promptLabel,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: enabled ? onExpand : null,
            behavior: HitTestBehavior.opaque,
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                promptLabel,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w300,
                  color: AppColors.textSecondaryLight,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.borderLight,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onSubmitted: onSubmit,
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w300,
            color: AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: hintLabel,
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
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final hasText = value.text.trim().isNotEmpty;
            // The 44pt slot is always laid out and only faded in. Swapping the
            // button into the layout on the first keystroke would shove the
            // field the user is typing in, mid-sentence.
            return IgnorePointer(
              ignoring: !hasText,
              child: ExcludeSemantics(
                excluding: !hasText,
                child: AnimatedOpacity(
                  opacity: hasText ? 1 : 0,
                  duration: const Duration(milliseconds: 160),
                  child: Semantics(
                    button: true,
                    label: submitLabel,
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: enabled ? () => onSubmit(controller.text) : null,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 44),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: Text(
                          submitLabel,
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: 1.5),
      );
}
