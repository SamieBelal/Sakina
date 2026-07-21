import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/constants/daily_questions.dart';
import 'package:sakina/core/constants/duas.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/bypass_flow_mixin.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/checkin_history_service.dart';
import 'package:sakina/services/daily_rewards_service.dart';
import 'package:sakina/services/economy_events.dart';
import 'package:sakina/services/gating_service.dart';
import 'package:sakina/services/streak_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/public_catalog_service.dart';
import 'package:sakina/services/xp_service.dart';
import 'package:sakina/services/title_service.dart';
import 'package:sakina/services/tier_up_scroll_service.dart';
import 'package:sakina/services/premium_grants_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

const _scrollRewardSyncError =
    'We couldn\'t save your scroll reward. Please try again.';

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
  final DailyQuestion?
      todaysQuestion; // displayed as subtitle under Muḥāsabah CTA
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

  // Last XP gain amount — consumed by AnimatedXpBar to show floating "+N XP"
  final int lastXpGained;

  // Streak milestone event (consumed by UI to show overlay)
  final bool streakMilestoneReached;
  final int? streakMilestoneCount;
  final int? streakMilestoneXp;
  final int? streakMilestoneScrolls;

  // Streak expired this reflection with a restorable streak (paid buy-back, §2g).
  // Consumed by the UI to show the rescue sheet, mirroring the milestone flag.
  final bool streakLapseRestorable;
  final int lapsePreLapseStreak;

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
    this.lastXpGained = 0,
    this.streakMilestoneReached = false,
    this.streakMilestoneCount,
    this.streakMilestoneXp,
    this.streakMilestoneScrolls,
    this.streakLapseRestorable = false,
    this.lapsePreLapseStreak = 0,
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
    int? lastXpGained,
    bool? streakMilestoneReached,
    int? streakMilestoneCount,
    int? streakMilestoneXp,
    int? streakMilestoneScrolls,
    bool? streakLapseRestorable,
    int? lapsePreLapseStreak,
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
      lastXpGained: lastXpGained ?? this.lastXpGained,
      streakMilestoneReached:
          streakMilestoneReached ?? this.streakMilestoneReached,
      streakMilestoneCount: streakMilestoneCount ?? this.streakMilestoneCount,
      streakMilestoneXp: streakMilestoneXp ?? this.streakMilestoneXp,
      streakMilestoneScrolls:
          streakMilestoneScrolls ?? this.streakMilestoneScrolls,
      streakLapseRestorable:
          streakLapseRestorable ?? this.streakLapseRestorable,
      lapsePreLapseStreak: lapsePreLapseStreak ?? this.lapsePreLapseStreak,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Test seam — replace in tests via `debugDailyLoopClock = ...` to drive
/// the daily-loop date math at deterministic UTC instants. Production
/// callers always read `DateTime.now().toUtc()`. Mirrors `debugLaunchGateClock`
/// (`launch_gate_state.dart`) and `debugRewardsClock` (`daily_rewards_service.dart`)
/// so all three modules agree on the day boundary. Without this seam the
/// daily-loop SharedPrefs key was keyed by local date while the server-side
/// `claim_daily_reward` RPC keyed by UTC, causing a "fresh muhasabah"
/// flicker for users crossing local midnight on the same UTC day. See PR #8
/// for the matching launch-gate fix and `TODO.md` for the prior context.
@visibleForTesting
DateTime Function() debugDailyLoopClock = () => DateTime.now().toUtc();

class DailyLoopNotifier extends StateNotifier<DailyLoopState>
    with BypassFlowMixin<DailyLoopState> {
  DailyLoopNotifier({
    @visibleForTesting Future<void> Function(DailyLoopNotifier self)?
        discoverNameOverride,
  })  : _discoverNameOverride = discoverNameOverride,
        super(const DailyLoopState()) {
    // Subscribe BEFORE _initialize so consumable grants that fire while
    // initial hydration is in flight (e.g., the customerInfo listener in
    // main.dart firing on app boot with a pending receipt) update the
    // balance pill without racing _initialize's `getTokens` read.
    //
    // Known low-probability race: if a stream event applies a fresh
    // tokenBalance AFTER `_initialize` reads `getTokens()` but BEFORE
    // `_initialize`'s `state.copyWith(...)` writes its hydrated state,
    // the listener's value is overwritten by the pre-grant cached value.
    // This requires a pending-receipt sync to land mid-init, which is
    // rare; subsequent refreshes (`refreshEconomyState`, pull-to-refresh)
    // re-read cache and reconcile. Not worth the complexity of an
    // init-vs-listener fence today; revisit if this surfaces in the wild.
    _grantsSub = EconomyEvents.stream.listen((event) {
      if (event is TokenGranted) {
        state = state.copyWith(tokenBalance: event.newBalance);
      } else if (event is XpGranted) {
        state = state.copyWith(
          xpTotal: event.newTotal,
          levelNumber: event.newState.level,
          levelTitle: event.newState.title,
          levelTitleArabic: event.newState.titleArabic,
          lastXpGained: event.amount,
        );
      }
    });
    _initialize();
  }

  StreamSubscription<EconomyEvent>? _grantsSub;
  Future<ReflectResponse>? _deeperReflectFuture;
  ReflectResponse? _deeperReflectResult;
  String? _deeperReflectKey;
  int _deeperReflectGeneration = 0;

  /// Test-only seam for [discoverName]. When non-null, the bypass wrappers
  /// ([discoverNameWithBypass], [discoverNameWithFirstBypass]) invoke this
  /// instead of the real `discoverName()` work, letting tests inject a
  /// Completer-backed stub that succeeds, fails, or hangs deterministically
  /// without driving the full Supabase + card-service surface. Production
  /// callers leave it null and get the real implementation.
  final Future<void> Function(DailyLoopNotifier self)? _discoverNameOverride;

  /// Static analytics hook (mirrors [GatingService.onAnalyticsEvent]). This
  /// notifier is a service-layer StateNotifier with no Riverpod access; main.dart
  /// wires this to the analytics service so the daily loop can emit
  /// `check_in_completed` without taking on an analytics dependency. Tests leave
  /// it null.
  static void Function(String event, Map<String, dynamic> props)?
      onAnalyticsEvent;

  /// The gated feature this notifier owns. Consumed by [BypassFlowMixin] as
  /// the cancel-RPC argument.
  @override
  GatedFeature get bypassFeature => GatedFeature.discoverName;

  @override
  void dispose() {
    // P0-4 + P1-B: cancel any active or in-flight bypass reservation so the
    // user's tokens are refunded immediately instead of waiting up to 15 min
    // for the server-side orphan cron. MUST run before super.dispose() so
    // the mixin's private state is still readable.
    disposeBypassFlow();
    _deeperReflectGeneration++;
    _grantsSub?.cancel();
    super.dispose();
  }

  void clearLastXpGained() {
    if (state.lastXpGained == 0) return;
    state = state.copyWith(lastXpGained: 0);
  }

  String get _todayKey {
    final now = debugDailyLoopClock();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return supabaseSyncService.scopedKey('daily_loop_$date');
  }

  Future<void> _initialize() async {
    try {
      // Load streak, XP, and tokens
      final streakState = await getStreak();
      final xpState = await getXp();
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
        // Re-derive the buy-back offer from the persisted lapse cache, so it
        // survives the provider rebuild the muḥāsabah "Return to Home" CTA
        // triggers (which would otherwise wipe the transient flag before Home
        // sees it). The cache is only cleared on dismiss / restore / start-fresh.
        streakLapseRestorable: streakState.hasRestorableLapse,
        lapsePreLapseStreak: streakState.preLapseStreak,
      );

      // Restore persisted state for today
      await _loadTodayState();

      // Re-read economy values in case hydration completed while we were
      // loading. This covers the sign-out → re-login path where _initialize
      // first reads default/empty cache, then hydration finishes before we
      // reach this point.
      await refreshEconomyState();

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
    // awardXp publishes XpGranted (with leveledUp + rewards when applicable)
    // to EconomyEvents.stream — AppShell subscribes and pushes LevelUpOverlay.
    // DailyLoopNotifier's own _grantsSub updates xpTotal / level / title.
    // No level-up state writes needed here.
    await awardXp(amount, source: EconomyEventSource.streak);
  }

  // ---------------------------------------------------------------------------
  // Streak helpers
  // ---------------------------------------------------------------------------

  /// Shared logic for both check-in flows: mark streak active and award
  /// milestone rewards.
  Future<void> _markStreakAndHandleMilestones() async {
    final streakResult = await markActiveToday();
    // Log user_activity_log + local cache so downstream analytics /
    // retention queries see the daily check-in. Previously only the
    // reflect flow hit logActivity(); muhasabah was silent.
    await logActivity();
    state = state.copyWith(
      streakCount: streakResult.currentStreak,
      // The streak just expired with a buy-back-worthy value → offer the rescue.
      streakLapseRestorable: streakResult.hasRestorableLapse,
      lapsePreLapseStreak: streakResult.preLapseStreak,
    );
    await _handleStreakMilestones(streakResult.currentStreak);
  }

  Future<void> _handleStreakMilestones(int currentStreak) async {
    final milestones = await checkStreakMilestones(currentStreak);
    for (final result in milestones) {
      if (result.milestone.xpReward > 0) {
        await _handleXpAward(result.milestone.xpReward);
      }
      if (result.milestone.scrollReward > 0) {
        final scrollResult =
            await earnTierUpScrolls(result.milestone.scrollReward, source: EconomyEventSource.streak);
        if (!scrollResult.success) {
          state = state.copyWith(error: _scrollRewardSyncError);
        }
      }
      // Title unlocks are derived from streak on read — no persistence needed.
    }

    // Emit a single streak-milestone event for the UI overlay. If multiple
    // milestones land at once (rare — only if the streak_service batches them),
    // we show the highest-day milestone and sum the rewards.
    if (milestones.isNotEmpty) {
      final totalXp = milestones.fold<int>(
        0,
        (sum, m) => sum + m.milestone.xpReward,
      );
      final totalScrolls = milestones.fold<int>(
        0,
        (sum, m) => sum + m.milestone.scrollReward,
      );
      final topMilestone = milestones.last;
      state = state.copyWith(
        streakMilestoneReached: true,
        streakMilestoneCount: topMilestone.milestone.days,
        streakMilestoneXp: totalXp,
        streakMilestoneScrolls: totalScrolls,
      );
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
      // No token charge here — discover is gated by daily caps, not tokens
      // (free: 1/day + warmup, premium: 30/day fair-use). Additional
      // muhasabahs go through the DailyCapSheet's 25-token AI bypass
      // (GatingService.bypassTokenCost) at the entry CTAs. Once we're
      // inside the flow, every step is free for the user.
      final collection = await getCardCollection();
      final card = pickNextCard(collection);
      final engageResult = await engageCard(card.id);

      CardEngageResult? cardResult;
      if (engageResult.tierChanged) {
        cardResult = engageResult;
      } else if (engageResult.isDuplicate) {
        try {
          await earnTokens(1, source: EconomyEventSource.streak);
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
      _prefetchDeeperReflection();

      // Save to history
      try {
        final today = debugDailyLoopClock();
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
        await _markStreakAndHandleMilestones();
      } catch (_) {}

      // Retention: the recurring core-loop DAU event (Home "Begin Muḥāsabah"
      // discover path). Powers D1/D7/D30 retention + habit-formation analysis.
      // Best-effort: a telemetry throw must never flip a completed check-in
      // into the error state below — the bypass wrapper reads `state.error` to
      // decide commit-vs-cancel, so an analytics failure here could otherwise
      // refund a bypass that actually succeeded.
      try {
        onAnalyticsEvent?.call(AnalyticsEvents.checkInCompleted, {
          'path': 'discover',
          'name': card.transliteration,
          'tier_changed': engageResult.tierChanged,
          'is_duplicate': engageResult.isDuplicate,
        });
      } catch (_) {}
    } catch (e) {
      debugPrint('[DISCOVER NAME ERROR] $e');
      state = state.copyWith(
          checkinLoading: false, error: 'Something went wrong. Try again.');
    }
  }

  /// Discover-name path funded by an AI bypass (token spend). Reserves on
  /// the server first; on success runs the same in-app card pick + engage
  /// flow as [discoverName], then commits. On any failure cancels the
  /// reservation so tokens are refunded.
  ///
  /// Discover-name has no observable AI-failure mode (it's a local card
  /// lookup), so in practice the cancel path is only hit when the reserve
  /// itself races a server-side state change. The retry surface is the
  /// muhasabah CTA — see plan 2026-05-23 line 304.
  ///
  /// Runs the real [discoverName] body, or the test-only override when one
  /// has been injected via the constructor seam. Centralized so both bypass
  /// wrappers share the same indirection point.
  Future<void> _runDiscoverName() {
    final override = _discoverNameOverride;
    if (override != null) return override(this);
    return discoverName();
  }

  Future<void> discoverNameWithBypass() async {
    if (state.checkinLoading || bypassInFlight) return;
    try {
      final reservation = await reserveActiveBypass();
      if (!mounted) return; // dispose chain owns cleanup
      if (reservation == null) {
        state = state.copyWith(error: 'Bypass unavailable. Try again.');
        return;
      }
      trackActiveBypassReservation(reservation.reservationId);
      await _runDiscoverName();
      if (!mounted) return; // dispose chain owns commit/cancel
      // discoverName() catches its own exceptions and surfaces them via
      // state.error, so we inspect state to decide commit-vs-cancel rather
      // than wrapping in try/catch. Local card lookup rarely fails — the
      // only realistic failure is a Supabase upsert (engageCard) timing out.
      if (state.error != null) {
        await cancelActiveBypassIfAny();
      } else {
        await commitActiveBypassIfAny();
      }
    } finally {
      // Unconditional: instance-field writes don't throw on disposed notifiers.
      clearBypassInFlight();
    }
  }

  /// Day-1 freebie variant (PR 4 of plan 2026-05-23, EXP-2). Atomic on
  /// the server with no token at stake — no commit/cancel flow. If the
  /// AI/upsert in [discoverName] fails after the claim succeeded, the
  /// user has consumed their global Day-1 freebie and falls back to
  /// paid bypass on retry. Intentional — see plan §EXP-2.
  Future<void> discoverNameWithFirstBypass() async {
    if (state.checkinLoading || bypassInFlight) return;
    // Flip the re-entry flag synchronously before the first await so a
    // rapid double-tap collapses to a single `claim_first_bypass` RPC.
    // The bypass-reserve path doesn't need this — `reserveActiveBypass`
    // flips the flag itself; the freebie path has no reserve call so we
    // arm it here directly.
    markBypassInFlight();
    try {
      final claimed =
          await GatingService().claimFirstBypass(GatedFeature.discoverName);
      if (!mounted) return;
      if (!claimed) {
        state = state.copyWith(error: 'Freebie unavailable. Try again.');
        return;
      }
      await _runDiscoverName();
      // After AI work: bail out if disposed mid-flight. `_runDiscoverName`
      // itself writes state.error on failure paths; we don't want to layer
      // additional writes on a torn-down notifier. The unconditional
      // `clearBypassInFlight()` in the finally below is safe post-dispose
      // (instance-field write, doesn't throw).
      if (!mounted) return;
    } finally {
      clearBypassInFlight();
    }
  }

  // ---------------------------------------------------------------------------
  // Step 1: Check-in (DEPRECATED multi-question flow)
  //
  // The launch overlay no longer renders question UI (the `_CheckInStep`
  // widget was removed 2026-04-26). The only remaining muhasabah path is
  // `discoverName()`. This `answerCheckin` is preserved as a reference
  // for the AI-context shape and for the latent re-entry-guard fix; delete
  // with the next muhasabah refactor unless a multi-question UI returns.
  // See finding 2026-04-26-launch-overlay-dead-checkinstep.md.
  // ---------------------------------------------------------------------------

  /// Called when the user taps an answer on any of the 4 check-in questions.
  /// Advances the question index until all 4 are answered, then calls the AI.
  ///
  /// Re-entry guard: returns early if a previous invocation is mid-flight on
  /// the final question (checkinLoading=true). Without this, two rapid taps
  /// on the final answer both pass `currentIndex == 3`, both run the AI/save
  /// path, and produce duplicate `user_checkin_history` rows + double streak
  /// marks. See finding 2026-04-26-answercheckin-no-reentry-guard.md.
  Future<void> answerCheckin(String answer) async {
    if (state.checkinLoading) return;
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
              await earnTokens(1, source: EconomyEventSource.streak);
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
      _prefetchDeeperReflection();

      // Save check-in to history
      try {
        final today = debugDailyLoopClock();
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
        await _markStreakAndHandleMilestones();
      } catch (_) {
        // Non-critical — don't fail the check-in
      }

      // Retention: same core-loop DAU event as the discover path, tagged with
      // `path: 'questionnaire'`.
      //
      // NOTE: `answerCheckin` is currently DORMANT — the launch overlay stopped
      // rendering the multi-question UI on 2026-04-26 (see this method's header
      // + 2026-04-26-launch-overlay-dead-checkinstep.md), so `discoverName` is
      // the only live muhasabah path today. In practice `check_in_completed`
      // therefore only emits `path: 'discover'`. This emit is retained so the
      // questionnaire path is instrumented the moment a multi-question UI ever
      // returns — do NOT build a dashboard assuming a non-empty `questionnaire`
      // bucket until then. Best-effort (see discover-path rationale above).
      try {
        onAnalyticsEvent?.call(AnalyticsEvents.checkInCompleted, {
          'path': 'questionnaire',
          // Cleaned name (same value shown in the UI), comparable to the
          // discover path's `card.transliteration`.
          'name': cleanName.isNotEmpty ? cleanName : result.name,
          'tier_changed': cardEngageResult?.tierChanged ?? false,
          'is_duplicate': cardEngageResult?.isDuplicate ?? false,
        });
      } catch (_) {}

      // Claim daily reward (idempotent — safe even if the launch overlay
      // already claimed today's reward.)
      try {
        final claimResult = await claimDailyReward();
        state = state.copyWith(
          rewardClaimResult: claimResult,
          tokenBalance: claimResult.newTokenBalance ?? state.tokenBalance,
        );
      } catch (_) {}

      await _persistTodayState();
    } catch (e) {
      state = state.copyWith(
        checkinLoading: false,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  /// Test seam — lets the re-entry-guard test put the notifier into a
  /// `checkinLoading=true` state without driving the full AI flow. Not
  /// callable from production code paths.
  @visibleForTesting
  void debugSetCheckinLoading(bool value) {
    state = state.copyWith(checkinLoading: value);
  }

  /// Test seam — lets the discover-name dispose/cancel suite synthesize a
  /// `state.error` from inside an injected `discoverNameOverride` closure
  /// without reaching into protected StateNotifier internals. Mirrors the
  /// branch the real `discoverName()` takes when its Supabase upsert fails.
  @visibleForTesting
  void debugSetError(String message) {
    state = state.copyWith(error: message);
  }

  /// Test seam — exposes `_handleXpAward` so the EconomyEvents XpGranted
  /// contract can be exercised without driving the full muhasabah/discovery
  /// flow. Production callsites all go through `_handleStreakMilestones`.
  @visibleForTesting
  Future<void> debugHandleXpAward(int amount) => _handleXpAward(amount);

  /// Test seam — sets streakMilestoneReached + the milestone counts directly
  /// on state, simulating the rising-edge that muhasabah_screen's ref.listen
  /// triggers off. Used by the race-ordering regression test to fire streak +
  /// level-up in the same tick without driving the full streak service flow.
  @visibleForTesting
  void debugSetStreakMilestone({
    required int streak,
    required int xp,
    required int scrolls,
  }) {
    state = state.copyWith(
      streakMilestoneReached: true,
      streakMilestoneCount: streak,
      streakMilestoneXp: xp,
      streakMilestoneScrolls: scrolls,
    );
  }

  /// Test seam — puts the notifier into a "completed muhasabah" shape so
  /// `resetToday` can be exercised without driving the full discoverName
  /// flow (which talks to Supabase + the card service). Used by
  /// `daily_loop_reset_today_test.dart` to pin the contract that resetToday
  /// clears every field initState's auto-trigger checks.
  @visibleForTesting
  void debugSetCheckinDoneForReset({
    required String checkinName,
    required String checkinNameArabic,
  }) {
    state = state.copyWith(
      checkinDone: true,
      checkinName: checkinName,
      checkinNameArabic: checkinNameArabic,
      currentStep: DailyLoopStep.completed,
    );
  }

  /// Reset today's daily loop so the user can redo it.
  Future<void> resetToday() async {
    _deeperReflectGeneration++;
    _deeperReflectFuture = null;
    _deeperReflectResult = null;
    _deeperReflectKey = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_todayKey);
    state = const DailyLoopState();
    await _initialize();
  }

  void clearStreakMilestone() {
    state = state.copyWith(
      streakMilestoneReached: false,
      streakMilestoneCount: 0,
      streakMilestoneXp: 0,
      streakMilestoneScrolls: 0,
    );
  }

  void clearStreakLapse() {
    state = state.copyWith(
      streakLapseRestorable: false,
      lapsePreLapseStreak: 0,
    );
    // Also clear the persisted lapse bookkeeping so a re-entry into muḥāsabah
    // on the SAME day (markActiveToday's already-active fast path returns the
    // cached pre-lapse) doesn't re-surface a rescue the user just dismissed.
    // The paid buy-back path already clears this cache inside repairStreakPaid.
    unawaited(clearLapseCache());
  }

  /// Restore the just-expired streak locally after a successful paid buy-back
  /// (the RPC already restored it server-side; this reflects it in the UI).
  void applyRestoredStreak(int restoredStreak) {
    state = state.copyWith(
      streakCount: restoredStreak,
      streakLapseRestorable: false,
      lapsePreLapseStreak: 0,
    );
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

  ({String key, String contextText, String forceName})? _deeperRequestFor(
    DailyLoopState source,
  ) {
    final forceName = source.checkinName?.trim();
    if (forceName == null || forceName.isEmpty) return null;

    final contextText = _deeperContextText(source);
    return (
      key: jsonEncode([forceName, contextText]),
      contextText: contextText,
      forceName: forceName,
    );
  }

  String _deeperContextText(DailyLoopState source) {
    if (source.checkinAnswers.isNotEmpty) {
      return source.checkinAnswers.join(' / ');
    }

    final card = source.engagedCard;
    if (card != null) {
      return [
        'The user just discovered ${card.transliteration} (${card.arabic}).',
        if (card.english.isNotEmpty) 'Meaning: ${card.english}.',
        if (card.lesson.isNotEmpty) 'Teaching shown: ${card.lesson}',
      ].join('\n');
    }

    final answer = source.checkinAnswer?.trim();
    if (answer != null && answer.isNotEmpty) {
      return "I answered '$answer'.";
    }

    return 'The user wants to go deeper with this Name of Allah.';
  }

  Future<ReflectResponse> _startDeeperReflectionRequest(
    ({String key, String contextText, String forceName}) request,
  ) {
    return reflectWithOpenAI(
      request.contextText,
      forceName: request.forceName,
    );
  }

  void _prefetchDeeperReflection() {
    final request = _deeperRequestFor(state);
    if (request == null) return;
    if (_deeperReflectKey == request.key &&
        (_deeperReflectResult != null || _deeperReflectFuture != null)) {
      return;
    }

    final generation = ++_deeperReflectGeneration;
    _deeperReflectKey = request.key;
    _deeperReflectResult = null;
    final future = _startDeeperReflectionRequest(request);
    _deeperReflectFuture = future;

    future.then(
      (result) {
        if (generation != _deeperReflectGeneration ||
            _deeperReflectKey != request.key) {
          return;
        }
        _deeperReflectResult = result;
        _deeperReflectFuture = null;
      },
      onError: (_) {
        if (generation != _deeperReflectGeneration ||
            _deeperReflectKey != request.key) {
          return;
        }
        _deeperReflectFuture = null;
      },
    );
  }

  Future<ReflectResponse> _loadDeeperReflection(
    ({String key, String contextText, String forceName}) request,
  ) async {
    if (_deeperReflectKey == request.key && _deeperReflectResult != null) {
      return _deeperReflectResult!;
    }

    if (_deeperReflectKey == request.key && _deeperReflectFuture != null) {
      return _deeperReflectFuture!;
    }

    _prefetchDeeperReflection();
    if (_deeperReflectKey == request.key && _deeperReflectFuture != null) {
      return _deeperReflectFuture!;
    }

    return _startDeeperReflectionRequest(request);
  }

  Future<void> startDeeper() async {
    final request = _deeperRequestFor(state);
    if (request == null) {
      state =
          state.copyWith(error: 'Could not load reflection. Please try again.');
      return;
    }

    if (_deeperReflectKey == request.key && _deeperReflectResult != null) {
      state = state.copyWith(
        currentStep: DailyLoopStep.deeper,
        reflectResult: _deeperReflectResult,
        reflectLoading: false,
        reflectStep: 1,
        error: null,
      );
      return;
    }

    // Always free. Additional muhasabahs are gated by daily caps (with a
    // 25-token bypass via DailyCapSheet) at the "Seek Another Name" /
    // "Discover a New Name" entry CTAs, so once the user is inside a
    // muhasabah cycle every step — the discover, the deeper reflection,
    // the dua — runs without any token gating.
    state = state.copyWith(
      currentStep: DailyLoopStep.deeper,
      reflectLoading: true,
      reflectStep: 1, // skip step 0 (name display) — user just saw it in gacha
      error: null,
    );

    try {
      final result = await _loadDeeperReflection(request);

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

  /// Completes the deeper flow in one step. The beat reveal flow owns per-beat
  /// stepping now and calls this once at "Ameen" — so quest/economy hooks fire
  /// exactly once. Mirrors the old [advanceReflectStep] step-3 branch:
  /// muḥāsabah is its own reward (no XP / tokens here), this only flips the
  /// lifecycle to completed and persists.
  Future<void> completeDeeper() async {
    if (state.currentStep == DailyLoopStep.completed) return; // idempotent
    state = state.copyWith(
      deeperDone: true,
      questDone: true,
      currentStep: DailyLoopStep.completed,
    );
    await _persistTodayState();
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

      if (checkinDone && !deeperDone) {
        _prefetchDeeperReflection();
      }
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
