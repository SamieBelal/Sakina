import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/analytics_events.dart';
import '../../../services/analytics_provider.dart';
import '../../../widgets/adjusted_arabic_display.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_question_scaffold.dart';

/// Curated Name entry shown in the resonant-name carousel.
class _ResonantName {
  const _ResonantName({
    required this.id,
    required this.arabic,
    required this.translit,
    required this.english,
    required this.emotion,
  });
  final String id;
  final String arabic;
  final String translit;
  final String english;
  final String emotion;
}

// Curated list of broadly-resonant Names for v1. Id values match the
// `names_of_allah` table slug convention used elsewhere in the app.
const _names = <_ResonantName>[
  _ResonantName(
    id: 'ar-rahman',
    arabic: 'الرَّحْمَنُ',
    translit: 'Ar-Rahman',
    english: 'The Most Merciful',
    emotion: 'For when you need warmth.',
  ),
  _ResonantName(
    id: 'ar-rahim',
    arabic: 'الرَّحِيمُ',
    translit: 'Ar-Rahim',
    english: 'The Especially Merciful',
    emotion: 'For when you need closeness.',
  ),
  _ResonantName(
    id: 'as-salam',
    arabic: 'السَّلَامُ',
    translit: 'As-Salam',
    english: 'The Source of Peace',
    emotion: 'For when your mind is racing.',
  ),
  _ResonantName(
    id: 'al-wadud',
    arabic: 'الْوَدُودُ',
    translit: 'Al-Wadud',
    english: 'The Most Loving',
    emotion: 'For when you feel unseen.',
  ),
  _ResonantName(
    id: 'al-hafiz',
    arabic: 'الْحَفِيظُ',
    translit: 'Al-Hafiz',
    english: 'The Preserver',
    emotion: 'For when you feel afraid.',
  ),
  _ResonantName(
    id: 'al-karim',
    arabic: 'الْكَرِيمُ',
    translit: 'Al-Karim',
    english: 'The Most Generous',
    emotion: 'For when you feel small.',
  ),
];

class ResonantNameScreen extends ConsumerWidget {
  const ResonantNameScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    return OnboardingQuestionScaffold(
      progressSegment: 9,
      headline: 'Which Name of Allah resonates right now?',
      subtitle: 'This becomes the first Name in your collection.',
      onBack: onBack,
      continueEnabled: state.resonantNameId != null,
      onContinue: () {
        ref
            .read(analyticsProvider)
            .trackOnboardingAnswer('resonant_name_id', state.resonantNameId);
        onNext();
      },
      body: SizedBox(
        height: 340,
        child: PageView.builder(
          controller: PageController(viewportFraction: 0.85),
          itemCount: _names.length,
          itemBuilder: (context, index) {
            final n = _names[index];
            final selected = state.resonantNameId == n.id;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: GestureDetector(
                onTap: () => ref
                    .read(onboardingProvider.notifier)
                    .setResonantNameId(n.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.borderLight,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 33),
                      AdjustedArabicDisplay(
                        text: n.arabic,
                        style: AppTypography.nameOfAllahDisplay.copyWith(
                          color: AppColors.secondary,
                          fontSize: 36,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        n.translit,
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        n.english,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                      Text(
                        n.emotion,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondaryLight,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
