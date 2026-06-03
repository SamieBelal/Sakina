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
      // signUpWithRecovery owns the post-signup session race: it reads the user
      // id straight off the signUp response (no `currentUser` propagation lag),
      // and if that response carried no session it does an in-flow password
      // sign-in for the just-created account. The user never hits the old dead
      // end where tapping Continue re-ran signUp.
      final result = await ref
          .read(authServiceProvider)
          .signUpWithRecovery(email, _controller.text);
      if (!mounted) return;

      if (result.outcome == SignUpOutcome.emailAlreadyRegistered) {
        // The email already has an account. We deliberately do NOT sign in or
        // continue — doing so would overwrite that existing user's profile with
        // this onboarding run. Point them at logging in instead.
        ref.read(analyticsProvider).track(
          AnalyticsEvents.signupFailed,
          properties: {
            'method': 'email',
            'error': AnalyticsEvents.signupFailedReasonEmailTaken,
          },
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('That email already has an account. Try logging in instead.'),
          ),
        );
        return;
      }

      if (result.outcome == SignUpOutcome.failed || result.userId == null) {
        // signUp AND the in-flow recovery both failed. Map to a bounded
        // analytics reason (errorMessage == null is the pure session-race miss);
        // show the raw auth message to the user since it's actionable (weak
        // password, rate limit, etc.).
        ref.read(analyticsProvider).track(
          AnalyticsEvents.signupFailed,
          properties: {
            'method': 'email',
            'error': result.errorMessage == null
                ? AnalyticsEvents.signupFailedReasonSessionRace
                : AnalyticsEvents.signupFailedReasonForCode(result.errorCode),
          },
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.errorMessage ?? 'Something went wrong. Please try again.',
            ),
          ),
        );
        return;
      }

      final userId = result.userId!;
      ref.read(onboardingProvider.notifier).setSignedUp(true);
      ref.read(analyticsProvider).identify(userId);
      ref.read(analyticsProvider).track(
        AnalyticsEvents.signupCompleted,
        properties: {
          'method': 'email',
          // Marks signups that completed only because the session-race recovery
          // kicked in, so the funnel shows the fix doing real work.
          if (result.outcome == SignUpOutcome.recoveredViaSignIn)
            'recovery': 'signin',
        },
      );

      // Refer-to-Unlock signup hook (mirrors save_progress_screen's social
      // paths). Runs BEFORE persistOnboardingToSupabase so referral rows
      // are written under the authenticated session.
      //
      // Safe to run before persistOnboardingToSupabase because the
      // `user_profiles` row that apply_referral targets is created by the
      // `handle_new_user` trigger on auth.users insert (initial_schema.sql
      // L631-633). signUpWithRecovery resolves only after a session exists
      // (whether via signUp directly or its sign-in fallback), and that account
      // was created by our signUp, so the trigger has fired and the row exists.
      try {
        await ref.read(referralServiceProvider).ensureReferralCode(userId);
      } catch (e) {
        debugPrint('[SignUpPassword] ensureReferralCode failed (non-fatal): $e');
      }
      try {
        final applyResult = await ref
            .read(referralServiceProvider)
            .applyPendingReferralIfAny(userId);
        // Same recovery-snackbar contract as the social paths in
        // save_progress_screen.dart — only invalid / self_referral surface to
        // the user via the OnboardingState flag drained on EncouragementScreen.
        if (!applyResult.ok &&
            (applyResult.reason == 'invalid' ||
                applyResult.reason == 'self_referral')) {
          if (!mounted) return;
          ref
              .read(onboardingProvider.notifier)
              .setReferralApplyFailedReason(applyResult.reason!);
        }
      } catch (e) {
        debugPrint(
            '[SignUpPassword] applyPendingReferralIfAny failed (non-fatal): $e');
      }

      await ref.read(onboardingProvider.notifier).persistOnboardingToSupabase();
      if (!mounted) return;
      widget.onNext();
    } on AuthException catch (e) {
      // Defensive: AuthException thrown by the post-recovery referral/persist
      // flow (signUpWithRecovery itself never throws AuthException). Map to a
      // bounded reason so signup_failed.error stays low-cardinality.
      if (!mounted) return;
      ref.read(analyticsProvider).track(AnalyticsEvents.signupFailed, properties: {
        'method': 'email',
        'error': AnalyticsEvents.signupFailedReasonForCode(e.code),
      });
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
