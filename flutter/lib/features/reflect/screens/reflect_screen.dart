import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sakina/core/utils/keyboard.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/achievement_checker.dart';
import 'package:sakina/widgets/reflect_loading.dart';
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
  bool _achievementChecked = false;
  bool _hasFocus = false;
  double _scaleValue = 5;

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

    // Check achievements when reflection result appears
    if (state.screenState == ReflectScreenState.result &&
        !_achievementChecked) {
      _achievementChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        checkAchievements(ref);
        // Mark First Steps "Reflect on a Feeling" beginner quest.
        ref.read(questsProvider.notifier).onReflectCompleted();
        // Flush queued quest notifications now that the flow is complete.
        flushQuestNotifications(ref);
      });
    }

    // Manage ripple animation based on state
    if (state.screenState == ReflectScreenState.loading) {
      _startRippleAnimation();
    } else {
      _stopRippleAnimation();
    }

    return GestureDetector(
      onTap: () => dismissKeyboard(context),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: _buildBody(state, notifier),
      ),
    );
  }

  Widget _buildBody(ReflectState state, ReflectNotifier notifier) {
    final Widget child;
    switch (state.screenState) {
      case ReflectScreenState.input:
        child = _buildInputState(state, notifier);
      case ReflectScreenState.loading:
        child = _buildLoadingState();
      case ReflectScreenState.followup:
        child = _buildFollowUpState(state, notifier);
      case ReflectScreenState.result:
        child = _buildResultState(state, notifier);
      case ReflectScreenState.offtopic:
        child = _buildOffTopicState(notifier);
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: KeyedSubtree(
        key: ValueKey(state.screenState),
        child: child,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INPUT
  // ---------------------------------------------------------------------------
  Widget _buildInputState(ReflectState state, ReflectNotifier notifier) {
    final enabled = state.userText.isNotEmpty;
    const emotions = [
      'Anxious',
      'Sad',
      'Grateful',
      'Frustrated',
      'Lost',
      'Hopeful',
      'Lonely',
      'Overwhelmed',
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, 32,
            AppSpacing.pagePadding, AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title — staggered entrance
            Text(
              'Reflect',
              style: AppTypography.displayLarge.copyWith(
                color: AppColors.textPrimaryLight,
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.05, end: 0, duration: 500.ms),
            const SizedBox(height: 8),
            // Subtitle — delayed entrance
            Text(
              'Share what is on your heart. This space is yours.',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: SvgPicture.asset(
                'assets/illustrations/onboarding_checkin.svg',
                height:
                    (MediaQuery.sizeOf(context).height * 0.16).clamp(100, 150),
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 300.ms)
                .slideY(begin: 0.05, end: 0, duration: 600.ms, delay: 300.ms),
            const SizedBox(height: AppSpacing.lg),
            // Text field with focus feedback
            Focus(
              onFocusChange: (focused) => setState(() => _hasFocus = focused),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                  color: _hasFocus
                      ? AppColors.primaryLight
                      : AppColors.surfaceLight,
                  border: Border.all(
                    color: _hasFocus ? AppColors.primary : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _textController,
                  minLines: 6,
                  maxLines: 8,
                  onChanged: (value) => notifier.setUserText(value),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.transparent,
                    hintText: 'What are you carrying today...',
                    hintStyle: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textTertiaryLight),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.inputRadius),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.inputRadius),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.inputRadius),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 400.ms)
                .slideY(begin: 0.02, end: 0, duration: 400.ms, delay: 400.ms),
            const SizedBox(height: 16),
            // Emotion chips — staggered wave entrance
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(emotions.length, (i) {
                return _buildEmotionChip(emotions[i], state, notifier)
                    .animate()
                    .fadeIn(duration: 300.ms, delay: (600 + i * 60).ms);
              }),
            ),
            const SizedBox(height: 24),
            // Submit button — AnimatedOpacity + shadow
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: enabled ? 1.0 : 0.5,
              child: GestureDetector(
                onTap: enabled
                    ? () {
                        HapticFeedback.mediumImpact();
                        notifier.submit();
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: enabled
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    'Reflect',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 700.ms),
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
                  style:
                      AppTypography.bodyMedium.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionChip(
      String emotion, ReflectState state, ReflectNotifier notifier) {
    final isSelected = state.selectedEmotions.contains(emotion);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        notifier.toggleEmotion(emotion);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primaryLight : AppColors.surfaceAltLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          emotion,
          style: AppTypography.bodyMedium.copyWith(
            color:
                isSelected ? AppColors.primary : AppColors.textSecondaryLight,
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
    return const ReflectLoading();
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
              const SizedBox(height: 24),
              _buildSparkleRow(),
              const SizedBox(height: 24),
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
                      const SizedBox(height: 8),
                      // Current value display
                      Text(
                        _scaleValue.round().toString(),
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Slider
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: AppColors.borderLight,
                          thumbColor: AppColors.primary,
                          overlayColor:
                              AppColors.primary.withValues(alpha: 0.12),
                          trackHeight: 6,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 14),
                        ),
                        child: Slider(
                          value: _scaleValue,
                          min: 1,
                          max: 10,
                          divisions: 9,
                          onChanged: (v) => setState(() => _scaleValue = v),
                        ),
                      ),
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
                      const SizedBox(height: 20),
                      // Confirm button
                      SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            notifier
                                .answerFollowUp(_scaleValue.round().toString());
                            _scaleValue = 5; // reset for next scale question
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Continue',
                              textAlign: TextAlign.center,
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              )
                  .animate(key: ValueKey(currentIndex))
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.03, end: 0, duration: 300.ms),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // RESULT
  // ---------------------------------------------------------------------------

  Widget _buildSparkleRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          Icons.auto_awesome,
          color: AppColors.secondary.withValues(alpha: i == 2 ? 1.0 : 0.6),
          size: i == 2 ? 20 : 14,
        )
            .animate()
            .scale(
              begin: const Offset(0, 0),
              end: const Offset(1, 1),
              curve: Curves.elasticOut,
              duration: 600.ms,
              delay: (i * 80).ms,
            )
            .fadeIn(duration: 400.ms, delay: (i * 80).ms);
      }),
    );
  }

  Widget _buildResultState(ReflectState state, ReflectNotifier notifier) {
    final result = state.result;
    if (result == null) return const SizedBox.shrink();

    final Widget stepWidget;
    switch (state.currentStep) {
      case ReflectStep.name:
        stepWidget = _buildNameStep(state, notifier);
      case ReflectStep.reflection:
        stepWidget = _buildReflectionStep(state, notifier);
      case ReflectStep.story:
        stepWidget = _buildStoryStep(state, notifier);
      case ReflectStep.dua:
        stepWidget = _buildDuaStep(state, notifier);
    }

    final showBack = state.currentStep != ReflectStep.name;

    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: KeyedSubtree(
            key: ValueKey(state.currentStep),
            child: stepWidget,
          ),
        ),
        if (showBack)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                notifier.previousStep();
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceLight,
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 400.ms),
          ),
      ],
    );
  }

  Widget _buildNameStep(ReflectState state, ReflectNotifier notifier) {
    final result = state.result!;
    // Celebration haptic when Name is revealed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HapticFeedback.mediumImpact();
    });
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSparkleRow(),
                    const SizedBox(height: 16),
                    // Background glow behind card
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulsing glow
                        Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.secondary.withValues(alpha: 0.15),
                                AppColors.secondary.withValues(alpha: 0.05),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scaleXY(begin: 0.9, end: 1.1, duration: 2000.ms),
                        // Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.cardRadius),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 24,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'A Name for your heart',
                                style: AppTypography.labelMedium.copyWith(
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 400.ms, delay: 200.ms),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 80,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    result.nameArabic,
                                    style: AppTypography.nameOfAllahDisplay
                                        .copyWith(
                                      color: Colors.white,
                                    ),
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ).animate().fadeIn(duration: 800.ms).scaleXY(
                                  begin: 0.85,
                                  end: 1.0,
                                  duration: 800.ms,
                                  curve: Curves.easeOutBack),
                              const SizedBox(height: 12),
                              Text(
                                result.name,
                                style: AppTypography.headlineLarge.copyWith(
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              )
                                  .animate()
                                  .fadeIn(duration: 500.ms, delay: 300.ms)
                                  .slideY(
                                      begin: 0.1,
                                      end: 0,
                                      duration: 500.ms,
                                      delay: 300.ms),
                              if (result.relatedNames.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                Text(
                                  'Related Names of Allah:',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                )
                                    .animate()
                                    .fadeIn(duration: 400.ms, delay: 500.ms),
                                const SizedBox(height: 8),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: result.relatedNames
                                      .asMap()
                                      .entries
                                      .map(
                                        (entry) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '${entry.value.name} · ${entry.value.nameArabic}',
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ).animate().fadeIn(
                                            duration: 300.ms,
                                            delay: (600 + entry.key * 100).ms),
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
                                    HapticFeedback.mediumImpact();
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
                              )
                                  .animate()
                                  .fadeIn(duration: 400.ms, delay: 700.ms),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.05, end: 0, duration: 600.ms),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReflectionStep(ReflectState state, ReflectNotifier notifier) {
    final result = state.result!;
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSparkleRow(),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.cardRadius),
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
                          Row(
                            children: [
                              // Gold accent line
                              Container(
                                width: 3,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ).animate().scaleY(
                                  begin: 0,
                                  end: 1,
                                  duration: 300.ms,
                                  delay: 200.ms,
                                  curve: Curves.easeOut),
                              const SizedBox(width: 8),
                              Text(
                                'Reflection',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.primary,
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 400.ms, delay: 200.ms),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            result.reframe,
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textPrimaryLight,
                              height: 1.6,
                            ),
                          ).animate().fadeIn(duration: 600.ms, delay: 300.ms),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
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
                          ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
                        ],
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.05, end: 0, duration: 600.ms),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryStep(ReflectState state, ReflectNotifier notifier) {
    final result = state.result!;
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSparkleRow(),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.cardRadius),
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
                          Row(
                            children: [
                              Container(
                                width: 3,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ).animate().scaleY(
                                  begin: 0,
                                  end: 1,
                                  duration: 300.ms,
                                  delay: 200.ms,
                                  curve: Curves.easeOut),
                              const SizedBox(width: 8),
                              Text(
                                'A Prophetic Story',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.primary,
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 400.ms, delay: 200.ms),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            result.story,
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textPrimaryLight,
                              height: 1.6,
                            ),
                          ).animate().fadeIn(duration: 600.ms, delay: 300.ms),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
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
                          ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
                        ],
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.05, end: 0, duration: 600.ms),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuaStep(ReflectState state, ReflectNotifier notifier) {
    final result = state.result!;
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Floating gold particles behind the card
                    ...List.generate(6, (i) {
                      final offsets = [
                        const Offset(-0.3, 0.4),
                        const Offset(0.3, 0.5),
                        const Offset(-0.15, 0.3),
                        const Offset(0.2, 0.6),
                        const Offset(-0.4, 0.5),
                        const Offset(0.35, 0.35),
                      ];
                      final sizes = [5.0, 7.0, 4.0, 6.0, 5.0, 8.0];
                      return Positioned(
                        left: MediaQuery.of(context).size.width *
                                (0.5 + offsets[i].dx) -
                            sizes[i] / 2,
                        top: MediaQuery.of(context).size.height * offsets[i].dy,
                        child: Container(
                          width: sizes[i],
                          height: sizes[i],
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.secondary.withValues(alpha: 0.6),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: (i * 100).ms)
                            .slideY(
                                begin: 0,
                                end: -2.0,
                                duration: 2500.ms,
                                delay: (i * 100).ms)
                            .fadeOut(
                                duration: 800.ms, delay: (1500 + i * 100).ms),
                      );
                    }),
                    // Main content
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSparkleRow(),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.cardRadius),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.secondary.withValues(alpha: 0.12),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (result.verses.isNotEmpty) ...[
                                Row(
                                  children: [
                                    Container(
                                      width: 3,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ).animate().scaleY(
                                        begin: 0,
                                        end: 1,
                                        duration: 300.ms,
                                        delay: 200.ms,
                                        curve: Curves.easeOut),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Verse',
                                      style: AppTypography.labelMedium.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ).animate().fadeIn(
                                        duration: 400.ms, delay: 200.ms),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ...List.generate(result.verses.length, (index) {
                                  final verse = result.verses[index];
                                  return Padding(
                                    padding: EdgeInsets.only(
                                        bottom:
                                            index == result.verses.length - 1
                                                ? 0
                                                : 20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: double.infinity,
                                          child: Text(
                                            verse.arabic,
                                            style: AppTypography.quranArabic
                                                .copyWith(
                                              fontSize: 24,
                                            ),
                                            textDirection: TextDirection.rtl,
                                            textAlign: TextAlign.center,
                                          ),
                                        )
                                            .animate()
                                            .fadeIn(
                                                duration: 800.ms,
                                                delay: (200 + index * 80).ms)
                                            .scaleXY(
                                                begin: 0.92,
                                                end: 1.0,
                                                duration: 800.ms,
                                                delay: (200 + index * 80).ms,
                                                curve: Curves.easeOutBack),
                                        const SizedBox(height: 12),
                                        Text(
                                          verse.translation,
                                          style:
                                              AppTypography.bodyLarge.copyWith(
                                            color: AppColors.textPrimaryLight,
                                            height: 1.6,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          textAlign: TextAlign.center,
                                        ).animate().fadeIn(
                                            duration: 500.ms,
                                            delay: (320 + index * 80).ms),
                                        const SizedBox(height: 8),
                                        Center(
                                          child: Text(
                                            verse.reference,
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                              color:
                                                  AppColors.textTertiaryLight,
                                            ),
                                          ),
                                        ).animate().fadeIn(
                                            duration: 400.ms,
                                            delay: (420 + index * 80).ms),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 20),
                                const Divider(color: AppColors.dividerLight),
                                const SizedBox(height: 20),
                              ],
                              Row(
                                children: [
                                  Container(
                                    width: 3,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ).animate().scaleY(
                                      begin: 0,
                                      end: 1,
                                      duration: 300.ms,
                                      delay: 200.ms,
                                      curve: Curves.easeOut),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Dua',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  )
                                      .animate()
                                      .fadeIn(duration: 400.ms, delay: 200.ms),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Arabic dua — scale in with easeOutBack
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  result.duaArabic,
                                  style: AppTypography.quranArabic,
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.center,
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 800.ms, delay: 200.ms)
                                  .scaleXY(
                                      begin: 0.9,
                                      end: 1.0,
                                      duration: 800.ms,
                                      delay: 200.ms,
                                      curve: Curves.easeOutBack),
                              const SizedBox(height: 16),
                              const Divider(color: AppColors.dividerLight),
                              const SizedBox(height: 16),
                              Text(
                                result.duaTransliteration,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.textSecondaryLight,
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 500.ms, delay: 400.ms),
                              const SizedBox(height: 12),
                              Text(
                                result.duaTranslation,
                                style: AppTypography.bodyLarge.copyWith(
                                  color: AppColors.textPrimaryLight,
                                  height: 1.6,
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 500.ms, delay: 500.ms),
                              const SizedBox(height: 12),
                              Text(
                                result.duaSource,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textTertiaryLight,
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 400.ms, delay: 600.ms),
                              const SizedBox(height: 24),
                              // Share button
                              Builder(
                                  builder: (btnContext) => IconButton(
                                        onPressed: () async {
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          HapticFeedback.mediumImpact();
                                          final box = btnContext
                                              .findRenderObject() as RenderBox;
                                          final origin =
                                              box.localToGlobal(Offset.zero) &
                                                  box.size;
                                          try {
                                            await shareReflectionCard(
                                              context: context,
                                              nameArabic: result.nameArabic,
                                              nameEnglish: result.name,
                                              verses: result.verses,
                                              duaArabic: result.duaArabic,
                                              duaTransliteration:
                                                  result.duaTransliteration,
                                              duaTranslation:
                                                  result.duaTranslation,
                                              duaSource: result.duaSource,
                                              reframe: result.reframe,
                                              story: result.story,
                                              sharePositionOrigin: origin,
                                            );
                                          } catch (e) {
                                            debugPrint('[SHARE ERROR] $e');
                                            messenger.showSnackBar(
                                              SnackBar(
                                                  content:
                                                      Text('Share failed: $e')),
                                            );
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.share_outlined,
                                          color: AppColors.primary,
                                        ),
                                      )).animate().fadeIn(
                                  duration: 300.ms, delay: 700.ms),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Celebratory CTA — Reflect Again
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            notifier.reset();
                          },
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.favorite_rounded,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Reflect Again',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 800.ms)
                            .slideY(
                                begin: 0.1,
                                end: 0,
                                duration: 500.ms,
                                delay: 800.ms),
                        const SizedBox(height: 12),
                        // Inspirational line
                        Text(
                          'Every reflection brings you closer to Allah',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.secondary,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(duration: 400.ms, delay: 1000.ms),
                      ],
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.05, end: 0, duration: 600.ms),
              ),
            ),
          ),
        ],
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
            SvgPicture.asset(
              'assets/illustrations/main_screens/reflect_offtopic.svg',
              height: 160,
            ),
            const SizedBox(height: 32),
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
