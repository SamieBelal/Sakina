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
import '../../streaks/models/companion_state.dart';
import '../../streaks/providers/cosmetics_ui_providers.dart';
import '../../streaks/widgets/companion_medallion.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_continue_button.dart';
import '../widgets/onboarding_page_wrapper.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({
    required this.onNext,
    required this.onBack,
    this.progressSegment = 14,
    this.totalSegments,
    this.lanternVariant = false,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  /// Segment this screen lights on the progress bar, and the bar's length.
  /// Defaulted to the kill-switch flows' values; the reel flow reuses this
  /// screen at a different position on a shorter bar (W2-E1).
  final int progressSegment;
  final int? totalSegments;

  /// Reel flow only (Wave G): swap the generic bell illustration for the
  /// lantern in its **unlit, waiting** state, and the three generic benefit
  /// rows for a preview of the system dialog that is about to appear.
  ///
  /// Why this is the flow's most valuable lantern placement: `pendingUnlit`
  /// does not mean "notifications off", it means *waiting to be lit* — the
  /// literal truth of a lamp whose owner hasn't returned today. Showing the
  /// real state turns an OS permission ask into a stake in something the user
  /// already owns, without the lantern having to say a word.
  ///
  /// **Off by default on purpose.** The kill-switch flows must reproduce
  /// today's production experience exactly, so trimmed/legacy keep the SVG and
  /// the benefit rows untouched.
  final bool lanternVariant;

  Future<void> _requestPermission(WidgetRef ref) async {
    bool granted = false;
    try {
      final notificationService = ref.read(notificationServiceProvider);
      granted = await notificationService.requestPermission();
      if (granted) {
        for (final key in notificationPreferenceTagKeys) {
          await notificationService.setNotificationPreference(key, true);
        }
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
      progressSegment: progressSegment,
      totalSegments: totalSegments,
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
                  if (lanternVariant)
                    Center(
                      // ambient:false — this is a cream surface, and the
                      // painter's full-canvas aura renders as a grey box here.
                      child: Consumer(
                        builder: (_, ref, __) => CompanionMedallion(
                          state: const CompanionState(
                            brightness: CompanionBrightness.pendingUnlit,
                            protected: false,
                          ),
                          size: 132,
                          ambient: false,
                          skin: ref.watch(renderableLanternSkinProvider),
                        ),
                      ),
                    ).animate().fadeIn(duration: 600.ms, delay: 300.ms).slideY(
                        begin: 0.05, end: 0, duration: 600.ms, delay: 300.ms)
                  else
                    Center(
                      child: SvgPicture.asset(
                        'assets/illustrations/onboarding_notification.svg',
                        height: 180,
                      ),
                    ).animate().fadeIn(duration: 600.ms, delay: 300.ms).slideY(
                        begin: 0.05, end: 0, duration: 600.ms, delay: 300.ms),
                  const SizedBox(height: AppSpacing.xl),
                  if (lanternVariant)
                    const _PermissionPrimer()
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 500.ms),
                  if (!lanternVariant)
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

/// A preview of the system permission dialog, shown *before* it appears
/// (Wave G — the device on Duolingo's notification screen).
///
/// The point is not decoration: a first-time user meets the real iOS sheet with
/// two equally-weighted buttons and about a second to decide, and the single
/// biggest predictor of granting is knowing which one to press before it opens.
/// Showing an inert copy costs nothing and removes the surprise.
///
/// Deliberately **not** a pixel-faithful iOS reproduction — this is drawn in
/// Sakina's own palette and type. A convincing fake of a system dialog is a
/// dark pattern; a recognisable diagram of one is a courtesy. It carries no
/// tap targets at all, so it cannot be mistaken for the real thing.
class _PermissionPrimer extends StatelessWidget {
  const _PermissionPrimer();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Next, iOS will ask permission to send notifications. '
          'Choose Allow.',
      excludeSemantics: true,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.borderLight.withValues(alpha: 0.6),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '"Sakina" Would Like to Send You Notifications',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Divider(
                  height: 1,
                  color: AppColors.borderLight.withValues(alpha: 0.6),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Don't Allow",
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Allow',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(child: Container()),
              Expanded(
                child: Icon(
                  Icons.arrow_upward_rounded,
                  size: 22,
                  color: AppColors.primary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
