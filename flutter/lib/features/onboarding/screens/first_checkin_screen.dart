import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/demo_result_card.dart';
import '../widgets/onboarding_continue_button.dart';
import '../widgets/onboarding_page_wrapper.dart';

class FirstCheckinScreen extends ConsumerStatefulWidget {
  const FirstCheckinScreen({
    required this.onNext,
    required this.onBack,
    required this.onComplete,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onComplete;

  @override
  ConsumerState<FirstCheckinScreen> createState() => _FirstCheckinScreenState();
}

class _FirstCheckinScreenState extends ConsumerState<FirstCheckinScreen> {
  late final TextEditingController _controller;

  static const _chips = [
    AppStrings.chipAnxious,
    AppStrings.chipSad,
    AppStrings.chipGrateful,
    AppStrings.chipFrustrated,
    AppStrings.chipLost,
    AppStrings.chipHopeful,
  ];

  @override
  void initState() {
    super.initState();
    final initial = ref.read(onboardingProvider).demoFeelingInput ?? '';
    _controller = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return OnboardingPageWrapper(
      progressSegment: 5,
      onBack: widget.onBack,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: state.isLoadingDemoResult
            ? _buildLoading()
            : state.demoCheckinCompleted
                ? _buildResult(state, notifier)
                : _buildInput(state, notifier),
      ),
    );
  }

  Widget _buildInput(OnboardingState state, OnboardingNotifier notifier) {
    final hasInput =
        state.demoFeelingInput != null && state.demoFeelingInput!.isNotEmpty;

    return Column(
      key: const ValueKey('input'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.checkinTitle,
          style: AppTypography.displaySmall.copyWith(
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppStrings.checkinSubtitle,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: _controller,
          maxLines: 3,
          onChanged: (value) => notifier.setDemoFeelingInput(value),
          decoration: InputDecoration(
            hintText: AppStrings.typeYourFeeling,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiaryLight,
            ),
            filled: true,
            fillColor: AppColors.surfaceLight,
            contentPadding: const EdgeInsets.all(AppSpacing.md),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _chips.map((chip) {
            return GestureDetector(
              onTap: () {
                _controller.text = chip;
                notifier.setDemoFeelingInput(chip);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAltLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text(
                  chip,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const Spacer(),
        OnboardingContinueButton(
          label: AppStrings.checkinReflectButton,
          onPressed: () => notifier.completeDemoCheckin(),
          enabled: hasInput,
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Center(
      key: const ValueKey('loading'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppStrings.checkinLoadingTitle,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(duration: 800.ms)
              .then()
              .fadeOut(duration: 800.ms),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.checkinLoadingSubtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(OnboardingState state, OnboardingNotifier notifier) {
    return Column(
      key: const ValueKey('result'),
      children: [
        Text(
          AppStrings.checkinResultLabel,
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        DemoResultCard(
          data: DemoResultData.forEmotion(state.demoFeelingInput ?? ''),
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: 0.05, end: 0, duration: 600.ms),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          '\u2728',
          style: TextStyle(fontSize: 32),
        ).animate().scale(
              begin: const Offset(0, 0),
              end: const Offset(1, 1),
              curve: Curves.elasticOut,
              duration: 800.ms,
            ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppStrings.checkinResultFooter,
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.textPrimaryLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppStrings.checkinResultUnlockCopy,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondaryLight,
          ),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        OnboardingContinueButton(
          label: AppStrings.checkinUnlockCta,
          onPressed: widget.onNext,
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: TextButton(
              onPressed: () async {
                await notifier.completeOnboarding();
                widget.onComplete();
              },
              child: Text(
                AppStrings.checkinSkip,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
