import 'package:flutter/material.dart';

import '../../../models/name_story_deck.dart';
import '../../../services/analytics_event_names.dart';
import '../../../services/card_collection_service.dart';
import '../../../services/name_stories_service.dart';
import '../../../widgets/beat_reveal/beat_reveal_flow.dart';
import '../../../widgets/beat_reveal/beat_reveal_models.dart';
import '../widgets/onboarding_card_reveal.dart';
import '../widgets/sealed_name_tease.dart';

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
    this.loaderBeat = const Duration(milliseconds: 900),
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

  /// The once-per-onboarding-run latch for the award / abandon emissions.
  ///
  /// The flags cannot live in the [State]: a back-nav that re-enters the reveal
  /// builds a fresh state object, which would re-award the card and re-emit
  /// `reveal_deck_completed`. Wave E owns one instance per run and passes it in.
  /// It is a belt to the braces — Wave E must STILL forbid back-nav past the
  /// reveal, because a re-entry with the latch set lands the user on a deck
  /// whose Ameen no longer does anything.
  final OnboardingRevealLatch? latch;

  /// Minimum time the loader beat holds before the deck appears. Zero in tests.
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
      // clear. Both halves move together — half a pair is not a reveal.
      if (one == null) {
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

  void _finish() {
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
      return SealedNameTease(deck: tease, onContinue: _finish);
    }
    // Name₂ has no approved deck (ship-gate fallback territory) — the reveal
    // still completed, so hand back rather than strand the user on a tease
    // with nothing in it.
    if (_phase == _Phase.tease) {
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
    );
  }
}
