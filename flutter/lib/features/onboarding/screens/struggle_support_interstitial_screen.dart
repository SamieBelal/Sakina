import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_continue_button.dart';
import '../widgets/onboarding_page_wrapper.dart';

class StruggleSupportInterstitialScreen extends ConsumerWidget {
  const StruggleSupportInterstitialScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  // Only heavy/negative emotions land right in "Many who started with {X}
  // found peace here." — skip grateful/joyful/hopeful.
  static const _focusEmotions = {
    'overwhelmed',
    'anxious',
    'grief',
    'sad',
    'lonely',
    'numb',
    'angry',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emotions = ref.watch(onboardingProvider).commonEmotions;
    final picked = emotions.firstWhere(
      _focusEmotions.contains,
      orElse: () => '',
    );
    final focus = picked.isNotEmpty ? picked : "what you're carrying";

    return OnboardingPageWrapper(
      progressSegment: 13,
      onBack: onBack,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  SvgPicture.asset(
                    'assets/illustrations/onboarding_encouragement.svg',
                    height: (MediaQuery.sizeOf(context).height * 0.24)
                        .clamp(140, 220),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1.0, 1.0),
                        duration: 600.ms,
                      ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    "You're not alone in this.",
                    style: AppTypography.displaySmall.copyWith(
                      color: AppColors.textPrimaryLight,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 200.ms)
                      .slideY(
                        begin: 0.05,
                        end: 0,
                        duration: 500.ms,
                        delay: 200.ms,
                      ),
                  const SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Text(
                      'Many who started with $focus found peace here.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondaryLight,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
                  const Spacer(flex: 3),
                  OnboardingContinueButton(
                    label: AppStrings.continueButton,
                    onPressed: onNext,
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
