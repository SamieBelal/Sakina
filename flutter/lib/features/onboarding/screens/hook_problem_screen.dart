import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_motion.dart';
import '../../../core/constants/app_spacing.dart';
import '../content/problem_chips.dart';
import '../widgets/hook_free_text_block.dart';
import '../widgets/hook_screen_header.dart';
import '../widgets/problem_chip_card.dart';
import '../widgets/scroll_more_fade.dart';

/// The reel flow's first screen (One Ship W2-B2) — "What's weighing on you
/// right now?" — built to the founder-approved UX spec of 2026-07-25.
///
/// Deliberately NOT a `ConsumerWidget` and NOT wrapped in
/// `OnboardingPageWrapper`: the wrapper always renders the progress bar, and
/// spec ③ bans a step counter here (it signals a long form and manufactures
/// hurry on screen one). State arrives through the constructor; Wave E does the
/// PageView assembly and the provider write inside [onCommitted].
class HookProblemScreen extends StatefulWidget {
  const HookProblemScreen({
    required this.onCommitted,
    this.onBack,
    this.initialChipKey,
    this.resolver,
    this.commitBeat = const Duration(milliseconds: 450),
    super.key,
  });

  static const String headerLabel = "What's weighing on you right now?";

  /// Answers "why are you asking me this?" in the same breath as the question.
  /// A first-time user otherwise meets the most exposing question in the app
  /// with no idea what happens after they tap (revised 2026-07-27).
  static const String promiseLabel =
      "Whatever it is, there's a Name of Allah for it.";

  /// Fired once, after the selected-state beat, with everything the tap
  /// promised. Called from the tap handler's continuation — never during
  /// build — so a Riverpod mutation inside it is safe.
  final ValueChanged<ChipSelection> onCommitted;

  /// Omitted (no affordance rendered) when this is the flow's first page.
  final VoidCallback? onBack;

  /// The break above the sign row — see [_signSeparator].
  static const Key signSeparatorKey = ValueKey('hook-sign-separator');

  /// Pre-selects a card — how Wave E's `sakina://feel/<emotion>` link lands.
  ///
  /// Arrives LATE in practice: the drain that produces it is async and resolves
  /// after this screen's first build, so it reaches the State as a widget
  /// update, not as an initState value. [_HookProblemScreenState.didUpdateWidget]
  /// is what makes the pre-selection actually happen.
  final String? initialChipKey;

  final ProblemChipResolver? resolver;

  /// The pause between the selected state and [onCommitted]; zero in tests.
  final Duration commitBeat;

  @override
  State<HookProblemScreen> createState() => _HookProblemScreenState();
}

class _HookProblemScreenState extends State<HookProblemScreen> {
  late final ProblemChipResolver _resolver =
      widget.resolver ?? ProblemChipResolver();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocus = FocusNode();
  final ScrollController _scroll = ScrollController();
  final ValueNotifier<bool> _moreBelow = ValueNotifier<bool>(false);

  String? _selectedKey;
  bool _committing = false;
  bool _freeTextExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedKey = widget.initialChipKey;
  }

  /// Adopts a chip key that arrived AFTER the first build.
  ///
  /// The deep-link drain (`_drainReelDeepLinks`) reads SharedPreferences, so it
  /// always loses the race to this screen's `initState` — reading
  /// `initialChipKey` there alone left `sakina://feel/<emotion>` with no
  /// visible effect at all. The user's own answer still wins: once they have
  /// selected a card (or a commit is in flight), a late link is ignored rather
  /// than moving the selection under their finger.
  @override
  void didUpdateWidget(covariant HookProblemScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.initialChipKey;
    if (incoming == null || incoming == oldWidget.initialChipKey) return;
    if (_committing || _selectedKey != null) return;
    setState(() => _selectedKey = incoming);
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocus.dispose();
    _scroll.dispose();
    _moreBelow.dispose();
    super.dispose();
  }

  /// [resolve] is a thunk, not a future: a swallowed tap must never start work
  /// nobody awaits, and an eagerly-created future whose error lands after the
  /// guard returns is an unhandled async error.
  ///
  /// [unresolved] is what we commit when the deck lookup fails (missing or
  /// unparseable asset). Screen one has no other way forward, so a failure
  /// costs the tailored Names — the reveal reads the empty pair as the comfort
  /// fallback — and never the user's progress. No snackbar: the flow continues,
  /// so there is nothing to ask them to do.
  Future<void> _commit({
    required Future<ChipSelection> Function() resolve,
    required ChipSelection Function() unresolved,
    String? key,
  }) async {
    // Double-tap guard: the first tap owns the beat, later taps are ignored.
    if (_committing) return;
    setState(() {
      _committing = true;
      _selectedKey = key;
    });
    HapticFeedback.selectionClick();
    ChipSelection? selection;
    try {
      await Future<void>.delayed(widget.commitBeat);
      selection = await resolve();
    } catch (error, stack) {
      debugPrint('HookProblemScreen: chip resolve failed — $error\n$stack');
    } finally {
      // Always released, so a failure leaves the screen tappable rather than
      // frozen behind a guard that can no longer be cleared.
      if (mounted) {
        setState(() => _committing = false);
      } else {
        _committing = false;
      }
    }
    if (!mounted) return;
    widget.onCommitted(selection ?? unresolved());
  }

  void _openFreeText() {
    setState(() => _freeTextExpanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _textFocus.requestFocus();
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  bool _trackExtentAfter(Notification n) {
    if (n is ScrollMetricsNotification) {
      _moreBelow.value = n.metrics.extentAfter > 4;
    } else if (n is ScrollUpdateNotification) {
      _moreBelow.value = n.metrics.extentAfter > 4;
    }
    return false;
  }

  /// Short screens (iPhone SE and friends) get a compacted rhythm.
  ///
  /// Not cosmetic: at the roomy metrics the seventh row — "I can't put it into
  /// words" — falls below the fold on a 667pt screen, and that is the option
  /// built for the user who cannot name their state. NN/g eyetracking shows
  /// content just below the fold is viewed about half as much as content just
  /// above it, so the escape hatch has to stay on screen. Pinned by
  /// hook_problem_screen_small_device_test.dart.
  static const double _compactHeightThreshold = 700;

  @override
  Widget build(BuildContext context) {
    final compact =
        MediaQuery.sizeOf(context).height < _compactHeightThreshold;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            NotificationListener<Notification>(
              onNotification: _trackExtentAfter,
              child: ListView(
                controller: _scroll,
                // Top air is deliberate: the question wants to sit slightly
                // below the notch rather than butt against it, and the list
                // ends well clear of the bottom edge so nothing feels packed.
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  compact ? AppSpacing.md : AppSpacing.xl + AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                children: [
                  HookScreenHeader(
                    title: HookProblemScreen.headerLabel,
                    promise: HookProblemScreen.promiseLabel,
                    compact: compact,
                    onBack: widget.onBack,
                  ),
                  SizedBox(
                    height: compact ? AppSpacing.md : AppSpacing.lg + 4,
                  ),
                  ..._cards(compact: compact),
                  SizedBox(height: compact ? AppSpacing.sm : AppSpacing.lg),
                  HookFreeTextBlock(
                    expanded: _freeTextExpanded,
                    controller: _textController,
                    focusNode: _textFocus,
                    enabled: !_committing,
                    onExpand: _openFreeText,
                    onSubmit: (text) {
                      if (text.trim().isEmpty) return;
                      _commit(
                        resolve: () => _resolver.forFreeText(text),
                        unresolved: () => _resolver.unresolvedForFreeText(text),
                      );
                    },
                  )
                      // Last thing to arrive — after every option has landed.
                      .animate()
                      .fadeIn(
                        duration: 450.ms,
                        delay: AppMotion.listStart +
                            AppMotion.stagger * problemChips.length,
                      ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ScrollMoreFade(visible: _moreBelow),
            ),
          ],
        ),
      ),
    );
  }

  /// The list OVERLAPS the question's settle rather than queuing behind it.
  ///
  /// This is the "bite-sized" trick on a screen that cannot afford an extra
  /// tap: the eye still meets the question first, but the options begin
  /// arriving while it is finishing, so nothing waits on a dead frame. The
  /// first pass started the list at 620ms — exactly when the question stopped
  /// moving — which pushed the last row's settle to ~1370ms, well past the 1s
  /// ceiling NN/g puts on interface animation. Starting at 320ms with a 40ms
  /// stagger settles row seven at ~900ms instead.
  List<Widget> _cards({required bool compact}) {
    final cards = <Widget>[];
    final anySelected = _selectedKey != null;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    for (var i = 0; i < problemChips.length; i++) {
      final chip = problemChips[i];
      final isSelected = _selectedKey == chip.chipKey;
      final delay = AppMotion.listStart + AppMotion.stagger * i;
      // The sign row gets a break above it — air plus one hairline — so it
      // reads as "or, if none of these fit" rather than as a greyer seventh
      // option. The row it follows drops its own rule so the break is a single
      // line with air on both sides, not two lines 8px apart.
      final nextIsSign =
          i + 1 < problemChips.length && problemChips[i + 1].isSign;
      if (chip.isSign && i > 0) {
        cards.add(
          _signSeparator(
            compact: compact,
            delay: delay,
            dimmed: anySelected && !isSelected,
          ),
        );
      }
      cards.add(
        ProblemChipCard(
          chip: chip,
          selected: isSelected,
          dimmed: anySelected && !isSelected,
          showRule: i < problemChips.length - 1 && !nextIsSign,
          rowHeight: compact
              ? ProblemChipCard.compactMinHeight
              : ProblemChipCard.minHeight,
          onTap: () => _commit(
            resolve: () => _resolver.forChip(chip.chipKey),
            unresolved: () => _resolver.unresolvedForChip(chip.chipKey),
            key: chip.chipKey,
          ),
        )
            .animate(delay: delay)
            .fadeIn(duration: AppMotion.item, curve: AppMotion.enter)
            .moveY(
              begin: reduceMotion ? 0 : AppMotion.riseSmall,
              end: 0,
              duration: AppMotion.item,
              curve: AppMotion.enter,
            ),
      );
    }
    return cards;
  }

  /// Separation, not promotion.
  ///
  /// Reading the six problem chips does real diagnostic work and one of them
  /// usually lands, so the escape hatch stays last (spec 🟡, revised
  /// 2026-07-29). But distinguishing it by typography alone made it recede
  /// exactly when it should read as an obvious way out. Air plus a hairline
  /// gives it the weight of a section break without promoting it.
  ///
  /// Deliberately NOT a tinted surface — rejected 2026-07-25, because a tint
  /// reads as pre-selected and the selected state IS an emerald tint.
  ///
  /// It fades with the row it introduces and recedes with the rest of the list
  /// once an answer is in flight; a rule left at full strength beside dimmed
  /// rows is the one thing left glowing on a screen that is meant to resolve to
  /// a single line. No travel: a hairline sliding 10px is noise, not motion.
  Widget _signSeparator({
    required bool compact,
    required Duration delay,
    required bool dimmed,
  }) {
    final gap = compact ? AppSpacing.sm : AppSpacing.md;
    return AnimatedOpacity(
      duration: AppMotion.recede,
      curve: AppMotion.enter,
      opacity: dimmed ? ProblemChipCard.unselectedFade : 1,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: gap),
        child: SizedBox(
          key: HookProblemScreen.signSeparatorKey,
          height: 1,
          // The same hairline the rows use, so the break belongs to the list.
          child: ColoredBox(color: ProblemChipCard.ruleColor),
        ),
      ),
    ).animate(delay: delay).fadeIn(
          duration: AppMotion.item,
          curve: AppMotion.enter,
        );
  }
}
