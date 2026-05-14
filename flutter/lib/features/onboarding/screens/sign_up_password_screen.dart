import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/keyboard.dart';
import '../../../services/auth_service.dart';
import '../../../services/analytics_provider.dart';
import '../../../services/analytics_events.dart';
import '../../../services/referral_service.dart';
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
        // Post-signup session race: auth.signUp resolved but currentUser
        // hasn't propagated yet (intermittent on iOS). Previously returned
        // silently — no analytics — so this churn was invisible. Now we
        // fire signup_failed so the funnel reflects reality, and the
        // outer `finally` resets the loading state so the user can tap
        // Continue again without restarting onboarding.
        debugPrint('[SignUpPassword] currentUser null after signUpWithEmail');
        ref.read(analyticsProvider).track(
          AnalyticsEvents.signupFailed,
          properties: {
            'method': 'email',
            'error': AnalyticsEvents.signupFailedReasonSessionRace,
          },
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created — tap Continue to finish signing in.')),
        );
        return;
      }
      ref.read(analyticsProvider).identify(userId);
      ref.read(analyticsProvider).track(AnalyticsEvents.signupCompleted, properties: {'method': 'email'});

      // Refer-to-Unlock signup hook (mirrors save_progress_screen's social
      // paths). Runs BEFORE persistOnboardingToSupabase so referral rows
      // are written under the authenticated session.
      try {
        await ref.read(referralServiceProvider).ensureReferralCode(userId);
      } catch (e) {
        debugPrint('[SignUpPassword] ensureReferralCode failed (non-fatal): $e');
      }
      try {
        await ref
            .read(referralServiceProvider)
            .applyPendingReferralIfAny(userId);
      } catch (e) {
        debugPrint(
            '[SignUpPassword] applyPendingReferralIfAny failed (non-fatal): $e');
      }

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
      ref.read(analyticsProvider).track(
        AnalyticsEvents.signupFailed,
        properties: {
          'method': 'email',
          'error': AnalyticsEvents.signupFailedReasonUnknown,
        },
      );
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
        progressSegment: 22,
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
                      // Keyboard's return key only dismisses — matches the
                      // dominant pattern across the app. Create Account button
                      // is the single source of truth for submission.
                      onSubmitted: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
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
