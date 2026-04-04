import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final currentInput = state.demoFeelingInput ?? '';

    return Column(
      key: const ValueKey('input'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Sparkle icon in primaryLight circle with pulse animation
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: AppColors.primary,
            size: 28,
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.12, 1.12),
              duration: 750.ms,
            )
            .then()
            .scale(
              begin: const Offset(1.12, 1.12),
              end: const Offset(1.0, 1.0),
              duration: 750.ms,
            ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          AppStrings.checkinTitle,
          style: AppTypography.displaySmall.copyWith(
            color: AppColors.textPrimaryLight,
          ),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(duration: 300.ms, delay: 100.ms)
            .slideY(begin: 0.03, end: 0, duration: 300.ms, delay: 100.ms),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppStrings.checkinSubtitle,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondaryLight,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
        const SizedBox(height: AppSpacing.xl),
        _FocusAwareTextField(
          controller: _controller,
          onChanged: (value) => notifier.setDemoFeelingInput(value),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 300.ms)
            .slideY(begin: 0.02, end: 0, duration: 400.ms, delay: 300.ms),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _chips.asMap().entries.map((entry) {
            final index = entry.key;
            final chip = entry.value;
            final isSelected =
                currentInput.isNotEmpty && currentInput == chip;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _controller.text = chip;
                notifier.setDemoFeelingInput(chip);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryLight
                      : AppColors.surfaceAltLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.borderLight,
                  ),
                ),
                child: Text(
                  chip,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms, delay: (400 + index * 60).ms);
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
          // Three pulsing dots
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fadeIn(duration: 600.ms, delay: (i * 200).ms)
                  .then()
                  .fadeOut(duration: 600.ms);
            }),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Decorative Arabic text at low opacity
          Opacity(
            opacity: 0.15,
            child: Text(
              '\u0628\u0650\u0633\u0652\u0645\u0650 \u0627\u0644\u0644\u0651\u064E\u0647\u0650',
              style: AppTypography.nameOfAllahDisplay.copyWith(
                color: AppColors.secondary,
                fontSize: 36,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppStrings.checkinLoadingTitle,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          ),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HapticFeedback.mediumImpact();
    });
    return SingleChildScrollView(
      key: const ValueKey('result'),
      child: Column(
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              return Icon(
                Icons.auto_awesome,
                size: 16 + (i == 2 ? 8 : 0),
                color: AppColors.secondary.withAlpha(180 + (i == 2 ? 75 : 0)),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0, 0),
                    end: const Offset(1, 1),
                    curve: Curves.elasticOut,
                    duration: 600.ms,
                    delay: (i * 80).ms,
                  )
                  .fadeIn(duration: 400.ms, delay: (i * 80).ms);
            }),
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
          const SizedBox(height: AppSpacing.lg),
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
      ),
    );
  }
}

class _FocusAwareTextField extends StatefulWidget {
  const _FocusAwareTextField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  State<_FocusAwareTextField> createState() => _FocusAwareTextFieldState();
}

class _FocusAwareTextFieldState extends State<_FocusAwareTextField> {
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) => setState(() => _hasFocus = focused),
      child: TextField(
        controller: widget.controller,
        maxLines: 3,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: AppStrings.typeYourFeeling,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textTertiaryLight,
          ),
          filled: true,
          fillColor:
              _hasFocus ? AppColors.primaryLight : AppColors.surfaceLight,
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
    );
  }
}
