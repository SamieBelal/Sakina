import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/constants/discovery_quiz.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/discovery/providers/discovery_quiz_provider.dart';
import 'package:sakina/widgets/sakina_loader.dart';

class DiscoveryQuizScreen extends ConsumerWidget {
  const DiscoveryQuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(discoveryQuizProvider);
    final notifier = ref.read(discoveryQuizProvider.notifier);
    final questions = notifier.questions;
    final questionCount = notifier.questionCount;

    if (!state.initialized) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: SafeArea(child: SakinaLoader.fullScreen()),
      );
    }

    if (!state.completed && !state.quizStarted && questions.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.ensureQuizReady();
      });
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: state.completed
            ? _ResultsScreen(results: state.results ?? const [])
            : _QuestionScreen(
                currentQuestion: state.currentQuestion,
                selectedAnswers: state.selectedAnswers,
                questions: questions,
                questionCount: questionCount,
                onBack: notifier.goBack,
                onSelectAnswer: (optionIndex) {
                  HapticFeedback.lightImpact();
                  notifier.answerQuestion(optionIndex);
                },
              ),
      ),
    );
  }
}

class _QuestionScreen extends StatelessWidget {
  const _QuestionScreen({
    required this.currentQuestion,
    required this.selectedAnswers,
    required this.questions,
    required this.questionCount,
    required this.onBack,
    required this.onSelectAnswer,
  });

  final int currentQuestion;
  final List<int?> selectedAnswers;
  final List<QuizQuestion> questions;
  final int questionCount;
  final VoidCallback onBack;
  final ValueChanged<int> onSelectAnswer;

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.pagePadding),
          child: Text(
            'Quiz content is unavailable right now. Please try again in a moment.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final boundedIndex = currentQuestion.clamp(0, questions.length - 1);
    final question = questions[boundedIndex];

    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
          child: Row(
            children: [
              if (boundedIndex > 0)
                GestureDetector(
                  onTap: onBack,
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
        _ProgressBar(
          currentQuestion: boundedIndex,
          questionCount: questionCount,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Question ${boundedIndex + 1} of $questionCount',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondaryLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
            child: Column(
              children: [
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
                    .animate(key: ValueKey('q_$boundedIndex'))
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: 0.05, end: 0, duration: 300.ms),
                const SizedBox(height: 20),
                ...List.generate(question.options.length, (index) {
                  final option = question.options[index];
                  final isSelected = selectedAnswers.length > boundedIndex &&
                      selectedAnswers[boundedIndex] == index;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => onSelectAnswer(index),
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
                      .animate(key: ValueKey('q${boundedIndex}_opt$index'))
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
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.currentQuestion,
    required this.questionCount,
  });

  final int currentQuestion;
  final int questionCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Row(
        children: List.generate(questionCount, (index) {
          final isFilled = index <= currentQuestion;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < questionCount - 1 ? 6 : 0),
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
}

class _ResultsScreen extends StatelessWidget {
  const _ResultsScreen({required this.results});

  final List<AnchorResult> results;

  @override
  Widget build(BuildContext context) {
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
          ...List.generate(results.length, (index) {
            final anchor = results[index];
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
                    Text(
                      anchor.name,
                      style: AppTypography.headlineLarge.copyWith(
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                    Text(
                      anchor.anchor,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
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
