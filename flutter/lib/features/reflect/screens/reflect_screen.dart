import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/widgets/share_card.dart';
import 'package:sakina/widgets/token_gate_sheet.dart';

class ReflectScreen extends ConsumerStatefulWidget {
  const ReflectScreen({super.key});

  @override
  ConsumerState<ReflectScreen> createState() => _ReflectScreenState();
}

class _ReflectScreenState extends ConsumerState<ReflectScreen>
    with TickerProviderStateMixin {
  late final List<AnimationController> _rippleControllers;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rippleControllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600),
      );
    });
  }

  void _startRippleAnimation() {
    for (var i = 0; i < _rippleControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 530), () {
        if (mounted) {
          _rippleControllers[i].repeat();
        }
      });
    }
  }

  void _stopRippleAnimation() {
    for (final controller in _rippleControllers) {
      controller.stop();
      controller.reset();
    }
  }

  @override
  void dispose() {
    for (final controller in _rippleControllers) {
      controller.dispose();
    }
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reflectProvider);
    final notifier = ref.read(reflectProvider.notifier);

    // Show token gate sheet when the free limit is hit
    ref.listen<ReflectState>(reflectProvider, (prev, next) {
      if (next.needsToken && !(prev?.needsToken ?? false)) {
        showTokenGateSheet(
          context,
          featureName: 'Reflect',
          cost: tokenCostReflection,
        ).then((approved) {
          if (approved) notifier.submitWithToken();
        });
      }
    });

    // Manage ripple animation based on state
    if (state.screenState == ReflectScreenState.loading) {
      _startRippleAnimation();
    } else {
      _stopRippleAnimation();
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: _buildBody(state, notifier),
    );
  }

  Widget _buildBody(ReflectState state, ReflectNotifier notifier) {
    switch (state.screenState) {
      case ReflectScreenState.input:
        return _buildInputState(state, notifier);
      case ReflectScreenState.loading:
        return _buildLoadingState();
      case ReflectScreenState.followup:
        return _buildFollowUpState(state, notifier);
      case ReflectScreenState.result:
        return _buildResultState(state, notifier);
      case ReflectScreenState.offtopic:
        return _buildOffTopicState(notifier);
    }
  }

  // ---------------------------------------------------------------------------
  // INPUT
  // ---------------------------------------------------------------------------
  Widget _buildInputState(ReflectState state, ReflectNotifier notifier) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reflect',
              style: AppTypography.displayLarge.copyWith(
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share what is on your heart. This space is yours.',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _textController,
              maxLines: 5,
              minLines: 3,
              onChanged: (value) => notifier.setUserText(value),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceLight,
                hintText: 'What are you carrying today...',
                hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiaryLight),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Anxious',
                'Sad',
                'Grateful',
                'Frustrated',
                'Lost',
                'Hopeful',
                'Lonely',
                'Overwhelmed',
              ].map((emotion) => _buildEmotionChip(emotion, state, notifier)).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: state.userText.isEmpty
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        notifier.submit();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                ),
                child: const Text('Reflect'),
              ),
            ),
            if (state.error != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  state.error!,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionChip(String emotion, ReflectState state, ReflectNotifier notifier) {
    final isSelected = state.selectedEmotions.contains(emotion);
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        notifier.toggleEmotion(emotion);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surfaceAltLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          emotion,
          style: AppTypography.bodyMedium.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LOADING
  // ---------------------------------------------------------------------------
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _rippleControllers[index],
                  builder: (context, child) {
                    final value = _rippleControllers[index].value;
                    final scale = 0.3 + (2.2 - 0.3) * value;
                    final opacity = (0.6 - 0.6 * value).clamp(0.0, 1.0);
                    return Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Reflecting...',
            style: AppTypography.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Finding the right Name of Allah for your heart',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FOLLOW-UP
  // ---------------------------------------------------------------------------
  Widget _buildFollowUpState(ReflectState state, ReflectNotifier notifier) {
    final questions = state.followUpQuestions;
    final currentIndex = state.currentFollowUpIndex;
    if (questions.isEmpty) return const SizedBox.shrink();

    final question = questions[currentIndex];

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            children: [
              // Progress dots + skip
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...List.generate(questions.length, (i) {
                    return Container(
                      width: i == currentIndex ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: i <= currentIndex
                            ? AppColors.primary
                            : AppColors.borderLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      notifier.skipFollowUps();
                    },
                    child: Text(
                      'Skip',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              // Question card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      question.question,
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.textPrimaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    if (question.type == FollowUpQuestionType.choice)
                      ...(question.options ?? []).map(
                        (option) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              notifier.answerFollowUp(option);
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 20),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: AppColors.borderLight),
                              ),
                              child: Text(
                                option,
                                style: AppTypography.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (question.type == FollowUpQuestionType.scale) ...[
                      // Slider-style scale
                      _buildScaleRow(1, 5, notifier),
                      const SizedBox(height: 10),
                      _buildScaleRow(6, 10, notifier),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Not at all',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textTertiaryLight,
                              ),
                            ),
                            Text(
                              'Very much',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textTertiaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ).animate(key: ValueKey(currentIndex))
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.03, end: 0, duration: 300.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScaleRow(int start, int end, ReflectNotifier notifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(end - start + 1, (i) {
        final number = start + i;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                notifier.answerFollowUp(number.toString());
              },
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text(
                  number.toString(),
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // RESULT
  // ---------------------------------------------------------------------------
  Widget _buildResultState(ReflectState state, ReflectNotifier notifier) {
    final result = state.result;
    if (result == null) return const SizedBox.shrink();

    switch (state.currentStep) {
      case ReflectStep.name:
        return _buildNameStep(state, notifier);
      case ReflectStep.reflection:
        return _buildReflectionStep(state, notifier);
      case ReflectStep.story:
        return _buildStoryStep(state, notifier);
      case ReflectStep.dua:
        return _buildDuaStep(state, notifier);
    }
  }

  Widget _buildNameStep(ReflectState state, ReflectNotifier notifier) {
    final result = state.result!;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Column(
                  children: [
                    Text(
                      'A Name for your heart',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      result.nameArabic,
                      style: AppTypography.nameOfAllahDisplay.copyWith(
                        color: Colors.white,
                      ),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      result.name,
                      style: AppTypography.headlineLarge.copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (result.relatedNames.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Also makes dua for:',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: result.relatedNames
                            .map(
                              (related) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${related.name} · ${related.nameArabic}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          notifier.continueStep();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppSpacing.buttonRadius),
                          ),
                        ),
                        child: const Text('See Reflection'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.05, end: 0),
        ),
      ),
    );
  }

  Widget _buildReflectionStep(ReflectState state, ReflectNotifier notifier) {
    final result = state.result!;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reflection',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      result.reframe,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textPrimaryLight,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          notifier.continueStep();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppSpacing.buttonRadius),
                          ),
                        ),
                        child: const Text('Read the Story'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  notifier.reset();
                },
                child: Text(
                  'Start over',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.05, end: 0),
        ),
      ),
    );
  }

  Widget _buildStoryStep(ReflectState state, ReflectNotifier notifier) {
    final result = state.result!;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'A Prophetic Story',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      result.story,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textPrimaryLight,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          notifier.continueStep();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppSpacing.buttonRadius),
                          ),
                        ),
                        child: const Text('See the Dua'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  notifier.reset();
                },
                child: Text(
                  'Start over',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.05, end: 0),
        ),
      ),
    );
  }

  Widget _buildDuaStep(ReflectState state, ReflectNotifier notifier) {
    final result = state.result!;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dua',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        result.duaArabic,
                        style: AppTypography.quranArabic,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.dividerLight),
                    const SizedBox(height: 16),
                    Text(
                      result.duaTransliteration,
                      style: AppTypography.bodyMedium.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      result.duaTranslation,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textPrimaryLight,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      result.duaSource,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            HapticFeedback.lightImpact();
                            try {
                              await shareReflectionCard(
                                context: context,
                                nameArabic: result.nameArabic,
                                nameEnglish: result.name,
                                duaArabic: result.duaArabic,
                                duaTransliteration: result.duaTransliteration,
                                duaTranslation: result.duaTranslation,
                                duaSource: result.duaSource,
                                reframe: result.reframe,
                                story: result.story,
                              );
                            } catch (e) {
                              debugPrint('[SHARE ERROR] $e');
                              messenger.showSnackBar(
                                  SnackBar(content: Text('Share failed: $e')),
                                );
                            }
                          },
                          icon: const Icon(
                            Icons.share_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            notifier.reset();
                          },
                          child: const Text('New Reflection'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.05, end: 0),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // OFF-TOPIC
  // ---------------------------------------------------------------------------
  Widget _buildOffTopicState(ReflectNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '\u{1F932}',
              style: TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 24),
            Text(
              'This space is for your heart',
              style: AppTypography.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Share what you are feeling, struggling with, or grateful for. '
              'This is a space for emotional and spiritual reflection.',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  notifier.reset();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                ),
                child: const Text('Try again'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
