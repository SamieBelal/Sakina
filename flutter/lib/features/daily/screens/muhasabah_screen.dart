import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/collection/providers/tier_up_scroll_provider.dart';
import 'package:sakina/features/daily/content/daily_question_copy.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/streaks/providers/cosmetics_ui_providers.dart';
import 'package:sakina/features/streaks/providers/freeze_burn_provider.dart';
import 'package:sakina/features/daily/providers/daily_rewards_provider.dart';
import 'package:sakina/features/daily/reveal/reveal_spec.dart';
import 'package:sakina/features/daily/widgets/card_reveal_overlay.dart';
import 'package:sakina/features/daily/widgets/daily_question_prompt.dart';
import 'package:sakina/features/daily/widgets/daily_reward_ceremony.dart';
import 'package:sakina/features/daily/widgets/streak_milestone_overlay.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/features/tour/models/onboarding_tour_step.dart';
import 'package:sakina/features/tour/providers/deferred_celebrations_provider.dart';
import 'package:sakina/features/tour/providers/onboarding_tour_controller.dart';
import 'package:sakina/models/name_story_deck.dart';
import 'package:sakina/services/achievement_checker.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_flow.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_models.dart';
import 'package:sakina/widgets/beat_reveal/sacred_canvas_threshold.dart';
import 'package:sakina/widgets/share_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/daily_question_gate.dart';
import 'package:sakina/services/daily_question_analytics.dart';
import 'package:sakina/services/daily_usage_service.dart' as daily_usage;
import 'package:sakina/services/gating_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/features/paywall/upgrade_callback.dart';
import 'package:sakina/features/paywall/paywall_navigation.dart';
import 'package:sakina/features/paywall/paywall_placement.dart';
import 'package:sakina/features/paywall/widgets/daily_cap_sheet.dart';
import 'package:sakina/features/paywall/widgets/warmup_exhausted_sheet.dart';
import 'package:sakina/widgets/coachmark/tour_anchor.dart';
import 'package:sakina/widgets/reflect_loading.dart';

/// Full-screen Muhasabah experience — check-in → deeper → completion.
/// Lives at /muhasabah route. Reads from dailyLoopProvider.
class MuhasabahScreen extends ConsumerStatefulWidget {
  const MuhasabahScreen({this.entrySource = questionEntryDayOpen, super.key});

  /// How the user reached this route, for `daily_question_shown` (W4 Wave 7).
  /// The router reads it out of `/muhasabah?entry=…`; anything that arrives
  /// untagged is the app having brought the user here on open, which is why the
  /// default is [questionEntryDayOpen] rather than an unknown sentinel.
  final String entrySource;

  @override
  ConsumerState<MuhasabahScreen> createState() => _MuhasabahScreenState();
}

class _MuhasabahScreenState extends ConsumerState<MuhasabahScreen> {
  /// Synchronous re-entry guard for the "Seek Another Name" CTA. Mirrors
  /// the progress_screen home dashboard guard. Set BEFORE any await; the
  /// try/finally clears it on every exit including early returns. Without
  /// this, a double-tap that lands while the first call is still inside
  /// `GatingService.canUse()` passes the gate twice and `markUsed` fires
  /// twice — same shape as the reflect/duas D-E5 race.
  bool _discoverInFlight = false;

  /// One warmup sheet at a time. The two entry points below are mutually
  /// exclusive in principle — a flag already set at mount produces no
  /// transition for the listener, and a flag set after mount arrives when the
  /// mount read has already run and found nothing — but they can collide in the
  /// single frame between `initState` and the post-frame callback, and showing
  /// this sheet twice is exactly what the "only one listener may own this"
  /// comment below exists to prevent.
  bool _warmupSheetShowing = false;

  /// Lifetime count of beat-flow advances (decision 4A). Null until loaded from
  /// prefs; the first-run "tap to continue" hint shows while this is < 3 (or
  /// whenever the guided tour is active — decision 10A). Bumped on first advance.
  int? _hintAdvances;
  static const String _hintAdvancesKey = 'beat_hint_advances';

  /// Global centre of the *Go Deeper* pill, captured on tap so the canvas
  /// blooms out of the button the user actually pressed. Stays null on every
  /// other entry path (error retry, restored state), which the threshold reads
  /// as "grow from the centre of the screen".
  final GlobalKey _goDeeperKey = GlobalKey();
  Offset? _canvasOrigin;

  // ------------------------------------------------------------------
  // Deck-reveal lifecycle (W3 §4). Only ever touched when the daily reveal is
  // deck-backed; the AI path leaves all three untouched.
  // ------------------------------------------------------------------

  /// The deck currently on the canvas, cached from `_buildBeatFlow` so [dispose]
  /// can close the reveal out without reading a provider on a torn-down state.
  /// A pure cache — assigning it has no user-visible effect, so it does not
  /// belong in the `ref.listen` dispatch the rest of this screen uses.
  NameStoryDeck? _abandonableDeck;

  /// Latest beat the user reached — the `beat_index` on an abandonment.
  int _lastBeatIndex = 0;

  /// Latches, mirroring `OnboardingRevealLatch`: completion and abandonment are
  /// mutually exclusive and each fires at most once per mount, so a deck the
  /// user finished never also counts as abandoned when the route unwinds.
  ///
  /// One deck per mount is the assumption, and it holds: only queue position 2
  /// carries a deck today, and a second reveal on the same day is a `QueueHold`
  /// or an exhausted-queue pull — both gacha, both AI-backed.
  bool _deckCompleted = false;
  bool _deckAbandoned = false;

  /// Telemetry is best-effort and must never sit between the user's tap and the
  /// state change it causes. [_emitDeckCompleted] runs inside `onAmeen` BEFORE
  /// `completeDeeper()`, so an uncaught throw from the hook would swallow the
  /// completion outright — no `deeperDone`, no persist, no daily Noor, and the
  /// Ameen tap does nothing. The bare catch is the same rule every provider-side
  /// emit follows (see the `check_in_completed` block in daily_loop_provider),
  /// and it covers the [dispose]-time abandonment too, where a throw would
  /// surface as a framework error while the route unwinds.
  void _emitDeck(String event, NameStoryDeck deck,
      [Map<String, dynamic> extra = const {}]) {
    try {
      DailyLoopNotifier.onAnalyticsEvent?.call(event, {
        AnalyticsEvents.propSurface: AnalyticsEvents.surfaceDailyUnseal,
        'deck_id': deck.deckId,
        'name_id': deck.nameId,
        ...extra,
      });
    } catch (_) {
      // Best-effort — see above.
    }
  }

  void _emitDeckCompleted(NameStoryDeck deck) {
    if (_deckCompleted) return;
    _deckCompleted = true;
    _emitDeck(AnalyticsEvents.revealDeckCompleted, deck);
  }

  /// A deck left unfinished — the explicit back tap AND any other unwind of the
  /// route (system back, `go('/')` from elsewhere), which is why [dispose] calls
  /// this too. Without the second path the D1 completion rate would only ever
  /// see the polite exits.
  void _emitDeckAbandoned() {
    final deck = _abandonableDeck;
    if (deck == null || _deckCompleted || _deckAbandoned) return;
    _deckAbandoned = true;
    _emitDeck(AnalyticsEvents.revealDeckAbandoned, deck, {
      AnalyticsEvents.propBeatIndex: _lastBeatIndex,
    });
  }

  @override
  void dispose() {
    _emitDeckAbandoned();
    super.dispose();
  }

  void _captureGoDeeperOrigin() {
    final box = _goDeeperKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    setState(() {
      _canvasOrigin = box.localToGlobal(box.size.center(Offset.zero));
    });
  }

  @override
  void initState() {
    super.initState();
    _loadHintAdvances();
    // NOTHING auto-fires here any more (W4 Wave 2). Landing on this route with
    // no check-in done shows [DailyQuestionPrompt]; `discoverName()` runs from
    // the user's own answer instead of from a post-frame callback.
    //
    // The rule the deleted one-shot existed to keep still holds, and is the
    // reason this comment survives its trigger: **no code path in this widget
    // may call discoverName implicitly.** Every state-change side effect is
    // dispatched from the ref.listen in build(), which fires on rising edges
    // and so cannot re-fire on a provider invalidation. That is what closes the
    // "phantom second gacha on Return to Home" bug class — an in-build (or
    // post-frame) auto-trigger racing provider invalidation is exactly how it
    // regressed the first time. If a future wave needs to start a reveal
    // without a tap, it belongs behind an explicit, latched user intent, not
    // behind "the screen mounted".
    //
    // The one thing that DOES read state at mount is the warmup sheet below,
    // and it is not an exception to that rule: it starts nothing, grants
    // nothing and charges nothing. It only presents a signal the provider has
    // already recorded.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showWarmupExhaustedSheet(
          ref.read(dailyLoopProvider).warmupJustExhausted);
    });
  }

  /// The "that was your last free one" sheet, from either entry point.
  ///
  /// **Why a mount-time read exists at all (W4 Wave 1 review, F1).**
  /// `dailyLoopProvider` is a plain `StateNotifierProvider`, not autoDispose, so
  /// the notifier outlives this route. `markUsed` sits at the tail of
  /// `discoverName` behind a Supabase round-trip, so a user who taps Return to
  /// Home right after their card reveal — an ordinary thing to do — leaves
  /// while the charge is still in flight. `mounted` on the notifier is still
  /// true, so the flag gets set with nobody watching, and `ref.listen` only
  /// fires on transitions that happen *after* it subscribes. Coming back later
  /// never fired it: `prev` is already non-null. `dismissWarmupExhausted` is
  /// only called from this sheet, so the flag stayed stuck set and the
  /// exhaustion was announced to the user exactly never — they met the cap
  /// sheet cold on their next re-roll instead.
  ///
  /// Nothing about the charge or the cap was wrong; the user simply lost the
  /// one moment where the free tier explains itself. In a wave whose defining
  /// decision was refusing to quietly reduce that tier, silently dropping its
  /// explanation is the wrong trade.
  ///
  /// Reading the pending flag once on mount is deliberately smaller than moving
  /// the sheet to a route-independent host: it keeps the single-listener
  /// property that stops the sheet showing twice, and it keeps this screen the
  /// only owner — which the comment at the listener explains is load-bearing,
  /// because progress_screen is already behind the pushed route by the time the
  /// flag is set.
  void _showWarmupExhaustedSheet(GatedFeature? feature) {
    if (feature == null || _warmupSheetShowing) return;
    _warmupSheetShowing = true;
    WarmupExhaustedSheet.show(
      context,
      feature: feature,
      onUpgrade: () =>
          pushPaywall(context, placement: PaywallPlacement.softInApp),
    ).whenComplete(() {
      _warmupSheetShowing = false;
      // Clears the provider flag, which is what stops the mount read from
      // re-showing the sheet on every subsequent visit to this route.
      ref.read(dailyLoopProvider.notifier).dismissWarmupExhausted();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Side effects live in ref.listen, NOT in build conditionals. listen
    // callbacks fire on rising edges (prev != next) without triggering a
    // rebuild themselves, which gives exactly-once semantics for free —
    // no guard flags needed. This closes the "phantom second gacha on
    // Return to Home" bug class by construction.
    ref.listen<DailyLoopState>(dailyLoopProvider, (prev, next) {
      // Streak milestone — DEFERRED to the very end of the ritual so it never
      // pre-empts the sacred Name reveal (the flag is set back in
      // discoverName(), but firing then would slam the celebration over/before
      // the gacha — same reasoning the rescue sheet is held for below). Fire on
      // the rising edge into the completed step (after Ameen → completeDeeper),
      // as the closing flourish.
      if (next.streakMilestoneReached &&
          next.currentStep == DailyLoopStep.completed &&
          prev?.currentStep != DailyLoopStep.completed) {
        _pushStreakMilestoneOverlay(next);
        return;
      }
      // Streak lapse (restorable) is NOT surfaced here — that would slam the
      // rescue modal over the sacred Name reveal. The flag stays set on the
      // daily-loop state; the Home screen offers the paid rescue as a calm
      // epilogue once the whole ritual is done (see progress_screen).
      // Gacha reveal — when a tier-changed engageResult freshly arrives.
      // Identity comparison is sufficient: every discoverName call
      // constructs a new CardEngageResult, so back-to-back discoveries
      // (Seek Another Name) still trigger because instances differ.
      //
      // Intentional skip: `isDuplicate` pulls (no tier change) never push the
      // reveal overlay. discoverName() leaves `cardEngageResult` null when
      // `!tierChanged` (it awards a token instead, see daily_loop_provider.dart),
      // so both the null guard and the `tierChanged` gate keep the tiered
      // CardRevealOverlay strictly on new-card / tier-up outcomes.
      final prevResult = prev?.cardEngageResult;
      final nextResult = next.cardEngageResult;
      if (nextResult != null &&
          nextResult.tierChanged &&
          !next.checkinLoading &&
          !identical(prevResult, nextResult)) {
        _pushCardRevealOverlay(next);
      }
      // One-shot warmup-exhaustion sheet, on the rising edge of the flag
      // `discoverName` sets when `markUsed` took this user's discover-name
      // warmup from 1 to 0. Before W4 Wave 1 the two discover CTAs awaited
      // `markUsed` themselves and fired this directly; the charge moved into the
      // provider, so the signal has to come back through state. Mirrors
      // duas_screen's `buildWarmupJustExhausted` branch exactly.
      //
      // This screen and not progress_screen: every non-bypass discover runs
      // from here — since W4 Wave 2 that means the user's answer on the
      // question surface and "Seek Another Name", the home CTA having become a
      // push of this route rather than a reveal of its own. Only one listener
      // may own this or the sheet shows twice, and it must stay on THIS screen:
      // progress_screen is already behind the pushed route by the time the flag
      // is set. Pinned by `muhasabah_question_step_test.dart`.
      if (next.warmupJustExhausted != null &&
          prev?.warmupJustExhausted == null) {
        _showWarmupExhaustedSheet(next.warmupJustExhausted!);
      }
    });

    final state = ref.watch(dailyLoopProvider);
    final notifier = ref.read(dailyLoopProvider.notifier);

    // The deeper reflection runs full-screen on the emerald sacred canvas
    // (BeatRevealFlow brings its own Scaffold + chrome + back handling). The
    // canvas is entered the moment the user leaves the gacha, so the wait is
    // part of the ritual — hence we branch on `deeper` even while loading.
    // SacredCanvasThreshold animates the crossing in both directions. It must
    // stay the outermost widget so the bloom origin, which is in screen
    // coordinates, coincides with its own local space.
    // The question shares the canvas with the beat flow deliberately (plan §4):
    // both are the same emerald surface, so the crossing from the answer into
    // the reveal has no seam, and leaving the question dissolves off the canvas
    // through the same threshold the "Ameen" exit uses.
    final showQuestion = _showsQuestion(state);
    final onCanvas = state.currentStep == DailyLoopStep.deeper || showQuestion;

    return SacredCanvasThreshold(
      onCanvas: onCanvas,
      origin: _canvasOrigin,
      child: showQuestion
          ? DailyQuestionPrompt(
              entrySource: widget.entrySource,
              // Their own words back, so a rephrase is an edit rather than a
              // retype. Null on the ordinary first ask.
              initialText: state.awaitingReAnswer
                  ? state.checkinAnswers.firstOrNull
                  : null,
              isReAsk: state.awaitingReAnswer,
              onSubmit: _onQuestionSubmit,
              onDefer: _onQuestionDefer,
            )
          : onCanvas
              ? _buildBeatFlow(state, notifier)
              : Scaffold(
                  backgroundColor: AppColors.backgroundLight,
                  body: SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        child: _buildContent(state, notifier),
                      ),
                    ),
                  ),
                ),
    );
  }

  /// Whether this mount is asking the daily question rather than showing a
  /// reveal (W4 Wave 2).
  ///
  /// `loaded` is part of the condition and not an afterthought: a fresh
  /// [DailyLoopState] starts on [DailyLoopStep.checkin] with nothing done, so
  /// without it a user whose day is already complete would meet the question
  /// for the frames before `_initialize()` restores today's state.
  ///
  /// **`awaitingReAnswer` is the single exception to `!checkinDone`**, and the
  /// narrowness is the point. `!checkinDone` is what stops a revealed day from
  /// re-entering the question and running a second `discoverName` — the
  /// phantom-second-gacha bug class. The off-topic re-ask needs the question
  /// back on a day that IS revealed, so it gets one explicitly-named flag
  /// rather than a loosened condition, and `submitDailyAnswer` refuses to
  /// reveal while that flag is what let it in. Both halves have to agree for a
  /// second reveal to happen, and neither can drift into agreeing by accident.
  static bool _showsQuestion(DailyLoopState state) =>
      state.loaded &&
      state.currentStep == DailyLoopStep.checkin &&
      (!state.checkinDone || state.awaitingReAnswer) &&
      !state.checkinLoading &&
      !state.reflectLoading;

  /// The user's answer (W4 Wave 3). Everything it does — the answer into
  /// `checkinAnswers`, the `problem_category` derivation, the reward claim and
  /// the reveal — lives in [DailyLoopNotifier.submitDailyAnswer]; the screen
  /// only hands it the text.
  ///
  /// Returned as a future the callback discards, deliberately: the question
  /// surface latches its own commit, and every visible consequence arrives
  /// through `dailyLoopProvider` state rather than through this call returning.
  Future<void> _onQuestionSubmit(String text, {String? chipKey}) => ref
      .read(dailyLoopProvider.notifier)
      .submitDailyAnswer(text, chipKey: chipKey);

  /// "Not right now" — a DEFER, not a dismissal (spec M2).
  ///
  /// Nothing is revealed, nothing is claimed, nothing is consumed: the whole
  /// loop stays collectible from the home CTA for the rest of the day. The
  /// navigation stays synchronous, so no prefs hiccup or slow disk can sit
  /// between the user's tap and the exit. A best-effort marker write continues
  /// after Home is visible so day-open does not immediately ask again.
  ///
  /// **The day marker moved to auto-entry** (founder, 2026-07-30 — W4 Wave 4).
  /// Wave 2 stamped it here, which meant a user who left with the system back
  /// gesture had not "deferred" and got the question thrown at them again on the
  /// next open. Preventing nagging has to hold however someone left, so
  /// `daily_question_gate.dart` is stamped when the app *asks* rather than only
  /// when the user declines. A defer from the Home CTA or widget still stamps
  /// it, because otherwise the next launch can auto-enter and turn “Not right
  /// now” into “ask me again immediately.”
  ///
  /// Skip-versus-abandon is still a real distinction; it lives in the analytics
  /// events (Wave 7), because that is about signal, not about frequency.
  void _onQuestionDefer() {
    unawaited(suppressDailyQuestionAutoEntryToday());
    context.go('/');
  }

  Future<void> _loadHintAdvances() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getInt(_hintAdvancesKey) ?? 0;
      if (mounted) setState(() => _hintAdvances = v);
    } catch (_) {
      if (mounted) setState(() => _hintAdvances = 3); // fail safe: hide hint
    }
  }

  Future<void> _bumpHintAdvances() async {
    final current = _hintAdvances ?? 0;
    if (current >= 3) return;
    final next = current + 1;
    if (mounted) setState(() => _hintAdvances = next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_hintAdvancesKey, next);
    } catch (_) {
      // Non-critical.
    }
  }

  Widget _buildBeatFlow(DailyLoopState state, DailyLoopNotifier notifier) {
    // Deck path (W3 §4): a queue-driven reveal of a Name with an approved story
    // deck renders the pre-authored beats instead of an AI reflection. There is
    // no `reflectResult` behind it and there never will be — `discoverName`
    // skipped the prefetch and `startDeeper` skips the request — so the deck
    // itself is the readiness signal. `includeVerses`/`includeName` don't apply:
    // the deck's beat list is already the final order and carries its own verse
    // and duʿā beats.
    final deck = state.revealDeck;
    // Built ONCE and then used as the single deck signal for every branch below.
    // `buildBeatScreensFromDeck` skips beats whose kind it doesn't know
    // (`default: continue`), so an approved deck whose every beat is unknown
    // yields an EMPTY list — and a deck the flow cannot render must not count as
    // a deck for the status while not counting as one for the screens. That
    // split is what made the empty case a dead end: `ready` + no screens lands
    // in `BeatRevealFlow`'s own empty-message view, whose retry calls
    // `startDeeper()` — which short-circuits on `revealDeck != null` and returns
    // to the identical state.
    // `nameAlreadyMet`: on THIS path the gacha `CardRevealOverlay` has just
    // shown the badge, the transliteration and the meaning, so the deck's
    // `name_intro` beat would restate them within seconds. It keeps the Arabic
    // calligraphy — the one thing the card renders too small to carry — and the
    // transliteration under it, so a reader who cannot read Arabic still knows
    // which Name this is. Only the meaning line is dropped. Onboarding passes
    // nothing, because there the deck runs BEFORE the card and the beat really
    // is the introduction.
    //
    // Conditional, NOT always-on: the card only appears when the engage changed
    // a tier (`cardEngageResult` is non-null exactly then, and the `ref.listen`
    // below pushes the overlay off it). A queue Name the user already owns at
    // max tier engages as a duplicate, so no card shows — and blanket-dropping
    // the meaning there would leave it displayed NOWHERE. The plan permits that
    // case outright: a Store purchase can pre-own a queued Name's card.
    // The meaning the user has already read, compared rather than assumed.
    //
    // Unconditional, and the earlier `cardEngageResult != null` gate was
    // guarding nothing: `_buildCheckinResult` renders `card.english` on EVERY
    // path and hosts the "Go Deeper" button itself, so the deck cannot be
    // reached without passing the meaning on the way in. The gate's stated
    // rationale — that a duplicate engage shows no card and would leave the
    // meaning displayed nowhere — was simply false. Dropping it also removes a
    // dependency on per-reveal state staleness and a cold-restart asymmetry.
    //
    // A STRING because the catalog and the decks do not always agree: 13 of the
    // 14 match byte-for-byte, and al-wakeel@1 — the D1 Name — does not, where the
    // card says "The Trustee" and the deck says "The Trustee — the Guardian you
    // hand your affairs to". Comparing keeps that clause; a boolean deleted it.
    final meaningAlreadyRead = state.engagedCard?.english;
    final deckScreens = deck == null
        ? null
        : buildBeatScreensFromDeck(deck,
            meaningAlreadyShown: meaningAlreadyRead);
    final hasDeck = deckScreens != null && deckScreens.isNotEmpty;
    final unrenderableDeck = deck != null && !hasDeck;
    // Only a deck the user can actually move through is abandonable — an
    // unrenderable one never shows a beat, and counting it would put a deck that
    // could not be completed into the completion-rate denominator.
    _abandonableDeck = hasDeck ? deck : null;
    // An unrenderable deck is an error, not a wait: falling through to the AI
    // path's `loading` would strand the user on a spinner with no chrome at all,
    // because `startDeeper` still short-circuits on the deck and no reflection
    // is ever requested. The error view at least offers a working way out; its
    // retry is suppressed below rather than offered as a no-op.
    // Off-topic (W4 Wave 3). Before the daily loop asked anything, the context
    // it sent to `reflectWithOpenAI` was the card's own blurb, so the
    // classifier could never fire on this path; now the user's own sentence
    // goes down, so it can. Reflect's exact handling is reused rather than a
    // new branch invented: same `offTopic` flag, same `BeatFlowStatus`, same
    // message view (`reflect_screen.dart:217-219`).
    //
    // It has to be caught, not ignored: the off-topic response is the DEMO
    // response, whose Name is not the Name the user just revealed, so rendering
    // it as an ordinary reflection would teach a different Name than the card.
    //
    // Deck path excluded because it has no `reflectResult` at all — a deck
    // reveal never asks OpenAI anything.
    final offTopic = !hasDeck && state.reflectResult?.offTopic == true;
    final status = state.error != null || unrenderableDeck
        ? BeatFlowStatus.error
        : offTopic
            ? BeatFlowStatus.offtopic
            : hasDeck
                ? BeatFlowStatus.ready
                : state.reflectLoading || state.reflectResult == null
                    ? BeatFlowStatus.loading
                    : BeatFlowStatus.ready;
    final surface = hasDeck
        ? AnalyticsEvents.surfaceDailyUnseal
        : AnalyticsEvents.surfaceMuhasabah;

    // Force the hint whenever the tour is active so the `readStoryCta` anchor
    // (which wraps the hint) is present on every tour path, incl. resume — the
    // anchor never times out for want of a target (decision 10A).
    final tourActive =
        ref.watch(onboardingTourControllerProvider.select((s) => s.isActive));
    final showHint = tourActive || ((_hintAdvances ?? 3) < 3);

    return BeatRevealFlow(
      status: status,
      response: hasDeck ? null : state.reflectResult,
      screens: hasDeck ? deckScreens : null,
      // The gacha card reveal already showed the Name; don't repeat it as the
      // opening hero beat (see daily_loop_provider "skip step 0" decision).
      includeName: false,
      showFirstRunHint: showHint,
      onFirstAdvance: _bumpHintAdvances,
      // Both paths share now. The deck has no `reflectResult` behind it, so it
      // builds the card from its own beats instead — see [_shareCurrentDeck].
      // The flow puts this on the final beat for a deck (the takeaway IS last
      // there) and on the takeaway beat for the AI path.
      onShare: hasDeck
          ? () => _shareCurrentDeck(deck!)
          : () => _shareCurrentMuhasabah(state.reflectResult),
      onAmeen: () {
        HapticFeedback.mediumImpact();
        if (hasDeck) _emitDeckCompleted(deck!);
        final tieredUp = state.cardEngageResult?.tierChanged == true;
        final qn = ref.read(questsProvider.notifier);
        qn.onMuhasabahCompleted();
        qn.onNameDiscovered();
        if (tieredUp) qn.onCardTieredUp();
        notifier.completeDeeper();
        // completeDeeper() mints the daily Noor, which `_creditNoorCache`
        // writes STRAIGHT to prefs — there is no provider write to observe, and
        // the service layer has no Ref to invalidate with. Before Home rendered
        // the equipped skin that did not matter: `cosmeticsStateProvider` is
        // autoDispose and its only consumers were the Companion stage and the
        // wardrobe, so both re-read on every open. Home now holds it alive
        // across pushed routes, so without this the Noor chip and the wardrobe's
        // affordability check would both show the PRE-award balance until the
        // user happened to switch bottom-nav tabs.
        ref.invalidate(cosmeticsStateProvider);
      },
      onReturnHome: () {
        _emitDeckAbandoned();
        // If the user backs out of the beat flow without completing (taps
        // the left zone at beat 0 before "Ameen"), the streak-milestone
        // flag may already be set from discoverName() but the `completed`
        // step transition that normally fires the overlay never happens.
        // Enqueue the milestone to the deferred-celebration queue so Home
        // drains and surfaces it as the next flourish — exactly once, and
        // only if clearStreakMilestone hasn't already run (which can't
        // happen here since we haven't completed the flow).
        final s = ref.read(dailyLoopProvider);
        if (s.streakMilestoneReached) {
          ref.read(deferredCelebrationsProvider.notifier).enqueue(
                StreakMilestoneCelebration(
                  streak: s.streakMilestoneCount ?? 0,
                  xp: s.streakMilestoneXp ?? 0,
                  scrolls: s.streakMilestoneScrolls ?? 0,
                ),
              );
          ref.read(dailyLoopProvider.notifier).clearStreakMilestone();
        }
        if (mounted) context.go('/');
      },
      // `startDeeper()` short-circuits on `revealDeck != null`, so on an
      // unrenderable deck the retry provably re-enters the same state. Pass null
      // and the message view drops the button entirely, leaving "Return home" —
      // which works — as the only action.
      onRetry: unrenderableDeck ? null : () => notifier.startDeeper(),
      // Rephrase, reusing the reveal that already happened. `_showsQuestion`
      // makes its one exception for `awaitingReAnswer` and `submitDailyAnswer`
      // skips `discoverName` in that state, so this cannot produce a second
      // reveal, a second charge or a second reward — only a fresh reflection
      // against the same Name.
      //
      // Clearing the cached off-topic result is half the fix: without it the
      // rejected response outlived the answer, and a user who went home and
      // came back met it again with no way past.
      onOffTopicRetry: () => notifier.reopenQuestionAfterOffTopic(),
      // Copy the user's own words back to them, never an error. See
      // `DailyQuestionCopy.offTopicHeader`.
      offTopicMessage: DailyQuestionCopy.offTopicHeader,
      offTopicBody: DailyQuestionCopy.offTopicBody,
      onBeatAdvanced: (index, kind) {
        _lastBeatIndex = index;
        DailyLoopNotifier.onAnalyticsEvent?.call(
          AnalyticsEvents.reflectBeatAdvanced,
          {
            AnalyticsEvents.propSurface: surface,
            AnalyticsEvents.propBeatIndex: index,
            AnalyticsEvents.propBeatKind: kind.wireName,
          },
        );
      },
      onSkip: (from) {
        DailyLoopNotifier.onAnalyticsEvent?.call(
          AnalyticsEvents.reflectFlowSkipped,
          {
            AnalyticsEvents.propSurface: surface,
            AnalyticsEvents.propFromBeatIndex: from,
          },
        );
      },
      readStoryAnchorBuilder: (child) => TourAnchor(
        surface: TourSurface.muhasabah,
        anchorId: 'readStoryCta',
        child: child,
      ),
      ameenAnchorBuilder: (child) => TourAnchor(
        surface: TourSurface.muhasabah,
        anchorId: 'ameenCta',
        child: child,
      ),
    );
  }

  /// Share a deck-backed reveal, sourced entirely from the deck's own beats.
  ///
  /// Nothing new is authored and nothing is generated: the Arabic and meaning
  /// come from `name_intro`, the English name from the deck, and the quote from
  /// the deck's own VERSE — its translation as the hero, its citation as the
  /// attribution. See `shareStoryDeckCard` for why the verse rather than the
  /// deck's opening or closing line. `TakeawayShareCard` already draws through
  /// `MihrabArchFrame`, so the artifact matches the canvas the user just came
  /// from by construction.
  Future<void> _shareCurrentDeck(NameStoryDeck deck) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await shareStoryDeckCard(context: context, deck: deck);
    } catch (e) {
      debugPrint('[SHARE ERROR] $e');
      showShareErrorSnackBar(messenger);
    }
  }

  /// Shares the muḥāsabah takeaway as the emerald mihrab card (Name + meaning +
  /// key line + takeaway). The AI path only — it fires from the floating share
  /// icon on the takeaway beat, which is never the last screen there because the
  /// duʿa always follows. The deck path uses [_shareCurrentDeck] instead.
  Future<void> _shareCurrentMuhasabah(ReflectResponse? result) async {
    if (result == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await shareTakeawayCard(
        context: context,
        nameArabic: result.nameArabic,
        nameEnglish: result.name,
        meaning: result.meaning,
        reframeKey: result.reframeKey,
        takeaway: result.takeaway,
      );
    } catch (e) {
      debugPrint('[SHARE ERROR] $e');
      showShareErrorSnackBar(messenger);
    }
  }

  void _pushStreakMilestoneOverlay(DailyLoopState state) {
    if (!mounted) return;
    final notifier = ref.read(dailyLoopProvider.notifier);
    final nav = Navigator.of(context, rootNavigator: true);
    nav.push(
      PageRouteBuilder(
        opaque: true,
        barrierDismissible: false,
        pageBuilder: (_, __, ___) => StreakMilestoneOverlay(
          streakCount: state.streakMilestoneCount ?? 0,
          xpAwarded: state.streakMilestoneXp ?? 0,
          scrollsAwarded: state.streakMilestoneScrolls ?? 0,
          onContinue: () {
            nav.pop();
            notifier.clearStreakMilestone();
          },
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Future<void> _pushCardRevealOverlay(DailyLoopState state) async {
    if (!mounted) return;
    ref.read(questsProvider.notifier).updateMonthlyStreak(state.streakCount);
    // The tiered reveal derives all display text from the engaged card, so we
    // only need the CollectibleName + its outcome tier. Both come from the
    // daily-loop state that discoverName() just wrote. Guard the (already
    // gated) non-null values: the ref.listen only fires when
    // cardEngageResult.tierChanged is set, and discoverName always writes
    // engagedCard alongside it.
    final engagedCard = state.engagedCard;
    final engageResult = state.cardEngageResult;
    if (engagedCard == null || engageResult == null) return;
    final rootNav = Navigator.of(context, rootNavigator: true);
    await rootNav.push(
      PageRouteBuilder(
        settings: const RouteSettings(name: CardRevealOverlay.routeName),
        opaque: true,
        barrierDismissible: false,
        pageBuilder: (_, __, ___) => CardRevealOverlay(
          card: engagedCard,
          spec: revealSpecFor(engageResult.tier),
          // Continue pops the reveal route, returning to the muhasabah screen
          // which then shows the check-in result → "Go Deeper" hand-off into
          // BeatRevealFlow. Identical to the legacy NameRevealOverlay pop.
          onContinue: rootNav.pop,
          onEvent: (name, props) =>
              DailyLoopNotifier.onAnalyticsEvent?.call(name, props),
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
    // Check achievements & flush quest toasts after the gacha overlay is
    // dismissed so toasts appear on the muhasabah screen (visible).
    if (!mounted) return;
    await checkAchievements(ref);
  }

  Widget _buildContent(DailyLoopState state, DailyLoopNotifier notifier) {
    if (state.checkinLoading || state.reflectLoading) {
      return const ReflectLoading();
    }
    if (state.currentStep == DailyLoopStep.completed) {
      return _buildCompleted(state);
    }
    // Deeper reflection is handled full-screen in build() via _buildBeatFlow.
    if (state.checkinDone && state.checkinName != null) {
      return _buildCheckinResult(state, notifier);
    }
    // Everything the question doesn't own: the frames before `_initialize()`
    // has restored today's state, and any step this switch doesn't render.
    // Once `loaded` lands, `_showsQuestion` takes the checkin step over in
    // build() and this is never the check-in view again (W4 Wave 2).
    return const ReflectLoading();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CHECK-IN (4 questions)
  // ═══════════════════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════════════════
  // CHECK-IN RESULT (Name card + Go Deeper)
  // ═══════════════════════════════════════════════════════════════════════════

  void _showDiscoverGateSheet(GateReason reason) {
    () async {
      final balance = (await getTokens()).balance;
      final bypassesUsed = await daily_usage.getDiscoverNameBypassesUsedToday();
      final premium = await PurchaseService().isPremium();
      final firstBypassEligible = await GatingService().firstBypassEligible();
      final displayName = await GatingService().displayName();
      if (!mounted) return;
      final notifier = ref.read(dailyLoopProvider.notifier);
      DailyCapSheet.show(
        context,
        feature: GatedFeature.discoverName,
        gateReason: reason,
        tokenBalance: balance,
        bypassesUsedToday: bypassesUsed,
        isPremium: premium,
        onBypassRequested: (_) => notifier.discoverNameWithBypass(),
        firstBypassAvailable: firstBypassEligible,
        userDisplayName: displayName,
        onFirstBypassRequested: (_) => notifier.discoverNameWithFirstBypass(),
        onUpgrade: buildPaywallUpgradeCallback(
          reason: reason,
          pushPaywall: () {
            if (mounted) {
              pushPaywall(
                context,
                placement: PaywallPlacement.softInApp,
                valueLine:
                    softGateValueLine(GatedFeature.discoverName, reason),
              );
            }
          },
        ),
      );
    }();
  }

  Widget _buildCheckinResult(DailyLoopState state, DailyLoopNotifier notifier) {
    // Try engagedCard first, fall back to looking up by name
    final card =
        state.engagedCard ?? findCollectibleByName(state.checkinName ?? '');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Text(
            'Your Reflection',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Name card — onboarding style
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: AppColors.borderLight, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  card?.arabic ?? state.checkinNameArabic ?? '',
                  style: AppTypography.nameOfAllahDisplay.copyWith(
                    color: AppColors.secondary,
                    fontSize: 40,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  card?.transliteration ?? state.checkinName ?? '',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                if (card != null) ...[
                  Text(
                    card.english,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  if (card.lesson.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(height: 1, color: AppColors.dividerLight),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      card.lesson,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondaryLight,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.05, end: 0, duration: 600.ms),
          const SizedBox(height: AppSpacing.lg),
          _sparkleRow(),
          const SizedBox(height: AppSpacing.lg),
          // Go Deeper button — always free. Additional muhasabahs are gated
          // by daily caps (25-token bypass via DailyCapSheet) at the "Seek
          // Another Name" / "Discover a New Name" entry CTAs, so once the
          // user is in the flow there's no further token gating.
          TourAnchor(
            surface: TourSurface.muhasabah,
            anchorId: 'goDeeperCta',
            child: GestureDetector(
              key: _goDeeperKey,
              onTap: () {
                HapticFeedback.mediumImpact();
                _captureGoDeeperOrigin();
                notifier.startDeeper();
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
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'Go Deeper',
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPLETED
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCompleted(DailyLoopState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _sparkleRow(),
          const SizedBox(height: 16),
          // Completion card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
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
                SvgPicture.asset(
                  'assets/illustrations/main_screens/daily_complete.svg',
                  height: 140,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Muhāsabah Complete',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.textPrimaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  "You've reflected, gone deeper, and connected with Allah today.",
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                // The reward ceremony, now that the work is done (W4 Wave 4 —
                // spec M1). The grant itself landed back at answer-submit; this
                // is the acknowledgement that used to be a two-tap gate BEFORE
                // the user had done anything.
                if (state.rewardClaimResult != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  DailyRewardCeremony(result: state.rewardClaimResult),
                ],
                const SizedBox(height: AppSpacing.xl),
                // Seek Another Name — primary CTA
                GestureDetector(
                  onTap: () async {
                    // Synchronous re-entry guard — see field doc. Set BEFORE
                    // any await; try/finally clears it on every exit.
                    if (_discoverInFlight) return;
                    _discoverInFlight = true;
                    try {
                      HapticFeedback.mediumImpact();
                      final notifier = ref.read(dailyLoopProvider.notifier);
                      // Gating layer enforces the 1/day cap (or warmup) for
                      // discover_name. No tokens are charged — caps replaced
                      // the token economy gate per the freemium redesign.
                      // Resolve premium ONCE so canUse + markUsed share a
                      // single RevenueCat round-trip.
                      final premium = await PurchaseService().isPremium();
                      final gate = await GatingService().canUse(
                        GatedFeature.discoverName,
                        isPremiumHint: premium,
                      );
                      if (!gate.allowed) {
                        if (mounted) _showDiscoverGateSheet(gate.reason);
                        return;
                      }
                      await notifier.resetToday();
                      if (!mounted) return;
                      // The charge lives inside `discoverName` now (W4 Wave 1) —
                      // it marks at its own tail, only once a Name has actually
                      // been engaged, so the "decrement on success only" contract
                      // this call site used to enforce by reading `state.error`
                      // is enforced at the source instead. `premium` still rides
                      // down so the tap costs one RevenueCat round-trip, not two.
                      //
                      // Why that contract exists, kept here because it is the
                      // reason the naive version is wrong: `discoverName` awaits
                      // an `unseal_next_name` RPC and a queue select, catches its
                      // own exceptions into `state.error`, and returns NORMALLY.
                      // An offline or 500 reveal therefore LOOKS like success to
                      // a caller — and consuming on it burns the user's one free
                      // reveal for a reveal that did not happen, after which the
                      // retry meets the cap sheet and costs 25 tokens while the
                      // server may already have spent the queue position.
                      //
                      // The warmup-exhaustion sheet fires from the ref.listen in
                      // build(), off `state.warmupJustExhausted`.
                      await notifier.discoverName(isPremiumHint: premium);
                    } finally {
                      _discoverInFlight = false;
                    }
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
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text('Seek Another Name',
                            style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 500.ms),
                const SizedBox(height: 24),
                // Return home
                TourAnchor(
                  surface: TourSurface.muhasabah,
                  anchorId: 'returnHomeCta',
                  child: GestureDetector(
                    onTap: () {
                      // Invalidate economy providers so Home reads fresh
                      // values after muhasabah rewards are granted (fixes the
                      // "token pill shows stale 1004 while DB has 1059" bug).
                      // Order doesn't matter anymore — there's no in-build
                      // auto-trigger to race against, so the invalidation
                      // can't accidentally re-fire discoverName.
                      ref.invalidate(dailyLoopProvider);
                      ref.invalidate(tierUpScrollProvider);
                      ref.invalidate(dailyRewardsProvider);
                      // The freeze-burn flag is stamped server-side mid-flow
                      // (markActiveToday → consume_streak_freeze), so refresh the
                      // (otherwise once-resolved) provider or Home keeps its
                      // stale pre-burn value and the reunion card never shows.
                      ref.invalidate(pendingFreezeBurnProvider);
                      context.go('/');
                    },
                    child: Text(
                      'Return to Home',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms, delay: 600.ms),
                const SizedBox(height: 16),
              ],
            ),
          ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _sparkleRow() {
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
                delay: (i * 80).ms)
            .fadeIn(duration: 400.ms, delay: (i * 80).ms);
      }),
    );
  }
}
