import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/daily/content/muhasabah_completion_copy.dart';
import 'package:sakina/features/journal/journal_resurfacing.dart';

/// E1 — "On This Night": the user's own entry from this date a month, three
/// months or a year ago, surfaced in the archive.
///
/// The sibling of `TimeMachineCard`, which shows the same anchor at the end of
/// the night. Both read the anchor from Wave C's one rule
/// (`selectTimeMachineAnchor`); they differ only in framing. This one is
/// tappable, because in the archive the obvious next thing is to go and read
/// that night in full — on the completion screen it deliberately is not, since
/// the night the user just finished is where they are meant to stay.
///
/// Costs no content: everything on screen was written by the user.
class OnThisNightCard extends StatelessWidget {
  const OnThisNightCard({
    required this.onThisNight,
    required this.onOpen,
    super.key,
  });

  final OnThisNight onThisNight;

  /// Opens the resurfaced entry. The host decides whether that is the story
  /// flow or the detail page.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final entry = onThisNight.entry;
    final words = entry.userText.trim();
    if (words.isEmpty) return const SizedBox.shrink();
    final name = entry.name.trim();

    return Semantics(
      button: true,
      label: JournalResurfacingCopy.onThisNight,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onOpen();
        },
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md + 4),
          decoration: BoxDecoration(
            // The same quiet emerald tint the completion-screen card uses, so
            // the two surfaces read as one feature seen twice.
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.14),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Gold as a non-text accent only (DESIGN.md).
                  const Icon(Icons.history_toggle_off,
                      size: 16, color: AppColors.secondary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    JournalResurfacingCopy.onThisNight.toUpperCase(),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiaryLight,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              Text(
                MuhasabahCompletionCopy.timeMachineLead(
                    onThisNight.offsetDays),
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                words,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textPrimaryLight,
                  height: 1.4,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm + 4),
              Row(
                children: [
                  if (name.isNotEmpty)
                    Expanded(
                      // Latin script only in this `Text`; the anchor's Arabic is
                      // not rendered here, so nothing in this widget mixes
                      // direction (CLAUDE.md).
                      child: Text(
                        '${MuhasabahCompletionCopy.timeMachineFooter} $name',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textTertiaryLight),
                        textDirection: TextDirection.ltr,
                      ),
                    )
                  else
                    const Spacer(),
                  Text(
                    JournalResurfacingCopy.onThisNightOpen,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      size: 16, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
