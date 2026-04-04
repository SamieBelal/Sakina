import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/core/constants/allah_names.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  bool _showDiscoveryQuiz = true;

  @override
  void initState() {
    super.initState();
    _checkDiscoveryQuiz();
  }

  Future<void> _checkDiscoveryQuiz() async {
    final prefs = await SharedPreferences.getInstance();
    final anchorNames = prefs.getStringList('anchor_names');
    if (mounted && anchorNames != null && anchorNames.isNotEmpty) {
      setState(() => _showDiscoveryQuiz = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dailyLoopProvider);
    final notifier = ref.read(dailyLoopProvider.notifier);
    final todaysName = getTodaysName();

    if (!state.loaded) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Bar
              _buildTopBar(state),
              const SizedBox(height: AppSpacing.lg),

              // 2. Streak + XP Strip
              _buildStreakXpStrip(state),
              const SizedBox(height: AppSpacing.lg),

              // 3. Daily Practice Card (Hero)
              _buildDailyPracticeCard(state, notifier),
              const SizedBox(height: AppSpacing.lg),

              // 4. Today's Name of Allah
              _buildTodaysNameCard(todaysName),
              const SizedBox(height: AppSpacing.lg),

              // 5. Discovery Quiz CTA
              if (_showDiscoveryQuiz) ...[
                _buildDiscoveryQuizCta(),
                const SizedBox(height: AppSpacing.lg),
              ],

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. Top Bar
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTopBar(DailyLoopState state) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${state.greeting}, ready to reflect?',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/settings');
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceAltLight,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Icon(
              Icons.settings_outlined,
              size: 20,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. Streak + XP Strip
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStreakXpStrip(DailyLoopState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department,
            color: AppColors.streakAmber,
            size: 22,
          ),
          const SizedBox(width: 6),
          Text(
            '${state.streakCount}',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'days',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const Spacer(),
          Text(
            state.levelTitle,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${state.xpTotal} XP',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. Daily Practice Card
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDailyPracticeCard(
    DailyLoopState state,
    DailyLoopNotifier notifier,
  ) {
    // Loading states
    if (state.checkinLoading || state.reflectLoading) {
      return _buildLoadingCard(state);
    }

    // Completed
    if (state.currentStep == DailyLoopStep.completed) {
      return _buildCompletedCard(state);
    }

    // Quest
    if (state.currentStep == DailyLoopStep.quest) {
      return _buildQuestCard(state, notifier);
    }

    // Deeper reflect in progress
    if (state.currentStep == DailyLoopStep.deeper &&
        state.reflectResult != null) {
      return _buildDeeperCard(state, notifier);
    }

    // Check-in done, deeper not started
    if (state.checkinDone && state.checkinName != null) {
      return _buildCheckinResultCard(state, notifier);
    }

    // Not started
    return _buildCheckinCard(state, notifier);
  }

  // ── Progress Ring ──────────────────────────────────────────────────────────

  Widget _buildProgressRing(int filled) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isFilled = i < filled;
        return Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? AppColors.primary : Colors.transparent,
            border: Border.all(
              color: isFilled ? AppColors.primary : AppColors.borderLight,
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }

  // ── Card Shell ─────────────────────────────────────────────────────────────

  Widget _cardShell({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // ── Not Started ────────────────────────────────────────────────────────────

  Widget _buildCheckinCard(DailyLoopState state, DailyLoopNotifier notifier) {
    final question = state.todaysQuestion;
    if (question == null) return const SizedBox.shrink();

    return _cardShell(
      child: Column(
        children: [
          _buildProgressRing(0),
          const SizedBox(height: AppSpacing.lg),
          // Arabic calligraphy — hero element
          Text(
            'محاسبة',
            style: AppTypography.nameOfAllahDisplay.copyWith(
              color: AppColors.secondary,
              fontSize: 40,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'MUḤĀSABAH',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textTertiaryLight,
              letterSpacing: 3,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Divider(color: AppColors.dividerLight, indent: 40, endIndent: 40),
          const SizedBox(height: AppSpacing.lg),
          Text(
            question.question,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ...question.options.map((option) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _buildOptionButton(option, notifier),
              )),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 100.ms)
        .slideY(begin: 0.08, end: 0);
  }

  Widget _buildOptionButton(String text, DailyLoopNotifier notifier) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        notifier.answerCheckin(text);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceAltLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Text(
          text,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimaryLight,
          ),
        ),
      ),
    );
  }

  // ── Loading ────────────────────────────────────────────────────────────────

  Widget _buildLoadingCard(DailyLoopState state) {
    final message = state.checkinLoading
        ? 'Finding the right Name...'
        : 'Preparing your reflection...';

    return _cardShell(
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildRippleRing(60, 0.ms),
                _buildRippleRing(45, 200.ms),
                _buildRippleRing(30, 400.ms),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildRippleRing(double size, Duration delay) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .scaleXY(begin: 0.8, end: 1.3, duration: 1500.ms, delay: delay)
        .fadeOut(duration: 1500.ms, delay: delay);
  }

  // ── Check-in Result ────────────────────────────────────────────────────────

  Widget _buildCheckinResultCard(
    DailyLoopState state,
    DailyLoopNotifier notifier,
  ) {
    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _buildProgressRing(1)),
          const SizedBox(height: AppSpacing.lg),

          // Name pill
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${state.checkinName} ${state.checkinNameArabic ?? ''}',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textOnPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Teaching
          if (state.checkinTeaching != null)
            Text(
              state.checkinTeaching!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          const SizedBox(height: AppSpacing.lg),

          // Dua section
          if (state.checkinDuaArabic != null) ...[
            Text(
              state.checkinDuaArabic!,
              style: AppTypography.quranArabic.copyWith(
                color: AppColors.secondary,
                fontSize: 22,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (state.checkinDuaTransliteration != null) ...[
            Text(
              state.checkinDuaTransliteration!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          if (state.checkinDuaTranslation != null)
            Text(
              state.checkinDuaTranslation!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          const SizedBox(height: AppSpacing.xl),

          // Go Deeper button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              notifier.startDeeper();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
              child: Text(
                'Go Deeper',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textOnPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Skip to Quest
          Center(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                notifier.skipToQuest();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Skip to Dua Quest',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05, end: 0);
  }

  // ── Deeper Reflect ─────────────────────────────────────────────────────────

  Widget _buildDeeperCard(DailyLoopState state, DailyLoopNotifier notifier) {
    final result = state.reflectResult!;
    final step = state.reflectStep;

    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _buildProgressRing(2)),
          const SizedBox(height: AppSpacing.lg),

          if (step == 0) _buildDeeperStepName(result, notifier),
          if (step == 1) _buildDeeperStepReflection(result, notifier),
          if (step == 2) _buildDeeperStepStory(result, notifier),
          if (step == 3) _buildDeeperStepDua(result, notifier),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildDeeperStepName(
    ReflectResponse result,
    DailyLoopNotifier notifier,
  ) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          child: Column(
            children: [
              Text(
                result.nameArabic,
                style: AppTypography.nameOfAllahDisplay.copyWith(
                  color: AppColors.primary,
                  fontSize: 40,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                result.name,
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildActionButton('See Reflection', () {
          HapticFeedback.lightImpact();
          notifier.advanceReflectStep();
        }),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildDeeperStepReflection(
    ReflectResponse result,
    DailyLoopNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          result.reframe,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondaryLight,
            height: 1.7,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _buildActionButton('Read the Story', () {
          HapticFeedback.lightImpact();
          notifier.advanceReflectStep();
        }),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildDeeperStepStory(
    ReflectResponse result,
    DailyLoopNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          result.story,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondaryLight,
            height: 1.7,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _buildActionButton('See the Dua', () {
          HapticFeedback.lightImpact();
          notifier.advanceReflectStep();
        }),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildDeeperStepDua(
    ReflectResponse result,
    DailyLoopNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          result.duaArabic,
          style: AppTypography.quranArabic.copyWith(
            color: AppColors.secondary,
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          result.duaTransliteration,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondaryLight,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          result.duaTranslation,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          result.duaSource,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textTertiaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _buildActionButton('Continue to Quest', () {
          HapticFeedback.lightImpact();
          notifier.advanceReflectStep();
        }),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  // ── Quest ──────────────────────────────────────────────────────────────────

  Widget _buildQuestCard(DailyLoopState state, DailyLoopNotifier notifier) {
    final dua = state.questDua;
    if (dua == null) return const SizedBox.shrink();

    final int filled = state.deeperDone ? 2 : 2;

    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _buildProgressRing(filled)),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text(
              'Your Dua Quest',
              style: AppTypography.headlineLarge.copyWith(
                color: AppColors.textPrimaryLight,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Quest dua card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceAltLight,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dua.arabic,
                  style: AppTypography.quranArabic.copyWith(
                    color: AppColors.secondary,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  dua.transliteration,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  dua.translation,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  dua.source,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Reason text
          if (dua.whenToRecite != null)
            Text(
              dua.whenToRecite!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          const SizedBox(height: AppSpacing.xl),

          // Ameen button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              notifier.completeQuest();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
              child: Text(
                'Ameen',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textOnPrimary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05, end: 0);
  }

  // ── Completed ──────────────────────────────────────────────────────────────

  Widget _buildCompletedCard(DailyLoopState state) {
    return _cardShell(
      child: Column(
        children: [
          _buildProgressRing(3),
          const SizedBox(height: AppSpacing.xl),

          // Checkmark circle
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            'Practice Complete',
            style: AppTypography.headlineLarge.copyWith(
              color: AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            "You've reflected, gone deeper, and completed your dua quest today.",
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Streak flame
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.local_fire_department,
                color: AppColors.streakAmber,
                size: 24,
              ),
              const SizedBox(width: 6),
              Text(
                '${state.streakCount} day streak',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // XP summary
          Text(
            '${state.xpTotal} XP earned',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            'Come back tomorrow',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 100.ms)
        .slideY(begin: 0.08, end: 0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. Today's Name of Allah
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTodaysNameCard(AllahName name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Today's Name",
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.secondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            name.arabic,
            style: AppTypography.nameOfAllahDisplay.copyWith(
              color: AppColors.secondary,
              fontSize: 40,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${name.transliteration} — ${name.english}',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            name.lesson,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 200.ms)
        .slideY(begin: 0.08, end: 0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. Discovery Quiz CTA
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDiscoveryQuizCta() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Discover your anchor Names',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.textPrimaryLight,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              GoRouter.of(context).push('/discovery-quiz');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
              child: Text(
                'Start Quiz',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textOnPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 300.ms);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Shared Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildActionButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        child: Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textOnPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
