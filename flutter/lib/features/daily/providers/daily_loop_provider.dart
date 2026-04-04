import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/constants/daily_questions.dart';
import 'package:sakina/core/constants/duas.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/daily_rewards_service.dart';
import 'package:sakina/services/streak_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/xp_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum DailyLoopStep { checkin, deeper, quest, completed }

class DailyLoopState {
  // Overall
  final bool loaded;
  final String greeting;

  // Step tracking
  final DailyLoopStep currentStep;
  final bool checkinDone;
  final bool deeperDone;
  final bool questDone;

  // Step 1: Check-in
  final DailyQuestion? todaysQuestion;
  final String? checkinAnswer;
  final String? checkinName;
  final String? checkinNameArabic;
  final String? checkinTeaching;
  final String? checkinDuaArabic;
  final String? checkinDuaTransliteration;
  final String? checkinDuaTranslation;
  final bool checkinLoading;

  // Step 2: Deeper reflect
  final ReflectResponse? reflectResult;
  final int reflectStep; // 0=name, 1=reflection, 2=story, 3=dua
  final bool reflectLoading;

  // Step 3: Quest
  final BrowseDua? questDua;
  final String? questReason;

  // Streak, XP & Tokens
  final int streakCount;
  final int xpTotal;
  final int tokenBalance;
  final String levelTitle;
  final String levelTitleArabic;

  // Card collection
  final CardEngageResult? cardEngageResult;
  final CollectibleName? engagedCard;

  // Daily reward
  final DailyRewardClaimResult? rewardClaimResult;

  // Error
  final String? error;

  const DailyLoopState({
    this.loaded = false,
    this.greeting = '',
    this.currentStep = DailyLoopStep.checkin,
    this.checkinDone = false,
    this.deeperDone = false,
    this.questDone = false,
    this.todaysQuestion,
    this.checkinAnswer,
    this.checkinName,
    this.checkinNameArabic,
    this.checkinTeaching,
    this.checkinDuaArabic,
    this.checkinDuaTransliteration,
    this.checkinDuaTranslation,
    this.checkinLoading = false,
    this.reflectResult,
    this.reflectStep = 0,
    this.reflectLoading = false,
    this.questDua,
    this.questReason,
    this.cardEngageResult,
    this.engagedCard,
    this.rewardClaimResult,
    this.streakCount = 0,
    this.xpTotal = 0,
    this.tokenBalance = 0,
    this.levelTitle = 'Seeker',
    this.levelTitleArabic = 'طَالِب',
    this.error,
  });

  DailyLoopState copyWith({
    bool? loaded,
    String? greeting,
    DailyLoopStep? currentStep,
    bool? checkinDone,
    bool? deeperDone,
    bool? questDone,
    DailyQuestion? todaysQuestion,
    String? checkinAnswer,
    String? checkinName,
    String? checkinNameArabic,
    String? checkinTeaching,
    String? checkinDuaArabic,
    String? checkinDuaTransliteration,
    String? checkinDuaTranslation,
    bool? checkinLoading,
    ReflectResponse? reflectResult,
    int? reflectStep,
    bool? reflectLoading,
    BrowseDua? questDua,
    String? questReason,
    CardEngageResult? cardEngageResult,
    CollectibleName? engagedCard,
    DailyRewardClaimResult? rewardClaimResult,
    int? streakCount,
    int? xpTotal,
    int? tokenBalance,
    String? levelTitle,
    String? levelTitleArabic,
    String? error,
  }) {
    return DailyLoopState(
      loaded: loaded ?? this.loaded,
      greeting: greeting ?? this.greeting,
      currentStep: currentStep ?? this.currentStep,
      checkinDone: checkinDone ?? this.checkinDone,
      deeperDone: deeperDone ?? this.deeperDone,
      questDone: questDone ?? this.questDone,
      todaysQuestion: todaysQuestion ?? this.todaysQuestion,
      checkinAnswer: checkinAnswer ?? this.checkinAnswer,
      checkinName: checkinName ?? this.checkinName,
      checkinNameArabic: checkinNameArabic ?? this.checkinNameArabic,
      checkinTeaching: checkinTeaching ?? this.checkinTeaching,
      checkinDuaArabic: checkinDuaArabic ?? this.checkinDuaArabic,
      checkinDuaTransliteration:
          checkinDuaTransliteration ?? this.checkinDuaTransliteration,
      checkinDuaTranslation:
          checkinDuaTranslation ?? this.checkinDuaTranslation,
      checkinLoading: checkinLoading ?? this.checkinLoading,
      reflectResult: reflectResult ?? this.reflectResult,
      reflectStep: reflectStep ?? this.reflectStep,
      reflectLoading: reflectLoading ?? this.reflectLoading,
      questDua: questDua ?? this.questDua,
      questReason: questReason ?? this.questReason,
      cardEngageResult: cardEngageResult ?? this.cardEngageResult,
      engagedCard: engagedCard ?? this.engagedCard,
      rewardClaimResult: rewardClaimResult ?? this.rewardClaimResult,
      streakCount: streakCount ?? this.streakCount,
      xpTotal: xpTotal ?? this.xpTotal,
      tokenBalance: tokenBalance ?? this.tokenBalance,
      levelTitle: levelTitle ?? this.levelTitle,
      levelTitleArabic: levelTitleArabic ?? this.levelTitleArabic,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class DailyLoopNotifier extends StateNotifier<DailyLoopState> {
  DailyLoopNotifier() : super(const DailyLoopState()) {
    _initialize();
  }

  String get _todayKey {
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return 'daily_loop_$date';
  }

  Future<void> _initialize() async {
    try {
      // Load streak, XP, and tokens
      final streakState = await getStreak();
      final xpState = await getXp();
      final tokenState = await getTokens();

      // Today's question
      final question = getTodaysDailyQuestion();

      // Greeting
      final hour = DateTime.now().hour;
      final greeting = hour < 12
          ? 'Good morning'
          : hour < 17
              ? 'Good afternoon'
              : 'Good evening';

      // Pick quest dua
      final questDua = _pickQuestDua(hour);

      state = state.copyWith(
        greeting: greeting,
        todaysQuestion: question,
        streakCount: streakState.currentStreak,
        xpTotal: xpState.totalXp,
        tokenBalance: tokenState.balance,
        levelTitle: xpState.title,
        levelTitleArabic: xpState.titleArabic,
        questDua: questDua,
      );

      // Restore persisted state for today
      await _loadTodayState();

      state = state.copyWith(loaded: true);
    } catch (e) {
      state = state.copyWith(loaded: true, error: e.toString());
    }
  }

  BrowseDua _pickQuestDua(int hour) {
    final String category;
    if (hour < 12) {
      category = 'morning';
    } else if (hour >= 17) {
      category = 'evening';
    } else {
      category = 'general';
    }

    final candidates =
        browseDuas.where((d) => d.category == category).toList();
    if (candidates.isEmpty) {
      return browseDuas.first;
    }

    // Rotate by day-of-year
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    return candidates[dayOfYear % candidates.length];
  }

  // ---------------------------------------------------------------------------
  // Step 1: Check-in
  // ---------------------------------------------------------------------------

  Future<void> answerCheckin(String answer) async {
    final question = state.todaysQuestion;
    if (question == null) return;

    state = state.copyWith(checkinLoading: true, error: null);

    try {
      // First daily check-in is free; subsequent ones cost a token
      if (state.checkinDone) {
        final spendResult = await spendTokens(tokenCostReflection);
        if (!spendResult.success) {
          state = state.copyWith(
            checkinLoading: false,
            tokenBalance: spendResult.newBalance,
            error: 'Not enough tokens. Earn more through daily rewards and quests.',
          );
          return;
        }
        state = state.copyWith(tokenBalance: spendResult.newBalance);
      }

      final result = await getDailyResponse(question.question, answer);

      state = state.copyWith(
        checkinAnswer: answer,
        checkinName: result.name,
        checkinNameArabic: result.nameArabic,
        checkinTeaching: result.teaching,
        checkinDuaArabic: result.duaArabic,
        checkinDuaTransliteration: result.duaTransliteration,
        checkinDuaTranslation: result.duaTranslation,
        checkinDone: true,
        checkinLoading: false,
      );

      // Engage card collection (discover or tier up)
      try {
        final rewardsState = await getDailyRewards();
        CollectibleName? collectible;

        if (rewardsState.guaranteedTierUpFlag) {
          // Guaranteed tier-up: pick an upgradeable card
          final collection = await getCardCollection();
          collectible = pickUpgradeableCard(collection);
          await clearGuaranteedTierUp();
        } else {
          collectible = findCollectibleByName(result.name);
          if (collectible == null && result.nameArabic.isNotEmpty) {
            for (final n in allCollectibleNames) {
              if (n.arabic.replaceAll(RegExp(r'\s'), '') ==
                  result.nameArabic.replaceAll(RegExp(r'\s'), '')) {
                collectible = n;
                break;
              }
            }
          }
        }

        if (collectible != null) {
          final engageResult = await engageCard(collectible.id);
          if (engageResult.tierChanged) {
            state = state.copyWith(
              cardEngageResult: engageResult,
              engagedCard: collectible,
            );
          }
        }
      } catch (e) {
        print('[CARD COLLECTION ERROR] $e');
      }

      // Award XP and mark streak
      try {
        final xpResult = await awardXp(5);
        final streakResult = await markActiveToday();
        state = state.copyWith(
          xpTotal: xpResult.newTotal,
          levelTitle: xpResult.state.title,
          levelTitleArabic: xpResult.state.titleArabic,
          streakCount: streakResult.currentStreak,
        );
      } catch (_) {
        // Non-critical — don't fail the check-in
      }

      // Claim daily reward
      try {
        final claimResult = await claimDailyReward();
        if (!claimResult.alreadyClaimed && claimResult.tokensAwarded > 0) {
          final tokenResult = await earnTokens(claimResult.tokensAwarded);
          state = state.copyWith(tokenBalance: tokenResult.balance);
        }
        state = state.copyWith(rewardClaimResult: claimResult);
      } catch (_) {}

      await _persistTodayState();
    } catch (e) {
      state = state.copyWith(
        checkinLoading: false,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  /// Reset today's daily loop so the user can redo it.
  Future<void> resetToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_todayKey);
    state = const DailyLoopState();
    await _initialize();
  }

  void clearCardEngageResult() {
    // Can't null out with copyWith, so we leave it — UI checks tierChanged
  }

  // ---------------------------------------------------------------------------
  // Step 2: Deeper reflect
  // ---------------------------------------------------------------------------

  Future<void> startDeeper() async {
    // Spend token for deeper reflection
    final spendResult = await spendTokens(tokenCostReflection);
    if (!spendResult.success) {
      state = state.copyWith(
        tokenBalance: spendResult.newBalance,
        error: 'Not enough tokens. Earn more through daily rewards and quests.',
      );
      return;
    }
    state = state.copyWith(
      tokenBalance: spendResult.newBalance,
      currentStep: DailyLoopStep.deeper,
      reflectLoading: true,
      error: null,
    );

    try {
      final contextText =
          "I answered '${state.checkinAnswer}' to '${state.todaysQuestion?.question}'. "
          "The Name shown was ${state.checkinName}.";

      final result = await reflectWithClaude(contextText);

      state = state.copyWith(
        reflectResult: result,
        reflectLoading: false,
        reflectStep: 0,
      );

      // Award XP for starting deeper reflection
      try {
        final xpResult = await awardXp(25);
        state = state.copyWith(
          xpTotal: xpResult.newTotal,
          levelTitle: xpResult.state.title,
          levelTitleArabic: xpResult.state.titleArabic,
        );
      } catch (_) {}

      // Award tokens for completing deeper reflection
      try {
        final tokenResult = await earnTokens(tokenRewardDeeperReflection);
        state = state.copyWith(tokenBalance: tokenResult.balance);
      } catch (_) {}
    } catch (e) {
      state = state.copyWith(
        reflectLoading: false,
        error: 'Could not load reflection. Please try again.',
      );
    }
  }

  Future<void> advanceReflectStep() async {
    final current = state.reflectStep;

    if (current == 3) {
      // Completing the dua step — finish deeper
      state = state.copyWith(
        deeperDone: true,
        currentStep: DailyLoopStep.quest,
      );
      await _persistTodayState();
      return;
    }

    final next = current + 1;
    state = state.copyWith(reflectStep: next);

    // Award XP for story (step 2) and dua (step 3)
    if (next == 2 || next == 3) {
      try {
        final xpResult = await awardXp(10);
        state = state.copyWith(
          xpTotal: xpResult.newTotal,
          levelTitle: xpResult.state.title,
          levelTitleArabic: xpResult.state.titleArabic,
        );
      } catch (_) {}
    }
  }

  // ---------------------------------------------------------------------------
  // Step 3: Quest
  // ---------------------------------------------------------------------------

  Future<void> completeQuest() async {
    state = state.copyWith(
      questDone: true,
      currentStep: DailyLoopStep.completed,
    );

    try {
      final xpResult = await awardXp(10);
      state = state.copyWith(
        xpTotal: xpResult.newTotal,
        levelTitle: xpResult.state.title,
        levelTitleArabic: xpResult.state.titleArabic,
      );
    } catch (_) {}

    // Award tokens for quest completion
    try {
      final tokenResult = await earnTokens(tokenRewardQuestComplete);
      state = state.copyWith(tokenBalance: tokenResult.balance);
    } catch (_) {}

    await _persistTodayState();
  }

  // ---------------------------------------------------------------------------
  // Skip helpers
  // ---------------------------------------------------------------------------

  Future<void> skipToQuest() async {
    state = state.copyWith(
      deeperDone: true,
      currentStep: DailyLoopStep.quest,
    );
    await _persistTodayState();
  }

  Future<void> skipAll() async {
    state = state.copyWith(
      checkinDone: true,
      deeperDone: true,
      questDone: true,
      currentStep: DailyLoopStep.completed,
    );
    await _persistTodayState();
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  Future<void> _persistTodayState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'checkinDone': state.checkinDone,
        'deeperDone': state.deeperDone,
        'questDone': state.questDone,
        'currentStep': state.currentStep.index,
        'checkinAnswer': state.checkinAnswer,
        'checkinName': state.checkinName,
        'checkinNameArabic': state.checkinNameArabic,
        'checkinTeaching': state.checkinTeaching,
        'checkinDuaArabic': state.checkinDuaArabic,
        'checkinDuaTransliteration': state.checkinDuaTransliteration,
        'checkinDuaTranslation': state.checkinDuaTranslation,
        'reflectStep': state.reflectStep,
      };
      await prefs.setString(_todayKey, jsonEncode(data));
    } catch (_) {
      // Non-critical — silently fail
    }
  }

  Future<void> _loadTodayState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_todayKey);
      if (raw == null) return;

      final data = jsonDecode(raw) as Map<String, dynamic>;

      final checkinDone = data['checkinDone'] as bool? ?? false;
      final deeperDone = data['deeperDone'] as bool? ?? false;
      final questDone = data['questDone'] as bool? ?? false;
      final stepIndex = data['currentStep'] as int? ?? 0;

      state = state.copyWith(
        checkinDone: checkinDone,
        deeperDone: deeperDone,
        questDone: questDone,
        currentStep: DailyLoopStep.values[stepIndex],
        checkinAnswer: data['checkinAnswer'] as String?,
        checkinName: data['checkinName'] as String?,
        checkinNameArabic: data['checkinNameArabic'] as String?,
        checkinTeaching: data['checkinTeaching'] as String?,
        checkinDuaArabic: data['checkinDuaArabic'] as String?,
        checkinDuaTransliteration:
            data['checkinDuaTransliteration'] as String?,
        checkinDuaTranslation: data['checkinDuaTranslation'] as String?,
        reflectStep: data['reflectStep'] as int? ?? 0,
      );
    } catch (_) {
      // Non-critical — start fresh
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final dailyLoopProvider =
    StateNotifierProvider<DailyLoopNotifier, DailyLoopState>(
  (ref) => DailyLoopNotifier(),
);
