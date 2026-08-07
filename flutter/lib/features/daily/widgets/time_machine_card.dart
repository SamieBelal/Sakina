import 'package:flutter/material.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/daily/content/muhasabah_completion_copy.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';

/// The same-prompt time machine (Wave C, C3) — the user's own answer from
/// 30 / 90 / 365 nights ago, revealed only after tonight is complete.
///
/// **It renders nothing when there is no anchor**, and that is the design, not
/// a degradation: a new user simply does not see it, and it arrives as a
/// surprise on day 31. The host is what guarantees it cannot be peeked at first
/// — the anchor is never on state before `DailyLoopStep.completed`.
///
/// Costs no content: everything on screen was written by the user.
class TimeMachineCard extends StatelessWidget {
  const TimeMachineCard({
    required this.anchor,
    required this.tonightLocalDay,
    super.key,
  });

  /// The resurfaced entry.
  final SavedReflection anchor;

  /// Tonight's `YYYY-MM-DD`, used only to name the distance in the lead line.
  final String? tonightLocalDay;

  /// Nights between the anchor and tonight, or null when either day is unusable.
  int? get _offsetDays {
    final today = tonightLocalDay == null
        ? null
        : parseLocalDayString(tonightLocalDay!);
    final then = anchor.entryLocalDay == null
        ? null
        : parseLocalDayString(anchor.entryLocalDay!);
    if (today == null || then == null) return null;
    return today.difference(then).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final words = anchor.userText.trim();
    if (words.isEmpty) return const SizedBox.shrink();
    final name = anchor.name.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md + 4),
      decoration: BoxDecoration(
        // A quiet emerald tint rather than a second white card: it has to read
        // as arriving from somewhere else without competing with the night the
        // user just finished.
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
              // Gold, but as an icon — a non-text accent (DESIGN.md).
              const Icon(Icons.history_toggle_off,
                  size: 16, color: AppColors.secondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  MuhasabahCompletionCopy.timeMachineLead(_offsetDays ?? 365),
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          Text(
            words,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textPrimaryLight,
              height: 1.4,
            ),
          ),
          if (name.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm + 4),
            // Latin script only in this `Text`; the anchor's Arabic is
            // deliberately not rendered here — a second calligraphic Name on the
            // completion screen would compete with tonight's.
            Text(
              '${MuhasabahCompletionCopy.timeMachineFooter} $name',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiaryLight,
              ),
              textDirection: TextDirection.ltr,
            ),
          ],
        ],
      ),
    );
  }
}
