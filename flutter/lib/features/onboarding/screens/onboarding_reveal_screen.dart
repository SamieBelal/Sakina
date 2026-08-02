import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/name_story_deck.dart';
import '../../../services/analytics_event_names.dart';
import '../../../services/card_collection_service.dart';
import '../../../services/name_stories_service.dart';
import '../../../services/supabase_sync_service.dart';
import '../../../widgets/beat_reveal/beat_reveal_flow.dart';
import '../../../widgets/beat_reveal/beat_reveal_models.dart';
import '../../streaks/providers/cosmetics_ui_providers.dart';
import '../widgets/lantern_kindle_beat.dart';
import '../widgets/onboarding_card_reveal.dart';
import '../widgets/sealed_name_tease.dart';

/// Unscoped base key for the once-ever `second_name_teased` flag. Scoped per
/// user via `supabaseSyncService.scopedKey` at read/write time — see
/// [_OnboardingRevealScreenState._scheduleSecondNameTeased].
const String onboardingRevealSecondNameTeasedBaseKey =
    'onboarding_reveal_second_name_teased';

/// The reel flow's reveal sequence (One Ship W2-C1) — what the hook screen's
/// tap actually buys:
///
///   loader beat → Name₁'s deck on the sacred canvas → "Ameen" → the card
///   reveal at **Silver** → Name₂ shown, sealed until tomorrow → [onDone].
///
/// Deliberately a plain `StatefulWidget` with constructor callbacks, like
/// `HookProblemScreen`: Wave E owns the PageView assembly and the provider
/// writes. Everything here is local — the deck asset and the const catalog —
/// so the whole sequence runs before the user has an account.
///
/// **The card award is deterministic Silver** (plan review blocker 1): no
/// weighted tier roll exists in the app, so inventing one here would be a new
/// economy mechanic. This screen only SHOWS the reveal; `completeOnboarding`
/// writes the row, at the same fixed tier.
class OnboardingRevealScreen extends StatefulWidget {
  const OnboardingRevealScreen({
    required this.pairNameIds,
    required this.onDone,
    this.onBack,
    this.stories,
    this.latch,
    this.contract,
    this.loaderBeat = const Duration(milliseconds: 2200),
    this.showFirstRunHint = true,
    super.key,
  });

  /// Analytics dispatch hook — this screen has no Riverpod access, so
  /// `main.dart` bridges it the same way as the notifier hooks. Null in tests
  /// unless the test sets it.
  static void Function(String name, Map<String, Object?> props)?
      onAnalyticsEvent;

  /// `[name₁, name₂]` from the hook commit. Name₁ is revealed here; Name₂ is
  /// teased sealed.
  final List<int> pairNameIds;

  /// Fired once, after the Name₂ tease's continue.
  final ValueChanged<OnboardingRevealResult> onDone;

  /// Back out of the reveal (Wave E wires the PageView). When null, backing out
  /// of the first beat does nothing.
  final VoidCallback? onBack;

  final NameStoriesService? stories;

  /// [HookContract.problem] / [HookContract.sign] — what the hook promised.
  /// Carried on `second_name_teased` (W6 Wave B / W3 §9) alongside Name₂'s own
  /// id/deck. Null in tests and for any caller that hasn't resolved a hook
  /// (the comfort-pair / kill-switch paths still reveal — the contract is
  /// just absent on that emit, not fabricated).
  final String? contract;

  /// The once-per-onboarding-run latch for the award / abandon emissions.
  ///
  /// The flags cannot live in the [State]: a back-nav that re-enters the reveal
  /// builds a fresh state object, which would re-award the card and re-emit
  /// `reveal_deck_completed`. Wave E owns one instance per run and passes it in.
  /// It is a belt to the braces — Wave E must STILL forbid back-nav past the
  /// reveal, because a re-entry with the latch set lands the user on a deck
  /// whose Ameen no longer does anything.
  final OnboardingRevealLatch? latch;

  /// Minimum time the opening beat holds before the deck appears. Zero in tests.
  ///
  /// This is NOT padding around a wait — Wave G puts the lantern's kindling
  /// beat in this slot, and the deck asset resolves in about a frame, so the
  /// duration is simply how long that beat is on screen. Budget: the flame
  /// settles at ~900ms, the headline lands at ~520ms and the subline trails it,
  /// leaving roughly a second to read before the deck dissolves in. Shorter and
  /// the copy is gone before it is read; longer and it becomes the fake theater
  /// the plan explicitly rejected.
  final Duration loaderBeat;

  /// The tap-to-continue hint — always on in production (this is the user's
  /// first beat flow, so there is no "already learned it" case to gate on the
  /// way muḥāsabah does). Off in tests: the hint pulses forever and would hang
  /// `pumpAndSettle`.
  final bool showFirstRunHint;

  @override
  State<OnboardingRevealScreen> createState() => _OnboardingRevealScreenState();
}

/// What the reveal committed, for the caller to persist. [awardedTier] is
/// always [CardTier.silver] today, carried explicitly so the persisted tier can
/// never drift from the one the user was shown.
class OnboardingRevealResult {
  const OnboardingRevealResult({
    required this.name1Id,
    required this.name2Id,
    required this.awardedTier,
  });

  final int name1Id;
  final int? name2Id;
  final CardTier awardedTier;
}

/// Survives the reveal screen's own [State] so a re-mount (back-nav, a PageView
/// rebuild) can neither award a second card nor re-emit the deck telemetry.
/// Mutable by design — it is a latch, not state to rebuild on.
class OnboardingRevealLatch {
  bool completed = false;
  bool abandonedFired = false;

  /// The lantern's kindling has been reported (Wave G). Lives here rather than
  /// in the [State] for the same reason as the others: a re-mount rebuilds the
  /// beat, and the lamp is only ever lit once per onboarding run.
  bool kindledFired = false;

  /// `second_name_teased` (W6 Wave B / W3 §9) has been reported THIS PROCESS.
  /// Mirrors [kindledFired]'s reasoning: lives here, not in [State], so a
  /// re-mount within one process (back-nav, a PageView rebuild) cannot re-fire
  /// it.
  ///
  /// This alone is NOT "one tease per user, ever": onboarding page position is
  /// durably persisted (SharedPreferences), so a process kill anywhere on the
  /// reveal page — including AFTER the tease already fired — restores a
  /// brand-new [State] and a brand-new, unset latch on relaunch, which would
  /// replay the tease. The durable half of the guard lives in the
  /// SharedPreferences flag [_OnboardingRevealScreenState._scheduleSecondNameTeased]
  /// checks; this field only guards the same-process rebuild case that a
  /// persisted-only check would still let through within one session.
  bool secondNameTeasedFired = false;

  /// [OnboardingRevealScreen.onDone] has been handed back. Guards the deckless-
  /// Name₂ path, where `_finish` runs from a post-frame callback in `build`:
  /// any rebuild while that phase is on screen (a parent setState, a PageView
  /// relayout) schedules another callback, and without this the caller is told
  /// the reveal finished once per frame.
  bool finished = false;
}

enum _Phase { deck, tease }

class _OnboardingRevealScreenState extends State<OnboardingRevealScreen> {
  /// The one place the reveal's tier is written down.
  static const CardTier awardTier = CardTier.silver;

  late final NameStoriesService _stories = widget.stories ?? nameStoriesService;
  late final OnboardingRevealLatch _latch =
      widget.latch ?? OnboardingRevealLatch();

  _Phase _phase = _Phase.deck;
  NameStoryDeck? _name1;
  NameStoryDeck? _name2;
  List<BeatScreen> _screens = const [];
  bool _failed = false;
  int _lastBeatIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    // A back-swipe / page change that leaves the deck unfinished is an
    // abandonment too, not just the explicit back tap.
    _emitAbandoned();
    super.dispose();
  }

  Future<void> _load() async {
    // Only a retry has an error on screen to clear; in `initState` this is
    // already false, and `setState` there is churn the framework warns about.
    if (_failed) setState(() => _failed = false);
    final ids = widget.pairNameIds;
    try {
      // The loader is a minimum, not a wait: the asset usually resolves in a
      // frame, and cutting straight to the deck reads as a glitch.
      final beat = Future<void>.delayed(widget.loaderBeat);
      var one = ids.isNotEmpty ? await _stories.deckForName(ids.first) : null;
      var two = ids.length > 1 ? await _stories.deckForName(ids[1]) : null;
      // The comfort fallback the hook screen promises, honoured here too: an
      // empty pair (a skipped/kill-switched hook) or an id no approved deck
      // teaches reveals the sign pair rather than an error the user cannot
      // clear. Both halves move together — half a pair is not a reveal, so a
      // resolvable Name₁ beside an unresolvable Name₂ takes the fallback as
      // well rather than revealing one Name and teasing nothing.
      if (one == null || two == null) {
        final comfort = await _stories.comfortPair();
        if (comfort.length == 2) {
          one = comfort.first;
          two = comfort[1];
        }
      }
      await beat;
      if (!mounted) return;
      setState(() {
        _name1 = one;
        _name2 = two;
        _screens = one == null ? const [] : buildBeatScreensFromDeck(one);
        _failed = one == null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  void _emit(String event, [Map<String, Object?> extra = const {}]) {
    OnboardingRevealScreen.onAnalyticsEvent?.call(event, {
      AnalyticsEvents.propSurface: AnalyticsEvents.surfaceOnboardingReveal,
      if (_name1 != null) 'deck_id': _name1!.deckId,
      if (_name1 != null) 'name_id': _name1!.nameId,
      ...extra,
    });
  }

  /// The lamp has finished catching. Emitted once per run — the kindle beat
  /// itself only fires its callback once, and a re-mount that rebuilds the beat
  /// is guarded by the same latch that protects the award.
  void _onKindled() {
    if (_latch.kindledFired) return;
    _latch.kindledFired = true;
    _emit(AnalyticsEvents.lanternKindled);
  }

  void _emitAbandoned() {
    if (_latch.completed || _latch.abandonedFired || _screens.isEmpty) return;
    _latch.abandonedFired = true;
    _emit(AnalyticsEvents.revealDeckAbandoned, {
      AnalyticsEvents.propBeatIndex: _lastBeatIndex,
    });
  }

  Future<void> _onAmeen() async {
    if (_latch.completed) return;
    _latch.completed = true;
    _emit(AnalyticsEvents.revealDeckCompleted);
    await pushOnboardingCardReveal(
      context,
      nameId: _name1!.nameId,
      tier: awardTier,
      onEvent: OnboardingRevealScreen.onAnalyticsEvent,
    );
    if (!mounted) return;
    setState(() => _phase = _Phase.tease);
  }

  /// Schedules `second_name_teased{name_id, deck_id, contract}` — the promise
  /// the seven-day queue is made of — for the frame after [two] is first
  /// shown sealed.
  ///
  /// Called from `build()`, not `_onAmeen`, and deliberately so: `_onAmeen`
  /// already guards ITSELF against re-entry via `_latch.completed`, which
  /// would make a guard living only there untestable dead code. `build()`
  /// re-runs on every rebuild while the tease is on screen (a parent
  /// `setState`, a PageView relayout) with no such guard of its own — exactly
  /// the shape `kindledFired` protects against for the kindle beat, and this
  /// mirrors it. The post-frame hop (not a direct call) keeps a side effect
  /// out of `build()` itself, matching the deckless-tease `_finish` scheduling
  /// three lines below.
  ///
  /// [_latch] alone only survives one process — see the comment on
  /// [OnboardingRevealLatch.secondNameTeasedFired]. The post-frame callback
  /// additionally consults a SharedPreferences flag, scoped to the current
  /// user via [supabaseSyncService], which DOES survive a kill: it is what
  /// makes "one tease per user, ever" true rather than "once per process".
  void _scheduleSecondNameTeased(NameStoryDeck two) {
    if (_latch.secondNameTeasedFired) return;
    // Set BEFORE scheduling, not inside the callback: several builds can land
    // before the first post-frame callback runs, and each would otherwise
    // schedule its own.
    _latch.secondNameTeasedFired = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Guarded: a throwing hook (or a failing prefs read) must not surface
      // as an uncaught exception from a scheduler callback, which Flutter
      // treats as a crash report. A read failure means we cannot tell whether
      // this user was already teased, so — same posture as
      // `FirstVisitHintService` on a prefs failure — we stay silent rather
      // than risk a double-count.
      try {
        final prefs = await SharedPreferences.getInstance();
        final key =
            supabaseSyncService.scopedKey(onboardingRevealSecondNameTeasedBaseKey);
        // Set by a PRIOR process for this same user — a kill anywhere on the
        // reveal page (including after this exact tease already fired) lands
        // back here with a fresh, unset in-memory latch. Without this check
        // that replay would re-fire the event.
        if (prefs.getBool(key) ?? false) return;
        await prefs.setBool(key, true);
        OnboardingRevealScreen.onAnalyticsEvent?.call(
          AnalyticsEvents.secondNameTeased,
          {
            AnalyticsEvents.propSurface: AnalyticsEvents.surfaceOnboardingReveal,
            AnalyticsEvents.propNameId: two.nameId,
            AnalyticsEvents.propDeckId: two.deckId,
            if (widget.contract != null)
              AnalyticsEvents.propContract: widget.contract,
          },
        );
      } catch (_) {}
    });
  }

  void _finish() {
    if (_latch.finished) return;
    _latch.finished = true;
    widget.onDone(OnboardingRevealResult(
      name1Id: _name1!.nameId,
      name2Id: _name2?.nameId,
      awardedTier: awardTier,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tease = _name2;
    if (_phase == _Phase.tease && tease != null) {
      _scheduleSecondNameTeased(tease);
      return SealedNameTease(deck: tease, onContinue: _finish);
    }
    // Name₂ has no approved deck (ship-gate fallback territory) — the reveal
    // still completed, so hand back rather than strand the user on a tease
    // with nothing in it.
    if (_phase == _Phase.tease && !_latch.finished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _finish();
      });
    }

    return BeatRevealFlow(
      status: _failed
          ? BeatFlowStatus.error
          : _screens.isEmpty
              ? BeatFlowStatus.loading
              : BeatFlowStatus.ready,
      // Deck path: no AI response behind these screens.
      response: null,
      screens: _screens.isEmpty ? null : _screens,
      showFirstRunHint: widget.showFirstRunHint,
      onAmeen: _onAmeen,
      onRetry: _load,
      onReturnHome: () {
        _emitAbandoned();
        widget.onBack?.call();
      },
      onBeatAdvanced: (index, _) => _lastBeatIndex = index,
      // The kindling beat (Wave G) replaces the ripple loader on this surface
      // only. It sits in the loading slot deliberately: that is where the
      // flow's dissolve-into-beat-1 already lives, so the lamp hands off to the
      // deck through the existing transition instead of a competing one.
      //
      // Inline Consumer rather than a ConsumerWidget: this screen is a plain
      // StatefulWidget by design (Wave E owns the provider writes), and the
      // same pattern is already how CardRevealOverlay reads the equipped skin.
      // Pre-auth the provider falls back to classicGold, which is correct — a
      // user this early owns no cosmetics.
      loadingView: Consumer(
        builder: (_, ref, __) => LanternKindleBeat(
          skin: ref.watch(renderableLanternSkinProvider),
          onKindled: _onKindled,
        ),
      ),
    );
  }
}
