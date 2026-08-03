import 'package:flutter/material.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/journal/journal_resurfacing.dart';

/// E2 — the weekly recap: what the last seven nights amounted to.
///
/// Sits in the Journal's stats region, in the slot the lifetime theme line
/// (*"You often turn to Allah with X"*) used to own outright. The two answer the
/// same question at different resolutions, and stacking them would put two theme
/// claims one above the other, the vaguer one on top. The host renders this when
/// [WeeklyRecap] resolves and falls back to the lifetime line when it does not.
///
/// **Nothing here is a score.** No streak, no comparison with last week, no
/// "you're down two entries". A recap of a spiritual practice that grades the
/// practice stops being a recap.
class WeeklyRecapCard extends StatelessWidget {
  const WeeklyRecapCard({required this.recap, super.key});

  final WeeklyRecap recap;

  @override
  Widget build(BuildContext context) {
    final themes = recap.themes;
    final names = recap.names.take(4).toList();
    final line = recap.oneLine.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        // The warm sand the lifetime insight card already uses, so replacing one
        // with the other does not read as the layout changing under the user.
        color: const Color(0xFFF5EBD9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  color: AppColors.secondary, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  JournalResurfacingCopy.recapHeader,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                JournalResurfacingCopy.recapCount(recap.entryCount),
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textTertiaryLight),
              ),
            ],
          ),
          if (themes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              themes.join(' · '),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondaryLight,
                height: 1.4,
              ),
            ),
          ],
          if (names.isNotEmpty) ...[
            const SizedBox(height: 6),
            // Latin transliterations only — the Names' Arabic is not rendered
            // here, so this `Text` never mixes direction (CLAUDE.md).
            Text(
              '${JournalResurfacingCopy.recapNamesLead} ${names.join(', ')}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondaryLight,
                height: 1.4,
              ),
              textDirection: TextDirection.ltr,
            ),
          ],
          if (line.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm + 2),
            Text(
              JournalResurfacingCopy.recapOneLineLead,
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.textTertiaryLight),
            ),
            const SizedBox(height: 2),
            Text(
              '"$line"',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimaryLight,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
