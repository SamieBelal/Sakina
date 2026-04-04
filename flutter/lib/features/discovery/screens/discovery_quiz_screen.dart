import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/constants/discovery_quiz.dart';
import 'package:sakina/core/theme/app_typography.dart';

class DiscoveryQuizScreen extends StatefulWidget {
  const DiscoveryQuizScreen({super.key});

  @override
  State<DiscoveryQuizScreen> createState() => _DiscoveryQuizScreenState();
}

class _DiscoveryQuizScreenState extends State<DiscoveryQuizScreen> {
  int currentQuestion = 0;
  final List<int?> selectedAnswers = List.filled(6, null);
  bool showResults = false;
  List<AnchorResult>? results;

  void _selectAnswer(int optionIndex) {
    HapticFeedback.lightImpact();
    setState(() {
      selectedAnswers[currentQuestion] = optionIndex;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (currentQuestion < 5) {
        setState(() {
          currentQuestion++;
        });
      } else {
        _showResultsScreen();
      }
    });
  }

  Future<void> _showResultsScreen() async {
    final answers = selectedAnswers.map((e) => e ?? 0).toList();
    final computed = calculateQuizResults(answers);

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final jsonList = computed
        .map((r) => {
              'nameKey': r.nameKey,
              'name': r.name,
              'arabic': r.arabic,
              'score': r.score,
              'anchor': r.anchor,
              'detail': r.detail,
            })
        .toList();
    await prefs.setString('anchor_names', jsonEncode(jsonList));

    if (!mounted) return;
    setState(() {
      results = computed;
      showResults = true;
    });
  }

  void _goBack() {
    if (currentQuestion > 0) {
      setState(() {
        currentQuestion--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: showResults ? _buildResultsScreen() : _buildQuestionScreen(),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Row(
        children: List.generate(6, (index) {
          final isFilled = index <= currentQuestion;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 5 ? 6 : 0),
              decoration: BoxDecoration(
                color: isFilled ? AppColors.primary : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ).animate(key: ValueKey('seg_${index}_$isFilled')).fadeIn(
                  duration: 200.ms,
                ),
          );
        }),
      ),
    );
  }

  Widget _buildQuestionScreen() {
    final question = discoveryQuizQuestions[currentQuestion];

    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        // Top bar with back button and progress
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
          child: Row(
            children: [
              if (currentQuestion > 0)
                GestureDetector(
                  onTap: _goBack,
                  child: const Icon(
                    Icons.arrow_back_ios,
                    size: 20,
                    color: AppColors.textSecondaryLight,
                  ),
                )
              else
                const SizedBox(width: 20),
              const Spacer(),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildProgressBar(),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Question ${currentQuestion + 1} of 6',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondaryLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        // Question + options
        Expanded(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
            child: Column(
              children: [
                // Question card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    question.prompt,
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.textPrimaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
                    .animate(key: ValueKey('q_$currentQuestion'))
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: 0.05, end: 0, duration: 300.ms),
                const SizedBox(height: 20),
                // Option cards
                ...List.generate(question.options.length, (index) {
                  final option = question.options[index];
                  final isSelected = selectedAnswers[currentQuestion] == index;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => _selectAnswer(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryLight
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.borderLight,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option.text,
                                style: AppTypography.bodyLarge.copyWith(
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    ),
                  )
                      .animate(key: ValueKey('q${currentQuestion}_opt$index'))
                      .fadeIn(duration: 300.ms, delay: (50 * index).ms)
                      .slideX(begin: 0.05, end: 0, duration: 300.ms);
                }),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsScreen() {
    final anchors = results ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Your Anchor Names',
            style: AppTypography.displayMedium.copyWith(
              color: AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 12),
          Text(
            'These are the Names of Allah that resonate most deeply with your soul',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          const SizedBox(height: 32),
          // Result cards
          ...List.generate(anchors.length, (index) {
            final anchor = anchors[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rank badge
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '#${index + 1}',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Name
                    Text(
                      anchor.name,
                      style: AppTypography.headlineLarge.copyWith(
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Arabic
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        anchor.arabic,
                        style: AppTypography.nameOfAllahDisplay.copyWith(
                          fontSize: 36,
                          color: AppColors.secondary,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Anchor sentence
                    Text(
                      anchor.anchor,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Detail text
                    Text(
                      anchor.detail,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: (200 * index).ms)
                .slideY(begin: 0.05, end: 0, duration: 400.ms);
          }),
          const SizedBox(height: 32),
          // Continue button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                ),
                elevation: 0,
              ),
              child: Text(
                'Continue',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textOnPrimary,
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
