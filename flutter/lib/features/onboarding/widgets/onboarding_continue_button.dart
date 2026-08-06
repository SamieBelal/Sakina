import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class OnboardingContinueButton extends StatelessWidget {
  const OnboardingContinueButton({
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  /// Swaps the label for a spinner and blocks further taps.
  ///
  /// Every screen whose Continue awaits the network needs this. Without it the
  /// button renders identically before and during the work, so the only
  /// feedback a tap produces is the haptic — and the spinner the user
  /// eventually sees belongs to the NEXT screen, which cannot be built until
  /// the await that is keeping them waiting has already finished. The
  /// indicator then marks the end of the wait instead of the start of it.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    // `loading` implies un-tappable: a second tap is at best wasted and at
    // worst a duplicate sign-up.
    final tappable = enabled && !loading;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(30),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ElevatedButton(
            onPressed: tappable
                ? () {
                    HapticFeedback.mediumImpact();
                    onPressed?.call();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              disabledBackgroundColor: AppColors.primary.withAlpha(128),
              disabledForegroundColor: AppColors.textOnPrimary.withAlpha(128),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.textOnPrimary,
                    ),
                  )
                : Text(
                    label,
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textOnPrimary,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
