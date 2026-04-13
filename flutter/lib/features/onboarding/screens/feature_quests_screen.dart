import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/onboarding_continue_button.dart';
import '../widgets/onboarding_page_wrapper.dart';

enum _Phase { xpFilling, questComplete, achievement }

class FeatureQuestsScreen extends StatefulWidget {
  const FeatureQuestsScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  State<FeatureQuestsScreen> createState() => _FeatureQuestsScreenState();
}

class _FeatureQuestsScreenState extends State<FeatureQuestsScreen> {
  _Phase _phase = _Phase.xpFilling;
  Timer? _timer;

  static const _phaseDuration = Duration(milliseconds: 2400);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_phaseDuration, (_) {
      if (!mounted) return;
      setState(() {
        _phase = switch (_phase) {
          _Phase.xpFilling => _Phase.questComplete,
          _Phase.questComplete => _Phase.achievement,
          _Phase.achievement => _Phase.xpFilling,
        };
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _phaseIndex => _phase.index;

  @override
  Widget build(BuildContext context) {
    return OnboardingPageWrapper(
      progressSegment: 4,
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.06),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: switch (_phase) {
                      _Phase.xpFilling => const _XpFillingCard(key: ValueKey('xp')),
                      _Phase.questComplete => const _QuestCompleteCard(key: ValueKey('complete')),
                      _Phase.achievement => const _AchievementCard(key: ValueKey('achievement')),
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Phase dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final active = i == _phaseIndex;
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
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.lg),
                Text(
                  AppStrings.featureQuestsHeadlinePostLoop,
                  style: AppTypography.displaySmall.copyWith(
                    color: AppColors.textPrimaryLight,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 200.ms)
                    .slideY(begin: 0.05, end: 0, duration: 500.ms, delay: 200.ms),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppStrings.featureQuestsSubtitlePostLoop,
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
}

// ---------------------------------------------------------------------------
// Phase 1 — Rank / XP progression
// ---------------------------------------------------------------------------
class _XpFillingCard extends StatelessWidget {
  const _XpFillingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _PhaseCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Rank row: current → next
          Row(
            children: [
              // Current rank
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withAlpha(30),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        AppStrings.featureQuestsRankStartArabic,
                        style: AppTypography.arabicClassical.copyWith(
                          fontSize: 18,
                          color: AppColors.primary,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      AppStrings.featureQuestsRankStart,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              // Progress bar + XP badge
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    // Animated XP bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        children: [
                          Container(height: 6, color: AppColors.primaryLight),
                          LayoutBuilder(
                            builder: (context, constraints) => Container(
                              height: 6,
                              width: constraints.maxWidth * 0.35,
                              color: AppColors.primary,
                            )
                                .animate()
                                .custom(
                                  duration: 1400.ms,
                                  delay: 300.ms,
                                  curve: Curves.easeOut,
                                  builder: (context, value, child) =>
                                      Container(
                                    height: 6,
                                    width: constraints.maxWidth *
                                        (0.35 + value * 0.65),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // +XP badge pulses when bar finishes
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt,
                              size: 12, color: AppColors.streakAmber),
                          const SizedBox(width: 2),
                          Text(
                            '+50 XP',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .scaleXY(
                          begin: 0.7,
                          end: 1.0,
                          duration: 400.ms,
                          delay: 1700.ms,
                          curve: Curves.elasticOut,
                        )
                        .fadeIn(duration: 300.ms, delay: 1700.ms),
                  ],
                ),
              ),
              // Next rank
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryLight,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.secondary.withAlpha(40),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        AppStrings.featureQuestsRankEndArabic,
                        style: AppTypography.arabicClassical.copyWith(
                          fontSize: 18,
                          color: AppColors.secondary,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      AppStrings.featureQuestsRankEnd,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Streak + daily reward row
          Row(
            children: [
              // Streak counter
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.streakBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.streakAmber.withAlpha(60)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_fire_department_rounded,
                          size: 18, color: AppColors.streakAmber),
                      const SizedBox(width: 4),
                      Text(
                        '7 day streak',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.streakAmber,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Daily reward chip
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.secondary.withAlpha(60)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.card_giftcard_rounded,
                          size: 16, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Text(
                        'Day 7 reward',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Phase 2 — Quest complete
// ---------------------------------------------------------------------------
class _QuestCompleteCard extends StatelessWidget {
  const _QuestCompleteCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _PhaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Checkmark icon with pop animation
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    size: 22, color: AppColors.primary),
              )
                  .animate()
                  .scaleXY(
                    begin: 0.3,
                    end: 1.0,
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quest Complete!',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                    Text(
                      'Daily Check-in',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Sparkles burst
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.auto_awesome,
                    size: i == 2 ? 22 : 14,
                    color: AppColors.primary.withAlpha(i == 2 ? 255 : 153),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                        duration: 500.ms,
                        delay: (200 + i * 80).ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: 300.ms, delay: (200 + i * 80).ms),
                );
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Full progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 1.0,
              minHeight: 8,
              backgroundColor: AppColors.primaryLight,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Phase 3 — Achievement unlock
// ---------------------------------------------------------------------------
class _AchievementCard extends StatelessWidget {
  const _AchievementCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _PhaseCard(
      borderColor: AppColors.secondary.withAlpha(120),
      borderWidth: 1.5,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Achievement Unlocked',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.secondaryLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.secondary.withAlpha(80), width: 1.5),
            ),
            child: const Icon(Icons.emoji_events_rounded,
                size: 32, color: AppColors.secondary),
          )
              .animate()
              .scaleXY(
                begin: 0.2,
                end: 1.0,
                duration: 600.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 400.ms),
          const SizedBox(height: AppSpacing.md),
          Text(
            'First Steps Complete',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
          const SizedBox(height: 4),
          Text(
            'You\'ve completed your first quest journey',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
          const SizedBox(height: AppSpacing.md),
          // Gold sparkles
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Icon(
                  Icons.auto_awesome,
                  size: i == 2 ? 18 : 12,
                  color: AppColors.secondary.withAlpha(i == 2 ? 255 : 153),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                      delay: (300 + i * 80).ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 300.ms, delay: (300 + i * 80).ms),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared card shell
// ---------------------------------------------------------------------------
class _PhaseCard extends StatelessWidget {
  const _PhaseCard({
    required this.child,
    this.borderColor,
    this.borderWidth = 0.5,
  });

  final Widget child;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: borderColor ?? AppColors.borderLight,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
