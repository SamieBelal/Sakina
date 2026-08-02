import 'package:flutter/material.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';

/// One "add to tonight" append (Wave C, C1).
///
/// A quiet line, not a chat bubble: this is a journal entry that grew, not a
/// conversation, and giving the appends speech-bubble shape would tell the user
/// they are talking to something.
class TonightThreadLine extends StatelessWidget {
  const TonightThreadLine({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gold as a NON-TEXT accent only (DESIGN.md) — a 4pt dot. The rule
          // exists because warm matte gold on cream fails text contrast; as a
          // mark it carries the warmth without the failure.
          Container(
            margin: const EdgeInsets.only(top: 7, right: AppSpacing.sm),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
