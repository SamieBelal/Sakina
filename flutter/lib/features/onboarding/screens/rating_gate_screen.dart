import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/analytics_events.dart';
import '../../../services/analytics_provider.dart';
import '../providers/onboarding_provider.dart';

/// Persistence key for the "user has already passed the rating gate" flag.
/// On iOS, SKStoreReviewController presents as a system overlay; if the user
/// backgrounds the app mid-prompt the screen state can be torn down + rebuilt.
/// Persisting `_rated` ensures they don't re-enter the "Leave a rating" state.
const _kRatingGateCompletedPrefsKey = 'rating_gate_completed';

class RatingGateScreen extends ConsumerStatefulWidget {
  const RatingGateScreen({
    required this.onNext,
    required this.onBack,
    this.requestReviewOverride,
    super.key,
  });

  /// Matches the callback shape used by every other onboarding screen
  /// (see `onboarding_screen.dart`). `OnboardingNotifier` does NOT expose
  /// `nextPage(controller:)` — only `setPage(int)` — so the parent's
  /// `_next` helper is what actually advances the PageView.
  final VoidCallback onNext;
  final VoidCallback onBack;

  /// Test seam — replace in widget tests to avoid platform-channel calls.
  /// In production this is null and the real `InAppReview.instance.requestReview()`
  /// runs. The function returns true if the review prompt was *attempted*;
  /// Apple does not surface whether the user actually rated.
  final Future<bool> Function()? requestReviewOverride;

  @override
  ConsumerState<RatingGateScreen> createState() => _RatingGateScreenState();
}

class _RatingGateScreenState extends ConsumerState<RatingGateScreen> {
  bool _rated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Re-hydrate persisted "rated" state in case the screen was torn down
      // while the iOS review overlay was up (background → resume rebuild).
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kRatingGateCompletedPrefsKey) == true && mounted) {
        setState(() => _rated = true);
      }

      if (!mounted) return;
      ref.read(analyticsProvider).track(AnalyticsEvents.ratingGateShown);
    });
  }

  Future<void> _onPrimary() async {
    final analytics = ref.read(analyticsProvider);
    final available = widget.requestReviewOverride != null ||
        await InAppReview.instance.isAvailable();
    // Track os_prompt_available so we can tell apart users who got the
    // system sheet vs. older iOS / Android-without-Play-Services who
    // silently fell through.
    analytics.track(
      AnalyticsEvents.ratingGatePromptTriggered,
      properties: {'os_prompt_available': available},
    );
    final fn = widget.requestReviewOverride ??
        () async {
          if (available) {
            await InAppReview.instance.requestReview();
            return true;
          }
          return false;
        };
    await fn();
    if (!mounted) return;
    setState(() => _rated = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRatingGateCompletedPrefsKey, true);
  }

  void _onContinue() {
    ref
        .read(analyticsProvider)
        .track(AnalyticsEvents.ratingGateContinueTapped);
    widget.onNext();
  }

  /// Personalized headline using the name the user entered on page 1 of
  /// onboarding (`signUpName`). Falls back to "Friend" so the screen never
  /// breaks for users who somehow reach the gate without a name set.
  String _buildHeadline() {
    final name = ref.read(onboardingProvider).signUpName?.trim();
    final greeting = (name == null || name.isEmpty) ? 'Friend' : name;
    return '$greeting, before you see your plan…';
  }

  /// Service-framed subhead. Sakina (سَكِينَة, tranquility) is brand-positioned
  /// against urgency — the frame is one Muslim leaving a sign on the road
  /// for the next. The intention the user picked on page 3 is woven in
  /// when present so the ask anchors to their own stated reason for being here.
  String _buildSubhead() {
    final intention = ref.read(onboardingProvider).intention;
    if (intention != null && intention.isNotEmpty) {
      return 'You came to Sakina for ${intention.toLowerCase()}. Would you '
          'leave a sign on the road for the next Muslim searching for the '
          'same? It helps Sakina reach more hearts, in shā\u02BCa Allāh.';
    }
    return 'Would you leave a sign on the road for the next Muslim searching '
        "for what you've just found? It helps Sakina reach more hearts, "
        'in shā\u02BCa Allāh.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            children: [
              const Spacer(),
              Text(
                _buildHeadline(),
                style: AppTypography.displaySmall.copyWith(
                  color: AppColors.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: AppSpacing.lg),
              Text(
                _buildSubhead(),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _rated ? _onContinue : _onPrimary,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.buttonRadius),
                    ),
                  ),
                  child: Text(
                    _rated ? 'I rated' : 'Leave a rating',
                    style: AppTypography.labelLarge,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
