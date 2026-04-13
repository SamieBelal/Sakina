import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/onboarding_continue_button.dart';
import '../widgets/onboarding_page_wrapper.dart';

class FeatureJournalScreen extends StatefulWidget {
  const FeatureJournalScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  State<FeatureJournalScreen> createState() => _FeatureJournalScreenState();
}

class _FeatureJournalScreenState extends State<FeatureJournalScreen> {
  int _activeIndex = 0;
  Timer? _timer;

  static const _entries = [
    _JournalEntryData(
      icon: Icons.auto_awesome,
      iconColor: AppColors.primary,
      iconBg: AppColors.primaryLight,
      badge: AppStrings.featureJournalItem1Title,
      badgeColor: AppColors.primary,
      badgeBg: AppColors.primaryLight,
      preview: AppStrings.featureJournalItem1Preview,
      accentType: _AccentType.nameBadge,
    ),
    _JournalEntryData(
      icon: Icons.mosque_outlined,
      iconColor: AppColors.secondary,
      iconBg: AppColors.secondaryLight,
      badge: AppStrings.featureJournalItem2Title,
      badgeColor: AppColors.secondary,
      badgeBg: AppColors.secondaryLight,
      preview: AppStrings.featureJournalItem2Preview,
      accentType: _AccentType.arabicSnippet,
    ),
    _JournalEntryData(
      icon: Icons.star_rounded,
      iconColor: AppColors.streakAmber,
      iconBg: AppColors.streakBackground,
      badge: AppStrings.featureJournalItem3Title,
      badgeColor: AppColors.streakAmber,
      badgeBg: AppColors.streakBackground,
      preview: AppStrings.featureJournalItem3Preview,
      accentType: _AccentType.tierDots,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (mounted) {
        setState(() => _activeIndex = (_activeIndex + 1) % _entries.length);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingPageWrapper(
      progressSegment: 5,
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Center(child: _buildJournalBrowser()),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.lg),
                Text(
                  AppStrings.featureJournalHeadline,
                  style: AppTypography.displaySmall.copyWith(
                    color: AppColors.textPrimaryLight,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 200.ms)
                    .slideY(begin: 0.05, end: 0, duration: 500.ms, delay: 200.ms),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppStrings.featureJournalSubtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 350.ms),
                const Spacer(),
                OnboardingContinueButton(
                  label: AppStrings.continueButton,
                  onPressed: widget.onNext,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalBrowser() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // All 3 cards stacked, active one highlighted
        for (var i = 0; i < _entries.length; i++) ...[
          _buildCard(_entries[i], i),
          if (i < _entries.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.md),
        // Page indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_entries.length, (i) {
            final active = i == _activeIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: active ? 18 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.borderLight,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCard(_JournalEntryData entry, int index) {
    final isActive = index == _activeIndex;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isActive ? AppColors.surfaceLight : AppColors.surfaceLight.withAlpha(180),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: isActive ? entry.badgeColor.withAlpha(80) : AppColors.borderLight,
          width: isActive ? 1.5 : 0.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: entry.badgeColor.withAlpha(20),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 350),
        opacity: isActive ? 1.0 : 0.45,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: entry.iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(entry.icon, size: 20, color: entry.iconColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: entry.badgeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          entry.badge,
                          style: AppTypography.labelSmall.copyWith(
                            color: entry.badgeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _buildAccent(entry),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    entry.preview,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: (200 + index * 100).ms)
        .slideY(begin: 0.08, end: 0, duration: 500.ms, delay: (200 + index * 100).ms);
  }

  Widget _buildAccent(_JournalEntryData entry) {
    switch (entry.accentType) {
      case _AccentType.nameBadge:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Al-Qawī',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'ٱلْقَوِيّ',
              style: AppTypography.arabicClassical.copyWith(
                fontSize: 13,
                color: AppColors.primary,
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        );
      case _AccentType.arabicSnippet:
        return Text(
          'يَا صَبُور',
          style: AppTypography.arabicClassical.copyWith(
            fontSize: 14,
            color: AppColors.secondary,
          ),
          textDirection: TextDirection.rtl,
        );
      case _AccentType.tierDots:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final active = i <= 2;
            return Padding(
              padding: EdgeInsets.only(right: i < 2 ? 3 : 0),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.streakAmber
                      : AppColors.streakAmber.withAlpha(40),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

enum _AccentType { nameBadge, arabicSnippet, tierDots }

class _JournalEntryData {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String badge;
  final Color badgeColor;
  final Color badgeBg;
  final String preview;
  final _AccentType accentType;

  const _JournalEntryData({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.badge,
    required this.badgeColor,
    required this.badgeBg,
    required this.preview,
    required this.accentType,
  });
}
