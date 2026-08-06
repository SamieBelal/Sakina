import 'package:flutter/material.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/daily/content/muhasabah_completion_copy.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/widgets/adjusted_arabic_display.dart';

/// What the night saved, shown back on the completion screen (Wave C, C2).
///
/// The words, the Name and the duʿā — in that order, because the user's own
/// sentence is the thing that was previously thrown away and is therefore the
/// thing this screen exists to prove is kept.
///
/// **Reads the persisted entry, not live loop state.** If a field is missing
/// here it is missing from the row, which is exactly what the user should be
/// told; rendering from state would show something the journal will not.
class TonightEntrySummary extends StatelessWidget {
  const TonightEntrySummary({
    required this.entry,
    this.isReplay = false,
    super.key,
  });

  final SavedReflection entry;

  /// True when [entry] is a row the day ALREADY had rather than the one this
  /// completion wrote — see [DailyLoopState.tonightEntryIsReplay].
  ///
  /// The entry is still shown, because it is real and it is the user's. What
  /// changes is the one claim on this screen that is about TONIGHT rather than
  /// about the row: [MuhasabahCompletionCopy.nameLabel] reads *"The Name you
  /// met"*, and on a replay the Name in the row is not the Name the ceremony
  /// just revealed. Defaults false, so every ordinary night is unchanged.
  final bool isReplay;

  @override
  Widget build(BuildContext context) {
    final words = entry.userText.trim();
    final dua = entry.duaTranslation.trim();
    final arabic = entry.nameArabic.trim();
    final name = entry.name.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (words.isNotEmpty) ...[
          _label(MuhasabahCompletionCopy.yourWordsLabel),
          const SizedBox(height: AppSpacing.sm),
          Text(
            words,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textPrimaryLight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (arabic.isNotEmpty || name.isNotEmpty) ...[
          _label(isReplay
              ? MuhasabahCompletionCopy.nameLabelReplay
              : MuhasabahCompletionCopy.nameLabel),
          const SizedBox(height: AppSpacing.sm),
          // Arabic and Latin never share a `Text` — separate widgets, each with
          // its own direction (CLAUDE.md). `AdjustedArabicDisplay` carries the
          // ascender correction Aref Ruqaa needs; the SizedBoxes around it are
          // the compensation its own doc prescribes, scaled to fontSize 30.
          if (arabic.isNotEmpty) ...[
            const SizedBox(height: 22),
            AdjustedArabicDisplay(
              text: arabic,
              textAlign: TextAlign.start,
              style: AppTypography.nameOfAllahDisplay.copyWith(
                color: AppColors.secondary,
                fontSize: 30,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (name.isNotEmpty)
            Text(
              name,
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textPrimaryLight,
              ),
              textDirection: TextDirection.ltr,
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (dua.isNotEmpty) ...[
          _label(MuhasabahCompletionCopy.duaLabel),
          const SizedBox(height: AppSpacing.sm),
          Text(
            dua,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
            textDirection: TextDirection.ltr,
          ),
        ],
      ],
    );
  }

  Widget _label(String text) => Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textTertiaryLight,
          letterSpacing: 0.6,
        ),
      );
}
