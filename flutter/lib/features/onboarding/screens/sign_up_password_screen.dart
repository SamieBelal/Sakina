import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/keyboard.dart';
import '../../../services/auth_service.dart';
import '../../../services/analytics_provider.dart';
import '../../../services/analytics_events.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_autofocus_text_field.dart';
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

  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_isValid || _isLoading) return;

    final email = ref.read(onboardingProvider).signUpEmail;

    if (email == null || email.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authServiceProvider).signUpWithEmail(
            email,
            _controller.text,
          );
      if (!mounted) return;
      ref.read(onboardingProvider.notifier).setSignedUp(true);
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        // Post-signup session race — bail out gracefully instead of crashing.
        debugPrint('[SignUpPassword] currentUser null after signUpWithEmail');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign-up succeeded but session is not ready. Please try again.')),
        );
        return;
      }
      ref.read(analyticsProvider).identify(userId);
      ref.read(analyticsProvider).track(AnalyticsEvents.signupCompleted, properties: {'method': 'email'});
      await ref.read(onboardingProvider.notifier).persistOnboardingToSupabase();
      if (!mounted) return;
      widget.onNext();
    } on AuthException catch (e) {
      if (!mounted) return;
      ref.read(analyticsProvider).track(AnalyticsEvents.signupFailed, properties: {'method': 'email', 'error': e.message});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ref.read(analyticsProvider).track(AnalyticsEvents.signupFailed, properties: {'method': 'email', 'error': 'unknown'});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Something went wrong. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = ref.watch(
      onboardingProvider.select(
        (state) => state.currentPage == onboardingPasswordPageIndex,
      ),
    );

    return GestureDetector(
      onTap: () => dismissKeyboard(context),
      behavior: HitTestBehavior.translucent,
      child: OnboardingPageWrapper(
        progressSegment: 23,
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
                    OnboardingAutofocusTextField(
                      controller: _controller,
                      shouldRequestFocus: isActive,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
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
                          borderSide:
                              BorderSide(color: AppColors.primary, width: 2),
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
