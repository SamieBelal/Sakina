import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';

class SubpageHeader extends StatelessWidget {
  const SubpageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onBack,
  });

  final String title;
  final String? subtitle;

  /// Optional widget rendered to the right of the title row (e.g. a token
  /// balance chip on the Quests screen). Aligned to the top so it sits in
  /// line with the title rather than centered against the subtitle.
  final Widget? trailing;

  /// Override the back tap. Defaults to `context.pop()` when the route can
  /// pop. Pass this when the caller needs to run analytics or custom close
  /// logic instead of a plain pop (e.g. ReferUnlock returning to paywall).
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final showBackButton = onBack != null || context.canPop();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBackButton)
          _HeaderIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack ?? context.pop,
          )
        else
          const SizedBox(width: 44),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.displaySmall.copyWith(
                  color: AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: trailing!,
          ),
        ],
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(
          color: AppColors.borderLight,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            size: 18,
            color: AppColors.textPrimaryLight,
          ),
        ),
      ),
    );
  }
}
