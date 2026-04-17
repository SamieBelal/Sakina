import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_question_scaffold.dart';

class StruggleSupportInterstitialScreen extends ConsumerWidget {
  const StruggleSupportInterstitialScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final struggles = ref.watch(onboardingProvider).struggles;
    final focus =
        struggles.isNotEmpty ? struggles.first : "what you're carrying";
    return OnboardingQuestionScaffold(
      progressSegment: 17,
      headline: "You're not alone in this.",
      subtitle: 'Many who started with $focus found peace here.',
      onBack: onBack,
      continueEnabled: true,
      onContinue: onNext,
      body: const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Icon(
          Icons.favorite,
          size: 96,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
