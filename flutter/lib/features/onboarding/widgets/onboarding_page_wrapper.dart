import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import 'onboarding_progress_bar.dart';

class OnboardingPageWrapper extends StatelessWidget {
  const OnboardingPageWrapper({
    required this.progressSegment,
    required this.onBack,
    required this.child,
    super.key,
  });

  final int progressSegment;
  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                GestureDetector(
                  onTap: onBack,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.only(right: AppSpacing.md),
                    child: Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                ),
                Expanded(
                  child: OnboardingProgressBar(
                    currentSegment: progressSegment,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
