import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/daily/providers/token_provider.dart';
import 'package:sakina/services/token_service.dart';

// ---------------------------------------------------------------------------
// Show the token gate sheet. Returns true if the user spent a token and
// the action should proceed, false if they cancelled or had no tokens.
// ---------------------------------------------------------------------------

Future<bool> showTokenGateSheet(
  BuildContext context, {
  required String featureName, // e.g. "Reflect" or "Build a Dua"
  required int cost,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TokenGateSheet(featureName: featureName, cost: cost),
  );
  return result ?? false;
}

class _TokenGateSheet extends ConsumerWidget {
  const _TokenGateSheet({required this.featureName, required this.cost});
  final String featureName;
  final int cost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenState = ref.watch(tokenProvider);
    final hasEnough = tokenState.balance >= cost;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        24,
        AppSpacing.pagePadding,
        MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Lock icon
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.secondaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.toll_rounded,
              color: AppColors.secondary,
              size: 32,
            ),
          )
              .animate()
              .scaleXY(begin: 0.7, end: 1.0, duration: 400.ms, curve: Curves.easeOutBack),

          const SizedBox(height: 16),

          Text(
            'Daily limit reached',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

          const SizedBox(height: 8),

          Text(
            'You\'ve used your 3 free $featureName sessions today. Spend $cost token${cost == 1 ? '' : 's'} to continue.',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 150.ms, duration: 300.ms),

          const SizedBox(height: 24),

          // Balance display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: hasEnough ? AppColors.primaryLight : AppColors.errorBackground,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.toll_rounded,
                  color: hasEnough ? AppColors.primary : AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Your balance: ${tokenState.balance} tokens',
                  style: AppTypography.bodyMedium.copyWith(
                    color: hasEnough ? AppColors.primary : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

          const SizedBox(height: 20),

          if (hasEnough) ...[
            // Spend tokens CTA
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  final result = await spendTokens(cost);
                  if (result.success) {
                    // Refresh token provider
                    ref.invalidate(tokenProvider);
                    if (context.mounted) Navigator.of(context).pop(true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                ),
                child: Text('Spend $cost token${cost == 1 ? '' : 's'} to continue'),
              ),
            ).animate().fadeIn(delay: 250.ms, duration: 300.ms),
          ] else ...[
            // No tokens — show earn path
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop(false);
                  context.push('/quests');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                ),
                child: const Text('Earn tokens from Quests'),
              ),
            ).animate().fadeIn(delay: 250.ms, duration: 300.ms),
          ],

          const SizedBox(height: 12),

          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop(false);
            },
            child: Text(
              'Not now',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiaryLight,
              ),
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
        ],
      ),
    );
  }
}
