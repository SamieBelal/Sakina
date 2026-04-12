import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/constants/daily_questions.dart';
import 'package:sakina/core/constants/duas.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/checkin_history_service.dart';
import 'package:sakina/services/daily_rewards_service.dart';
import 'package:sakina/services/streak_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/public_catalog_service.dart';
import 'package:sakina/services/xp_service.dart';
import 'package:sakina/services/title_service.dart';
import 'package:sakina/services/tier_up_scroll_service.dart';
import 'package:sakina/services/premium_grants_service.dart';
import 'package:sakina/services/purchase_service.dart';
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
  final DailyQuestion? todaysQuestion; // displayed as subtitle under Muḥāsabah CTA
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
  final LevelUpRewards? levelUpRewards;

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
    this.levelUpRewards,
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
    LevelUpRewards? levelUpRewards,
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
      levelUpRewards: levelUpRewards ?? this.levelUpRewards,
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

      // Initialize unlocked titles for existing users
      await initializeUnlockedTitles(xpState.level);

      // Check premium monthly grants (may add tokens/scrolls)
      await checkPremiumMonthlyGrant();
      // Re-read token balance after potential grant
      final finalTokenState = await getTokens();

      // Get display title (respects auto/manual selection)
      final displayTitle = await getDisplayTitle(xpState.level);

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
        tokenBalance: finalTokenState.balance,
        levelTitle: displayTitle.title,
        levelTitleArabic: displayTitle.titleArabic,
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
    final catalog = browseDuasCatalog;
    final String category;
    if (hour < 12) {
      category = 'morning';
    } else if (hour >= 17) {
      category = 'evening';
    } else {
      category = 'general';
    }

    final candidates = catalog.where((d) => d.category == category).toList();
    if (candidates.isEmpty) {
      return catalog.first;
    }

    // Rotate by day-of-year
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return candidates[dayOfYear % candidates.length];
  }

  void onCatalogRefreshed() {
    final hour = DateTime.now().hour;
    state = state.copyWith(
      todaysQuestion: getTodaysDailyQuestion(),
      questDua: _pickQuestDua(hour),
    );
  }

  // ---------------------------------------------------------------------------
  // XP + Level-up reward helper
  // ---------------------------------------------------------------------------

  Future<void> _handleXpAward(int amount) async {
    final xpResult = await awardXp(amount);
    state = state.copyWith(
      xpTotal: xpResult.newTotal,
      levelNumber: xpResult.state.level,
    );

    if (xpResult.leveledUp && xpResult.rewards != null) {
      final rewards = xpResult.rewards!;

      // Award tokens
      if (rewards.tokensAwarded > 0) {
        final tokenResult = await earnTokens(rewards.tokensAwarded);
        state = state.copyWith(tokenBalance: tokenResult.balance);
      }

      // Award scrolls
      if (rewards.scrollsAwarded > 0) {
        await earnTierUpScrolls(rewards.scrollsAwarded);
      }

      // Unlock title
      if (rewards.titleUnlocked && rewards.unlockedTitle != null) {
        await unlockTitle(rewards.unlockedTitle!);
      }

      // Update display title (auto mode will pick the new level title)
      final displayTitle = await getDisplayTitle(xpResult.state.level);

      state = state.copyWith(
        leveledUp: true,
        newLevelTitle: xpResult.state.title,
        newLevelTitleArabic: xpResult.state.titleArabic,
        newLevelNumber: xpResult.state.level,
        levelTitle: displayTitle.title,
        levelTitleArabic: displayTitle.titleArabic,
        levelUpRewards: rewards,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Streak milestone helper
  // ---------------------------------------------------------------------------

  Future<void> _handleStreakMilestones(int currentStreak) async {
    final milestones = await checkStreakMilestones(currentStreak);
    for (final result in milestones) {
      if (result.milestone.xpReward > 0) {
        await _handleXpAward(result.milestone.xpReward);
      }
      if (result.milestone.scrollReward > 0) {
        await earnTierUpScrolls(result.milestone.scrollReward);
      }
      if (result.milestone.titleUnlock != null) {
        await unlockTitle(result.milestone.titleUnlock!);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Discover a Name — skip questions, straight to gacha
  // ---------------------------------------------------------------------------

  /// Instantly picks a name (smart priority: undiscovered → lowest tier) and
  /// engages it. No AI call, no questions. The UI shows the gacha animation.
  Future<void> discoverName() async {
    state = state.copyWith(checkinLoading: true, error: null);

    try {
      // No token charge here — the entry-point CTAs ("Seek Another Name" /
      // "Discover a New Name") are responsible for charging the 50-token
      // unlock fee on additional muhasabahs. Once we're inside the flow,
      // every step is free for the user.
      final collection = await getCardCollection();
      final card = pickNextCard(collection);
      final engageResult = await engageCard(card.id);

      CardEngageResult? cardResult;
      if (engageResult.tierChanged) {
        cardResult = engageResult;
      } else if (engageResult.isDuplicate) {
        try {
          await earnTokens(1);
        } catch (_) {}
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

      // Mark streak (XP is awarded once at Muhasabah completion, not here)
      try {
        final streakResult = await markActiveToday();
        state = state.copyWith(streakCount: streakResult.currentStreak);
        await _handleStreakMilestones(streakResult.currentStreak);
      } catch (_) {}
    } catch (e) {
      debugPrint('[DISCOVER NAME ERROR] $e');
      state = state.copyWith(
          checkinLoading: false, error: 'Something went wrong. Try again.');
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
      // No token charge here — see discoverName for the rationale. The 50
      // token unlock for additional muhasabahs is collected at the entry
      // CTA, not at the per-step level.

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
      final collectibleNames = currentCollectibleNames();
      final discoveredNames = collection.discoveredIds
          .map((id) {
            final card = collectibleNames.where((n) => n.id == id).firstOrNull;
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
        CollectibleName? collectible;

        collectible = findCollectibleByName(result.name);
        if (collectible == null && result.nameArabic.isNotEmpty) {
          for (final n in collectibleNames) {
            if (n.arabic.replaceAll(RegExp(r'\s'), '') ==
                result.nameArabic.replaceAll(RegExp(r'\s'), '')) {
              collectible = n;
              break;
            }
          }
        }

        debugPrint(
            '[CARD] Looking for: "${result.name}" / "${result.nameArabic}"');
        debugPrint(
            '[CARD] Found collectible: ${collectible?.transliteration ?? "NULL"} (id: ${collectible?.id})');
        if (collectible != null) {
          engagedCard = collectible; // Always set for check-in result display
          final engageResult = await engageCard(collectible.id);
          debugPrint(
              '[CARD] Engage result: isNew=${engageResult.isNew}, tierChanged=${engageResult.tierChanged}, newTier=${engageResult.newTier}, isDuplicate=${engageResult.isDuplicate}');
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
          .replaceAll(
              RegExp(
                  r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]+'),
              '')
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

      // Mark streak (XP is awarded once at Muhasabah completion, not here)
      try {
        final streakResult = await markActiveToday();
        state = state.copyWith(streakCount: streakResult.currentStreak);
        await _handleStreakMilestones(streakResult.currentStreak);
      } catch (_) {
        // Non-critical — don't fail the check-in
      }

      // Claim daily reward (idempotent — safe even if the launch overlay
      // already claimed today's reward; the second call returns
      // alreadyClaimed=true and we skip the wallet credit.)
      try {
        final isPremium = await PurchaseService().isPremium();
        final claimResult = await claimDailyReward(isPremium: isPremium);
        if (!claimResult.alreadyClaimed) {
          if (claimResult.tokensAwarded > 0) {
            final tokenResult = await earnTokens(claimResult.tokensAwarded);
            state = state.copyWith(tokenBalance: tokenResult.balance);
          }
          if (claimResult.scrollsAwarded > 0) {
            await earnTierUpScrolls(claimResult.scrollsAwarded);
          }
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

  void refreshTokenBalance(int balance) {
    state = state.copyWith(tokenBalance: balance);
  }

  /// Re-reads streak, XP, and token state from cache.
  /// Call after economy hydration completes to pick up server-synced values.
  Future<void> refreshEconomyState() async {
    try {
      final streakState = await getStreak();
      final xpState = await getXp();
      final tokenState = await getTokens();
      final displayTitle = await getDisplayTitle(xpState.level);
      state = state.copyWith(
        streakCount: streakState.currentStreak,
        xpTotal: xpState.totalXp,
        tokenBalance: tokenState.balance,
        levelTitle: displayTitle.title,
        levelTitleArabic: displayTitle.titleArabic,
        levelNumber: xpState.level,
      );
    } catch (_) {
      // Non-critical — stale values are better than crashing
    }
  }

  // ---------------------------------------------------------------------------
  // Step 2: Deeper reflect
  // ---------------------------------------------------------------------------

  Future<void> startDeeper() async {
    // Always free. The 50-token unlock for additional muhasabahs is charged
    // up front at the "Seek Another Name" / "Discover a New Name" entry
    // CTAs, so once the user is inside a muhasabah cycle every step — the
    // discover, the deeper reflection, the dua — runs without any token
    // gating.
    state = state.copyWith(
      currentStep: DailyLoopStep.deeper,
      reflectLoading: true,
      reflectStep: 1, // skip step 0 (name display) — user just saw it in gacha
      error: null,
    );

    try {
      final contextText = state.checkinAnswers.isNotEmpty
          ? state.checkinAnswers.join(' / ')
          : "I answered '${state.checkinAnswer}'.";

      final result = await reflectWithOpenAI(
        contextText,
        forceName: state.checkinName,
      );

      state = state.copyWith(
        reflectResult: result,
        reflectLoading: false,
        reflectStep:
            1, // skip step 0 (name display) — user saw the name in gacha
      );

      // No token reward for entering deeper reflection — muhasabah is its
      // own reward (the card pull). Tokens come from quests, daily login
      // rewards, and streak milestones.
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
      // Completing the dua step — finish Muhasabah. The reward for going
      // through the muhasabah is the card pull itself, nothing more. XP and
      // tokens come from quests, daily rewards, and streak milestones —
      // never from this flow, on either the free first daily or replays.
      state = state.copyWith(
        deeperDone: true,
        questDone: true,
        currentStep: DailyLoopStep.completed,
      );

      await _persistTodayState();
      return;
    }

    final next = current + 1;
    state = state.copyWith(reflectStep: next);
    // No per-step XP — XP is awarded once at completion above.
  }

  // ---------------------------------------------------------------------------
  // Step 3: Quest (legacy entrypoint — completes Muhasabah)
  // ---------------------------------------------------------------------------

  Future<void> completeQuest() async {
    // Legacy completion entrypoint. Like advanceReflectStep, this no longer
    // grants XP or tokens — muhasabah is its own reward.
    state = state.copyWith(
      questDone: true,
      currentStep: DailyLoopStep.completed,
    );
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
  (ref) {
    final notifier = DailyLoopNotifier();
    ref.listen<int>(
      publicCatalogRegistryProvider.select((registry) => registry.revision),
      (_, __) {
        notifier.onCatalogRefreshed();
      },
    );
    return notifier;
  },
);
