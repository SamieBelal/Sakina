import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_motion.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/daily/content/daily_question_copy.dart';
import 'package:sakina/features/daily/widgets/daily_question_chip_list.dart';
import 'package:sakina/features/daily/widgets/daily_question_defer_link.dart';
import 'package:sakina/features/daily/widgets/daily_question_field.dart';
import 'package:sakina/features/daily/widgets/daily_question_header.dart';
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
    this.initialText,
    this.isReAsk = false,
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

  /// What to put in the field on open — the user's previous answer, when they
  /// are being asked to rephrase after an off-topic result.
  ///
  /// Making someone re-write a sentence about what they are carrying because a
  /// classifier did not like it is a small cruelty, and an empty box reads as
  /// *"that was deleted"*. The caret goes to the END so the keyboard opens
  /// ready to append rather than to overwrite.
  final String? initialText;

  /// Whether this mount is a re-ask rather than the day's first question.
  ///
  /// Suppresses `daily_question_shown`, for two reasons. The soft one: the app
  /// did not put the question in front of the user, the user asked for it back.
  /// The hard one: Wave 7's debug guard asserts that
  /// `daily_question_shown{entry_source: day_open}` fires at most once per
  /// local day, and a re-ask remounts this widget with the screen's original
  /// entry source — so emitting would trip that assert on the most ordinary
  /// possible path. The re-ask stays countable through `attempt` on
  /// `daily_question_answered`.
  final bool isReAsk;

  /// The pause between filling the field from a chip and committing, so the
  /// user sees their own words land. Zero in tests.
  final Duration commitBeat;

  @override
  State<DailyQuestionPrompt> createState() => _DailyQuestionPromptState();
}

class _DailyQuestionPromptState extends State<DailyQuestionPrompt>
    with WidgetsBindingObserver {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText ?? '',
  )..selection = TextSelection.collapsed(
      offset: (widget.initialText ?? '').length,
    );

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

  /// Short screens (SE and friends) get the compacted rhythm. One breakpoint
  /// for the whole surface — header step, row padding and every gap — computed
  /// here and threaded down, rather than each widget reading `MediaQuery` and
  /// drifting apart over time.
  ///
  /// 700pt and the metrics behind it are `hook_problem_screen.dart`'s, which
  /// asks this same question in onboarding and had them tuned on device.
  static const double _compactHeightThreshold = 700;

  EdgeInsets _padding(bool compact) => EdgeInsets.fromLTRB(
        AppSpacing.lg,
        // The question wants air above it. `xl` alone put the header almost
        // against the status bar, which is the other half of "no presence" —
        // a hero line that starts at the top edge reads as a toolbar title.
        compact ? AppSpacing.md : AppSpacing.xl + AppSpacing.md,
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
    //
    // Except on a re-ask, which is the user asking for the question back rather
    // than the app putting it to them, and which would trip Wave 7's
    // once-per-local-day day_open assert. See [DailyQuestionPrompt.isReAsk].
    if (!widget.isReAsk) DailyQuestionAnalytics.shown(widget.entrySource);
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
    // A re-ask emitted no `daily_question_shown`, so it must not emit an
    // outcome either — an abandon without its show would inflate the abandon
    // rate against a denominator it was never in.
    //
    // Giving up at the re-ask is still fully visible, just from the other side:
    // `daily_question_off_topic{attempt:1}` minus
    // `daily_question_answered{attempt:2}` is exactly the people who were asked
    // to rephrase and did not. That is the number to watch if the classifier
    // turns out to fire often.
    if (widget.isReAsk) return;
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
    // Suppressed on a re-ask for the same denominator reason as the abandon
    // above: no show, no outcome. The behaviour is unchanged — declining to
    // rephrase still returns home with everything already earned intact.
    if (!widget.isReAsk) DailyQuestionAnalytics.skipped(_dwell.elapsed);
    widget.onDefer();
  }

  @override
  Widget build(BuildContext context) {
    // **The gradient wraps the Scaffold rather than being its body.**
    //
    // It used to be the body, with a transparent Scaffold behind it — and that
    // is fine until the keyboard opens. `resizeToAvoidBottomInset` shrinks the
    // BODY to sit above the keyboard, so on iOS 26, whose keyboard is inset
    // with rounded corners, the strip the keyboard does not cover fell outside
    // the body entirely and showed the transparent Scaffold as **black**: a
    // hard black frame around three sides of the keyboard, against an emerald
    // canvas.
    //
    // Painting the gradient outside the Scaffold makes it cover the whole
    // route, so whatever the keyboard exposes is canvas. The Scaffold stays
    // transparent, which is the contract `SacredCanvasThreshold` crosses on.
    final compact = MediaQuery.sizeOf(context).height < _compactHeightThreshold;

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.sacredCanvasGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: _padding(compact),
            // The house pattern for every text-entry screen: the column may
            // grow past the viewport (Dynamic Type, a raised keyboard) without
            // ever overflowing the bottom. The padding sits OUTSIDE the
            // LayoutBuilder so `constraints.maxHeight` is already the height
            // the column actually gets.
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: _column(context, compact: compact),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _column(BuildContext context, {required bool compact}) {
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

    // **Two groups, `spaceBetween`.** The ask and its options are one unit; the
    // exit is not. Any height the viewport has left over after the unit lands
    // between them, so on a tall device the screen bottoms out at the exit
    // instead of stopping three-quarters of the way down and leaving a quarter
    // of the canvas empty (founder, 2026-07-31, from a Pro Max screenshot).
    //
    // `MainAxisAlignment`, NOT a `Spacer` — and this is the distinction that
    // broke it last time. A flex child has no intrinsic height to contribute,
    // so inside the `IntrinsicHeight` this column used to sit in, `Spacer`
    // inflated the measurement to 780pt on a 568pt screen and pushed the exit
    // off the bottom at every text size. `MainAxisAlignment` needs no flex
    // child: `RenderFlex` computes the free space from the column's FINAL
    // constrained height, which the `ConstrainedBox(minHeight:)` above has
    // already raised to the viewport. The `IntrinsicHeight` is gone with the
    // `Spacer` that needed it.
    //
    // Nothing about the keyboard-up behaviour changes. With the keyboard up
    // the viewport shrinks below the column's own height, the free space is
    // zero, and the exit sits directly under the last option and scrolls —
    // which is exactly the un-pinned behaviour asked for on 2026-07-30.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // **No gloss** (density pass, founder 2026-07-30). This screen used to
            // teach muḥāsabah here, one line under the question — but the home CTA
            // the user tapped a second earlier already carries
            // `DailyLoopCtaCopy.notStartedGloss`, teaching the same word in the
            // same breath. The definition was duplicated across two consecutive
            // screens, and this was the copy of it the user had least earned: it
            // arrives before they have done anything. `DailyQuestionCopy.gloss` is
            // retained for the surface that has earned it, not deleted.
            rise(
              DailyQuestionHeader(
                title: DailyQuestionCopy.header,
                compact: compact,
              ),
              delay: Duration.zero,
              travel: AppMotion.riseLarge,
            ),
            SizedBox(height: compact ? AppSpacing.xs + 2 : AppSpacing.sm + 2),
            // The answer set, as a persistent caption rather than the field's hint
            // (Wave 2 review F1). It says a grateful answer is permitted, which is
            // the job the chips used to do by simply existing — so it has to be
            // readable while the user types, and on a re-ask where the field opens
            // pre-filled. A hint is neither. No `maxLines`: this line wraps as far
            // as it needs to at any Dynamic Type step, because truncating it turns
            // the question back into "what's wrong".
            //
            // **Above the field, not below it** (density pass). Underneath, it sat
            // between the input and its action and read as a footnote to the box.
            // Here it completes the question — *this is what I am asking, and this
            // is what counts as an answer* — before the box appears, which is the
            // order the sentence is actually in.
            //
            // **`bodyLarge` at w400, not `bodyMedium` at w300** (founder,
            // 2026-07-31). This line is the whole of the permission to answer with
            // something good, and at 15pt hairline it read as fine print under the
            // question — the one register it must never have. Still quieter than
            // the header by two full steps and by 15% of ink, which is all the
            // subordination it needs.
            rise(
              Text(
                DailyQuestionCopy.answerSetCaption,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.sacredInk.withValues(alpha: 0.85),
                  height: 1.4,
                ),
              ),
              delay: Duration.zero,
              travel: AppMotion.riseLarge,
            ),
            SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg + 4),
            // The send control lives INSIDE this field now — see `_SendButton` in
            // `daily_question_field.dart` for why the standalone "Continue" pill
            // went. In short: it was disabled for the entire time the user was
            // deciding, occupying the best space on the screen to say nothing, and
            // hiding it until first keystroke left no visible answer to "how do I
            // send this?" at exactly the moment someone is working out what to say.
            rise(
              DailyQuestionField(
                controller: _controller,
                enabled: !_committing,
                onSubmitted: _submitTyped,
              ),
              delay: AppMotion.beat,
            ),
            SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
            DailyQuestionChipList(
              selectedChipKey: _selectedChipKey,
              compact: compact,
              onChipTapped: _submitChip,
            ),
          ],
        ),
        // **In the scroll flow, not pinned above the keyboard** (founder,
        // 2026-07-30). It used to sit outside the scroll view so it was on
        // screen at every size — but with the keyboard up that made it a
        // floating row hovering over a half-cut option list, which is what it
        // looked like on device.
        //
        // Plan §2 rule 7 still holds, by a different route: the exit is visible
        // without scrolling whenever the keyboard is DOWN, and the keyboard's
        // return key now dismisses rather than submits, so getting back to it
        // is one tap that the user is already reaching for. Typing is a mode
        // you leave, not a trap.
        //
        // The minimum gap; the `spaceBetween` above adds whatever the viewport
        // has spare on top of it. On a short screen that is nothing and the
        // exit sits directly under the last option.
        Padding(
          padding: EdgeInsets.only(
            top: compact ? AppSpacing.md : AppSpacing.lg,
          ),
          child: _deferLink(),
        ),
      ],
    );
  }

  /// Last to arrive — after every chip has landed. Not wrapped in `rise`: a
  /// translate would slide it against whatever edge the free space has just
  /// pushed it to.
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
