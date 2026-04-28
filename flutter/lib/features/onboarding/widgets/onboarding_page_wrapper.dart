import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import 'onboarding_progress_bar.dart';

class OnboardingPageWrapper extends StatelessWidget {
  const OnboardingPageWrapper({
    required this.progressSegment,
    required this.onBack,
    required this.child,
    this.contentTopPadding,
    this.resizeToAvoidBottomInset = true,
    super.key,
  });

  final int progressSegment;
  final VoidCallback onBack;
  final Widget child;
  final double? contentTopPadding;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: SafeArea(
        maintainBottomViewPadding: !resizeToAvoidBottomInset,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.borderLight,
                          width: 0.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OnboardingProgressBar(
                      currentSegment: progressSegment,
                    ),
                  ),
                ],
              ),
              SizedBox(height: contentTopPadding ?? AppSpacing.xxl),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
