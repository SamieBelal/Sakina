import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/analytics_events.dart';
import '../../../services/analytics_provider.dart';
import '../../../widgets/adjusted_arabic_display.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_question_scaffold.dart';

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

class ResonantNameScreen extends ConsumerStatefulWidget {
  const ResonantNameScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  ConsumerState<ResonantNameScreen> createState() => _ResonantNameScreenState();
}

class _ResonantNameScreenState extends ConsumerState<ResonantNameScreen> {
  late final PageController _controller;
  int _lastHapticPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.82);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _pageValue() {
    if (_controller.hasClients && _controller.position.haveDimensions) {
      return _controller.page ?? 0;
    }
    return 0;
  }

  Widget _card(_ResonantName n, bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.borderLight,
          width: selected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: selected
                ? AppColors.secondary.withAlpha(60)
                : Colors.black.withAlpha(12),
            blurRadius: selected ? 24 : 10,
            offset: const Offset(0, 4),
          ),
        ],
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
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(
                begin: 0.78,
                duration: 2200.ms,
                curve: Curves.easeInOut,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    return OnboardingQuestionScaffold(
      progressSegment: 7,
      headline: 'Which Name of Allah resonates right now?',
      subtitle: 'This becomes the first Name in your collection.',
      onBack: widget.onBack,
      continueEnabled: state.resonantNameId != null,
      onContinue: () {
        ref
            .read(analyticsProvider)
            .trackOnboardingAnswer('resonant_name_id', state.resonantNameId);
        widget.onNext();
      },
      body: SizedBox(
        height: 360,
        child: PageView.builder(
          controller: _controller,
          itemCount: _names.length,
          onPageChanged: (i) {
            if (i != _lastHapticPage) {
              _lastHapticPage = i;
              HapticFeedback.selectionClick();
            }
            ref
                .read(onboardingProvider.notifier)
                .setResonantNameId(_names[i].id);
          },
          itemBuilder: (context, index) {
            final n = _names[index];
            final selected = state.resonantNameId == n.id;
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final page = _pageValue();
                final delta = (page - index).abs().clamp(0.0, 1.0);
                final scale = 1 - (delta * 0.1);
                final opacity = 1 - (delta * 0.45);
                return Transform.scale(
                  scale: scale,
                  child: Opacity(opacity: opacity, child: child),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref
                        .read(onboardingProvider.notifier)
                        .setResonantNameId(n.id);
                    _controller.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  child: _card(n, selected),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
