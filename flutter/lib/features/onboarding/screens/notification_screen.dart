import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/analytics_events.dart';
import '../../../services/analytics_provider.dart';
import '../../../services/notification_service.dart';
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
    bool granted = false;
    try {
      final notificationService = ref.read(notificationServiceProvider);
      granted = await notificationService.requestPermission();
      if (granted) {
        await notificationService.setNotificationPreference(
          notifyDailyTagKey,
          true,
        );
        await notificationService.setNotificationPreference(
          notifyStreakTagKey,
          true,
        );
      }
    } catch (_) {}
    ref
        .read(analyticsProvider)
        .track(AnalyticsEvents.notificationPermissionResult, properties: {
      'granted': granted,
      'action': 'enabled',
    });
    ref.read(onboardingProvider.notifier).setNotificationPermission(granted);
    onNext();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final benefits = [
      (Icons.wb_sunny_outlined, AppStrings.notificationBenefit1),
      (Icons.local_fire_department, AppStrings.notificationBenefit2),
      (Icons.auto_stories, AppStrings.notificationBenefit3),
    ];

    return OnboardingPageWrapper(
      progressSegment: 11,
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.notificationTitle,
                    style: AppTypography.displaySmall.copyWith(
                      color: AppColors.textPrimaryLight,
                    ),
                    textAlign: TextAlign.left,
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.05, end: 0, duration: 500.ms),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppStrings.notificationSubtitle,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.left,
                  ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: SvgPicture.asset(
                      'assets/illustrations/onboarding_notification.svg',
                      height: 180,
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 300.ms).slideY(
                      begin: 0.05, end: 0, duration: 600.ms, delay: 300.ms),
                  const SizedBox(height: AppSpacing.xl),
                  ...benefits.asMap().entries.map((entry) {
                    final delay = (500 + entry.key * 100).ms;
                    final (icon, text) = entry.value;
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
                            child: Icon(
                              icon,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              text,
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: delay).slideX(
                          begin: 0.05,
                          end: 0,
                          duration: 400.ms,
                          delay: delay,
                        );
                  }),
                ],
              ),
            ),
          ),
          OnboardingContinueButton(
            label: AppStrings.notificationCta,
            onPressed: () => _requestPermission(ref),
          ),
          Center(
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                ref.read(analyticsProvider).track(
                    AnalyticsEvents.notificationPermissionResult,
                    properties: {
                      'granted': false,
                      'action': 'skipped',
                    });
                onNext();
              },
              child: Text(
                AppStrings.notificationSkip,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: Text(
              AppStrings.notificationFooter,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
