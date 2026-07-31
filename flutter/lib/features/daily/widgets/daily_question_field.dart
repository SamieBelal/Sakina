import 'package:flutter/material.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_motion.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';

/// The daily question's free-text field — the PRIMARY input (spec M2).
///
/// On the sacred canvas, so none of the cream-surface field styling
/// (`free_text_dialog.dart`) carries over: the fill is 8% cream on emerald and
/// every stroke is a cream/gold accent rather than `borderLight`.
///
/// **Starts at one line and grows** (density pass, founder 2026-07-30). It used
/// to open at `minLines: 3` — ~130pt of empty box claimed before anyone had
/// typed anything, on a screen whose whole problem was that it asked for too
/// much attention at once. The field is not smaller; it is unreserved. By the
/// time there is a real sentence in it, it is exactly as tall as the sentence.
///
/// **The send control lives inside it.** See [_SendButton] — the reasoning is
/// there because it is where someone will read it.
class DailyQuestionField extends StatefulWidget {
  const DailyQuestionField({
    required this.controller,
    required this.enabled,
    required this.onSubmitted,
    super.key,
  });

  /// Handle for the send control.
  ///
  /// A key rather than a glyph or a semantics label, because both of those are
  /// the wrong thing to bind a test to: `find.byIcon` matches the 18pt icon
  /// rather than the 44pt tap target it sits inside, and `find.bySemanticsLabel`
  /// silently finds nothing unless that test happens to have called
  /// `ensureSemantics()` — which is how three assertions in this suite briefly
  /// passed for the wrong reason.
  static const Key sendButtonKey = ValueKey('daily-question-send');

  final TextEditingController controller;

  final bool enabled;
  final VoidCallback onSubmitted;

  @override
  State<DailyQuestionField> createState() => _DailyQuestionFieldState();
}

class _DailyQuestionFieldState extends State<DailyQuestionField> {
  /// Whether the field currently holds something submittable. Drives only the
  /// send button's colour — never its presence, see [_SendButton].
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final next = widget.controller.text.trim().isNotEmpty;
    if (next != _hasText) setState(() => _hasText = next);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          // One line at rest, growing to six. See the class dartdoc.
          minLines: 1,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          // Deliberately NOT `keyboardType.multiline` — that turns the return
          // key into a newline, and a newline is not what anyone wants from
          // this key here.
          textInputAction: TextInputAction.done,
          // **The keyboard's checkmark DISMISSES; it does not submit** (founder,
          // 2026-07-30). Overriding `onEditingComplete` is what does it —
          // Flutter's default implementation both submits and unfocuses.
          //
          // This is only safe because the send arrow exists. The original
          // wiring routed this key straight to submit precisely because it was
          // the sole way forward for anyone on an external keyboard or using
          // dictation; with an always-visible arrow that constraint is met, and
          // an accidental return on a composition about something painful no
          // longer commits it. Typing becomes a mode you step out of, which is
          // also what makes the un-pinned exit below reachable again.
          onEditingComplete: () => FocusScope.of(context).unfocus(),
          cursorColor: AppColors.sacredInk,
          style: AppTypography.bodyLarge.copyWith(color: AppColors.sacredInk),
          decoration: InputDecoration(
            // **No hint, and no helper either** (W4 Wave 2 review F1).
            //
            // The answer-set line that used to live here as `hintText` now
            // renders as a caption owned by `DailyQuestionPrompt`. It is the
            // only thing telling the user a grateful answer is permitted (spec
            // M4), and neither slot on a `TextField` can hold it safely:
            //
            //  * A HINT disappears the moment the field is non-empty — so the
            //    line vanished on the first keystroke, and was never shown at
            //    all on an off-topic re-ask, where the field opens pre-filled
            //    with the user's own words. That is precisely when someone
            //    needs to know what kind of answer is permitted.
            //  * `hintMaxLines: 3` plus `InputDecorator`'s ellipsis truncated
            //    it to "A worry, a thanks, a ques…" at large Dynamic Type,
            //    silently reverting the question to meaning "what's wrong".
            //  * A HELPER persists, but `InputDecorator` sizes the helper slot
            //    from `helperMaxLines` and clips to it — measured at one line,
            //    20pt for a 100pt string. Trading a hint's threshold for a
            //    helper's is not a fix.
            //
            // A plain caption above has no line budget at anyone's discretion,
            // so there is no font-dependent threshold left to get wrong.
            filled: true,
            fillColor: AppColors.sacredInk.withValues(alpha: 0.08),
            // Right padding clears the send button so a long line never runs
            // underneath it.
            contentPadding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              _SendButton.tapTarget + AppSpacing.xs,
              AppSpacing.md,
            ),
            border: _border(AppColors.sacredTrack),
            enabledBorder: _border(AppColors.sacredTrack),
            disabledBorder: _border(AppColors.sacredTrack),
            // Gold as a non-text accent only — never as a label colour.
            focusedBorder: _border(AppColors.secondary),
          ),
        ),
        // **Vertically centred, not bottom-anchored.** The chat-app convention
        // is to pin send to the bottom so it tracks the last line being typed,
        // and that is what this was — but this field opens at ONE line and most
        // answers are one to three, so bottom-anchoring read as misaligned in
        // the state the user actually meets. Centring is correct at one line
        // and stays acceptable as the field grows to six; the field is a single
        // composition, not a message thread, so nothing depends on the button
        // tracking the caret.
        Positioned(
          right: 2,
          top: 0,
          bottom: 0,
          child: Center(
            child: _SendButton(
              active: _hasText && widget.enabled,
              onTap: widget.onSubmitted,
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        borderSide: BorderSide(color: color, width: 1.5),
      );
}

/// The send control, inside the field (founder decision 2026-07-30).
///
/// **It is always present, and only its colour changes.** The alternative —
/// showing a "Continue" button once the field is non-empty — was mocked and
/// rejected for a reason worth keeping: while someone is still deciding what to
/// say, a screen with no visible submit affordance gives them no answer to
/// "how do I send this?". They have to trust something will appear. That is a
/// worse trade than the large disabled pill it was meant to replace.
///
/// It also has a mechanical justification independent of taste. This field
/// grows to six lines, and on a soft keyboard a multi-line field's return key
/// is not a reliable submit — so the surface needs its own send control however
/// the visual argument lands.
///
/// Inside the field rather than below it because it costs **no vertical space**
/// there, and because it is unambiguously *this* input's action: the seven
/// options below submit themselves on tap and must not look like they need it.
class _SendButton extends StatelessWidget {
  const _SendButton({required this.active, required this.onTap});

  /// The visible circle. Deliberately smaller than the tap target: a 44pt disc
  /// inside a text field crowds the text it sits beside.
  static const double diameter = 34;

  /// Apple's floor. The circle is 34pt to the eye and this to a finger — the
  /// gap is transparent padding, which is the standard way to keep a small
  /// control honest rather than an excuse for shipping one under the floor.
  static const double tapTarget = 44;

  /// There is submittable text. Drives colour only — never presence.
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: active,
      // Named for what it does to the user's answer, not for the glyph.
      label: 'Send',
      excludeSemantics: true,
      child: GestureDetector(
        key: DailyQuestionField.sendButtonKey,
        onTap: active ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: tapTarget,
          height: tapTarget,
          child: Center(
            child: AnimatedContainer(
              duration: AppMotion.feedback,
              curve: AppMotion.enter,
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Gold as a FILL is the sanctioned use on this canvas; gold as
                // text is not (DESIGN.md §2.3). The glyph on top is
                // canvas-dark, which is why this reads at contrast when active.
                color: active
                    ? AppColors.secondary
                    : AppColors.sacredInk.withValues(alpha: 0.10),
              ),
              child: Icon(
                Icons.arrow_upward_rounded,
                size: 18,
                color: active
                    ? AppColors.sacredCanvasTop
                    : AppColors.sacredInk.withValues(alpha: 0.30),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
