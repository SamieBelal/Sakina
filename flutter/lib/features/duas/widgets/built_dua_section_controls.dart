import 'package:flutter/material.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';

/// Segmented progress: one pill per section, filled gold up to and including
/// [current], the remainder on the faint `sacredTrack`. Used by the Build-a-Dua
/// section step viewer.
class DuaSegmentedProgress extends StatelessWidget {
  const DuaSegmentedProgress({
    super.key,
    required this.count,
    required this.current,
  });

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final filled = i <= current;
        return Container(
          width: 22,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: filled ? AppColors.secondary : AppColors.sacredTrack,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

/// Next button — cream fill so its emerald label passes contrast, matching the
/// canvas's functional-chrome rule.
class DuaNextButton extends StatelessWidget {
  const DuaNextButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.sacredInk,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        child: Text(
          'Next',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// The final-section Ameen CTA — cream pill with a gold accent icon and a gold
/// glow, the celebratory gateway to the Ameen screen.
class DuaAmeenCta extends StatelessWidget {
  const DuaAmeenCta({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.sacredInk,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 18, color: AppColors.secondary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Ameen',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fallback shown when the AI returned no breakdown (off-topic input). Kept on
/// the sacred canvas so the ritual surface stays consistent.
class DuaEmptyBreakdown extends StatelessWidget {
  const DuaEmptyBreakdown({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.sacredCanvasGradient),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite_outline,
                    size: 48, color: AppColors.sacredInk),
                const SizedBox(height: 16),
                Text(
                  'This place is for your heart',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.sacredInk,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please describe a sincere need or intention for your dua.',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.sacredInkSoft),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sacredInk,
                    foregroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
