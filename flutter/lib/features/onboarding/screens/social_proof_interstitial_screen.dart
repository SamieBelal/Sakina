import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/onboarding_question_scaffold.dart';

class SocialProofInterstitialScreen extends ConsumerWidget {
  const SocialProofInterstitialScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OnboardingQuestionScaffold(
      progressSegment: 15,
      headline: '40,000+ Muslims use Sakina.',
      subtitle: "You're not doing this alone.",
      onBack: onBack,
      continueEnabled: true,
      onContinue: onNext,
      body: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surfaceAltLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '"Sakina gave me a way back to my deen when I needed it most." '
          '— Aisha, 27',
          style: AppTypography.bodyLarge.copyWith(
            fontStyle: FontStyle.italic,
            color: AppColors.textPrimaryLight,
          ),
        ),
      ),
    );
  }
}
