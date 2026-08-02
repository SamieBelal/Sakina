import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/widgets/beat_reveal/beat_progress_bar.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_models.dart';
import 'package:sakina/widgets/beat_reveal/beat_screen_view.dart';
import 'package:sakina/widgets/sakina_loader.dart';

/// The lifecycle state the host feeds the flow. The canvas is entered
/// immediately on `loading` (the wait is part of the ritual) and stays for
/// every non-happy outcome — never a snackbar over the canvas.
enum BeatFlowStatus { loading, error, offtopic, ready }

/// Full-screen tap-through reflection flow on the emerald "sacred canvas".
///
/// The host owns data + side effects (gating, save, quest/economy hooks) and
/// feeds this widget a [status] + parsed [response]; the widget owns the
/// interaction: canvas, segmented progress, tap-to-advance, motion, first-run
/// hint, the Ameen completion beat, and accessibility. See the design spec
/// §"Renderer A".
class BeatRevealFlow extends StatefulWidget {
  final BeatFlowStatus status;
  final ReflectResponse? response;

  /// Pre-built screens, used INSTEAD of building from [response] when non-null
  /// — the deck path (`buildBeatScreensFromDeck`), which has no AI response
  /// behind it. [includeVerses] / [includeName] don't apply: a deck's beat list
  /// is already the final screen order.
  final List<BeatScreen>? screens;

  /// Reflect passes true (verse beats between takeaway and duʿa); muḥāsabah false.
  final bool includeVerses;

  /// Whether to open with the Name-of-Allah mihrab hero beat. Reflect passes
  /// true; muḥāsabah passes false because the gacha card reveal already showed
  /// the Name (avoids showing it twice back-to-back).
  final bool includeName;

  /// Whether to show the first-run "tap to continue" hint (the host computes
  /// this from the persisted lifetime-advance counter OR an active tour).
  final bool showFirstRunHint;

  final VoidCallback onAmeen;
  final VoidCallback? onRetry;
  final VoidCallback? onReturnHome;
  final VoidCallback? onOffTopicRetry;
  final VoidCallback? onShare;
  final void Function(int index, BeatKind kind)? onBeatAdvanced;
  final void Function(int fromIndex)? onSkip;

  /// Called the first time the user advances (so the host can bump the
  /// persisted lifetime counter that eventually hides the hint).
  final VoidCallback? onFirstAdvance;

  /// Optional tour anchors (decisions 3A / 10A): the host wraps the tap-hint
  /// zone (`readStoryCta`) and the Ameen pill (`ameenCta`).
  final Widget Function(Widget child)? readStoryAnchorBuilder;
  final Widget Function(Widget child)? ameenAnchorBuilder;

  /// Replaces the default "Preparing your reflection…" body while [status] is
  /// [BeatFlowStatus.loading].
  ///
  /// Added for the onboarding kindling beat (Wave G): that beat is not a wait,
  /// it is the moment the lantern is lit, and it has to sit in the loading slot
  /// specifically so it inherits the existing `AnimatedSwitcher` dissolve into
  /// beat 1 rather than introducing a competing transition. Null everywhere
  /// else — the two AI surfaces keep the ripple loader.
  final Widget? loadingView;

  /// Replaces the default off-topic line, and adds a second, quieter line under
  /// it. Reflect leaves both null and keeps the string it has always shown.
  ///
  /// The daily loop needs its own wording because the two surfaces are not in
  /// the same situation. In Reflect the user typed into a box whose only job is
  /// to be reflected on, and being asked to rephrase costs them nothing. In the
  /// daily loop they answered *"What's on your heart today?"*, have already
  /// been given their Name, and are being asked to say it again — so the line
  /// has to read as an invitation rather than a rejection.
  final String? offTopicMessage;
  final String? offTopicBody;

  const BeatRevealFlow({
    super.key,
    required this.status,
    required this.response,
    required this.onAmeen,
    this.screens,
    this.includeVerses = false,
    this.includeName = true,
    this.showFirstRunHint = false,
    this.onRetry,
    this.onReturnHome,
    this.onOffTopicRetry,
    this.onShare,
    this.onBeatAdvanced,
    this.onSkip,
    this.onFirstAdvance,
    this.readStoryAnchorBuilder,
    this.ameenAnchorBuilder,
    this.loadingView,
    this.offTopicMessage,
    this.offTopicBody,
  });

  @override
  State<BeatRevealFlow> createState() => _BeatRevealFlowState();
}

class _BeatRevealFlowState extends State<BeatRevealFlow> {
  int _index = 0;
  bool _forward = true;
  bool _completing = false;
  bool _firstAdvanceFired = false;
  bool _nameEntrancePlayed = false;

  List<BeatScreen> get _screens {
    final prebuilt = widget.screens;
    if (prebuilt != null) return prebuilt;
    final response = widget.response;
    if (response == null) return const <BeatScreen>[];
    return buildBeatScreens(
      response,
      includeVerses: widget.includeVerses,
      includeName: widget.includeName,
    );
  }

  bool get _reducedMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void didUpdateWidget(BeatRevealFlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A host that swaps the content under a live flow (deck → deck, or a retry
    // that lands a different response) would otherwise keep an index that is
    // now out of range for the new screen list. Restart from its first beat.
    //
    // Compared by content, not list identity: a host that rebuilds its screen
    // list inline in `build()` hands us a new list every frame, and an identity
    // check would reset the flow under the user's thumb.
    final old = oldWidget.screens;
    final now = widget.screens;
    final swapped = old?.length != now?.length ||
        (old != null &&
            now != null &&
            old.isNotEmpty &&
            now.isNotEmpty &&
            old.first.semanticText != now.first.semanticText) ||
        !identical(widget.response, oldWidget.response);
    if (swapped) {
      _index = 0;
      _nameEntrancePlayed = false;
    }
  }

  void _announce(String message) {
    // ignore: deprecated_member_use
    SemanticsService.announce(message, TextDirection.ltr);
  }

  void _advance() {
    if (_completing) return;
    final screens = _screens;
    if (_index >= screens.length - 1) return;
    HapticFeedback.lightImpact();
    if (!_firstAdvanceFired) {
      _firstAdvanceFired = true;
      widget.onFirstAdvance?.call();
    }
    setState(() {
      _forward = true;
      _index++;
    });
    final s = screens[_index];
    widget.onBeatAdvanced?.call(_index, s.kind);
    _announce('${s.semanticText}. Beat ${_index + 1} of ${screens.length}');
  }

  void _back() {
    if (_completing) return;
    if (_index <= 0) {
      // Back on the first beat exits the canvas (lifecycle stays inProgress;
      // the home CTA re-enters and restarts from beat 1).
      widget.onReturnHome?.call();
      return;
    }
    setState(() {
      _forward = false;
      _index--;
    });
    final s = _screens[_index];
    _announce('${s.semanticText}. Beat ${_index + 1} of ${_screens.length}');
  }

  void _skipToDua() {
    final screens = _screens;
    final target = duaScreenIndex(screens);
    if (target == _index) return;
    HapticFeedback.selectionClick();
    widget.onSkip?.call(_index);
    setState(() {
      _forward = target > _index;
      _index = target;
    });
    _announce(screens[_index].semanticText);
  }

  Future<void> _sayAmeen() async {
    if (_completing) return;
    HapticFeedback.mediumImpact();
    setState(() => _completing = true);
    await Future<void>.delayed(
      Duration(milliseconds: _reducedMotion ? 350 : 1100),
    );
    if (!mounted) return;
    widget.onAmeen();
  }

  /// The Name hero plays its draw-on entrance only the first time it's shown —
  /// back-navigating to beat 0 afterwards renders it static (the flag is set
  /// after the first frame that displays it).
  bool _playNameEntrance(BeatScreen screen) {
    if (screen.kind != BeatKind.name || _nameEntrancePlayed) return false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameEntrancePlayed = true;
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: DecoratedBox(
          decoration:
              const BoxDecoration(gradient: AppColors.sacredCanvasGradient),
          child: SafeArea(
            // The loading → ready swap used to pop. Fading it keeps the whole
            // entrance continuous: the canvas threshold's bloom lands on the
            // loader, then the loader dissolves into beat 1.
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: _reducedMotion ? 1 : 350),
              child: KeyedSubtree(
                key: ValueKey<BeatFlowStatus>(widget.status),
                child: _body(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    switch (widget.status) {
      case BeatFlowStatus.loading:
        return widget.loadingView ?? _LoadingView();
      case BeatFlowStatus.error:
        return _MessageView(
          message: "We couldn't prepare your reflection.",
          primaryLabel: 'Try Again',
          onPrimary: widget.onRetry,
          onReturnHome: widget.onReturnHome,
        );
      case BeatFlowStatus.offtopic:
        return _MessageView(
          message: widget.offTopicMessage ??
              "Share how you're feeling, and I'll find a Name for it.",
          secondary: widget.offTopicBody,
          primaryLabel: 'Try again',
          onPrimary: widget.onOffTopicRetry,
          onReturnHome: widget.onReturnHome,
        );
      case BeatFlowStatus.ready:
        if (_screens.isEmpty) {
          return _MessageView(
            message: "We couldn't prepare your reflection.",
            primaryLabel: 'Try Again',
            onPrimary: widget.onRetry,
            onReturnHome: widget.onReturnHome,
          );
        }
        return _flowView();
    }
  }

  Widget _flowView() {
    final screens = _screens;
    final screen = screens[_index];
    final isDua = screen.kind == BeatKind.dua;
    final isTakeaway = screen.kind == BeatKind.takeaway;
    // The completion CTA belongs to the LAST beat, whatever its kind. On the AI
    // path the duʿa is last, so this is the duʿa screen as before; deck decks
    // end `…dua → takeaway`, and keying on the duʿa would strand the user on the
    // takeaway with no way to complete.
    final isLast = _index == screens.length - 1;

    return Stack(
      children: [
        // Geometric accent, one corner, decorative only.
        const Positioned(
          top: -40,
          right: -60,
          child: _CanvasPattern(),
        ),

        // The current beat — a single semantics node with tap + custom actions.
        // Tap-to-advance wraps the content: a tap in the left 40% goes back, the
        // right 60% advances; vertical drags fall through to the inner scroll
        // view (center-until-overflow) via the gesture arena.
        Positioned.fill(
          top: 44,
          bottom: isLast ? 96 : 56,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapUp: (details) {
              final width = context.size?.width ?? 0;
              if (details.localPosition.dx < width * 0.4) {
                _back();
              } else {
                _advance();
              }
            },
            child: Semantics(
            button: true,
            label: '${screen.semanticText}. Beat ${_index + 1} of ${screens.length}',
            hint: 'Double-tap to continue',
            onTap: _advance,
            customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
              const CustomSemanticsAction(label: 'Next beat'): _advance,
              const CustomSemanticsAction(label: 'Previous beat'): _back,
              // Gated exactly like the visible button. Registering it
              // unconditionally left a screen-reader user able to trigger, on a
              // deck's final beat, the same backward jump and spurious
              // `reflect_flow_skipped` that was just removed for sighted users —
              // and `_skipToDua`'s `target == _index` guard does not catch it,
              // because on an 8-screen deck the duʿa is index 6 and the last
              // beat is index 7.
              if (!isDua && !isLast)
                const CustomSemanticsAction(label: 'Skip to duʿa'): _skipToDua,
            },
            child: AnimatedSwitcher(
              duration:
                  Duration(milliseconds: _reducedMotion ? 1 : 450),
              reverseDuration:
                  Duration(milliseconds: _reducedMotion ? 1 : 250),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: _transition,
              child: KeyedSubtree(
                key: ValueKey<int>(_index),
                child: BeatScreenView(
                  screen: screen,
                  playNameEntrance: _playNameEntrance(screen),
                ),
              ),
            ),
            ),
          ),
        ),

        // Top chrome: progress + skip.
        Positioned(
          top: 8,
          left: 18,
          right: 8,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: BeatProgressBar(
                  count: screens.length,
                  currentIndex: _index,
                ),
              ),
              const SizedBox(width: 10),
              // On the FINAL beat the skip button is worse than useless: the
              // shipped decks end `… dua → takeaway`, so `isDua` is false there
              // and "Skip to duʿa" renders — jumping the user BACKWARDS and
              // emitting a spurious `reflect_flow_skipped`. The slot it vacates
              // is where the share icon belongs anyway.
              if (!isDua && !isLast) _skipButton(),
              // `!isDua` matters as much as `isLast`. The AI path's screen list
              // always ENDS on the duʿa, so without it a second share icon
              // appeared there — Reflect would carry two affordances at once
              // (the floating one on its takeaway, this one on its duʿa) and the
              // AI path would not be untouched after all. Decks end on a
              // takeaway, so the deck path is unaffected by the guard.
              if (isLast && !isDua && widget.onShare != null)
                _shareIconInline(),
            ],
          ),
        ),

        if (isTakeaway && widget.onShare != null && !isLast) _shareButton(),
        if (isLast) _ameenPill(),
        if (widget.showFirstRunHint && _index <= 1 && !isLast) _tapHint(),
        if (_completing) const Positioned.fill(child: _CompletionBeat()),
      ],
    );
  }

  Widget _transition(Widget child, Animation<double> animation) {
    final beginOffset =
        _forward ? const Offset(0, 0.045) : const Offset(0, -0.045);
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: beginOffset, end: Offset.zero)
            .animate(animation),
        child: child,
      ),
    );
  }

  Widget _skipButton() {
    // Functional chrome: cream ink >= 80% (gold fails contrast on emerald),
    // >= 44px hit area.
    return Semantics(
      button: true,
      label: 'Skip to duʿa',
      child: InkResponse(
        onTap: _skipToDua,
        radius: 28,
        child: Container(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Skip to duʿa',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.sacredInk.withValues(alpha: 0.85),
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  /// Share on the FINAL beat, in the top-right slot the skip button vacates.
  ///
  /// The floating [_shareButton] cannot be reused here: it sits at `bottom: 18`
  /// and the Ameen pill occupies `bottom: 24` plus 56 of height, so the icon
  /// would land on top of the primary action. This is also the better moment —
  /// someone who has just finished the deck and is about to say Ameen is far
  /// likelier to share than someone mid-flow. The AI path keeps the floating
  /// button, because there the takeaway is never the last beat.
  Widget _shareIconInline() {
    return Semantics(
      button: true,
      label: 'Share this reflection',
      child: InkResponse(
        onTap: widget.onShare,
        radius: 26,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.ios_share,
            size: 21,
            color: AppColors.sacredInk.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }

  Widget _shareButton() {
    return Positioned(
      right: 14,
      bottom: 18,
      child: Semantics(
        button: true,
        label: 'Share this reflection',
        child: InkResponse(
          onTap: widget.onShare,
          radius: 26,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Icon(
              Icons.ios_share,
              size: 21,
              color: AppColors.sacredInk.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ameenPill() {
    final pill = GestureDetector(
      onTap: _sayAmeen,
      child: Container(
        width: double.infinity,
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
          'Ameen',
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.sacredCanvasTop,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
    final wrapped = widget.ameenAnchorBuilder?.call(pill) ?? pill;
    return Positioned(
      left: 24,
      right: 24,
      bottom: 24,
      child: Semantics(button: true, label: 'Ameen', child: wrapped),
    );
  }

  Widget _tapHint() {
    // The hint is an active advance target (not just decoration): tapping it
    // advances the beat. It sits below the content tap-zone, so it's the tour's
    // `readStoryCta` anchor — tapping the outlined hint advances the beat AND
    // the tour, the same gesture the flow teaches.
    final label = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.unfold_more,
          size: 16,
          color: AppColors.sacredInk.withValues(alpha: 0.45),
        ),
        const SizedBox(height: 2),
        Text(
          'Tap to move through your reflection',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.sacredInk.withValues(alpha: 0.45),
          ),
        ),
      ],
    ).animate(onPlay: (c) => _reducedMotion ? null : c.repeat(reverse: true)).fadeIn(
          duration: 1200.ms,
          begin: 0.35,
        );
    final hint = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _advance,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: label,
      ),
    );
    final wrapped = widget.readStoryAnchorBuilder?.call(hint) ?? hint;
    return Positioned(left: 0, right: 0, bottom: 22, child: Center(child: wrapped));
  }
}

// ── Loading ──────────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The ripple Lottie (fixed gold+emerald) — its purpose is longer AI
          // waits, and it reads on the emerald sacred canvas without a tint.
          // (Passing `color` here forced the old monochrome khatam SVG.)
          const SakinaLoader(variant: SakinaLoaderVariant.ripple),
          const SizedBox(height: 20),
          Text(
            'Preparing your reflection…',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.sacredInk.withValues(alpha: 0.70),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error / off-topic (shared warm, in-canvas layout) ──────────────────────
class _MessageView extends StatelessWidget {
  final String message;

  /// An optional quieter line under [message]. Only the daily loop's off-topic
  /// view uses it; every other message here is a single line by design.
  final String? secondary;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onReturnHome;

  const _MessageView({
    required this.message,
    required this.primaryLabel,
    this.secondary,
    this.onPrimary,
    this.onReturnHome,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge.copyWith(
                fontSize: 22,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppColors.sacredInk,
              ),
            ),
            if (secondary != null) ...[
              const SizedBox(height: 12),
              Text(
                secondary!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  height: 1.45,
                  color: AppColors.sacredInk.withValues(alpha: 0.75),
                ),
              ),
            ],
            const SizedBox(height: 28),
            if (onPrimary != null)
              GestureDetector(
                onTap: onPrimary,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    primaryLabel,
                    style: AppTypography.labelLarge
                        .copyWith(color: AppColors.sacredCanvasTop),
                  ),
                ),
              ),
            if (onReturnHome != null) ...[
              const SizedBox(height: 14),
              TextButton(
                onPressed: onReturnHome,
                child: Text(
                  'Return home',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.sacredInk.withValues(alpha: 0.80),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Completion beat (post-Ameen, non-interactive) ──────────────────────────
class _CompletionBeat extends StatelessWidget {
  const _CompletionBeat();

  @override
  Widget build(BuildContext context) {
    // Blur + dim the dua content behind so the "Ameen" moment stands alone on a
    // clean field instead of overlapping the still-visible dua text.
    return Stack(
      fit: StackFit.expand,
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: ColoredBox(
            color: AppColors.sacredCanvasBase.withValues(alpha: 0.66),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 44, color: AppColors.sacredInk)
                  .animate()
                  .scaleXY(begin: 0.6, end: 1.0, duration: 500.ms, curve: Curves.easeOutBack)
                  .fadeIn(duration: 400.ms),
              const SizedBox(height: 18),
              Text(
                'Ameen',
                style: AppTypography.bodyLarge.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sacredInk,
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 150.ms),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 220.ms);
  }
}

// ── Decorative geometric accent (8% cream, one corner) ─────────────────────
class _CanvasPattern extends StatelessWidget {
  const _CanvasPattern();

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.08,
          child: Icon(
            Icons.star_border,
            size: 190,
            color: AppColors.sacredInk,
          ),
        ),
      ),
    );
  }
}
