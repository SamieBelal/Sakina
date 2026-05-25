import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_continue_button.dart';
import '../widgets/onboarding_page_wrapper.dart';

class EncouragementScreen extends ConsumerStatefulWidget {
  const EncouragementScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  static String _subtitleForFamiliarity(String? familiarity) {
    switch (familiarity) {
      case 'beginner':
        return AppStrings.encouragementSubtitleBeginner;
      case 'somewhat':
        return AppStrings.encouragementSubtitleSomewhat;
      case 'very_familiar':
        return AppStrings.encouragementSubtitleVeryFamiliar;
      default:
        return AppStrings.encouragementSubtitleDefault;
    }
  }

  @override
  ConsumerState<EncouragementScreen> createState() =>
      _EncouragementScreenState();
}

class _EncouragementScreenState extends ConsumerState<EncouragementScreen> {
  @override
  void initState() {
    super.initState();
    // Drain the one-shot recovery-snackbar flag (set by the 3 sign-up
    // paths when apply_referral returns ok:false reason:invalid|self_referral).
    // Deferred to a post-frame callback so the ScaffoldMessenger lookup hits
    // the wrapped Scaffold reliably. The cold-launch defensive retry in
    // app_session.dart does NOT write this flag, so users won't see a stale
    // snackbar days after onboarding.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reason =
          ref.read(onboardingProvider).referralApplyFailedReason;
      if (reason == null) return;
      ref
          .read(onboardingProvider.notifier)
          .clearReferralApplyFailedReason();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "We couldn't apply your friend's code. You can try again in Settings → Redeem a referral code.",
          ),
          duration: Duration(seconds: 5),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final name = state.signUpName ?? '';
    final headline = name.isNotEmpty
        ? 'Something beautiful awaits you, $name'
        : 'Something beautiful awaits you';
    final subtitle =
        EncouragementScreen._subtitleForFamiliarity(state.familiarity);

    return OnboardingPageWrapper(
      progressSegment: 23,
      onBack: widget.onBack,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
        children: [
          const Spacer(flex: 2),
          SvgPicture.asset(
            'assets/illustrations/onboarding_encouragement.svg',
            height: (MediaQuery.sizeOf(context).height * 0.24).clamp(140, 220),
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.0, 1.0),
                duration: 600.ms,
              ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            headline,
            style: AppTypography.displaySmall.copyWith(
              color: AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 200.ms)
              .slideY(begin: 0.05, end: 0, duration: 500.ms, delay: 200.ms),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              subtitle,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppStrings.encouragementPlanReadyTease,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.secondary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 500.ms, delay: 600.ms),
          const Spacer(flex: 3),
          OnboardingContinueButton(
            label: AppStrings.continueButton,
            onPressed: widget.onNext,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
