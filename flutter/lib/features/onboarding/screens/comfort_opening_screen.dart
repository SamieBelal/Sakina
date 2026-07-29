import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_motion.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/adjusted_arabic_display.dart';
import '../../../widgets/beat_reveal/mihrab_arch_frame.dart';
import '../../../widgets/beat_reveal/sacred_canvas_threshold.dart';
import '../../../widgets/scribe_reveal.dart';

/// The app's opening beat — 2:286 on the sacred canvas (Wave H §6).
///
/// **This REPLACES the welcome screen** (`hook_screen.dart`, deleted
/// 2026-07-29). It does not precede it: comfort → welcome → question would be
/// two gates before the most exposing question in the app. The only element
/// carried over from the old screen is the "I already have an account" link.
///
/// Why it exists. Acquisition is two organic reels, and the second one promises
/// **2:286** — *Allah does not burden a soul beyond that it can bear*. The old
/// screen answered that promise with a **different** ayah (94:6), the tagline
/// "Reflect · Build · Discover" (a feature list, delivered to someone in pain),
/// and an arch image **fetched over the network from a `googleusercontent.com`
/// URL on the app's very first screen**. Ad-scent broke in the first second, and
/// the first frame depended on someone else's CDN.
///
/// It also closes a structural gap: we ask the most exposing question in the app
/// before depositing any trust. This is the deposit before the withdrawal.
///
/// **The arch is now code-drawn.** [MihrabArchFrame] — already the house arch,
/// already used for the Name-of-Allah hero — replaces the remote image outright,
/// so there is no asset to bundle and nothing to fetch. Its gold strokes are a
/// sanctioned non-text accent on the canvas (DESIGN.md §6.2); every glyph on the
/// screen is cream `sacredInk`/`Soft`/`Faint`.
///
/// **Arabic and Latin never share a `Text`** (CLAUDE.md). The ayah, its
/// translation and the reference are three widgets; the Arabic one carries an
/// explicit `TextDirection.rtl`.
///
/// ## The cold open
///
/// This screen does not present itself, it is *staged* — the pattern Calm,
/// Headspace and Finch open on. It runs as two movements on one unbroken canvas,
/// so the emerald never blinks between them:
///
/// **Movement I — the greeting.** The salaam alone, centre-screen, held, and then
/// *gone*. It is the only element in the whole opening that leaves; every other
/// beat arrives and stays. That departure is what makes it read as a title card
/// rather than as content the user is waiting to be allowed to act on.
///
/// **Movement II — the verse.** The ayah is written on, its translation and
/// reference follow, the app speaks one line, and only then does the niche draw
/// itself *around* the verse and the chrome arrive.
///
/// Full timetable in [_Beat]; it settles at [coldOpenDuration]. The pauses
/// between acts are load-bearing — they are what lets each point land on its own
/// rather than merely follow the last — so they are not slack to be reclaimed if
/// someone later wants the screen shorter. Cut a beat, not the silence around
/// it.
///
/// Four things make a ~14s opening safe on the highest-drop-off screen in the
/// product:
///
/// 1. **A tap anywhere catches the sequence up** ([_skip]) — every app in the
///    reference set allows this, and someone who arrived from a reel and is
///    already sold should not be made to wait.
/// 2. **It plays once per install.** Backing in from sign-in, or returning by
///    back-nav, lands on the settled screen. Charming once; infuriating third.
/// 3. **Reduced motion settles on frame one**, sequence and all.
/// 4. **Begin is tappable the moment it starts fading in**, not when it lands.
///
/// Everything is laid out and occupying its final space from the first frame —
/// only opacity, offset and the two masks animate. Nothing may be added to the
/// tree as a beat arrives, or the ayah would shift under the reader when the
/// wordmark and CTA appear.
///
/// **On the ~900ms ceiling in [AppMotion].** That ceiling governs UI *response*
/// — feedback, transitions, anything standing between a user and their intent.
/// This is a title sequence, seen once, and is a deliberate departure confined
/// to this one screen. Do not take it as licence anywhere else in the flow.
class ComfortOpeningScreen extends StatefulWidget {
  const ComfortOpeningScreen({
    required this.onNext,
    this.onSignIn,
    this.departureLead = AppMotion.beat,
    this.playColdOpen,
    super.key,
  });

  // ── Copy ────────────────────────────────────────────────────────────────
  // Short, plain, small words. The verse does the theological work; the English
  // line only opens the door. Nothing here attributes a stance, intent or
  // outcome to Allah, claims a "sign", or implies the reader drifted.

  /// Movement I. The greeting one Muslim gives another, which is the whole
  /// gesture: the app receives the reader as a person before it shows them
  /// anything. Unvocalized on purpose — this is a greeting set as display
  /// calligraphy, not scripture, and harakat crowd Aref Ruqaa at this size.
  ///
  /// No romanization underneath it. A transliteration would turn a welcome into
  /// a lesson, and it would put Arabic and Latin on the app's very first frame
  /// as two stacked widgets for no gain.
  static const String greetingArabic = 'السلام عليكم';

  /// 2:286, verbatim from the app's pre-verified catalog
  /// (`reflection_verse_catalog.dart`) — never re-typed, never generated.
  static const String ayahArabic = 'لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا';

  /// The catalog's translation of the same verse, so the app renders 2:286 one
  /// way everywhere.
  static const String ayahEnglish =
      'Allah does not burden a soul beyond that it can bear.';

  static const String ayahReference = 'Al-Baqarah · 2:286';

  /// The one line the app speaks in its own voice. An open door, not a promise
  /// about what happens next.
  static const String acknowledgement =
      "Whatever you're carrying, you can bring it here.";

  static const String ctaLabel = 'Begin';

  /// When the whole sequence has settled. Public so tests and the plan docs can
  /// reference one number instead of re-deriving it from [_Beat].
  static const Duration coldOpenDuration = Duration(milliseconds: _Beat.total);

  /// Fired after the canvas has begun dissolving. Its future completes when the
  /// pushed flow is popped back here, which is what restores the canvas — see
  /// [_begin].
  final Future<void> Function() onNext;

  final VoidCallback? onSignIn;

  /// How long the departure dissolve runs before [onNext] fires. The push
  /// overlaps the dissolve rather than queueing behind it (the house rule); zero
  /// in tests.
  final Duration departureLead;

  /// Forces the cold open on or off. Null — the default — decides from
  /// persistence: it plays on the first visit of the first install and the
  /// screen is settled from frame one on every visit after.
  final bool? playColdOpen;

  /// Lets a test replay the sequence. The once-per-session latch is static, so
  /// without this the second test in a file would open on a settled screen.
  @visibleForTesting
  static void debugResetColdOpen() =>
      _ComfortOpeningScreenState._playedThisSession = false;

  @override
  State<ComfortOpeningScreen> createState() => _ComfortOpeningScreenState();
}

/// The timetable, in milliseconds from the first frame.
///
/// Read it as two movements, not as sixteen numbers. Every act is given its own
/// held moment — the brief was "slow and controlled, everything renders
/// beautifully one by one", with "pauses for effect driving each of the points
/// home" — so beats here do NOT overlap the way the rest of the onboarding's
/// layers deliberately do. The ~700-900ms gaps between one act ending and the
/// next beginning are the effect being asked for.
///
/// To retime the whole thing, scale these together and update [total].
abstract final class _Beat {
  // ── Movement I · the greeting ────────────────────────────────────────────

  /// A quarter-second of bare canvas before anything at all, so the greeting
  /// fades up onto the emerald rather than already being there when the app
  /// opens.
  static const int greetingIn = 250;
  static const int greetingSettled = 1450;

  /// Held with nothing else on screen competing for the eye. This dwell *is*
  /// movement I — shorten it and the greeting becomes a flash.
  static const int greetingOutStart = 3050;

  /// The one departure in the opening: fades while drifting up, leaving the
  /// canvas genuinely empty again.
  static const int greetingOutEnd = 4050;

  // ── Movement II · the verse ──────────────────────────────────────────────

  /// 700ms of silence after the greeting has gone — the reset between movements.
  static const int ayahStart = 4750;

  /// The ayah is written, right to left, by a steady hand. The slowest beat on
  /// the screen and the one everything else is paced against.
  static const int ayahEnd = 6950;

  /// What it means, then where it is from.
  static const int translationStart = 7750;
  static const int translationEnd = 8650;
  static const int referenceStart = 9350;
  static const int referenceEnd = 9950;

  /// The app speaks. The only line in its own voice, so it gets the longest
  /// silence before it and a slow arrival.
  static const int acknowledgementStart = 10800;
  static const int acknowledgementEnd = 11700;

  /// The screen becomes a screen. The niche is drawn *around* the verse rather
  /// than the verse being placed into it, which is the beat this whole ordering
  /// exists for.
  static const int archStart = 12500;
  static const int archEnd = 13800;
  static const int wordmarkStart = 12650;
  static const int wordmarkEnd = 13350;
  static const int ctaStart = 12950;
  static const int ctaEnd = 13650;

  static const int total = archEnd;
}

class _ComfortOpeningScreenState extends State<ComfortOpeningScreen>
    with SingleTickerProviderStateMixin {
  /// Short screens (iPhone SE and friends) get a compacted rhythm — same
  /// threshold as the hook screen it hands over to.
  static const double _compactHeightThreshold = 700;

  static const String _prefsKey = 'comfort_opening_cold_open_played';

  /// How long a tap-to-skip takes to catch the sequence up. Not a hard snap:
  /// the rush of everything arriving at once *is* the acknowledgement of the
  /// tap, which is why this screen deliberately has no skip haptic. A little
  /// longer than it wants to be, because from movement I there are ~14s of
  /// timeline to collapse and the greeting has to be seen leaving.
  static const Duration _skipCatchUp = Duration(milliseconds: 450);

  /// How far the greeting drifts up as it goes. Slightly more than an entrance
  /// rise: it is leaving, not settling.
  static const double _greetingExitDrift = 12;

  /// Survives a route rebuild, so back-nav within a session never replays the
  /// opening even before the async preference read has resolved.
  static bool _playedThisSession = false;

  late final AnimationController _controller;

  /// The greeting is the only two-sided beat in the file — everything else
  /// arrives and stays, so it is the only one that needs an out as well as an
  /// in. See [_greetingEnvelope].
  late final CurvedAnimation _greetingIn;
  late final CurvedAnimation _greetingOut;

  late final CurvedAnimation _ayahIn;
  late final CurvedAnimation _translationIn;
  late final CurvedAnimation _referenceIn;
  late final CurvedAnimation _acknowledgementIn;
  late final CurvedAnimation _archIn;
  late final CurvedAnimation _wordmarkIn;
  late final CurvedAnimation _ctaIn;

  bool _staged = false;

  /// True from the tap on Begin until the flow is popped back to this screen.
  bool _leaving = false;

  bool get _reduceMotion => MediaQuery.of(context).disableAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: ComfortOpeningScreen.coldOpenDuration,
    );

    // Both sides of the greeting are sine — the gentlest curve in the house
    // vocabulary, and symmetrical, so it leaves the way it came.
    _greetingIn =
        _beat(_Beat.greetingIn, _Beat.greetingSettled, curve: AppMotion.ambient);
    _greetingOut = _beat(
      _Beat.greetingOutStart,
      _Beat.greetingOutEnd,
      curve: AppMotion.ambient,
    );

    // The ink wipe gets a sine ease — a hand accelerating and settling. The
    // house `enter` curve is far too front-loaded for a stroke: it would empty
    // most of the line in the first third and then crawl.
    _ayahIn = _beat(_Beat.ayahStart, _Beat.ayahEnd, curve: AppMotion.ambient);
    _translationIn = _beat(_Beat.translationStart, _Beat.translationEnd);
    _referenceIn = _beat(_Beat.referenceStart, _Beat.referenceEnd);
    _acknowledgementIn =
        _beat(_Beat.acknowledgementStart, _Beat.acknowledgementEnd);
    _archIn = _beat(_Beat.archStart, _Beat.archEnd, curve: Curves.easeInOutCubic);
    _wordmarkIn = _beat(_Beat.wordmarkStart, _Beat.wordmarkEnd);
    _ctaIn = _beat(_Beat.ctaStart, _Beat.ctaEnd);
  }

  CurvedAnimation _beat(int startMs, int endMs, {Curve curve = AppMotion.enter}) {
    final total = _Beat.total.toDouble();
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(startMs / total, endMs / total, curve: curve),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_staged) return;
    _staged = true;
    _stage();
  }

  /// Decides whether this visit gets the cold open, and starts it.
  ///
  /// The sequence starts **immediately** rather than waiting on the preference
  /// read, and the read only ever snaps it to the end. Gating on the read would
  /// make the first launch's opening depend on disk latency; snapping is free
  /// because Act I is a bare canvas, so a repeat visit resolves during frames
  /// in which there was nothing on screen to interrupt.
  void _stage() {
    final forced = widget.playColdOpen;
    if (forced == false || (forced == null && _playedThisSession) ||
        _reduceMotion) {
      _controller.value = 1;
      _playedThisSession = true;
      return;
    }
    _playedThisSession = true;
    _controller.forward();
    if (forced == null) unawaited(_resolvePersisted());
  }

  Future<void> _resolvePersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      if (prefs.getBool(_prefsKey) ?? false) {
        _controller.value = 1;
      } else {
        await prefs.setBool(_prefsKey, true);
      }
    } catch (_) {
      // No persistence available (a test binding without the plugin, a wedged
      // platform channel). The opening simply plays, which is the safe side of
      // the trade — a first-run user must never be denied it.
    }
  }

  @override
  void dispose() {
    _greetingIn.dispose();
    _greetingOut.dispose();
    _ayahIn.dispose();
    _translationIn.dispose();
    _referenceIn.dispose();
    _acknowledgementIn.dispose();
    _archIn.dispose();
    _wordmarkIn.dispose();
    _ctaIn.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// A tap anywhere on the canvas catches the sequence up.
  ///
  /// This competes with the CTA and the sign-in link only in the ~0.9s window
  /// where both exist; nested tap recognizers resolve to the innermost, so the
  /// specific control always wins. Everything that has not arrived yet is
  /// wrapped in an `IgnorePointer`, so a fully transparent Begin cannot be hit.
  void _skip() {
    if (_leaving || _controller.isCompleted) return;
    _controller.animateTo(1, duration: _skipCatchUp, curve: AppMotion.enter);
  }

  /// Crossing out of the canvas, then into the (cream) hook screen.
  ///
  /// The emerald dissolves to cream first, so the push lands cream-on-cream and
  /// the user never meets the full-luminance inversion the threshold spec was
  /// written to kill. `_leaving` is restored when [ComfortOpeningScreen.onNext]'s
  /// future completes — i.e. when the flow is popped back to this route — which
  /// is the only moment the canvas is wanted again. Resetting on a timer instead
  /// would re-bloom the canvas underneath the page covering it.
  Future<void> _begin() async {
    if (_leaving) return;
    HapticFeedback.lightImpact();
    setState(() => _leaving = true);
    if (widget.departureLead > Duration.zero) {
      await Future<void>.delayed(widget.departureLead);
      if (!mounted) return;
    }
    await widget.onNext();
    if (!mounted) return;
    // Popped back: the opening has already been spent, so the screen is waiting
    // fully assembled rather than replaying itself behind the returning user.
    _controller.value = 1;
    setState(() => _leaving = false);
  }

  void _signIn() {
    final onSignIn = widget.onSignIn;
    if (onSignIn == null || _leaving) return;
    HapticFeedback.lightImpact();
    onSignIn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Cream underneath, so the departure dissolve resolves onto the surface
      // the next screen is painted on.
      backgroundColor: AppColors.backgroundLight,
      body: SacredCanvasThreshold(
        onCanvas: !_leaving,
        child: _leaving
            ? const SizedBox.expand()
            : _canvas(context, key: const ValueKey('comfort-opening-canvas')),
      ),
    );
  }

  Widget _canvas(BuildContext context, {Key? key}) {
    final compact = MediaQuery.sizeOf(context).height < _compactHeightThreshold;
    final gap = compact ? AppSpacing.md : AppSpacing.lg;
    return DecoratedBox(
      key: key,
      decoration: const BoxDecoration(gradient: AppColors.sacredCanvasGradient),
      child: GestureDetector(
        onTap: _skip,
        // Translucent so the empty canvas around the content is tappable while
        // the controls underneath stay reachable.
        behavior: HitTestBehavior.translucent,
        // The greeting is an overlay, NOT a row in the column below. It has to
        // be centred on the whole canvas rather than on the space the verse
        // layout happens to leave, and it must occupy no layout at all — a
        // greeting that reserved a slot would push the ayah down and then leave
        // a hole behind when it went.
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  compact ? AppSpacing.md : AppSpacing.lg,
                  AppSpacing.pagePadding,
                  compact ? AppSpacing.md : AppSpacing.lg,
                ),
                // The niche takes the slack on a roomy screen; when it runs out
                // — a short device at a large Dynamic Type setting — the page
                // scrolls rather than overflowing, so no line of the ayah is
                // ever lost.
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: _body(compact: compact, gap: gap),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _greeting(),
          ],
        ),
      ),
    );
  }

  /// Movement I. Fades up on an empty canvas, holds, then fades out while
  /// drifting up.
  ///
  /// `in × (1 - out)` rather than one animation run forwards and back: the two
  /// sides have different lengths (1200ms in, 1000ms out) and a long dwell
  /// between them, which a single reversible animation cannot express.
  ///
  /// Never hit-tests, so a tap during the greeting reaches the skip detector
  /// underneath it.
  Widget _greeting() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final opacity =
              (_greetingIn.value * (1 - _greetingOut.value)).clamp(0.0, 1.0);
          if (opacity == 0) return const SizedBox.shrink();
          final dy = _reduceMotion
              ? 0.0
              : (1 - _greetingIn.value) * AppMotion.riseMedium -
                  _greetingOut.value * _greetingExitDrift;
          return Center(
            child: Opacity(
              opacity: opacity,
              child: Transform.translate(offset: Offset(0, dy), child: child),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
          ),
          child: AdjustedArabicDisplay(
            text: ComfortOpeningScreen.greetingArabic,
            style: AppTypography.nameOfAllahDisplay.copyWith(
              fontSize: 40,
              color: AppColors.sacredInk,
            ),
          ),
        ),
      ),
    );
  }

  Widget _body({required bool compact, required double gap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _act(_wordmark(), _wordmarkIn, rise: AppMotion.riseMedium),
        SizedBox(height: gap),
        // The arch takes whatever the fixed rows leave, so the niche is tall on
        // a large phone and merely shorter on an SE — never squashed into a
        // tunnel mouth. It reserves that space from frame one, empty, which is
        // what keeps the ayah still while the strokes arrive around it.
        Expanded(child: _ayahInArch(compact: compact)),
        SizedBox(height: gap),
        _act(
          Text(
            ComfortOpeningScreen.acknowledgement,
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(
              fontSize: 19,
              height: 1.45,
              color: AppColors.sacredInk,
            ),
          ),
          _acknowledgementIn,
          rise: AppMotion.riseMedium,
        ),
        SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
        _act(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _beginCta(),
              SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
              _signInLink(),
            ],
          ),
          _ctaIn,
          rise: AppMotion.riseSmall,
        ),
      ],
    );
  }

  /// One beat of the opening. Travel drops out under reduced motion; the fade —
  /// and so the content — always stays. Nothing here touches layout: an unplayed
  /// beat still occupies exactly the space it will occupy when it lands.
  Widget _act(Widget child, Animation<double> beat, {required double rise}) {
    return AnimatedBuilder(
      animation: beat,
      builder: (context, child) => IgnorePointer(
        // A fully transparent control is still hit-testable, so this is load
        // bearing: without it a tap on empty canvas during Act I could land on
        // Begin and skip the whole flow.
        ignoring: beat.value == 0,
        child: Opacity(
          opacity: beat.value,
          child: Transform.translate(
            offset: Offset(0, (1 - beat.value) * (_reduceMotion ? 0 : rise)),
            child: child,
          ),
        ),
      ),
      child: child,
    );
  }

  /// Arabic-only, so it needs no direction guard beyond the widget's own —
  /// [AdjustedArabicDisplay] pins `TextDirection.rtl` and corrects Aref Ruqaa's
  /// ascender whitespace (direct Aref Ruqaa text bleeds into the row below).
  Widget _wordmark() => AdjustedArabicDisplay(
        text: AppStrings.sakinaArabic,
        style: AppTypography.nameOfAllahDisplay.copyWith(
          fontSize: 30,
          color: AppColors.sacredInkSoft,
        ),
      );

  /// Scripture inside the niche; the app's own voice stays outside it.
  Widget _ayahInArch({required bool compact}) {
    final content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Written rather than typed — see [ScribeReveal] for why a per-
          // character reveal is not survivable on vocalized Arabic.
          AnimatedBuilder(
            animation: _ayahIn,
            builder: (context, child) => ScribeReveal(
              progress: _reduceMotion ? 1 : _ayahIn.value,
              direction: TextDirection.rtl,
              child: child!,
            ),
            child: Text(
              ComfortOpeningScreen.ayahArabic,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: AppTypography.quranArabic.copyWith(
                fontSize: compact ? 24 : 27,
                color: AppColors.sacredInk,
              ),
            ),
          ),
          SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
          // Extra inset ON TOP of the frame's own 30pt. The translation is
          // the longest line in the niche, so at the frame's padding alone
          // it wrapped to within ~9pt of the arch's side rails and read as
          // if it were touching them. The Arabic is deliberately NOT inset
          // with it — it is a single unbreakable line, and narrowing it
          // would force a wrap the calligraphy cannot take.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Faded as a block, not written. The translation wraps to two
                // lines, and a directional mask over a wrapped paragraph
                // reveals both lines at the same x at once — a curtain, not a
                // hand. The written idiom belongs to the single-line Arabic.
                _act(
                  Text(
                    ComfortOpeningScreen.ayahEnglish,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.sacredInkSoft,
                      height: 1.55,
                    ),
                  ),
                  _translationIn,
                  rise: AppMotion.riseSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                _act(
                  Text(
                    ComfortOpeningScreen.ayahReference,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.sacredInkFaint,
                      letterSpacing: 1.4,
                    ),
                  ),
                  _referenceIn,
                  rise: AppMotion.riseSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return AnimatedBuilder(
      animation: _archIn,
      // The draw-on is the sanctioned ~1s sacred moment (DESIGN.md §5), here
      // stretched and moved onto the sequence's clock so the niche is built
      // around a verse that is already on the page.
      builder: (context, child) => MihrabArchFrame(
        progress: _reduceMotion ? 1 : _archIn.value,
        child: child!,
      ),
      child: content,
    );
  }

  /// The canvas's own CTA shape — gold as a FILL with dark emerald ink on it,
  /// never gold text (DESIGN.md §2.3). Same pill as "Ameen".
  Widget _beginCta() {
    return Semantics(
      button: true,
      label: ComfortOpeningScreen.ctaLabel,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _begin,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            ComfortOpeningScreen.ctaLabel,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.sacredCanvasTop,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  /// The one element the old welcome screen must keep.
  Widget _signInLink() {
    return TextButton(
      onPressed: widget.onSignIn == null ? null : _signIn,
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        foregroundColor: AppColors.sacredInk,
      ),
      child: Text(
        AppStrings.hookLoginLink,
        textAlign: TextAlign.center,
        style: AppTypography.labelLarge.copyWith(
          // Chrome ink stays >=80% on the canvas (DESIGN.md §6.4).
          color: AppColors.sacredInk.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}
