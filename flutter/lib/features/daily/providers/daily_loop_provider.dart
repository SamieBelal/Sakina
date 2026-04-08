import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/constants/checkin_questions.dart';
import 'package:sakina/core/constants/daily_questions.dart';
import 'package:sakina/core/constants/duas.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/checkin_history_service.dart';
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

  // Step 1: Check-in (4-question adaptive flow)
  final int checkinQuestionIndex; // 0-3, which of the 4 questions we're on
  final List<String> checkinAnswers; // accumulates as user answers
  final DailyQuestion? todaysQuestion; // kept for legacy compat, unused
  final String? checkinAnswer; // final combined summary for display
  final String? checkinName;
  final String? checkinNameArabic;
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
  final int levelNumber;

  // Level-up event (consumed by UI to show overlay)
  final bool leveledUp;
  final String? newLevelTitle;
  final String? newLevelTitleArabic;
  final int? newLevelNumber;

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
    this.checkinQuestionIndex = 0,
    this.checkinAnswers = const [],
    this.todaysQuestion,
    this.checkinAnswer,
    this.checkinName,
    this.checkinNameArabic,
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
    this.levelNumber = 1,
    this.leveledUp = false,
    this.newLevelTitle,
    this.newLevelTitleArabic,
    this.newLevelNumber,
    this.error,
  });

  DailyLoopState copyWith({
    bool? loaded,
    String? greeting,
    DailyLoopStep? currentStep,
    bool? checkinDone,
    bool? deeperDone,
    bool? questDone,
    int? checkinQuestionIndex,
    List<String>? checkinAnswers,
    DailyQuestion? todaysQuestion,
    String? checkinAnswer,
    String? checkinName,
    String? checkinNameArabic,
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
    int? levelNumber,
    bool? leveledUp,
    String? newLevelTitle,
    String? newLevelTitleArabic,
    int? newLevelNumber,
    String? error,
  }) {
    return DailyLoopState(
      loaded: loaded ?? this.loaded,
      greeting: greeting ?? this.greeting,
      currentStep: currentStep ?? this.currentStep,
      checkinDone: checkinDone ?? this.checkinDone,
      deeperDone: deeperDone ?? this.deeperDone,
      questDone: questDone ?? this.questDone,
      checkinQuestionIndex: checkinQuestionIndex ?? this.checkinQuestionIndex,
      checkinAnswers: checkinAnswers ?? this.checkinAnswers,
      todaysQuestion: todaysQuestion ?? this.todaysQuestion,
      checkinAnswer: checkinAnswer ?? this.checkinAnswer,
      checkinName: checkinName ?? this.checkinName,
      checkinNameArabic: checkinNameArabic ?? this.checkinNameArabic,
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
      levelNumber: levelNumber ?? this.levelNumber,
      leveledUp: leveledUp ?? this.leveledUp,
      newLevelTitle: newLevelTitle ?? this.newLevelTitle,
      newLevelTitleArabic: newLevelTitleArabic ?? this.newLevelTitleArabic,
      newLevelNumber: newLevelNumber ?? this.newLevelNumber,
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
      const greeting = 'Assalamu Alaykum';

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
        levelNumber: xpState.level,
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

    final candidates = browseDuas.where((d) => d.category == category).toList();
    if (candidates.isEmpty) {
      return browseDuas.first;
    }

    // Rotate by day-of-year
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return candidates[dayOfYear % candidates.length];
  }

  // ---------------------------------------------------------------------------
  // Discover a Name — skip questions, straight to gacha
  // ---------------------------------------------------------------------------

  /// Instantly picks a name (smart priority: undiscovered → lowest tier) and
  /// engages it. No AI call, no questions. The UI shows the gacha animation.
  Future<void> discoverName() async {
    state = state.copyWith(checkinLoading: true, error: null);

    try {
      // First daily discover is free; subsequent ones cost a token
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

      final collection = await getCardCollection();
      final card = pickNextCard(collection);
      final engageResult = await engageCard(card.id);

      CardEngageResult? cardResult;
      if (engageResult.tierChanged) {
        cardResult = engageResult;
      } else if (engageResult.isDuplicate) {
        try { await earnTokens(1); } catch (_) {}
      }

      state = state.copyWith(
        checkinName: card.transliteration,
        checkinNameArabic: card.arabic,
        checkinDone: true,
        checkinLoading: false,
        cardEngageResult: cardResult,
        engagedCard: card,
      );

      // Save to history
      try {
        final today = DateTime.now();
        final dateStr =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        await saveCheckinRecord(CheckInRecord(
          date: dateStr,
          q1: 'discover',
          q2: '',
          q3: '',
          q4: '',
          nameReturned: card.transliteration,
          nameArabic: card.arabic,
        ));
      } catch (_) {}

      // Award XP and mark streak
      try {
        final xpResult = await awardXp(5);
        final streakResult = await markActiveToday();
        state = state.copyWith(
          xpTotal: xpResult.newTotal,
          levelTitle: xpResult.state.title,
          levelTitleArabic: xpResult.state.titleArabic,
          levelNumber: xpResult.state.level,
          streakCount: streakResult.currentStreak,
          leveledUp: xpResult.leveledUp,
          newLevelTitle: xpResult.leveledUp ? xpResult.state.title : null,
          newLevelTitleArabic: xpResult.leveledUp ? xpResult.state.titleArabic : null,
          newLevelNumber: xpResult.leveledUp ? xpResult.state.level : null,
        );
      } catch (_) {}
    } catch (e) {
      debugPrint('[DISCOVER NAME ERROR] $e');
      state = state.copyWith(checkinLoading: false, error: 'Something went wrong. Try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // Step 1: Check-in (legacy — used by deeper reflection)
  // ---------------------------------------------------------------------------

  /// Called when the user taps an answer on any of the 4 check-in questions.
  /// Advances the question index until all 4 are answered, then calls the AI.
  Future<void> answerCheckin(String answer) async {
    final currentIndex = state.checkinQuestionIndex;
    final updatedAnswers = [...state.checkinAnswers, answer];

    // Not on the last question yet — just advance
    if (currentIndex < 3) {
      state = state.copyWith(
        checkinAnswers: updatedAnswers,
        checkinQuestionIndex: currentIndex + 1,
      );
      return;
    }

    // All 4 answered — call the AI
    state = state.copyWith(
      checkinAnswers: updatedAnswers,
      checkinLoading: true,
      error: null,
    );

    try {
      // First daily check-in is free; subsequent ones cost a token
      if (state.checkinDone) {
        final spendResult = await spendTokens(tokenCostReflection);
        if (!spendResult.success) {
          state = state.copyWith(
            checkinLoading: false,
            tokenBalance: spendResult.newBalance,
            error:
                'Not enough tokens. Earn more through daily rewards and quests.',
          );
          return;
        }
        state = state.copyWith(tokenBalance: spendResult.newBalance);
      }

      // Load history for context
      final history = await getCheckinHistory();
      final historyContext = buildHistoryContext(history);
      // Extract recent names to avoid repeating them (last 10 sessions)
      final recentNames = history
          .take(10)
          .map((r) => r.nameReturned)
          .where((n) => n.isNotEmpty)
          .toList();

      // Also pass all discovered names so AI prioritizes undiscovered ones
      final collection = await getCardCollection();
      final discoveredNames = collection.discoveredIds
          .map((id) {
            final card = allCollectibleNames.where((n) => n.id == id).firstOrNull;
            return card?.transliteration ?? '';
          })
          .where((n) => n.isNotEmpty)
          .toList();

      final result = await getDailyResponse(
        updatedAnswers,
        historyContext: historyContext,
        recentNames: recentNames,
        discoveredNames: discoveredNames,
      );

      // Engage card collection BEFORE setting checkinDone so the gacha
      // reveal receives the card result in the same state update.
      CardEngageResult? cardEngageResult;
      CollectibleName? engagedCard;
      try {
        final rewardsState = await getDailyRewards();
        CollectibleName? collectible;

        if (rewardsState.guaranteedTierUpFlag) {
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

        debugPrint('[CARD] Looking for: "${result.name}" / "${result.nameArabic}"');
        debugPrint('[CARD] Found collectible: ${collectible?.transliteration ?? "NULL"} (id: ${collectible?.id})');
        if (collectible != null) {
          engagedCard = collectible; // Always set for check-in result display
          final engageResult = await engageCard(collectible.id);
          debugPrint('[CARD] Engage result: isNew=${engageResult.isNew}, tierChanged=${engageResult.tierChanged}, newTier=${engageResult.newTier}, isDuplicate=${engageResult.isDuplicate}');
          if (engageResult.tierChanged) {
            // New card or tier upgrade — show gacha overlay
            cardEngageResult = engageResult;
          } else if (engageResult.isDuplicate) {
            // Already maxed or cooldown not met — award bonus tokens
            try {
              await earnTokens(1);
            } catch (_) {}
          }
        }
      } catch (e, st) {
        debugPrint('[CARD COLLECTION ERROR] $e');
        debugPrint('[CARD COLLECTION STACK] $st');
      }

      // Clean AI name — strip Arabic chars and " — meaning" suffix
      // Only split on em-dash/en-dash surrounded by spaces, not hyphens in "Al-Lateef"
      final cleanName = result.name
          .replaceAll(RegExp(r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]+'), '')
          .split(RegExp(r'\s+[—–]\s+'))
          .first
          .trim();

      // Single state update — widget sees checkinDone + card data together
      state = state.copyWith(
        checkinAnswer: answer,
        checkinName: cleanName.isNotEmpty ? cleanName : result.name,
        checkinNameArabic: result.nameArabic,
        checkinDone: true,
        checkinLoading: false,
        cardEngageResult: cardEngageResult,
        engagedCard: engagedCard,
      );

      // Save check-in to history
      try {
        final today = DateTime.now();
        final dateStr =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        await saveCheckinRecord(CheckInRecord(
          date: dateStr,
          q1: updatedAnswers.isNotEmpty ? updatedAnswers[0] : '',
          q2: updatedAnswers.length > 1 ? updatedAnswers[1] : '',
          q3: updatedAnswers.length > 2 ? updatedAnswers[2] : '',
          q4: updatedAnswers.length > 3 ? updatedAnswers[3] : '',
          nameReturned: result.name,
          nameArabic: result.nameArabic,
        ));
      } catch (e) {
        debugPrint('[HISTORY SAVE ERROR] $e');
      }

      // Award XP and mark streak
      try {
        final xpResult = await awardXp(5);
        final streakResult = await markActiveToday();
        state = state.copyWith(
          xpTotal: xpResult.newTotal,
          levelTitle: xpResult.state.title,
          levelTitleArabic: xpResult.state.titleArabic,
          levelNumber: xpResult.state.level,
          streakCount: streakResult.currentStreak,
          leveledUp: xpResult.leveledUp,
          newLevelTitle: xpResult.leveledUp ? xpResult.state.title : null,
          newLevelTitleArabic:
              xpResult.leveledUp ? xpResult.state.titleArabic : null,
          newLevelNumber: xpResult.leveledUp ? xpResult.state.level : null,
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

  void clearLevelUp() {
    state = state.copyWith(leveledUp: false);
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
      reflectStep: 1, // skip step 0 (name display) — user just saw it in gacha
      error: null,
    );

    try {
      final contextText = state.checkinAnswers.isNotEmpty
          ? state.checkinAnswers.join(' / ')
          : "I answered '${state.checkinAnswer}'.";

      final result = await reflectWithClaude(
        contextText,
        forceName: state.checkinName,
      );

      state = state.copyWith(
        reflectResult: result,
        reflectLoading: false,
        reflectStep:
            1, // skip step 0 (name display) — user saw the name in gacha
      );

      // Award XP for starting deeper reflection
      try {
        final xpResult = await awardXp(25);
        state = state.copyWith(
          xpTotal: xpResult.newTotal,
          levelTitle: xpResult.state.title,
          levelTitleArabic: xpResult.state.titleArabic,
          levelNumber: xpResult.state.level,
          leveledUp: xpResult.leveledUp,
          newLevelTitle: xpResult.leveledUp ? xpResult.state.title : null,
          newLevelTitleArabic:
              xpResult.leveledUp ? xpResult.state.titleArabic : null,
          newLevelNumber: xpResult.leveledUp ? xpResult.state.level : null,
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

  void setReflectStep(int step) {
    state = state.copyWith(reflectStep: step);
  }

  Future<void> advanceReflectStep() async {
    final current = state.reflectStep.clamp(1, 3); // step 0 is skipped

    if (current == 3) {
      // Completing the dua step — finish Muhasabah (skip quest)
      state = state.copyWith(
        deeperDone: true,
        questDone: true,
        currentStep: DailyLoopStep.completed,
      );

      // Award quest XP + tokens here since we skip the quest step
      try {
        final xpResult = await awardXp(10);
        state = state.copyWith(
          xpTotal: xpResult.newTotal,
          levelTitle: xpResult.state.title,
          levelTitleArabic: xpResult.state.titleArabic,
          levelNumber: xpResult.state.level,
          leveledUp: xpResult.leveledUp,
          newLevelTitle: xpResult.leveledUp ? xpResult.state.title : null,
          newLevelTitleArabic:
              xpResult.leveledUp ? xpResult.state.titleArabic : null,
          newLevelNumber: xpResult.leveledUp ? xpResult.state.level : null,
        );
      } catch (_) {}

      try {
        final tokenResult = await earnTokens(tokenRewardQuestComplete);
        state = state.copyWith(tokenBalance: tokenResult.balance);
      } catch (_) {}

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
          levelNumber: xpResult.state.level,
          leveledUp: xpResult.leveledUp,
          newLevelTitle: xpResult.leveledUp ? xpResult.state.title : null,
          newLevelTitleArabic:
              xpResult.leveledUp ? xpResult.state.titleArabic : null,
          newLevelNumber: xpResult.leveledUp ? xpResult.state.level : null,
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
        levelNumber: xpResult.state.level,
        leveledUp: xpResult.leveledUp,
        newLevelTitle: xpResult.leveledUp ? xpResult.state.title : null,
        newLevelTitleArabic:
            xpResult.leveledUp ? xpResult.state.titleArabic : null,
        newLevelNumber: xpResult.leveledUp ? xpResult.state.level : null,
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
        'checkinQuestionIndex': state.checkinQuestionIndex,
        'checkinAnswers': state.checkinAnswers,
        'checkinAnswer': state.checkinAnswer,
        'checkinName': state.checkinName,
        'checkinNameArabic': state.checkinNameArabic,
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
      final savedAnswers = (data['checkinAnswers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [];

      state = state.copyWith(
        checkinDone: checkinDone,
        deeperDone: deeperDone,
        questDone: questDone,
        currentStep: DailyLoopStep.values[stepIndex],
        checkinQuestionIndex: data['checkinQuestionIndex'] as int? ?? 0,
        checkinAnswers: savedAnswers,
        checkinAnswer: data['checkinAnswer'] as String?,
        checkinName: data['checkinName'] as String?,
        checkinNameArabic: data['checkinNameArabic'] as String?,
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
