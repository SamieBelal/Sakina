import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_motion.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/features/daily/content/daily_question_copy.dart';
import 'package:sakina/features/daily/widgets/daily_question_chip_list.dart';
import 'package:sakina/features/daily/widgets/daily_question_defer_link.dart';
import 'package:sakina/features/daily/widgets/daily_question_field.dart';
import 'package:sakina/features/daily/widgets/daily_question_header.dart';
import 'package:sakina/features/daily/widgets/daily_question_submit_button.dart';
import 'package:sakina/features/onboarding/content/problem_chips.dart';
import 'package:sakina/services/daily_question_analytics.dart';

/// The daily loop's question surface (W4 Wave 2 — plan §4, spec M2/M4).
///
/// Renders where `DailyLoopStep.checkin`'s spinner used to be, on the emerald
/// sacred canvas so the crossing into the reveal has no seam. Free text is the
/// primary input; the seven approved [problemChips] sit underneath as
/// quick-fill.
///
/// **No urgency mechanics.** No timer, no auto-advance, no countdown, and
/// nothing guilt-shaped on the way out — the exit defers the whole loop rather
/// than dismissing it.
///
/// **Pure UI.** It owns no provider, claims no reward and runs no AI: the host
/// supplies [onSubmit] and [onDefer].
///
/// It does own three of the wave's five analytics events (W4 Wave 7), because
/// it is the only thing that knows them: `daily_question_shown` is this widget
/// mounting, and a skip and an abandon never reach the provider at all. The
/// dwell clock behind both is this mount's lifetime. `daily_question_answered`
/// is deliberately NOT here — the provider derives `problem_category` and
/// `input_mode` at submit, and re-deriving them up here would fork the
/// taxonomy.
///
/// **The text the user typed is never in any of them.** See the privacy note in
/// `daily_question_analytics.dart`.
class DailyQuestionPrompt extends StatefulWidget {
  const DailyQuestionPrompt({
    required this.onSubmit,
    required this.onDefer,
    this.entrySource = questionEntryDayOpen,
    this.commitBeat = AppMotion.feedback,
    super.key,
  });

  /// The answer, plus the chip that produced it when the user tapped rather
  /// than typed. Wave 3 turns this into `checkinAnswers` + `discoverName()`.
  final void Function(String text, {String? chipKey}) onSubmit;

  /// "Not right now" — the host writes the local-day marker and returns home,
  /// leaving the whole loop collectible from the home CTA for the rest of the
  /// day. No reveal, no reward, nothing consumed.
  final VoidCallback onDefer;

  /// How the user got here — `day_open` | `widget` | `home_cta`. Reported on
  /// `daily_question_shown` and nothing else; the outcome events do not repeat
  /// it because Mixpanel funnels carry the first step's properties forward.
  final String entrySource;

  /// The pause between filling the field from a chip and committing, so the
  /// user sees their own words land. Zero in tests.
  final Duration commitBeat;

  @override
  State<DailyQuestionPrompt> createState() => _DailyQuestionPromptState();
}

class _DailyQuestionPromptState extends State<DailyQuestionPrompt>
    with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();

  String? _selectedChipKey;

  /// One commit per mount. Covers the double-tap and the type-then-tap-a-chip
  /// race in one flag, and latches the defer, which navigates away.
  bool _committing = false;

  /// Time on the question, for `dwell_ms_bucket`. A [Stopwatch] rather than two
  /// `DateTime.now()` reads because it is monotonic — a device clock that moves
  /// under us (NTP, a timezone change, the user setting the clock) would
  /// otherwise produce negative or absurd dwells in exactly the bucket the
  /// short-abandon signal lives in.
  final Stopwatch _dwell = Stopwatch()..start();

  /// Whether this mount has already reported an outcome. Covers all three exits
  /// with one flag so a background-then-navigate-away cannot report two
  /// abandons for one question.
  bool _outcomeReported = false;

  static const EdgeInsets _padding = EdgeInsets.fromLTRB(
    AppSpacing.lg,
    AppSpacing.xl,
    AppSpacing.lg,
    AppSpacing.lg,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Mounting IS the show. The question is on the canvas from the first frame
    // — there is no load, no gate and no reveal in front of it — so there is no
    // later moment that would be more truthful.
    DailyQuestionAnalytics.shown(widget.entrySource);
  }

  @override
  void dispose() {
    // Navigated away, popped, or replaced by the reveal. The flag is what makes
    // the last case silent: a submit reports its own outcome from the provider
    // and then disposes this widget a frame later.
    _reportAbandonedIfUndecided();
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Backgrounding without deciding is an abandon, and NOT covered by
    // [dispose]: the route stays mounted, and if the OS reaps the app from the
    // background dispose never runs at all. Leaving it to dispose would
    // systematically undercount the most likely way someone bails on a question
    // about their heart — swiping away and not coming back.
    //
    // The honest edge, recorded because it shows up in the numbers: a user who
    // backgrounds here, returns, and then answers produces BOTH
    // `daily_question_abandoned` and `daily_question_answered` for one
    // `daily_question_shown`. `_outcomeReported` only latches this widget's own
    // events; `daily_question_answered` is emitted by the provider and stays
    // truthful whatever happened before it. So outcomes can sum to slightly
    // more than shows — read the abandon rate as "left at least once", not as
    // one minus the answer rate.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _reportAbandonedIfUndecided();
    }
  }

  void _reportAbandonedIfUndecided() {
    if (_outcomeReported || _committing) return;
    _outcomeReported = true;
    DailyQuestionAnalytics.abandoned(_dwell.elapsed);
  }

  void _submitTyped() {
    final text = _controller.text;
    if (_committing || text.trim().isEmpty) return;
    setState(() => _committing = true);
    // The answer's own event is the provider's (it owns `problem_category` and
    // `input_mode`); all this has to do is stop the abandon from firing when
    // the reveal replaces this widget.
    _outcomeReported = true;
    HapticFeedback.selectionClick();
    widget.onSubmit(text);
  }

  Future<void> _submitChip(ProblemChip chip) async {
    if (_committing) return;
    _outcomeReported = true;
    setState(() {
      _committing = true;
      _selectedChipKey = chip.chipKey;
      // Fills, THEN submits: the chip is a shortcut through the field, not a
      // parallel input, so the text the loop receives is the label verbatim.
      _controller.text = chip.label;
    });
    HapticFeedback.selectionClick();
    await Future<void>.delayed(widget.commitBeat);
    if (!mounted) return;
    widget.onSubmit(chip.label, chipKey: chip.chipKey);
  }

  void _defer() {
    if (_committing) return;
    setState(() => _committing = true);
    // A DEFER, never folded into the abandon. The user told us the placement
    // was wrong for this moment and the whole loop stays collectible from home;
    // an abandon says the question itself was wrong. Merging the two would
    // leave us unable to tell "people want this later" from "people don't want
    // this", which is the entire readout for this design (plan §9).
    _outcomeReported = true;
    DailyQuestionAnalytics.skipped(_dwell.elapsed);
    widget.onDefer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Transparent: the gradient below is the only surface, so the screen can
      // be crossed into through `SacredCanvasThreshold` without a seam.
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration:
            const BoxDecoration(gradient: AppColors.sacredCanvasGradient),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: _padding,
                  // The house pattern for every text-entry screen: the column
                  // may grow past the viewport (Dynamic Type, a raised
                  // keyboard) without ever overflowing the bottom. The padding
                  // sits OUTSIDE the LayoutBuilder so `constraints.maxHeight`
                  // is already the height the column actually gets.
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(child: _column(context)),
                      ),
                    ),
                  ),
                ),
              ),
              // **Outside the scroll view on purpose.** Seven chips plus a
              // multi-line field overflow an iPhone SE before Dynamic Type is
              // even considered, and an escape hatch the user has to go
              // looking for is not one (plan §2 rule 7). Pinning it here is
              // the only arrangement where the exit is visible at every screen
              // size and every type scale — and, because the Scaffold resizes
              // for the keyboard, it stays above the keyboard too.
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: AppSpacing.sm,
                ),
                child: _deferLink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _column(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    // Entrances overlap rather than queue (`app_motion.dart`): each layer
    // starts a beat after the previous one, while it is still settling.
    Widget rise(
      Widget child, {
      required Duration delay,
      double travel = AppMotion.riseMedium,
    }) =>
        child
            .animate(delay: delay)
            .fadeIn(duration: AppMotion.entrance, curve: AppMotion.enter)
            .moveY(
              begin: reduceMotion ? 0 : travel,
              end: 0,
              duration: AppMotion.entrance,
              curve: AppMotion.enter,
            );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        rise(
          const DailyQuestionHeader(
            title: DailyQuestionCopy.header,
            gloss: DailyQuestionCopy.gloss,
          ),
          delay: Duration.zero,
          travel: AppMotion.riseLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        rise(
          DailyQuestionField(
            controller: _controller,
            hintText: DailyQuestionCopy.placeholder,
            enabled: !_committing,
            onSubmitted: _submitTyped,
          ),
          delay: AppMotion.beat,
        ),
        const SizedBox(height: AppSpacing.md),
        rise(
          DailyQuestionSubmitButton(
            controller: _controller,
            label: DailyQuestionCopy.submit,
            onTap: _submitTyped,
          ),
          delay: AppMotion.beat,
        ),
        const SizedBox(height: AppSpacing.xl),
        DailyQuestionChipList(
          leadLabel: DailyQuestionCopy.chipsLead,
          selectedChipKey: _selectedChipKey,
          onChipTapped: _submitChip,
        ),
      ],
    );
  }

  /// Last to arrive — after every chip has landed. Not wrapped in `rise`: it
  /// lives outside the scrolling column, and a translate there would slide the
  /// pinned row against a fixed edge.
  Widget _deferLink() => DailyQuestionDeferLink(
        label: DailyQuestionCopy.defer,
        onTap: _defer,
      )
          .animate(
            delay: AppMotion.listStart +
                AppMotion.stagger * (problemChips.length + 1),
          )
          .fadeIn(duration: AppMotion.item, curve: AppMotion.enter);
}
