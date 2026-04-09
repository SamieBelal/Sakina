import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/app_session.dart';
import '../../../services/auth_service.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_continue_button.dart';
import '../widgets/onboarding_page_wrapper.dart';
import '../widgets/social_sign_in_button.dart';

class SaveProgressScreen extends ConsumerStatefulWidget {
  const SaveProgressScreen({
    required this.onNext,
    required this.onBack,
    required this.onSocialAuthComplete,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSocialAuthComplete;

  @override
  ConsumerState<SaveProgressScreen> createState() =>
      _SaveProgressScreenState();
}

class _SaveProgressScreenState extends ConsumerState<SaveProgressScreen> {
  bool _isLoading = false;

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    ref.read(onboardingProvider.notifier).clearAuthError();

    try {
      await ref.read(authServiceProvider).signInWithApple();
      if (!mounted) return;
      ref.read(onboardingProvider.notifier).setSignedUp(true);
      await ref.read(onboardingProvider.notifier).persistOnboardingToSupabase();
      if (!mounted) return;
      widget.onSocialAuthComplete();
    } on AuthException catch (e) {
      if (!mounted) return;
      ref.read(onboardingProvider.notifier).setAuthError(e.message);
    } catch (_) {
      if (!mounted) return;
      ref.read(onboardingProvider.notifier).setAuthError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    ref.read(onboardingProvider.notifier).clearAuthError();

    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      if (!mounted) return;
      ref.read(onboardingProvider.notifier).setSignedUp(true);
      await ref.read(onboardingProvider.notifier).persistOnboardingToSupabase();
      if (!mounted) return;
      widget.onSocialAuthComplete();
    } on AuthException catch (e) {
      if (!mounted) return;
      ref.read(onboardingProvider.notifier).setAuthError(e.message);
    } catch (_) {
      if (!mounted) return;
      ref.read(onboardingProvider.notifier).setAuthError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authError = ref.watch(
      onboardingProvider.select((s) => s.authError),
    );

    return OnboardingPageWrapper(
      progressSegment: 15,
      onBack: widget.onBack,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
        children: [
          SvgPicture.asset(
            'assets/illustrations/onboarding_save.svg',
            height: (MediaQuery.sizeOf(context).height * 0.18).clamp(110, 170),
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.0, 1.0),
                duration: 600.ms,
              ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppStrings.signUpChoiceTitle,
            style: AppTypography.displaySmall.copyWith(
              color: AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 100.ms)
              .slideY(begin: 0.03, end: 0),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.signUpChoiceSubtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
          const SizedBox(height: AppSpacing.lg),
          // Apple Sign-In
          SocialSignInButton(
            label: AppStrings.signUpChoiceApple,
            onPressed: _isLoading ? () {} : _signInWithApple,
            isDark: true,
            icon: const Icon(Icons.apple, color: Colors.white, size: 22),
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
          const SizedBox(height: AppSpacing.sm + 4),
          // Google Sign-In
          SocialSignInButton(
            label: AppStrings.signUpChoiceGoogle,
            onPressed: _isLoading ? () {} : _signInWithGoogle,
            isDark: false,
            icon: const Icon(Icons.g_mobiledata,
                size: 26, color: AppColors.textPrimaryLight),
          ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
          const SizedBox(height: AppSpacing.md),
          // Divider with "or"
          Row(
            children: [
              const Expanded(
                child: Divider(color: AppColors.borderLight),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  AppStrings.signUpChoiceOrDivider,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ),
              const Expanded(
                child: Divider(color: AppColors.borderLight),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Auth error display
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: authError != null
                ? Padding(
                    key: ValueKey(authError),
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      authError,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          // Continue with Email
          OnboardingContinueButton(
            label: AppStrings.signUpChoiceEmail,
            onPressed: _isLoading ? null : widget.onNext,
            enabled: !_isLoading,
          ),
          const SizedBox(height: AppSpacing.md),
          // Skip for now (guest mode)
          TextButton(
            onPressed: _isLoading
                ? null
                : () async {
                    await ref.read(appSessionProvider).continueAsGuest();
                    if (!context.mounted) return;
                    context.go('/');
                  },
            child: Text(
              'Skip for now',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textTertiaryLight,
              ),
            ),
          ),
          const Spacer(),
        ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
