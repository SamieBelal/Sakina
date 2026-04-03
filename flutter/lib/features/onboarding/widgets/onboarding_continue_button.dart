import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class OnboardingContinueButton extends StatelessWidget {
  const OnboardingContinueButton({
    required this.label,
    required this.onPressed,
    this.enabled = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.5,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: enabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              disabledBackgroundColor: AppColors.primary.withAlpha(128),
              disabledForegroundColor: AppColors.textOnPrimary.withAlpha(128),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
            ),
            child: Text(label, style: AppTypography.labelLarge.copyWith(
              color: AppColors.textOnPrimary,
              fontSize: 16,
            )),
          ),
        ),
      ),
    );
  }
}
