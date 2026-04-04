import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_continue_button.dart';
import '../widgets/onboarding_page_wrapper.dart';

class SignUpNameScreen extends ConsumerStatefulWidget {
  const SignUpNameScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  ConsumerState<SignUpNameScreen> createState() => _SignUpNameScreenState();
}

class _SignUpNameScreenState extends ConsumerState<SignUpNameScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final existing = ref.read(onboardingProvider).signUpName;
    if (existing != null) _controller.text = existing;
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
    ref.read(onboardingProvider.notifier).setSignUpName(name);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _controller.text.trim().isNotEmpty;

    return OnboardingPageWrapper(
      progressSegment: 12,
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.signUpNameTitle,
            style: AppTypography.displaySmall.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.03, end: 0),
          const Spacer(),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: AppStrings.signUpNameHint,
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
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            style: AppTypography.displaySmall.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          OnboardingContinueButton(
            label: AppStrings.continueButton,
            onPressed: _submit,
            enabled: isValid,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
