import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/keyboard.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_autofocus_text_field.dart';
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
    dismissKeyboard(context);
    ref.read(onboardingProvider.notifier).setSignUpName(name);
    // Update auth metadata + DB profile with the name (best-effort, don't block)
    final userId = Supabase.instance.client.auth.currentUser?.id;
    unawaited(
      Supabase.instance.client.auth
          .updateUser(UserAttributes(data: {'full_name': name}))
          .then((_) {}, onError: (_) {}),
    );
    if (userId != null) {
      unawaited(
        Supabase.instance.client
            .from('user_profiles')
            .update({'display_name': name})
            .eq('id', userId)
            .then((_) {}, onError: (_) {}),
      );
    }
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _controller.text.trim().isNotEmpty;
    final isActive = ref.watch(
      onboardingProvider.select((state) => state.currentPage == 18),
    );

    return GestureDetector(
      onTap: () => dismissKeyboard(context),
      behavior: HitTestBehavior.translucent,
      child: OnboardingPageWrapper(
        progressSegment: 18,
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
                      AppStrings.signUpNameTitle,
                      style: AppTypography.displaySmall.copyWith(
                        color: AppColors.textPrimaryLight,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.03, end: 0),
                    const Spacer(),
                    OnboardingAutofocusTextField(
                      controller: _controller,
                      shouldRequestFocus: isActive,
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
                          borderSide:
                              BorderSide(color: AppColors.primary, width: 2),
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
