import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/core/utils/keyboard.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/services/achievement_checker.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_flow.dart';
import 'package:sakina/features/paywall/upgrade_callback.dart';
import 'package:sakina/features/paywall/widgets/daily_cap_sheet.dart';
import 'package:sakina/features/paywall/widgets/warmup_exhausted_sheet.dart';
import 'package:sakina/services/daily_usage_service.dart' as daily_usage;
import 'package:sakina/services/gating_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/widgets/reflect_loading.dart';
import 'package:sakina/widgets/share_card.dart';
import 'package:sakina/widgets/upgrade_required_sheet.dart';

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

    // Surface freemium-gating sheets (daily-cap + warmup-exhausted) when the
    // gating layer blocks a submit or signals the warmup→0 transition.
    ref.listen<ReflectState>(reflectProvider, (prev, next) {
      // Clear text field when returning to input screen
      if (next.screenState == ReflectScreenState.input &&
          prev?.screenState != ReflectScreenState.input) {
        _textController.clear();
        _achievementChecked = false;
      }

      if (next.gateResult != null && prev?.gateResult == null) {
        // Snapshot bypass state at sheet-open time. Async — sheet renders
        // after these complete, which is fine: dailyCap is a paywall, not a
        // hot path. If a tap-then-quick-second-tap races the load, the
        // worst case is a stale balance shown for ~50ms.
        final sheetContext = context;
        () async {
          final balance = (await getTokens()).balance;
          final bypassesUsed = await daily_usage
              .getReflectBypassesUsedToday();
          final premium = await PurchaseService().isPremium();
          final firstBypassEligible =
              await GatingService().firstBypassEligible();
          final displayName = await GatingService().displayName();
          if (!sheetContext.mounted) return;
          DailyCapSheet.show(
            sheetContext,
            feature: GatedFeature.reflect,
            tokenBalance: balance,
            bypassesUsedToday: bypassesUsed,
            isPremium: premium,
            onBypassRequested: (_) => notifier.submitWithBypass(),
            firstBypassAvailable: firstBypassEligible,
            userDisplayName: displayName,
            onFirstBypassRequested: (_) => notifier.submitWithFirstBypass(),
            onUpgrade: buildPaywallUpgradeCallback(
              reason: next.gateResult!.reason,
              pushPaywall: () {
                if (mounted) GoRouter.of(context).push('/paywall');
              },
            ),
          ).whenComplete(notifier.dismissGate);
        }();
      }
      // One-shot warmup-exhaustion sheet — fires on the SUCCESSFUL reflect
      // that decremented warmup from 1 to 0, distinct from the recurring
      // daily-cap sheet above.
      if (next.warmupJustExhausted != null &&
          prev?.warmupJustExhausted == null) {
        WarmupExhaustedSheet.show(
          context,
          feature: next.warmupJustExhausted!,
          onUpgrade: () => GoRouter.of(context).push('/paywall'),
        ).whenComplete(notifier.dismissWarmupExhausted);
      }
      // Journal-limit upsell (decision 18A): NEVER surface it over the beat
      // canvas mid-ritual. `needsUpgrade` flips at response time (screenState =
      // result), so we defer the sheet until the user lands back on the input
      // screen after the flow — the natural pause.
      if (next.needsUpgrade &&
          next.screenState == ReflectScreenState.input &&
          prev?.screenState != ReflectScreenState.input) {
        UpgradeRequiredSheet.show(
          context,
          currentCount: next.savedReflections.length,
          featureLabel: 'reflection',
        ).then((_) => notifier.dismissUpgradePrompt());
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
      });
    }

    // Manage ripple animation based on state
    if (state.screenState == ReflectScreenState.loading) {
      _startRippleAnimation();
    } else {
      _stopRippleAnimation();
    }

    // The result and off-topic outcomes run full-screen on the emerald sacred
    // canvas via BeatRevealFlow (its own Scaffold + chrome). Input, loading, and
    // follow-up keep the existing light-theme screens.
    if (state.screenState == ReflectScreenState.result ||
        state.screenState == ReflectScreenState.offtopic) {
      return _buildReflectBeatFlow(state, notifier);
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

  Widget _buildReflectBeatFlow(ReflectState state, ReflectNotifier notifier) {
    final isOffTopic = state.screenState == ReflectScreenState.offtopic;
    return BeatRevealFlow(
      status: isOffTopic ? BeatFlowStatus.offtopic : BeatFlowStatus.ready,
      response: state.result,
      includeVerses: true, // Reflect surfaces catalog verses as their own beats
      onAmeen: () => notifier.reset(),
      onReturnHome: () => notifier.reset(),
      onOffTopicRetry: () => notifier.reset(),
      onRetry: () => notifier.reset(),
      onShare: () => _shareCurrentReflection(state),
      onBeatAdvanced: (index, kind) {
        ReflectNotifier.onAnalyticsEvent?.call(
          AnalyticsEvents.reflectBeatAdvanced,
          {
            AnalyticsEvents.propSurface: AnalyticsEvents.surfaceReflect,
            AnalyticsEvents.propBeatIndex: index,
            AnalyticsEvents.propBeatKind: kind.name,
          },
        );
      },
      onSkip: (from) {
        ReflectNotifier.onAnalyticsEvent?.call(
          AnalyticsEvents.reflectFlowSkipped,
          {
            AnalyticsEvents.propSurface: AnalyticsEvents.surfaceReflect,
            AnalyticsEvents.propFromBeatIndex: from,
          },
        );
      },
    );
  }

  Future<void> _shareCurrentReflection(ReflectState state) async {
    final result = state.result;
    if (result == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Reuses the existing capture/share-sheet pipeline. A dedicated emerald
      // takeaway-card composition (decision 20A) is a follow-up.
      await shareReflectionCard(
        context: context,
        nameArabic: result.nameArabic,
        nameEnglish: result.name,
        verses: result.verses,
        duaArabic: result.duaArabic,
        duaTransliteration: result.duaTransliteration,
        duaTranslation: result.duaTranslation,
        duaSource: result.duaSource,
        reframe: result.reframe,
        story: result.story,
      );
    } catch (e) {
      debugPrint('[SHARE ERROR] $e');
      showShareErrorSnackBar(messenger);
    }
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
      case ReflectScreenState.offtopic:
        // Handled full-screen in build() via _buildReflectBeatFlow; unreachable
        // here (build short-circuits these states before _buildBody).
        child = const SizedBox.shrink();
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
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                32,
                AppSpacing.pagePadding,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Editorial header
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
                  Text(
                    'Share what is on your heart. This space is yours.',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textSecondaryLight,
                      height: 1.5,
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
                  const SizedBox(height: AppSpacing.xl),

                  // Text field — warm white card with soft shadow
                  Focus(
                    onFocusChange: (focused) =>
                        setState(() => _hasFocus = focused),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.cardRadius),
                        color: AppColors.surfaceLight,
                        border: Border.all(
                          color: _hasFocus
                              ? AppColors.primary
                              : AppColors.borderLight,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                                alpha: _hasFocus ? 0.06 : 0.03),
                            blurRadius: _hasFocus ? 18 : 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _textController,
                        minLines: 5,
                        maxLines: 7,
                        onChanged: (value) => notifier.setUserText(value),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        onTapOutside: (_) =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textPrimaryLight,
                          height: 1.5,
                        ),
                        decoration: InputDecoration(
                          contentPadding:
                              const EdgeInsets.fromLTRB(18, 16, 18, 16),
                          filled: false,
                          hintText: 'What are you carrying today...',
                          hintStyle: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textTertiaryLight,
                            fontStyle: FontStyle.italic,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 350.ms)
                      .slideY(
                          begin: 0.02,
                          end: 0,
                          duration: 400.ms,
                          delay: 350.ms),
                  const SizedBox(height: AppSpacing.lg),

                  // "Or pick a feeling" hint
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 1,
                        color: AppColors.secondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'OR TAP A FEELING',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.secondary,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
                  const SizedBox(height: 12),

                  // Emotion chips — warm pills, staggered wave
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(emotions.length, (i) {
                      return _buildEmotionChip(emotions[i], state, notifier)
                          .animate()
                          .fadeIn(
                              duration: 300.ms, delay: (550 + i * 50).ms);
                    }),
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
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Sticky CTA with cream gradient fade above
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              12,
              AppSpacing.pagePadding,
              16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.backgroundLight.withValues(alpha: 0),
                  AppColors.backgroundLight,
                  AppColors.backgroundLight,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
            child: AnimatedOpacity(
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
                              color:
                                  AppColors.primary.withValues(alpha: 0.32),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Reflect',
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
        ],
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

}
