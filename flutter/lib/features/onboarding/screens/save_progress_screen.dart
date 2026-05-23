import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/auth_service.dart';
import '../../../services/analytics_provider.dart';
import '../../../services/analytics_events.dart';
import '../../../services/referral_service.dart';
import '../../../widgets/referral_code_field.dart';
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

  // ── Referral disclosure state ──
  // Collapsed by default. If pending_referral exists in SharedPreferences (e.g.
  // a deep-link captured the code BEFORE the user opened the app), the
  // disclosure auto-expands AND renders the pre-fill as read-only — see
  // _buildReferralDisclosure(). The user can clear the lock via "Change code".
  bool _isReferralExpanded = false;
  bool _isPrefillLocked = false;
  String? _prefilledCode;
  bool _hasPendingCode = false;

  @override
  void initState() {
    super.initState();
    // Read prefs in a microtask — initState can't await directly. The default
    // (collapsed, no prefill) is fine until the future resolves.
    _hydrateReferralPrefs();
  }

  Future<void> _hydrateReferralPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(referralPendingReferralPrefsKey);
    if (!mounted) return;
    if (code != null && code.isNotEmpty) {
      setState(() {
        _isReferralExpanded = true;
        _isPrefillLocked = true;
        _prefilledCode = code;
        _hasPendingCode = true;
      });
    }
  }

  /// Two-step referral hook, called from both _signInWithApple and
  /// _signInWithGoogle AFTER the auth response resolves but BEFORE
  /// persistOnboardingToSupabase. Wrapped in try/catch — referral failures
  /// must never block signup. The defensive cold-launch path in
  /// AppSessionNotifier retries applyPendingReferralIfAny if a kill window
  /// strands a pending code in SharedPreferences.
  ///
  /// Why this is safe to run BEFORE persistOnboardingToSupabase: the
  /// `user_profiles` row that `apply_referral` updates is created
  /// synchronously by the `handle_new_user` trigger on `auth.users` insert
  /// (supabase/migrations/20260407000000_initial_schema.sql L631-633, body
  /// updated by 20260407200000_fix_handle_new_user_display_name.sql). By the
  /// time `signInWithApple/Google` returns, the row exists — so the
  /// `apply_referral` UPDATE on `user_profiles.referral_premium_until`
  /// affects exactly 1 row and the referee's 7d window is set correctly.
  /// `persistOnboardingToSupabase` runs an UPDATE on the same row to fill
  /// onboarding fields; the two writes don't conflict.
  Future<void> _applyReferralHooks(String userId) async {
    try {
      await ref.read(referralServiceProvider).ensureReferralCode(userId);
    } catch (e) {
      debugPrint('[SaveProgress] ensureReferralCode failed (non-fatal): $e');
    }
    try {
      await ref.read(referralServiceProvider).applyPendingReferralIfAny(userId);
    } catch (e) {
      debugPrint(
          '[SaveProgress] applyPendingReferralIfAny failed (non-fatal): $e');
    }
  }

  Future<void> _signInWithApple() async {
    ref.read(analyticsProvider).track(AnalyticsEvents.signupMethodSelected, properties: {'method': 'apple'});
    setState(() => _isLoading = true);
    ref.read(onboardingProvider.notifier).clearAuthError();

    try {
      await ref.read(authServiceProvider).signInWithApple();
      if (!mounted) return;
      ref.read(onboardingProvider.notifier).setSignedUp(true);
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[SaveProgress] currentUser null after Apple sign-in');
        ref.read(onboardingProvider.notifier).setAuthError('Sign-in succeeded but session is not ready. Please try again.');
        return;
      }
      ref.read(analyticsProvider).identify(userId);
      ref.read(analyticsProvider).track(AnalyticsEvents.signupCompleted, properties: {'method': 'apple'});

      // Refer-to-Unlock signup hook. Must run BEFORE persistOnboardingToSupabase
      // so the referral row is written under the freshly authenticated
      // session. ensure_referral_code populates the user's own code;
      // applyPendingReferralIfAny drains any inbound code from
      // SharedPreferences (set by main.dart's deep-link capture).
      await _applyReferralHooks(userId);

      await ref.read(onboardingProvider.notifier).persistOnboardingToSupabase();
      if (!mounted) return;
      widget.onSocialAuthComplete();
    } on AuthException catch (e) {
      if (!mounted) return;
      ref.read(analyticsProvider).track(AnalyticsEvents.signupFailed, properties: {'method': 'apple', 'error': e.message});
      ref.read(onboardingProvider.notifier).setAuthError(e.message);
    } catch (_) {
      if (!mounted) return;
      ref.read(analyticsProvider).track(AnalyticsEvents.signupFailed, properties: {'method': 'apple', 'error': 'unknown'});
      ref.read(onboardingProvider.notifier).setAuthError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    ref.read(analyticsProvider).track(AnalyticsEvents.signupMethodSelected, properties: {'method': 'google'});
    setState(() => _isLoading = true);
    ref.read(onboardingProvider.notifier).clearAuthError();

    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      if (!mounted) return;
      ref.read(onboardingProvider.notifier).setSignedUp(true);
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[SaveProgress] currentUser null after Google sign-in');
        ref.read(onboardingProvider.notifier).setAuthError('Sign-in succeeded but session is not ready. Please try again.');
        return;
      }
      ref.read(analyticsProvider).identify(userId);
      ref.read(analyticsProvider).track(AnalyticsEvents.signupCompleted, properties: {'method': 'google'});

      // Same referral hook as Apple — see _signInWithApple comment.
      await _applyReferralHooks(userId);

      await ref.read(onboardingProvider.notifier).persistOnboardingToSupabase();
      if (!mounted) return;
      widget.onSocialAuthComplete();
    } on AuthException catch (e) {
      if (!mounted) return;
      ref.read(analyticsProvider).track(AnalyticsEvents.signupFailed, properties: {'method': 'google', 'error': e.message});
      ref.read(onboardingProvider.notifier).setAuthError(e.message);
    } catch (_) {
      if (!mounted) return;
      ref.read(analyticsProvider).track(AnalyticsEvents.signupFailed, properties: {'method': 'google', 'error': 'unknown'});
      ref.read(onboardingProvider.notifier).setAuthError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Referral field handlers ──

  void _onReferralDisclosureTap() {
    if (_isReferralExpanded) return;
    ref
        .read(analyticsProvider)
        .track(AnalyticsEvents.referralFieldRevealed);
    setState(() => _isReferralExpanded = true);
  }

  Future<void> _onChangePrefilledCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(referralPendingReferralPrefsKey);
    await prefs.remove(referralPendingReferralSourcePrefsKey);
    if (!mounted) return;
    setState(() {
      _isPrefillLocked = false;
      _prefilledCode = null;
      _hasPendingCode = false;
    });
  }

  Future<void> _onCodeChanged(
      String code, ReferralCodeValidationState state) async {
    final prefs = await SharedPreferences.getInstance();
    if (code.isEmpty) {
      await prefs.remove(referralPendingReferralPrefsKey);
      await prefs.remove(referralPendingReferralSourcePrefsKey);
      if (_hasPendingCode) {
        ref
            .read(analyticsProvider)
            .track(AnalyticsEvents.referralFieldCodeCleared);
      }
      if (mounted) setState(() => _hasPendingCode = false);
      return;
    }
    // Skip transient states — let the user finish typing / let validation
    // settle. The widget itself only fires onCodeChanged on debounced
    // settled edges, but validating/tooShort still slip through and we
    // don't want to persist mid-flight values.
    if (state == ReferralCodeValidationState.validating ||
        state == ReferralCodeValidationState.tooShort) {
      return;
    }
    await prefs.setString(referralPendingReferralPrefsKey, code);
    await prefs.setString(
      referralPendingReferralSourcePrefsKey,
      AnalyticsEvents.referralSourceOnboardingField,
    );
    ref
        .read(analyticsProvider)
        .track(AnalyticsEvents.referralFieldCodeEntered);
    if (mounted) setState(() => _hasPendingCode = true);
  }

  Widget _buildReferralDisclosure() {
    if (!_isReferralExpanded) {
      return InkWell(
        onTap: _onReferralDisclosureTap,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.card_giftcard_rounded,
                size: 16,
                color: AppColors.textSecondaryLight,
              ),
              const SizedBox(width: AppSpacing.xs),
              // Flexible so the text ellipsizes on narrow viewports
              // (iPhone SE ~375 logical px) instead of overflowing the Row.
              // Tested-with widget tests use the standard iPhone 13 viewport
              // (390 logical px) where this Row had ~166px of overflow without
              // the Flexible wrapper. See onboarding_auth_routing_test.dart.
              Flexible(
                child: Text(
                  'Did a friend send you a gift?',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.textSecondaryLight,
              ),
            ],
          ),
        ),
      );
    }

    // Expanded state.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Got a code from a friend? Enter it here for 7 free days of '
          'Sakina, our gift to you.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_isPrefillLocked && _prefilledCode != null)
          _buildPrefilledChip(_prefilledCode!)
        else
          ReferralCodeField(
            key: const ValueKey('referral-code-field'),
            onCodeChanged: _onCodeChanged,
          ),
      ],
    );
  }

  Widget _buildPrefilledChip(String code) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              code,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textPrimaryLight,
                letterSpacing: 1.5,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          TextButton(
            onPressed: _onChangePrefilledCode,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Change code',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authError = ref.watch(
      onboardingProvider.select((s) => s.authError),
    );

    return OnboardingPageWrapper(
      progressSegment: 20,
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
          // "Did a friend send you a gift?" disclosure — collapsed by default,
          // auto-expanded + locked when a pending_referral pref is present.
          // Optional: never gates the Continue/Apple/Google/Email buttons.
          _buildReferralDisclosure(),
          const SizedBox(height: AppSpacing.md),
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
            onPressed: _isLoading ? null : () {
              ref.read(analyticsProvider).track(AnalyticsEvents.signupMethodSelected, properties: {'method': 'email'});
              widget.onNext();
            },
            enabled: !_isLoading,
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
