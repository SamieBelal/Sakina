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
    this.totalSegments,
    this.showBack = true,
    super.key,
  });

  final int progressSegment;
  final VoidCallback onBack;
  final Widget child;
  final double? contentTopPadding;
  final bool resizeToAvoidBottomInset;

  /// Length of the bar. Null keeps [OnboardingProgressBar]'s own default (23,
  /// sized for both kill-switch flows); the reel flow passes its own shorter
  /// count (W2-E1, [onboardingReelTotalSegments]).
  final int? totalSegments;

  /// When false the back circle is omitted entirely and the bar takes the whole
  /// row. Used by the reel page immediately after the reveal, which must not go
  /// back — an inert back button is worse than no back button.
  final bool showBack;

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
                  if (showBack) ...[
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
                  ] else
                    // Keeps the bar on the same baseline as every other page —
                    // without it the row collapses to the bar's 3px height and
                    // the content jumps up by ~20px on this one screen.
                    const SizedBox(height: 44),
                  Expanded(
                    child: OnboardingProgressBar(
                      currentSegment: progressSegment,
                      totalSegments: totalSegments ?? onboardingProgressSegments,
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
