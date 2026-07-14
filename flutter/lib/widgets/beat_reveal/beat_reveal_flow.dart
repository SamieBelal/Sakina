import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
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

  /// Reflect passes true (verse beats between takeaway and duʿa); muḥāsabah false.
  final bool includeVerses;

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

  const BeatRevealFlow({
    super.key,
    required this.status,
    required this.response,
    required this.onAmeen,
    this.includeVerses = false,
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
  });

  @override
  State<BeatRevealFlow> createState() => _BeatRevealFlowState();
}

class _BeatRevealFlowState extends State<BeatRevealFlow> {
  int _index = 0;
  bool _forward = true;
  bool _completing = false;
  bool _firstAdvanceFired = false;

  List<BeatScreen> get _screens => widget.response == null
      ? const <BeatScreen>[]
      : buildBeatScreens(widget.response!, includeVerses: widget.includeVerses);

  bool get _reducedMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

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
          child: SafeArea(child: _body()),
        ),
      ),
    );
  }

  Widget _body() {
    switch (widget.status) {
      case BeatFlowStatus.loading:
        return _LoadingView();
      case BeatFlowStatus.error:
        return _MessageView(
          message: "We couldn't prepare your reflection.",
          primaryLabel: 'Try Again',
          onPrimary: widget.onRetry,
          onReturnHome: widget.onReturnHome,
        );
      case BeatFlowStatus.offtopic:
        return _MessageView(
          message: "Share how you're feeling, and I'll find a Name for it.",
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
          bottom: isDua ? 96 : 56,
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
                child: BeatScreenView(screen: screen),
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
              if (!isDua) _skipButton(),
            ],
          ),
        ),

        if (isTakeaway && widget.onShare != null) _shareButton(),
        if (isDua) _ameenPill(),
        if (widget.showFirstRunHint && _index <= 1 && !isDua) _tapHint(),
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
    final hint = IgnorePointer(
      child: Column(
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
      ),
    ).animate(onPlay: (c) => _reducedMotion ? null : c.repeat(reverse: true)).fadeIn(
          duration: 1200.ms,
          begin: 0.35,
        );
    final wrapped = widget.readStoryAnchorBuilder?.call(hint) ?? hint;
    return Positioned(left: 0, right: 0, bottom: 30, child: Center(child: wrapped));
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
          const SakinaLoader(color: AppColors.sacredInk),
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
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onReturnHome;

  const _MessageView({
    required this.message,
    required this.primaryLabel,
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
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 22,
                height: 1.35,
                color: AppColors.sacredInk,
              ),
            ),
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
    return ColoredBox(
      color: AppColors.sacredCanvasBase.withValues(alpha: 0.001),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 40, color: AppColors.secondary)
                .animate()
                .scaleXY(begin: 0.6, end: 1.0, duration: 500.ms, curve: Curves.easeOutBack)
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 16),
            Text(
              'Ameen',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 30,
                color: AppColors.sacredInk,
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 150.ms),
          ],
        ),
      ),
    );
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
