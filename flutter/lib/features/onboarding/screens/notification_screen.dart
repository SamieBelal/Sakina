import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_continue_button.dart';
import '../widgets/onboarding_page_wrapper.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  Future<void> _requestPermission(WidgetRef ref) async {
    try {
      await OneSignal.Notifications.requestPermission(true);
    } catch (_) {}
    ref.read(onboardingProvider.notifier).setNotificationPermission(true);
    onNext();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final benefits = [
      AppStrings.notificationBenefit1,
      AppStrings.notificationBenefit2,
      AppStrings.notificationBenefit3,
    ];

    return OnboardingPageWrapper(
      progressSegment: 4,
      onBack: onBack,
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.primary,
                    size: 32,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.06, 1.06),
                      duration: 750.ms,
                    )
                    .then()
                    .scale(
                      begin: const Offset(1.06, 1.06),
                      end: const Offset(1.0, 1.0),
                      duration: 750.ms,
                    ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  AppStrings.notificationTitle,
                  style: AppTypography.displaySmall.copyWith(
                    color: AppColors.textPrimaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppStrings.notificationSubtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                ...benefits.asMap().entries.map((entry) {
                  final delay = (entry.key * 100).ms;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: delay)
                      .slideX(
                        begin: 0.05,
                        end: 0,
                        duration: 400.ms,
                        delay: delay,
                      );
                }),
              ],
            ),
          ),
          OnboardingContinueButton(
            label: AppStrings.notificationCta,
            onPressed: () => _requestPermission(ref),
          ),
          Center(
            child: TextButton(
              onPressed: onNext,
              child: Text(
                AppStrings.notificationSkip,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
