import 'package:flutter/material.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/theme/app_typography.dart';

/// The freeze-burn "reunion" card (spec S4 / D4 / D14). Shown on Home load after
/// a streak freeze auto-bridged a missed day. Deliberately **reunion-first** —
/// it leads with "Welcome back", not "your freeze saved you", so the moment
/// reads as relief, never "you almost failed" (the brand's "resting, not
/// shamed" stance). Dismissible; the freeze mention is secondary.
class FreezeBurnCard extends StatefulWidget {
  const FreezeBurnCard({
    super.key,
    required this.streak,
    required this.onDismiss,
    this.onShown,
  });

  final int streak;
  final VoidCallback onDismiss;

  /// Fired once when the card first appears (for the `freeze_burn_ack_shown`
  /// instrument). Kept as a callback so the widget stays Riverpod-free.
  final VoidCallback? onShown;

  @override
  State<FreezeBurnCard> createState() => _FreezeBurnCardState();
}

class _FreezeBurnCardState extends State<FreezeBurnCard> {
  @override
  void initState() {
    super.initState();
    widget.onShown?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          const Icon(Icons.shield_moon_outlined,
              color: AppColors.primary, size: 26),
          const SizedBox(height: 8),
          Text(
            'Welcome back',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Your ${widget.streak}-day streak is intact.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'A freeze held it while you were away.',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: widget.onDismiss,
            child: Text(
              'Okay',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
