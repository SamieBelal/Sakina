import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/onboarding_provider.dart';

class GeneratingScreen extends ConsumerStatefulWidget {
  const GeneratingScreen({
    required this.onNext,
    super.key,
  });

  final VoidCallback onNext;

  @override
  ConsumerState<GeneratingScreen> createState() => _GeneratingScreenState();
}

class _GeneratingScreenState extends ConsumerState<GeneratingScreen> {
  bool _hasAdvanced = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingProvider.notifier).runGeneratingTheater(() {
        if (mounted && !_hasAdvanced) {
          _hasAdvanced = true;
          widget.onNext();
        }
      });
    });
  }

  static const _steps = [
    (threshold: 0.0, label: AppStrings.generatingStep1),
    (threshold: 0.33, label: AppStrings.generatingStep2),
    (threshold: 0.66, label: AppStrings.generatingStep3),
  ];

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(
      onboardingProvider.select((s) => s.generateProgress),
    );
    final percentage = (progress * 100).toInt();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 3),
              // Decorative Arabic at low opacity
              Opacity(
                opacity: 0.75,
                child: Text(
                  AppStrings.generatingBismillah,
                  style: AppTypography.nameOfAllahDisplay.copyWith(
                    color: AppColors.secondary,
                    fontSize: 32,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ).animate().fadeIn(duration: 800.ms),
              const SizedBox(height: AppSpacing.xxl),
              // Percentage display
              Text(
                '$percentage%',
                style: AppTypography.displayLarge.copyWith(
                  color: AppColors.primary,
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppStrings.generatingTitle,
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              // Step labels
              ...List.generate(_steps.length, (index) {
                final step = _steps[index];
                final isActive = progress >= step.threshold;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? AppColors.primaryLight
                              : AppColors.surfaceAltLight,
                        ),
                        child: Icon(
                          isActive
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 20,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textTertiaryLight,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        step.label,
                        style: AppTypography.bodyLarge.copyWith(
                          color: isActive
                              ? AppColors.textPrimaryLight
                              : AppColors.textTertiaryLight,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: (index * 100).ms);
              }),
              const Spacer(flex: 4),
            ],
          ),
        ),
      ),
    );
  }
}
