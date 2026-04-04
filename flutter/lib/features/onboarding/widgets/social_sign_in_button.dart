import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class SocialSignInButton extends StatelessWidget {
  const SocialSignInButton({
    required this.label,
    required this.onPressed,
    required this.icon,
    this.isDark = true,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final Widget icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? Colors.black : AppColors.surfaceLight,
          foregroundColor: isDark ? Colors.white : AppColors.textPrimaryLight,
          side: BorderSide(
            color: isDark ? Colors.black : AppColors.borderLight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: AppSpacing.sm + 4),
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
