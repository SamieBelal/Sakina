import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/constants/daily_questions.dart';
import 'package:sakina/core/constants/duas.dart';
// The chip taxonomy, not the hook screen: `problem_chips.dart` is pure content
// (the seven chips and the free-text keyword map) with no widget or provider
// behind it, and reusing it is what keeps the daily answer's `problem_category`
// comparable with `acquisition_promise.problem_category` instead of forking a
// second vocabulary (plan §9 guardrails).
import 'package:sakina/features/onboarding/content/problem_chips.dart';
import 'package:sakina/models/name_story_deck.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/bypass_flow_mixin.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/checkin_history_service.dart';
import 'package:sakina/services/cosmetics_service.dart';
// `charCountBucket` — bucketed answer length. The verbatim answer never leaves
// the device (W4 Wave 7); see the privacy note in that file.
import 'package:sakina/services/daily_question_analytics.dart';
import 'package:sakina/services/daily_question_gate.dart';
import 'package:sakina/services/daily_rewards_service.dart';
import 'package:sakina/services/daily_usage_service.dart' as daily_usage;
import 'package:sakina/services/economy_events.dart';
import 'package:sakina/services/gating_service.dart';
// Re-exports `launch_gate_state.dart`, which is where `markDailyLaunchShown`
// actually lives — see the cycle note in `launch_gate_service.dart`.
import 'package:sakina/services/launch_gate_service.dart';
import 'package:sakina/services/name_queue_cache.dart';
import 'package:sakina/services/name_queue_planner.dart';
import 'package:sakina/services/name_queue_service.dart';
import 'package:sakina/services/name_stories_service.dart';
import 'package:sakina/services/streak_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:sakina/services/widget_sync.dart';
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

/// [DailyLoopState.revealSource] values. Wire strings, not an enum, because they
/// go straight out as the `name_source` analytics prop.
const String revealSourceQueue = 'queue';
const String revealSourceGacha = 'gacha';

/// [DailyLoopState.checkinInputMode] values — how the day's answer was given.
/// Wire strings for the same reason as [revealSourceQueue]: Wave 7 sends them
/// out verbatim as `input_mode`, and they round-trip through the day blob, so an
/// unrecognised value read back from another build has to degrade rather than
/// fail a parse.
const String inputModeTyped = 'typed';
const String inputModeChip = 'chip';

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

  /// The chip taxonomy's reading of today's answer — a [ProblemChip.problemCategory]
  /// or [problemCategoryUnmatched]. Derived at submit (W4 Wave 3) by the same
  /// pure keyword map the onboarding hook screen uses, so a typed sentence
  /// segments identically to the chip it would have tapped and `problem_category`
  /// stays comparable with `acquisition_promise.problem_category`.
  ///
  /// Null until the user answers, and on every legacy path (`answerCheckin`, a
  /// re-roll, a restored pre-W4 day blob).
  final String? checkinProblemCategory;

  /// [inputModeTyped] or [inputModeChip] — whether today's answer was written or
  /// tapped. Held for Wave 7's `input_mode`; nothing reads it yet.
  final String? checkinInputMode;

  /// Which try at answering today's question this is — 1 for the first, 2+
  /// after an off-topic re-ask. Zero before the user has answered at all.
  final int checkinAttempt;

  /// The user's answer came back off-topic and they have been invited to
  /// rephrase (W4 Wave 3 follow-up).
  ///
  /// The ONE state in which the question surface is shown again while
  /// [checkinDone] is true. It is what lets the re-ask reuse the reveal instead
  /// of running a second one: `_showsQuestion` admits the question, and
  /// [DailyLoopNotifier.submitDailyAnswer] re-runs only the reflection.
  ///
  /// Persisted, and that is not incidental — a force-quit while the user is
  /// rephrasing must come back to the question, not to a second reveal that
  /// would spend another queue position and teach a different Name.
  final bool awaitingReAnswer;

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

  // ------------------------------------------------------------------
  // Queue-driven reveal (W3 §3e). [revealSource], [revealQueuePosition] and the
  // revealed Name's id round-trip through the `daily_loop_$date` blob, so a cold
  // restart mid-flow resumes the same reveal instead of running a second one.
  // The deck itself is not persisted — it is bundled content, so the id is the
  // only durable part and re-resolving is a local asset read.
  // ------------------------------------------------------------------

  /// [revealSourceQueue] when today's Name came from `user_name_queue`,
  /// [revealSourceGacha] when it came from `pickNextCard`. Drives copy register
  /// and the analytics props Wave 5 adds.
  ///
  /// Wire strings rather than an enum for two reasons: they go straight out as
  /// the `name_source` analytics prop, and — the stronger one — they are a
  /// **persisted prefs format**, so an unrecognised value read back from an older
  /// or newer build has to degrade safely rather than fail a parse.
  final String revealSource;

  /// The queue position (1-7) behind the reveal, or null on a gacha reveal.
  final int? revealQueuePosition;

  /// The pre-authored deck for the revealed Name, when one exists. Only
  /// positions 1-2 have approved decks today; 3-7 fall through to the AI
  /// reflection. Non-null only on a queue-driven reveal (§4) — a legacy user who
  /// gachas into a decked Name still gets exactly today's experience.
  ///
  /// When set, the reveal has NO OpenAI dependency at all: `discoverName` skips
  /// the prefetch, `startDeeper` skips the request, and the beat flow renders
  /// `buildBeatScreensFromDeck` instead of a [ReflectResponse].
  final NameStoryDeck? revealDeck;

  /// How many positions are still sealed. Lets the home CTA subtitle (Wave 4)
  /// render without a second fetch.
  final int queueSealedRemaining;

  // Daily reward
  final DailyRewardClaimResult? rewardClaimResult;

  /// Non-null for exactly one state transition after the reveal that decremented
  /// this user's discover-name warmup budget from 1 to 0. The screen layer
  /// (`muhasabah_screen`) fires [WarmupExhaustedSheet] on the rising edge and
  /// then calls [DailyLoopNotifier.dismissWarmupExhausted].
  ///
  /// This exists because W4 Wave 1 moved `markUsed` off the CTA and into
  /// [DailyLoopNotifier.discoverName]: the `UsageOutcome` that used to be
  /// returned straight to a widget now has to travel back out through state.
  /// Mirrors `DuasState.buildWarmupJustExhausted`, which solves the identical
  /// problem for build-a-dua.
  final GatedFeature? warmupJustExhausted;

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
    this.checkinProblemCategory,
    this.checkinInputMode,
    this.checkinAttempt = 0,
    this.awaitingReAnswer = false,
    this.reflectResult,
    this.reflectStep = 0,
    this.reflectLoading = false,
    this.questDua,
    this.questReason,
    this.cardEngageResult,
    this.engagedCard,
    this.revealSource = revealSourceGacha,
    this.revealQueuePosition,
    this.revealDeck,
    this.queueSealedRemaining = 0,
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
    this.warmupJustExhausted,
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
    String? checkinProblemCategory,
    String? checkinInputMode,
    int? checkinAttempt,
    bool? awaitingReAnswer,
    ReflectResponse? reflectResult,

    /// Explicit clear for [DailyLoopState.reflectResult] — the `?? this.x`
    /// merge cannot express "back to null", and the off-topic re-ask has to,
    /// or the stale off-topic response outlives the answer that produced it and
    /// the user meets it again the moment they re-enter from home.
    ///
    /// Deliberately NOT the same treatment for `error`: that field's merge
    /// semantics are being fixed in their own commit (see the follow-up task),
    /// and two agents changing `copyWith`'s semantics in sequence is how the
    /// subtle version of that bug ships.
    bool clearReflectResult = false,
    int? reflectStep,
    bool? reflectLoading,
    BrowseDua? questDua,
    String? questReason,
    CardEngageResult? cardEngageResult,
    CollectibleName? engagedCard,
    String? revealSource,
    int? revealQueuePosition,
    NameStoryDeck? revealDeck,
    int? queueSealedRemaining,

    /// Set only by the reveal write in [DailyLoopNotifier.discoverName], which
    /// specifies all reveal fields at once. Without it the `?? this.x` merge
    /// would leave a stale `revealQueuePosition` on a subsequent same-day gacha
    /// reveal (premium 30/day fair-use), mislabelling it in analytics. Every
    /// other `copyWith` caller leaves it false and the reveal fields survive —
    /// which they must, because Wave 3's deck has to live from the reveal write
    /// until `DailyLoopStep.deeper` renders.
    bool resetReveal = false,
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
    GatedFeature? warmupJustExhausted,

    /// Explicit clear for [DailyLoopState.warmupJustExhausted] — the `?? this.x`
    /// merge cannot express "back to null", and a sticky flag would re-fire the
    /// sheet on the next rising edge the screen observes.
    bool clearWarmupJustExhausted = false,
    String? error,

    /// Explicit clear for [DailyLoopState.error], matching
    /// [clearReflectResult]'s shape rather than inventing a second convention.
    ///
    /// **`error` used to be ASSIGNED rather than merged**, so every state write
    /// that did not name it silently wiped an error already set. The visible
    /// symptom was a failure view vanishing; the expensive one was that
    /// `discoverNameWithBypass` reads `state.error` to decide commit-versus-
    /// cancel, so a cleared error told it to **commit a bypass for a reveal
    /// that never happened** — the user pays 25 tokens and gets nothing. Wave 3
    /// patched the one racing write it had found (`_claimDailyRewardAtSubmit`)
    /// by passing `error: state.error` through; this makes the whole class
    /// impossible instead of that one instance.
    ///
    /// Every write that genuinely means "clear it" now says so, and there are
    /// only five: `discoverName` and the dormant `answerCheckin` at entry, and
    /// the three `startDeeper` paths. All five are "a new attempt is starting,
    /// or the thing that failed has now succeeded" — which is also why a stale
    /// error cannot get stuck on screen: every path that can set one has a
    /// retry that explicitly clears it.
    bool clearError = false,
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
      checkinProblemCategory:
          checkinProblemCategory ?? this.checkinProblemCategory,
      checkinInputMode: checkinInputMode ?? this.checkinInputMode,
      checkinAttempt: checkinAttempt ?? this.checkinAttempt,
      awaitingReAnswer: awaitingReAnswer ?? this.awaitingReAnswer,
      reflectResult:
          clearReflectResult ? null : (reflectResult ?? this.reflectResult),
      reflectStep: reflectStep ?? this.reflectStep,
      reflectLoading: reflectLoading ?? this.reflectLoading,
      questDua: questDua ?? this.questDua,
      questReason: questReason ?? this.questReason,
      // Cleared by `resetReveal` along with the other per-reveal fields. It used
      // to merge unconditionally, which made it write-once-sticky: `discoverName`
      // passes null on a duplicate engage, null merged to the PREVIOUS reveal's
      // result, and any consumer asking "did a card appear THIS time?" got yes.
      // The overlay push survived that because it compares with
      // `!identical(prev, next)`, but the deck's meaning-suppression had no such
      // guard and would have hidden the meaning on a reveal that showed no card.
      cardEngageResult: resetReveal
          ? cardEngageResult
          : (cardEngageResult ?? this.cardEngageResult),
      engagedCard: engagedCard ?? this.engagedCard,
      revealSource: resetReveal
          ? (revealSource ?? revealSourceGacha)
          : (revealSource ?? this.revealSource),
      revealQueuePosition: resetReveal
          ? revealQueuePosition
          : (revealQueuePosition ?? this.revealQueuePosition),
      revealDeck: resetReveal ? revealDeck : (revealDeck ?? this.revealDeck),
      queueSealedRemaining: queueSealedRemaining ?? this.queueSealedRemaining,
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
      warmupJustExhausted: clearWarmupJustExhausted
          ? null
          : (warmupJustExhausted ?? this.warmupJustExhausted),
      error: clearError ? null : (error ?? this.error),
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
    /// When true, skips [_initialize] (and the EconomyEvents subscription).
    /// ONLY for widget tests that pump the sheet and don't need real state.
    @visibleForTesting bool skipInitForTests = false,

    /// Injectable so queue tests can drive the RLS select and the unseal RPC
    /// without a Supabase client. Production leaves it null and gets a service
    /// whose uid comes from [supabaseSyncService], matching every other write
    /// path in this notifier.
    @visibleForTesting NameQueueService? nameQueueService,

    /// Injectable so deck-reveal tests can drive the asset read. Production
    /// leaves it null and shares the process-wide instance, whose parse is
    /// cached for the app's lifetime.
    @visibleForTesting NameStoriesService? storiesService,
  })  : _discoverNameOverride = discoverNameOverride,
        _stories = storiesService ?? nameStoriesService,
        _nameQueue = nameQueueService ??
            NameQueueService(
              currentUserId: () => supabaseSyncService.currentUserId,
            ),
        super(const DailyLoopState()) {
    if (skipInitForTests) return;
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

  /// The attempt whose off-topic rejection has already been reported. Keyed on
  /// the attempt rather than a bool so a rephrase that is ALSO rejected counts
  /// again — a user rejected twice is the case worth seeing.
  int? _offTopicReportedAttempt;

  /// Test-only seam for [discoverName]. When non-null, the bypass wrappers
  /// ([discoverNameWithBypass], [discoverNameWithFirstBypass]) invoke this
  /// instead of the real `discoverName()` work, letting tests inject a
  /// Completer-backed stub that succeeds, fails, or hangs deterministically
  /// without driving the full Supabase + card-service surface. Production
  /// callers leave it null and get the real implementation.
  final Future<void> Function(DailyLoopNotifier self)? _discoverNameOverride;
  final NameQueueService _nameQueue;
  final NameStoriesService _stories;

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

  /// The queue rows to plan today's reveal from: the authoritative RLS select
  /// when it's reachable, the advisory prefs mirror when it isn't.
  ///
  /// A network failure here must NOT fail the reveal — that is what the mirror is
  /// for (§5 "Offline with a cached queue"). It also cannot *cause* an unseal: the
  /// rows only feed the planner, and only `unseal_next_name` moves a position. A
  /// user with no rows in either place is `QueueAbsent`, i.e. today's exact path.
  Future<List<NameQueueRow>> _resolveQueueRows() async {
    try {
      final rows = await _nameQueue.queue();
      await writeCachedNameQueue(rows);
      return rows;
    } catch (_) {
      try {
        return await readCachedNameQueue();
      } catch (_) {
        return const [];
      }
    }
  }

  /// Sealed positions left after this reveal, for the Wave 4 home CTA subtitle.
  /// [justUnsealed] is folded in because [rows] is the pre-unseal view.
  int _sealedRemainingAfter(
    List<NameQueueRow> rows,
    NameQueueRow? justUnsealed,
  ) {
    if (rows.isEmpty) return 0;
    return rows
        .where((row) => row.isSealed && row.position != justUnsealed?.position)
        .length;
  }

  /// The in-flight submit-time reward claim, so tests can await a call this
  /// function deliberately does not await. Production never reads it.
  @visibleForTesting
  Future<void>? dailyRewardClaimFuture;

  /// The user's answer to the day's question (W4 Wave 3 — plan §5, spec M1/M3).
  ///
  /// [text] is what the user wrote, or the chip's label verbatim when they
  /// tapped one; [chipKey] is set only on a tap. Everything the loop needs from
  /// the answer is derived here and then the ordinary [discoverName] runs
  /// unchanged — no new AI plumbing, because there was none to add: the answer
  /// lands in `checkinAnswers`, which `_deeperContextText` already prefers over
  /// the card blurb, while `_deeperRequestFor` already pins `forceName` to the
  /// Name the queue chose. So the reflection comes back written about the user's
  /// own words, against the Name W3 promised them.
  ///
  /// **THE REVEAL MUST NEVER BLOCK ON THE AI, and that is why this method awaits
  /// so little.** The April 2026 commit removed the 4-question check-in precisely
  /// to swap an OpenAI round-trip for an instant local picker; putting a question
  /// back in front of the reveal reintroduces the same risk, and the mitigation
  /// is that the card plays *over* the call. `_prefetchDeeperReflection()` is
  /// fire-and-forget inside `discoverName`, and nothing here may add an `await`
  /// between the submit and the reveal.
  ///
  /// **The reward is claimed HERE, at submit — not at "Ameen"** (spec §6,
  /// DECISION 1). `claim_daily_reward` is a 7-day escalating ladder that resets
  /// to day 0 on a single missed claim, so tying the grant to the last tap of the
  /// beat flow would cost a day-6 user their ladder for not tapping through every
  /// beat. Only the *grant* moves in this wave; the animated ceremony follows the
  /// work (Wave 4). It is deliberately NOT awaited: it is a Supabase round-trip,
  /// and awaiting it would put a network hop between the user's answer and their
  /// card for no benefit — the claim is idempotent and server-authoritative, so
  /// it can land whenever it lands.
  ///
  /// **A re-ask after an off-topic answer runs the same method and reveals
  /// nothing.** [awaitingReAnswer] is the only state in which a submit is
  /// accepted while [DailyLoopState.checkinDone] is true, and in it the reveal
  /// is skipped entirely: the card, the Name, the streak and the reward are all
  /// already the user's, and only the reflection is retried. That is what makes
  /// "rephrase" cost nothing — no second `discoverName`, no second queue
  /// position, no second charge, no second claim.
  Future<void> submitDailyAnswer(String text, {String? chipKey}) async {
    final answer = text.trim();
    // Empty input never becomes an answer: it would be persisted as the day's
    // reflection context and would drive the AI with nothing. The question
    // surface already blocks it; this is the provider-side floor.
    if (answer.isEmpty) return;
    // Re-entry guard, and the reason the claim below fires exactly once per
    // submit. `discoverName` sets `checkinLoading` synchronously before its
    // first await, so a second call landing after this one has started sees it
    // set; `checkinDone` covers a stale submit arriving after the day is done —
    // EXCEPT during an off-topic re-ask, which is the one legitimate way to
    // answer a day that is already revealed.
    final isReAnswer = state.awaitingReAnswer;
    if (state.checkinLoading) return;
    if (state.checkinDone && !isReAnswer) return;

    state = state.copyWith(
      // Single-element, REPLACING rather than appending: this is one question
      // with one answer, unlike the dormant 4-question `answerCheckin` that
      // accumulated. Persisted by `_persistTodayState` and restored by
      // `_loadTodayState` with no change, so it survives a cold restart.
      checkinAnswers: [answer],
      checkinProblemCategory: _problemCategoryFor(answer, chipKey),
      checkinInputMode: chipKey == null ? inputModeTyped : inputModeChip,
      checkinAttempt: state.checkinAttempt + 1,
      // Consumed. A second off-topic result sets it again (see
      // [reopenQuestionAfterOffTopic]); leaving it set here would let the next
      // ordinary submit skip its reveal.
      awaitingReAnswer: false,
    );

    // The middle of the within-wave funnel (W4 Wave 7). Emitted HERE and not
    // from the question surface because this is where `problem_category` and
    // `input_mode` were just derived — deriving them a second time up in the
    // widget would fork the taxonomy the moment either side changed.
    //
    // **`answer.length`, never `answer`.** The user's words about what is on
    // their heart do not go to Mixpanel: not as a property, not truncated, not
    // hashed, and not in an error payload. What leaves the device is a bucket
    // and a chip category. `charCountBucket` takes an int precisely so that
    // there is no overload of it a careless refactor could hand the String to.
    //
    // Best-effort, for the same reason the `check_in_completed` emit below is:
    // a telemetry throw here would escape into `discoverName`'s caller and,
    // through `state.error`, refund a bypass for a reveal that happened.
    //
    // `attempt` added by the Wave 3 off-topic follow-up — a DIMENSION on this
    // event, deliberately not a `daily_question_re_asked` event of its own.
    // The funnel is shown → answered → completed; a new event at step two would
    // fork it, and every segment built on the original would silently
    // under-count the people who had to try twice.
    try {
      onAnalyticsEvent?.call(AnalyticsEvents.dailyQuestionAnswered, {
        AnalyticsEvents.propProblemCategory: state.checkinProblemCategory,
        AnalyticsEvents.propInputMode: state.checkinInputMode,
        AnalyticsEvents.propCharCountBucket: charCountBucket(answer.length),
        AnalyticsEvents.propAttempt: state.checkinAttempt,
      });
    } catch (_) {}

    // A re-ask stops here. The reveal already happened on attempt 1 and the
    // reward was claimed with it, so all that is owed is a fresh reflection
    // against the SAME Name — `_deeperRequestFor` still pins `forceName` to
    // `checkinName`, so the rephrased answer cannot change which Name the user
    // is taught, only what is said about it.
    if (isReAnswer) {
      await _persistTodayState();
      await startDeeper();
      return;
    }

    dailyRewardClaimFuture = _claimDailyRewardAtSubmit();

    await discoverName();
  }

  /// Invite the user to rephrase after the classifier rejected their answer
  /// (W4 Wave 3 follow-up).
  ///
  /// The off-topic response is the DEMO response — a different Name than the
  /// one the card just showed — so it can never be rendered as the day's
  /// reflection. Before this existed the off-topic view offered only "Return
  /// home", which made a misclassification terminal for the day and, because
  /// the rejected result stayed cached, met the user again the moment they
  /// re-entered from home. Both halves of that are fixed here.
  ///
  /// **Nothing the user has earned is given back.** The card, the tier, the
  /// streak day and the reward all stand; only the reflection is retried.
  Future<void> reopenQuestionAfterOffTopic() async {
    // Idempotent, and narrow on purpose: this is reachable only from the
    // off-topic view, and re-entering the question from any other state would
    // be the phantom-second-gacha bug class this screen is built around.
    if (state.reflectResult?.offTopic != true) return;

    // Drop the rejected reflection AND its cache. Bumping the generation is
    // what makes an in-flight request for the old answer land on the floor
    // instead of overwriting the new one.
    _deeperReflectGeneration++;
    _deeperReflectFuture = null;
    _deeperReflectResult = null;
    _deeperReflectKey = null;

    state = state.copyWith(
      // Back to the question. `checkinDone` deliberately stays true — the
      // reveal happened and must not happen again; `awaitingReAnswer` is what
      // tells `_showsQuestion` to make an exception for it.
      awaitingReAnswer: true,
      currentStep: DailyLoopStep.checkin,
      clearReflectResult: true,
      reflectLoading: false,
      reflectStep: 0,
    );
    await _persistTodayState();
  }

  /// Reports that the classifier rejected this attempt, at most once per
  /// attempt.
  ///
  /// **The known limit, recorded rather than papered over:** the latch is
  /// in-memory, so a cold restart that re-requests the same off-topic answer
  /// emits a second time for one answer. Persisting it would buy exact
  /// per-answer counts at the cost of another field whose only job is metric
  /// hygiene, and the distortion is smaller than the one Wave 7 already
  /// documents for `daily_question_abandoned`. Read the rate as an upper bound.
  void _noteOffTopic(ReflectResponse result) {
    if (!result.offTopic) return;
    if (_offTopicReportedAttempt == state.checkinAttempt) return;
    _offTopicReportedAttempt = state.checkinAttempt;
    try {
      onAnalyticsEvent?.call(AnalyticsEvents.dailyQuestionOffTopic, {
        AnalyticsEvents.propAttempt: state.checkinAttempt,
      });
    } catch (_) {}
  }

  /// The chip taxonomy's reading of an answer.
  ///
  /// A tap is authoritative — its own key is used rather than re-deriving from
  /// the label, which matters for the sign chip ("I can't put it into words"),
  /// whose wording deliberately contains no keyword and would otherwise come
  /// back `unmatched` instead of `unspoken`.
  ///
  /// Typed text goes through [matchChipKeyForText] — the same pure, offline
  /// keyword map the onboarding hook screen uses. `ProblemChipResolver` is
  /// deliberately NOT used: its extra work is resolving the Name *pair* from the
  /// story-deck asset, and on this path the queue picks the Name (spec M3), so
  /// that would be an asset read between the answer and the reveal for a value
  /// nothing consumes. When the answer starts picking the Name — post-queue,
  /// behind the kill switch — the resolver is what to reach for.
  String _problemCategoryFor(String answer, String? chipKey) {
    final chip = chipKey == null
        ? problemChipsByKey[matchChipKeyForText(answer)]
        : problemChipsByKey[chipKey];
    return chip?.problemCategory ?? problemCategoryUnmatched;
  }

  /// Best-effort, and idempotent on the server. A claim failure must not touch
  /// `state.error`: that field is what `discoverNameWithBypass` reads to decide
  /// commit-versus-refund, so a reward hiccup could otherwise refund a bypass
  /// whose reveal genuinely happened. Same rule as the analytics emit and the
  /// `markUsed` block inside [discoverName].
  Future<void> _claimDailyRewardAtSubmit() async {
    try {
      final claimResult = await claimDailyReward();
      // W4 Wave 7. The whole reason this event exists is that the claim MOVED
      // in this wave — from opening the app to answering the question — and
      // "the reward is now granted at submit" should be readable in the data
      // rather than inferred from the absence of something else.
      //
      // Gated on `!alreadyClaimed` so it counts grants, not calls: the claim is
      // idempotent and server-authoritative, and an idempotent replay (a second
      // submit, a cross-device race) hands back the same ladder state without
      // granting anything. Counting those would inflate the claim rate exactly
      // where we are trying to see whether the re-timing preserved it.
      //
      // Emitted BEFORE the `mounted` check on purpose: the grant happened on
      // the server whether or not the user is still on this route, and dropping
      // it for a user who navigated away would bias the metric toward the
      // people who stayed.
      if (!claimResult.alreadyClaimed) {
        try {
          onAnalyticsEvent?.call(AnalyticsEvents.dailyRewardClaimed, {
            AnalyticsEvents.propTrigger: AnalyticsEvents.triggerAnswerSubmit,
            // The ladder position this claim landed on (1-7). The whole reason
            // the claim moved to answer-submit was to PROTECT this ladder —
            // `claim_daily_reward` resets to day 0 on a single missed claim, so
            // tying the grant to "Ameen" would have cost a day-6 user theirs.
            // Without the field we would be trusting that decision with the
            // data sitting right there unrecorded: a healthy re-timing shows
            // users climbing to 6 and 7, a broken one shows everyone stuck at
            // 1. Not sensitive — a position in a 7-day cycle, nothing about
            // what the user said.
            AnalyticsEvents.propLadderDay: claimResult.day,
          });
        } catch (_) {}
      }
      // The claim outlives no state it owns, but it does outlive the notifier
      // if the user leaves the route mid-flight — and a write to a disposed
      // StateNotifier throws.
      if (!mounted) return;
      // No `error:` passthrough any more. This write is deliberately racing
      // `discoverName` and can land after its catch block, so clearing the
      // error here would wipe the failure view out from under the user and —
      // the case that actually costs money — tell `discoverNameWithBypass` to
      // commit a bypass for a reveal that never happened. It used to need an
      // explicit `error: state.error` to avoid that, because `copyWith`
      // ASSIGNED the field. `copyWith` now merges it like every other field, so
      // preserving it is the default and the guard is structural rather than
      // something each racing caller has to remember.
      state = state.copyWith(
        rewardClaimResult: claimResult,
        tokenBalance: claimResult.newTokenBalance ?? state.tokenBalance,
      );
    } catch (_) {
      // Nothing the user can act on, and nothing is lost: the ladder is
      // server-side and the next claim re-reads it.
    }
  }

  /// Picks today's Name and engages it. No AI call, no questions. The UI shows
  /// the gacha animation.
  ///
  /// Which Name comes from `user_name_queue` when the user has one (W3 §3b):
  /// `pickNextCard` stops deciding *who* and becomes the fallback. A user with no
  /// queue rows — every legacy user, and every kill-switch-reverted user — runs
  /// this function's original path with an empty `exclude` set.
  ///
  /// What the reveal then RENDERS is decided here too (§4): a queue-driven Name
  /// with an approved story deck parks it in `state.revealDeck` and the AI
  /// prefetch is skipped entirely; everything else keeps the AI reflection with
  /// the Name forced.
  ///
  /// **Consumption (W4 Wave 1).** This function owns `GatingService.markUsed`.
  /// It used to fire at the CTA, before navigation — which was survivable while
  /// the tap led straight to the reveal, and stops being survivable the moment a
  /// question sits between the two: opening the prompt and backing out would
  /// burn the user's one free reveal for the day. `canUse` stays at the CTA (a
  /// capped user must be told BEFORE being asked to disclose anything); the
  /// charge happens here, at the tail, only once a Name has actually been
  /// engaged. See plan `2026-07-30-one-ship-04-daily-loop-restructure.md` §3 and
  /// spec §8.
  ///
  /// **The day's first reveal is free and unmetered; only re-rolls are metered.**
  /// This preserves the pre-W4 shape rather than inventing one — "Begin
  /// Muḥāsabah" never gated or charged, so a free user past warmup has always
  /// had one unmetered daily reveal plus one metered re-roll. The marker lives
  /// in `daily_usage_service` alongside the cap counters.
  ///
  /// [consumeFreeUsage] is false on the two bypass paths, mirroring
  /// `DuasNotifier._doBuild` and `ReflectNotifier._doSubmit`: the
  /// `reserve_ai_bypass` / `claim_first_bypass` RPCs already increment the
  /// daily-uses row server-side, and warmup is a pre-bypass mechanic. Marking
  /// again there would double-count.
  ///
  /// [isPremiumHint] lets a caller that already resolved premium for its `canUse`
  /// check hand the answer down, keeping the whole tap to one RevenueCat
  /// round-trip.
  Future<void> discoverName({
    bool consumeFreeUsage = true,
    bool? isPremiumHint,
  }) async {
    // Re-entry guard, and now a *charging* guard. `checkinLoading` is the same
    // in-flight signal the muhasabah screen's one-shot post-frame trigger and
    // both bypass wrappers already read, so this adds no new concept — but with
    // `markUsed` living in here it is what makes a double-tap consume once even
    // if a caller's own synchronous guard (`_discoverInFlight` on the two CTAs)
    // is ever bypassed or forgotten. Set synchronously below, before any await.
    if (state.checkinLoading) return;
    state = state.copyWith(checkinLoading: true, clearError: true);

    try {
      // No token charge here — discover is gated by daily caps, not tokens
      // (free: 1/day + warmup, premium: 30/day fair-use). Additional
      // muhasabahs go through the DailyCapSheet's 25-token AI bypass
      // (GatingService.bypassTokenCost) at the entry CTAs. Once we're
      // inside the flow, every step is free for the user.
      final collection = await getCardCollection();
      final maxTier = await premiumTierCeiling();

      final queueRows = await _resolveQueueRows();
      final localDay = await resolveUserLocalDay(clock: debugDailyLoopClock);
      final plan = planQueueReveal(
        queue: queueRows,
        discoveredIds: collection.discoveredIds,
        nowUtc: debugDailyLoopClock(),
        localToday: localDay.day,
        localUtcOffset: localDay.utcOffset,
      );

      // The unseal RPC runs BEFORE engageCard, so nothing is ever granted for a
      // reveal that then fails to resolve a Name. It is deliberately inside this
      // function's existing `try`: `unsealNext()` lets errors propagate (see its
      // dartdoc) and this is the single place that catches them, so a failure
      // lands in state.error and the bypass wrappers refund correctly — the
      // reveal genuinely did not happen. See §5 for what the user sees.
      NameQueueRow? queueRow;
      switch (plan) {
        case QueueUnseal():
          // A null result means another device drained the queue between the
          // advisory read and this call. Treat as exhausted and pull normally —
          // the user sees a reveal, not an error.
          final rpcRow = await _nameQueue.unsealNext();
          if (rpcRow == null) {
            queueRow = null;
          } else {
            // A non-null result is NOT proof that a position moved. Inside its
            // 20h floor `unseal_next_name` returns the row it last unsealed
            // rather than null, so the server can answer this call by holding.
            //
            // The guard looks redundant against the planner, which is supposed
            // to keep us out of that branch. It isn't, because the two sides
            // read different clocks: the planner mirrors the floor from the
            // DEVICE clock (`debugDailyLoopClock`) against a possibly stale
            // cache, while the RPC re-derives it from the server clock. They
            // disagree on ordinary drift at the floor's edge, after a failed
            // authoritative read leaves the mirror behind, and — the case that
            // matters — when a user sets their device clock forward on purpose.
            // There the server is correctly refusing, and an unguarded client
            // rewards the attempt: `queueCard` resolves to the D0 Name,
            // `deckForName` re-serves its deck, and `engageCard(floorTier: 2)`
            // tiers up a card they already own, all reported as
            // `queue_position: 1`.
            //
            // "Not new" needs BOTH halves, and each without the other is wrong:
            //
            //  * already unsealed in the pre-call view — we knew about this
            //    position before we asked, so the RPC did not advance it. On its
            //    own this would also discard a held row whose Name was never
            //    met, and that row is a promise still owed: teaching it is the
            //    QueueResume recovery, so it must survive.
            //  * its Name is already in the collection — nothing left to teach.
            //    On its own this would discard a GENUINE unseal of a Name the
            //    user happens to already own, which is reachable: when the
            //    mirror is unavailable the ordinary pull runs with an empty
            //    `sealedQueueNameIds` and can hand over a still-sealed Name.
            //    That case is a re-encounter, and re-encounter tier-up is
            //    deliberate behaviour (see queue_reveal_tier_floor_test).
            //
            // Read from the pre-call view, before the merge below rewrites it.
            final serverHeld = queueRows.any((row) =>
                    row.position == rpcRow.position && !row.isSealed) &&
                collection.discoveredIds.contains(rpcRow.nameId);

            // Merged either way: the row IS unsealed server-side, so writing it
            // to the mirror is what makes the next plan agree with the server
            // instead of asking again.
            try {
              await mergeCachedNameQueueRow(rpcRow);
            } catch (_) {}

            // Falling through to the ordinary pull is exactly what QueueHold
            // produces, which is the honest outcome: no position moved today.
            queueRow = serverHeld ? null : rpcRow;
          }
        case QueueResume(:final row):
          // The RPC already consumed this position on an earlier attempt today;
          // re-present it rather than asking again, which would skip the Name.
          queueRow = row;
        case QueueHold():
        case QueueExhausted():
        case QueueAbsent():
          queueRow = null;
      }

      CollectibleName? queueCard;
      if (queueRow != null) {
        queueCard = findCollectibleById(queueRow.nameId);
        if (queueCard == null) {
          // The position is spent but its Name isn't in the catalog. Fail rather
          // than silently substituting a random Name: state.error refunds any
          // bypass, and the RPC's per-local-day idempotence means a retry returns
          // this same row instead of burning another position.
          // The position is spent but its Name isn't in the catalog — a bad seed,
          // or a server-side catalog shrink (`engageCard` already contemplates
          // one). Throwing here bricked the whole local day rather than costing
          // one reveal: the unseal has committed, so every retry re-plans to
          // QueueResume for this same row and re-throws, and `discoverName`
          // cannot succeed again until the 20h floor clears and rule 5 advances
          // past the position — losing the user's muḥāsabah AND their streak for
          // the day, burning a cap or a bypass on each attempt.
          //
          // So: never substitute a random Name for a *resolvable* queue row, but
          // don't brick the loop for an unresolvable one. Fall through to the
          // ordinary pull as an honest gacha reveal — no Silver floor, no deck,
          // `revealSource` 'gacha'. The position is already spent either way, and
          // a degraded reveal beats no reveal plus a broken streak.
          debugPrint(
            '[DISCOVER] queue position ${queueRow.position} points at unknown '
            'name_id ${queueRow.nameId} — falling through to an ordinary pull',
          );
          queueRow = null;
        }
      }

      final queueDriven = queueCard != null;

      // The rule is content-driven, not position-driven (§4): a pre-authored
      // deck if one exists for the revealed Name, else the existing AI
      // reflection. Today only positions 1-2 carry approved decks, so in
      // practice only D1 is a deck reveal — but the day a founder approves an
      // aspiration deck, D4 becomes one with no code change.
      //
      // Gated on the queue source so a legacy user who happens to gacha into a
      // decked Name still gets exactly today's experience.
      //
      // Resolved before `engageCard` (nothing is granted yet) and inside its own
      // catch: a bundle read that fails is not a failed reveal. Letting it throw
      // would error a reveal the server already spent a position on, and the
      // AI reflection is a complete fallback.
      NameStoryDeck? deck;
      if (queueCard != null) {
        try {
          deck = await _stories.deckForName(queueCard.id);
          // An undrawable deck is not a deck. Parking one here would strand the
          // user: `startDeeper` short-circuits on `revealDeck != null`, so the
          // screen would show the "couldn't prepare your reflection" view whose
          // only action is a retry that returns to the identical state. Dropping
          // it restores the AI reflection as a working fallback.
          if (deck != null && !deck.hasRenderableBeat) deck = null;
        } catch (_) {}
      }

      final card = queueCard ??
          pickNextCard(
            collection,
            maxTier: maxTier,
            // Empty for a legacy user, so their pull is bit-identical.
            exclude: sealedQueueNameIds(queueRows),
          );
      final engageResult = await engageCard(
        card.id,
        maxTier: maxTier,
        // The dignity floor on the first seven reveals (§8): a queue-driven
        // first discovery lands at Silver so D1 isn't a visible downgrade from
        // D0's Silver starter card.
        floorTier: queueDriven ? 2 : 1,
      );

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
        resetReveal: true,
        revealSource: queueDriven ? revealSourceQueue : revealSourceGacha,
        revealQueuePosition: queueDriven ? queueRow!.position : null,
        revealDeck: deck,
        queueSealedRemaining: _sealedRemainingAfter(queueRows, queueRow),
      );
      // A deck-backed reveal must NOT spend an OpenAI call whose result is
      // thrown away (and, post-W4, could count against an allowance). It is
      // also what makes the single most important comeback moment in the funnel
      // the one reveal with no network dependency on OpenAI (§3b, §4).
      if (deck == null) _prefetchDeeperReflection();

      // Persist the reveal, so a cold restart resumes it instead of running a
      // second one.
      //
      // `discoverName` never wrote the day blob — only `completeDeeper` and the
      // dormant `answerCheckin` did — so on a process kill between the card
      // landing and "Ameen" there was no blob at all: `_loadTodayState` returned
      // at `raw == null`, `checkinDone` came back false, and the screen's
      // post-frame guard re-ran this function. The planner then returns
      // QueueHold (the position was unsealed minutes ago, and its Name is now in
      // `discoveredIds`, so rule 2 skips and rule 3 fires), which hands the user
      // a DIFFERENT random Name with an AI reflection — while the D1 Name whose
      // queue position the server already spent, and whose card was already
      // granted, is never taught. It also duplicated `engageCard`, the history
      // row and `check_in_completed`.
      //
      // Writing it here is also what makes `_loadTodayState`'s reveal-restore
      // branch reachable at all; without this line those three persisted keys
      // were dead code.
      //
      // Safe next to the grant: `_persistTodayState` swallows every error
      // internally, so it cannot flip `state.error` and break the bypass
      // commit-versus-refund contract.
      await _persistTodayState();

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

      // Re-push the home-screen widget now that today's Name actually exists
      // (W4 Wave 6 / plan §8).
      //
      // Until this point the widget is deliberately in its `awaiting` state,
      // naming no Name — see `composeWidgetSyncState`. This is the moment that
      // stops being true, and waiting for the next `sync_all_user_data` to
      // notice would leave the widget inviting the user to a muḥāsabah they
      // just finished, for hours.
      //
      // Placed here, after the history row and the streak mark, because those
      // are precisely the two things the payload is composed from:
      // `composeWidgetSyncState` flips to personalized off a history row dated
      // today, and the streak count comes from the mark above. Pushing earlier
      // would publish a half-built payload.
      //
      // Deliberately wired to the REVEAL rather than to "Ameen": the widget's
      // claim is "you have met today's Name", which is true from here on
      // whether or not the user taps through the rest of the flow. It is also
      // why Waves 3 and 4 can move the day-open around without touching this.
      //
      // Fire-and-forget: `syncHomeWidget` swallows its own errors, and the
      // payload write is de-duplicated inside `WidgetDataService`, so a
      // redundant call is free.
      unawaited(syncHomeWidget());

      // Retention: the recurring core-loop DAU event (Home "Begin Muḥāsabah"
      // discover path). Powers D1/D7/D30 retention + habit-formation analysis.
      // Best-effort: a telemetry throw must never flip a completed check-in
      // into the error state below — the bypass wrapper reads `state.error` to
      // decide commit-vs-cancel, so an analytics failure here could otherwise
      // refund a bypass that actually succeeded.
      //
      // EXTENDED, NEVER FORKED (W4 Wave 7, plan §9 / spec §9). `path` stays
      // `'discover'`. The original Phase-2 prescription wanted `'feeling'` now
      // that the loop asks a question — that would break every historical D1/D7
      // comparison built on this event, which is the whole retention spine. The
      // question shows up as two new PROPERTIES instead, read straight off the
      // state Wave 3 already derived at submit rather than re-derived here.
      //
      // Both are null on every path that did not go through the question — a
      // re-roll (`resetToday` returns a blank state), a restored pre-W4 day
      // blob, the dormant `answerCheckin`. Null is the honest value there and
      // segments cleanly as "no answer".
      try {
        onAnalyticsEvent?.call(AnalyticsEvents.checkInCompleted, {
          'path': 'discover',
          'name': card.transliteration,
          'tier_changed': engageResult.tierChanged,
          'is_duplicate': engageResult.isDuplicate,
          AnalyticsEvents.propProblemCategory: state.checkinProblemCategory,
          AnalyticsEvents.propInputMode: state.checkinInputMode,
        });
      } catch (_) {}

      // ---- Consume the daily allowance (W4 Wave 1) --------------------------
      //
      // ORDERING IS LOAD-BEARING, three ways:
      //
      //  1. LAST, and after the reveal write. Everything above either succeeded
      //     or threw into the catch below. Landing here is the only proof the
      //     user actually got a Name — `engageCard` has committed, the reveal is
      //     already on screen (state was written at the copyWith above, and none
      //     of the tail awaits block it), and the day blob is persisted. An
      //     earlier position would charge for work that can still fail.
      //
      //  2. INSIDE ITS OWN try/catch, not the outer one. The outer catch writes
      //     `state.error`, and `state.error` is the signal
      //     `discoverNameWithBypass` reads to decide commit-versus-cancel. A
      //     SharedPreferences or upsert failure in here must never flip a reveal
      //     that HAPPENED into an error — that would refund a bypass the user
      //     genuinely spent and re-offer a reveal the server already granted.
      //     Same rationale as the analytics emit directly above. The failure mode
      //     this accepts is failing open (an uncharged reveal), which is the
      //     right way round.
      //
      //  3. AFTER `_resolveQueueRows()`, which is now automatic by being here.
      //     `daily_usage_service._capDay()` keys the counter user-locally once a
      //     queue mirror exists and UTC otherwise; at the CTA that read happened
      //     before the first authoritative queue read, so a queue user's very
      //     first charge could land under the UTC key and lock out their next
      //     local day (see the note in `onboarding_provider._seedNameQueue`).
      if (consumeFreeUsage) {
        try {
          // The day's FIRST reveal is free and unmetered; only re-rolls are
          // metered. This preserves today's behaviour exactly rather than
          // introducing it: the "Begin Muḥāsabah" CTA has never gated or
          // charged, while the two re-roll CTAs did — so a free user past
          // warmup has always had one unmetered daily reveal plus one metered
          // re-roll. Charging here would have quietly halved that for every
          // existing user, in a wave that ships to all of them.
          //
          // It is a safety property too. The day-open reveal is where W4 asks
          // what is on the user's heart; that surface must never be able to
          // answer a disclosure with a cap sheet. Because the free reveal
          // consults no gate at all, it cannot.
          //
          // The marker lives next to the cap counters in `daily_usage_service`
          // and shares their `_capDay()` key, so the two can never disagree
          // about when the day turned over. It is read HERE rather than passed
          // down by the caller because the re-roll signal cannot survive the
          // trip: the home CTA calls `resetToday()` (which wipes the day blob)
          // and then navigates, so whatever fires the reveal on the other side
          // of that push has no idea it was a re-roll.
          if (!await daily_usage.hasTakenFreeDailyRevealToday()) {
            await daily_usage.markFreeDailyRevealTaken();
          } else {
            final outcome = await GatingService().markUsed(
              GatedFeature.discoverName,
              isPremiumHint: isPremiumHint,
            );
            // The 1 → 0 warmup transition is a one-shot UI moment, and the
            // sheet now has to be fired by whoever is on screen rather than by
            // the CTA that used to await this call. `mounted` because the tail
            // awaits give dispose plenty of room to land first.
            if (mounted && outcome == UsageOutcome.warmupJustExhausted) {
              state = state.copyWith(
                warmupJustExhausted: GatedFeature.discoverName,
              );
            }
          }
        } catch (_) {}
      }
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
  /// [consumeFreeUsage] is false for both wrappers: the bypass RPCs own the
  /// daily-counter increment server-side (`reserve_ai_bypass` /
  /// `claim_first_bypass`), and the warmup budget is a pre-bypass mechanic — a
  /// user with warmup left is never gated, so never offered a bypass. Marking
  /// here would charge the reveal twice. Matches `submitBuildWithBypass` /
  /// `submitWithBypass` on the other two gated features.
  ///
  /// `isPremiumHint: false` is not passed on purpose: `reserveBypass` already
  /// short-circuits premium users, so no premium read is owed here at all.
  Future<void> _runDiscoverName() {
    final override = _discoverNameOverride;
    if (override != null) return override(this);
    return discoverName(consumeFreeUsage: false);
  }

  /// Clears the one-shot warmup-exhaustion signal after
  /// [WarmupExhaustedSheet] has been shown and dismissed.
  void dismissWarmupExhausted() {
    if (state.warmupJustExhausted == null) return;
    state = state.copyWith(clearWarmupJustExhausted: true);
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
      clearError: true,
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
          final maxTier = await premiumTierCeiling();
          final engageResult = await engageCard(collectible.id, maxTier: maxTier);
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
        // NOTE if this path ever goes live: it omits `problem_category` and
        // `input_mode` entirely, where the discover path sends them as
        // explicit nulls. Key-absent and null are different things in
        // Mixpanel — one segments as "no data", the other as "no answer" — so
        // a returning multi-question UI should send explicit nulls (or real
        // values) rather than inherit this omission.
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

  /// Test seam — runs the milestone reward loop (XP + tier-up scrolls +
  /// celebration state) for [currentStreak] without driving discoverName's
  /// card/AI machinery. Used to pin that a claim the SERVER refused grants
  /// nothing here: this is the code that turns `checkStreakMilestones`'
  /// return value into real economy writes.
  @visibleForTesting
  Future<void> debugHandleStreakMilestones(int currentStreak) =>
      _handleStreakMilestones(currentStreak);

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

  /// Test seam — the exact request the prefetch would issue for the current
  /// state, so W4 Wave 3 can pin the two properties spec M3 rests on (the
  /// answer reaches the context text; `forceName` still pins the queue's Name)
  /// without asserting on an OpenAI call that tests never make.
  @visibleForTesting
  ({String key, String contextText, String forceName})? debugDeeperRequest() =>
      _deeperRequestFor(state);

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
    // Deck path (§4): the pre-authored beats ARE the content, so crossing to the
    // sacred canvas is a pure state flip. Without this short-circuit the "Go
    // Deeper" tap would fire the very OpenAI call `discoverName` skipped, which
    // is the whole point of a reveal that cannot fail on an OpenAI outage.
    // `muhasabah_screen._buildBeatFlow` reads `revealDeck` and renders
    // `buildBeatScreensFromDeck`, so no `reflectResult` is ever needed.
    if (state.revealDeck != null) {
      state = state.copyWith(
        currentStep: DailyLoopStep.deeper,
        reflectLoading: false,
        // Skip step 0 (name display) for the same reason the AI path does — the
        // gacha card reveal already showed the Name.
        reflectStep: 1,
        clearError: true,
      );
      return;
    }

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
        clearError: true,
      );
      _noteOffTopic(_deeperReflectResult!);
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
      clearError: true,
    );

    try {
      final result = await _loadDeeperReflection(request);

      state = state.copyWith(
        reflectResult: result,
        reflectLoading: false,
        reflectStep:
            1, // skip step 0 (name display) — user saw the name in gacha
      );
      // Both assignment sites report, because either can be the one that puts
      // an off-topic result in front of the user: this is the cold path, the
      // early return above is the prefetch already having landed.
      _noteOffTopic(result);

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
  /// lifecycle to completed, persists, and opens the daily Noor faucet.
  Future<void> completeDeeper() async {
    if (state.currentStep == DailyLoopStep.completed) return; // idempotent
    state = state.copyWith(
      deeperDone: true,
      questDone: true,
      currentStep: DailyLoopStep.completed,
    );
    await _persistTodayState();
    await _awardDailyNoor();
    await _markDayOpenSatisfied();
  }

  /// Stamps both day-open markers on completion, by **any** entry path (W4
  /// Wave 4 — plan §6).
  ///
  /// This lives here rather than in `muhasabah_screen.onAmeen` because
  /// [completeDeeper] is the one place every entry converges — day-open, the
  /// home CTA, and a home-screen widget tap, which reaches `/muhasabah`
  /// directly and never passes the overlay at all. (`advanceReflectStep` also
  /// reaches `completed`, but it has had no caller outside this file since the
  /// beat flow took over; it is dead, and scheduled for deletion alongside
  /// `answerCheckin`.) Putting the write in the UI would have covered one
  /// caller of one path.
  ///
  /// **Two markers, two clocks, both needed:**
  ///
  /// * [markDailyLaunchShown] is UTC, and closes the bug the widget path had
  ///   all along: enter by widget, finish the whole loop, open the app an hour
  ///   later, and `shouldShowDailyLaunch()` was still true — day-open fired on
  ///   a day already done.
  /// * [markDailyQuestionAutoEnteredToday] is user-local, and is the belt to
  ///   that brace. The UTC gate *will* legitimately reopen after UTC midnight
  ///   on the same local evening (a UTC-7 user finishing at 16:00 local is
  ///   already into the next UTC day), and without the local stamp the question
  ///   would be asked twice in one evening. See `daily_question_gate.dart` for
  ///   why the clocks stay separate.
  ///
  /// Best-effort, exactly like [_awardDailyNoor]: completion is the
  /// user-visible contract, and a prefs failure must never make the Ameen tap
  /// look like it did nothing. The markers each swallow their own errors too —
  /// this catch is the backstop, not the only one.
  Future<void> _markDayOpenSatisfied() async {
    try {
      await markDailyLaunchShown();
      await markDailyQuestionAutoEnteredToday();
    } catch (_) {
      // Costs at most one redundant day-open; the next completion re-stamps.
    }
  }

  /// The daily-muḥāsabah Noor grant (spec §3). THE earn path for the wardrobe
  /// currency — milestone Noor aside, this is the only way a user accumulates
  /// Noor by using the app.
  ///
  /// Deliberately fired from the completion transition and nowhere else: the
  /// server verifies a `user_checkin_history` row exists for its own UTC date
  /// before minting, so calling it speculatively (on entry, on a partial flow)
  /// would just be refused. It is also idempotent server-side — it dedupes on
  /// `daily:<server date>` and reports 0 on a replay, which
  /// [awardDailyNoor] mirrors by crediting nothing and emitting nothing.
  ///
  /// Best-effort: completion is the user-visible contract and must survive a
  /// faucet that cannot reach the server.
  Future<void> _awardDailyNoor() async {
    try {
      await awardDailyNoor();
    } catch (_) {
      // The next completion (or the next full sync) reconciles the balance.
    }
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
        // Derived from the answer, and persisted alongside it so a reveal
        // resumed after a cold restart still knows how the day was segmented —
        // Wave 7's `check_in_completed` props must not silently become null on
        // the one path where the user's session was interrupted.
        'checkinProblemCategory': state.checkinProblemCategory,
        'checkinInputMode': state.checkinInputMode,
        'checkinAttempt': state.checkinAttempt,
        // The one that matters on a force-quit: a user killed mid-rephrase
        // comes back to the question, not to a second reveal that would spend
        // another queue position and teach a different Name.
        'awaitingReAnswer': state.awaitingReAnswer,
        'checkinName': state.checkinName,
        'checkinNameArabic': state.checkinNameArabic,
        'reflectStep': state.reflectStep,
        // Enough to rebuild the reveal on a cold restart. The deck itself is
        // NOT persisted — it is bundled content, so the id is the only durable
        // part and re-resolving it is a local asset read.
        'revealSource': state.revealSource,
        'revealQueuePosition': state.revealQueuePosition,
        'revealNameId': state.engagedCard?.id,
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

      final revealSource = data['revealSource'] as String? ?? revealSourceGacha;
      final revealNameId = (data['revealNameId'] as num?)?.toInt();

      // Rebuild the deck across a cold restart.
      //
      // Without this, a user who revealed their D1 Name and then had the app
      // killed before "Ameen" — a phone call, a swipe-away, iOS reclaiming
      // memory — came back to the AI reflection instead of the authored deck,
      // because `checkinDone` is restored and so `discoverName` never re-runs.
      // That is the one reveal the plan promises has no OpenAI dependency, on
      // the single most important comeback day in the funnel, so it is worth
      // one local asset read to get right rather than a documented hole.
      //
      // Only mid-flow (`checkinDone && !deeperDone`) and only for a queue
      // reveal: a legacy gacha reveal must resume exactly as it does today,
      // even if its Name happens to have a deck.
      NameStoryDeck? deck;
      if (checkinDone &&
          !deeperDone &&
          revealSource == revealSourceQueue &&
          revealNameId != null) {
        try {
          deck = await _stories.deckForName(revealNameId);
          // Same rule as the live path: an undrawable deck is not a deck.
          if (deck != null && !deck.hasRenderableBeat) deck = null;
        } catch (_) {
          // A failed bundle read resumes on the AI reflection below — the same
          // fallback `discoverName` uses.
        }
      }

      state = state.copyWith(
        checkinDone: checkinDone,
        deeperDone: deeperDone,
        questDone: questDone,
        currentStep: DailyLoopStep.values[stepIndex],
        checkinQuestionIndex: data['checkinQuestionIndex'] as int? ?? 0,
        checkinAnswers: savedAnswers,
        checkinAnswer: data['checkinAnswer'] as String?,
        // Absent from any blob written before W4 Wave 3, and from every blob a
        // re-roll or the dormant `answerCheckin` writes — null is the honest
        // answer there, not a value to re-derive.
        checkinProblemCategory: data['checkinProblemCategory'] as String?,
        checkinInputMode: data['checkinInputMode'] as String?,
        checkinAttempt: (data['checkinAttempt'] as num?)?.toInt() ?? 0,
        awaitingReAnswer: data['awaitingReAnswer'] as bool? ?? false,
        checkinName: data['checkinName'] as String?,
        checkinNameArabic: data['checkinNameArabic'] as String?,
        reflectStep: data['reflectStep'] as int? ?? 0,
        // Rehydrate the card the persisted id names, through the same helper
        // `discoverName` uses. Without it the restore forked from the live path:
        // `_deeperContextText` reads `engagedCard` for the Name's meaning and
        // its "Teaching shown" line, and on the discover path no earlier branch
        // catches (`checkinAnswers` is empty, `checkinAnswer` null) — so every
        // restored NON-deck reveal fell through to the generic fallback and the
        // prefetched reflection lost its context. `forceName` still pinned the
        // Name, so this degraded prompt quality rather than choosing wrongly.
        engagedCard:
            revealNameId == null ? null : findCollectibleById(revealNameId),
        // All three reveal fields are specified together, which is the only
        // condition under which `resetReveal` may be set.
        resetReveal: true,
        revealSource: revealSource,
        revealQueuePosition: (data['revealQueuePosition'] as num?)?.toInt(),
        revealDeck: deck,
      );

      // Unchanged rule from `discoverName`: prefetch only when there is no deck
      // to render, so a restored deck reveal still spends no OpenAI call.
      if (checkinDone && !deeperDone && deck == null) {
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
