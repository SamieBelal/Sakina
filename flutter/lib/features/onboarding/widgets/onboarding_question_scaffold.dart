import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import 'onboarding_continue_button.dart';
import 'onboarding_page_wrapper.dart';

/// Shared scaffold for every quiz screen in the onboarding flow.
/// Headline + optional subtitle + body + Continue button, with
/// Continue disabled until the parent reports `continueEnabled`.
class OnboardingQuestionScaffold extends StatelessWidget {
  const OnboardingQuestionScaffold({
    super.key,
    required this.progressSegment,
    required this.headline,
    required this.body,
    required this.onContinue,
    required this.onBack,
    required this.continueEnabled,
    this.subtitle,
    this.continueLabel,
  });

  final int progressSegment;
  final String headline;
  final String? subtitle;
  final Widget body;
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final bool continueEnabled;
  final String? continueLabel;

  @override
  Widget build(BuildContext context) {
    return OnboardingPageWrapper(
      progressSegment: progressSegment,
      onBack: onBack,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style: AppTypography.displaySmall.copyWith(
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      subtitle!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  body,
                  const Spacer(),
                  OnboardingContinueButton(
                    label: continueLabel ?? AppStrings.continueButton,
                    onPressed: onContinue,
                    enabled: continueEnabled,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
