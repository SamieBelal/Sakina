import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/keyboard.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_autofocus_text_field.dart';
import '../widgets/onboarding_continue_button.dart';
import '../widgets/onboarding_page_wrapper.dart';

class NameInputScreen extends ConsumerStatefulWidget {
  const NameInputScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  ConsumerState<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends ConsumerState<NameInputScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(onboardingProvider).signUpName ?? '',
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    dismissKeyboard(context);
    ref.read(onboardingProvider.notifier).setSignUpName(name);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = ref.watch(
      onboardingProvider.select((state) => state.currentPage == 1),
    );
    final name = _controller.text.trim();

    return GestureDetector(
      onTap: () => dismissKeyboard(context),
      behavior: HitTestBehavior.translucent,
      child: OnboardingPageWrapper(
        progressSegment: 1,
        onBack: () {
          dismissKeyboard(context);
          widget.onBack();
        },
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What should we call you?',
                      style: AppTypography.displaySmall.copyWith(
                        color: AppColors.textPrimaryLight,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.03, end: 0),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Just your first name.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
                    const Spacer(),
                    OnboardingAutofocusTextField(
                      controller: _controller,
                      shouldRequestFocus: isActive,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        hintText: 'Your first name',
                        hintStyle: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textTertiaryLight,
                        ),
                        border: const UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.borderLight),
                        ),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.borderLight),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: AppColors.primary, width: 2),
                        ),
                        counterText: '',
                      ),
                      style: AppTypography.displaySmall.copyWith(
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    OnboardingContinueButton(
                      label: AppStrings.continueButton,
                      onPressed: _submit,
                      enabled: name.isNotEmpty,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
