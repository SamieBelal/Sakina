import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4, bottom: 10),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        // Warm emerald wash so it reads as a real moment (not a pale placeholder
        // box). Fades to near-transparent at the base so it settles into the
        // dashboard card rather than fighting it.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryLight,
            AppColors.primaryLight.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Emerald "seal" — a protective shield held around the streak.
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.shield_moon,
                color: Colors.white, size: 27),
          ),
          const SizedBox(height: 14),
          Text(
            'Welcome back',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Your ${widget.streak}-day streak is intact.',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textPrimaryLight,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'A freeze quietly held it while you were away.',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          // Single clean action — a white pill on the emerald wash, not a weak
          // grey text link.
          _DismissPill(onTap: widget.onDismiss),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .scaleXY(begin: 0.97, end: 1, duration: 400.ms, curve: Curves.easeOut);
  }
}

class _DismissPill extends StatelessWidget {
  const _DismissPill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border:
                Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
          ),
          child: Text(
            'Okay',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
