import 'package:flutter/material.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';

/// The shared Arabic + transliteration + translation + source stack for a duʿa.
///
/// This is the single owner of the mixed-direction rule: Arabic and Latin text
/// are always rendered as SEPARATE [Text] widgets with an explicit
/// [textDirection], never mixed in one widget (RTL bleed corrupts adjacent UI).
///
/// ```
///   ┌─────────────────────────────┐
///   │      رَبِّ اشْرَحْ لِي صَدْرِي        │  Arabic  (RTL, quranArabic)
///   │  ───────────────────────    │  divider
///   │   Rabbi-shrah li sadri      │  transliteration (LTR, italic)
///   │   My Lord, expand my breast │  translation (LTR)
///   │   Qur'an 20:25              │  source (LTR, faint) — optional
///   └─────────────────────────────┘
/// ```
///
/// [onSacredCanvas] switches the palette from the light theme to the emerald
/// sacred canvas (cream ink on emerald) — same layout, different colors.
class DuaTextBlock extends StatelessWidget {
  final String arabic;
  final String transliteration;
  final String translation;
  final String source;
  final bool onSacredCanvas;

  const DuaTextBlock({
    super.key,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    this.source = '',
    this.onSacredCanvas = false,
  });

  @override
  Widget build(BuildContext context) {
    final translationColor =
        onSacredCanvas ? AppColors.sacredInk : AppColors.textPrimaryLight;
    final secondaryColor =
        onSacredCanvas ? AppColors.sacredInkSoft : AppColors.textSecondaryLight;
    final sourceColor =
        onSacredCanvas ? AppColors.sacredInkFaint : AppColors.textTertiaryLight;
    final dividerColor = onSacredCanvas
        ? AppColors.sacredTrack
        : AppColors.dividerLight;
    final arabicColor =
        onSacredCanvas ? AppColors.sacredInk : AppColors.textPrimaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vertical centering of the Arabic is deliberate and load-bearing.
        // Two things used to push it high with a dead gap underneath:
        //   1. `Divider()` defaults to a 16px-tall BOX with its 1px line
        //      centered — so it silently reserved 8px above itself, on top of
        //      the 16px gap already there. Against the caller's ~8px above the
        //      block that made the spacing 8-above / 24-below. `height: 1`
        //      removes the phantom box.
        //   2. Amiri's line box is much taller than its ink; `even` leading
        //      splits that slack equally instead of proportionally.
        // Keep both, and keep the padding here symmetric — re-check the
        // related-dua card, beat reveal, and journal views before retuning.
        if (arabic.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                arabic,
                style: AppTypography.quranArabic.copyWith(
                  color: arabicColor,
                  leadingDistribution: TextLeadingDistribution.even,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        if (arabic.isNotEmpty && transliteration.isNotEmpty) ...[
          Divider(height: 1, color: dividerColor),
          const SizedBox(height: AppSpacing.md),
        ],
        if (transliteration.isNotEmpty)
          Text(
            transliteration,
            style: AppTypography.bodyMedium.copyWith(
              fontStyle: FontStyle.italic,
              color: secondaryColor,
            ),
            textDirection: TextDirection.ltr,
          ),
        if (translation.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            translation,
            style: AppTypography.bodyLarge.copyWith(
              color: translationColor,
              height: 1.6,
            ),
            textDirection: TextDirection.ltr,
          ),
        ],
        if (source.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            source,
            style: AppTypography.bodySmall.copyWith(color: sourceColor),
            textDirection: TextDirection.ltr,
          ),
        ],
      ],
    );
  }
}
