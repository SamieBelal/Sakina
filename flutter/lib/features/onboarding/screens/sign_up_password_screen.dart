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

class SignUpPasswordScreen extends ConsumerStatefulWidget {
  const SignUpPasswordScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  ConsumerState<SignUpPasswordScreen> createState() =>
      _SignUpPasswordScreenState();
}

class _SignUpPasswordScreenState extends ConsumerState<SignUpPasswordScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isValid => _controller.text.length >= 6;

  void _submit() {
    if (!_isValid) return;
    // TODO: Wire up actual Supabase signUpWithEmail when backend is ready.
    ref.read(onboardingProvider.notifier).setSignedUp(true);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingPageWrapper(
      progressSegment: 14,
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.signUpPasswordTitle,
            style: AppTypography.displaySmall.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.03, end: 0),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.signUpPasswordSubtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
          const Spacer(),
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: AppStrings.signUpPasswordHint,
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
          const SizedBox(height: AppSpacing.lg),
          OnboardingContinueButton(
            label: AppStrings.signUpPasswordCta,
            onPressed: _submit,
            enabled: _isValid,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
