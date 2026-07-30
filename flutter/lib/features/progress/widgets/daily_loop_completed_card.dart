import 'package:flutter/material.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';

/// Finished for today. Deliberately NOT the emerald fill — the work is done, so
/// the card stops asking. It keeps the same footprint so the page doesn't
/// reflow when the day completes, and hosts the metered re-roll as an explicit,
/// separate tap target rather than making the whole card re-rollable (a re-roll
/// past the free daily one can cost 25 tokens; it should be deliberate).
class DailyLoopCompletedCard extends StatelessWidget {
  const DailyLoopCompletedCard({
    super.key,
    required this.name,
    required this.onReroll,
  });

  final String? name;
  final VoidCallback onReroll;

  @override
  Widget build(BuildContext context) {
    final metName = name?.trim();
    // `Material` + `Ink`, not a decorated `Container` — and the difference is
    // invisible until you tap it. An `InkWell` paints its splash on the nearest
    // `Material` ANCESTOR; with a plain `Container` that ancestor is the
    // Scaffold, so the ripple was drawn *underneath* this card's opaque
    // `primaryLight` fill and never seen. `Ink` moves the decoration onto the
    // Material's own canvas so the splash lands on top of it.
    //
    // It matters here more than anywhere else on the card: the re-roll is the
    // ONLY interactive element on it, and past the day's free reveal that tap
    // can cost 25 tokens — the exact place a user needs to see that their tap
    // registered. `_Invitation` in `daily_loop_cta_card.dart` already does this
    // correctly, so this was an inconsistency inside one wave rather than a
    // house-style question.
    return Material(
      color: Colors.transparent,
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md + 2,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.primary, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Today\'s muḥāsabah is complete',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (metName != null && metName.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'You sat with $metName.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
            const SizedBox(height: 6),
            _RerollAction(onTap: onReroll),
          ],
        ),
      ),
    );
  }
}

/// Quiet secondary action inside the completed card. 44pt tall so it clears the
/// minimum target on its own, without padding the whole card out.
class _RerollAction extends StatelessWidget {
  const _RerollAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.explore_outlined,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Meet another Name',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
