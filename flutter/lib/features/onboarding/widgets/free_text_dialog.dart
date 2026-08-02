import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_motion.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Derived from the approved prompt ("Or say it in your own words…") with the
/// leading "Or" and the ellipsis dropped: inside the modal this is a heading,
/// not one option among several.
const String freeTextDialogTitle = 'Say it in your own words';

const String freeTextDialogHint = 'Whatever it is, you can name it here.';

/// The check button's accessible name — sighted users get the glyph.
const String freeTextDialogSubmitLabel = 'Done';

/// The hook screen's free-text path, as a modal over a blurred canvas
/// (founder, 2026-07-29 — replaced the inline expanding field).
///
/// **Why a modal beat an inline field.** The inline version expanded *below*
/// seven options, so on a real device it opened under the fold, the screen had
/// to auto-scroll to find it, and the keyboard then covered the very rows the
/// user had just been reading. Worse, it left the six options live and competing
/// while someone was trying to compose a sentence about the hardest thing in
/// their week. A modal gives that sentence the whole screen.
///
/// **The scrim is dark emerald, not black.** A black scrim on a warm cream app
/// is what makes this flow read as "white on black" — the exact note this change
/// came from. [AppColors.sacredCanvasTop] is the emerald the app's sacred canvas
/// opens on, so the blur reads as the app receding rather than as a system
/// alert.
///
/// Returns the text **as typed** on Done, or null on dismiss. A dismissal must
/// commit nothing: this screen's answer decides which Names the user is shown.
Future<String?> showFreeTextDialog({
  required BuildContext context,
  required TextEditingController controller,
}) {
  return showGeneralDialog<String>(
    context: context,
    // The barrier is painted inside [_FreeTextDialog] so it can carry a blur; a
    // barrierColor here would sit on top of that blur instead of under it.
    barrierColor: Colors.transparent,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: AppMotion.entrance,
    pageBuilder: (_, __, ___) => _FreeTextDialog(controller: controller),
    transitionBuilder: (context, animation, _, child) {
      final reduceMotion = MediaQuery.of(context).disableAnimations;
      final eased = CurvedAnimation(parent: animation, curve: AppMotion.enter);
      if (reduceMotion) return FadeTransition(opacity: eased, child: child);
      // Rises the same short distance as every other entrance in the flow. No
      // scale — a popping dialog is the wrong register for this answer.
      return FadeTransition(
        opacity: eased,
        child: AnimatedBuilder(
          animation: eased,
          builder: (_, inner) => Transform.translate(
            offset: Offset(0, (1 - eased.value) * AppMotion.riseMedium),
            child: inner,
          ),
          child: child,
        ),
      );
    },
  );
}

class _FreeTextDialog extends StatelessWidget {
  const _FreeTextDialog({required this.controller});

  /// Owned by the screen, not by this dialog, so someone who dismisses and
  /// reopens meets their own half-written sentence rather than an empty box.
  final TextEditingController controller;

  static const double _blurSigma = 12;
  static const double _checkDiameter = 48;

  void _submit(BuildContext context) {
    final text = controller.text;
    if (text.trim().isEmpty) return;
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Tapping the blur dismisses. First in the stack, so the card and every
        // control on it sit above it in the hit-test order.
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
              child: ColoredBox(
                color: AppColors.sacredCanvasTop.withValues(alpha: 0.32),
              ),
            ),
          ),
        ),
        // The keyboard's inset shrinks the box the card centres itself in, so
        // the card lands centred in the space *above* the keyboard rather than
        // centred on the screen and then covered by it.
        Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Center(
            // Scrolls only when it has to: a short device at a large Dynamic
            // Type setting can make the card taller than the space left over
            // once the keyboard is up.
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              child: _card(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _card(BuildContext context) {
    return Material(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: Text(
                freeTextDialogTitle,
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              // This is the whole point of the modal: the keyboard is up before
              // the user has to reach for anything.
              autofocus: true,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              // Deliberately NOT keyboardType.multiline — that would turn the
              // return key into a newline and remove the only way forward for
              // anyone on an external keyboard or dictation.
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(context),
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w300,
                color: AppColors.textPrimaryLight,
              ),
              decoration: InputDecoration(
                hintText: freeTextDialogHint,
                hintStyle: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w300,
                  color: AppColors.textTertiaryLight,
                ),
                filled: true,
                fillColor: AppColors.backgroundLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                border: _border(AppColors.borderLight),
                enabledBorder: _border(AppColors.borderLight),
                focusedBorder: _border(AppColors.primary),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: _checkButton(context),
            ),
          ],
        ),
      ),
    );
  }

  /// The done affordance: emerald as a FILL with a white glyph on it, which is
  /// how this app is allowed to use a brand colour behind a mark (DESIGN.md
  /// §2.3). Matches `queue_name_row.dart`, the only other `check_rounded` in
  /// the flow.
  ///
  /// Always laid out and only faded, never added on the first keystroke — a
  /// button that appears mid-sentence shifts the field under the user's thumb.
  Widget _checkButton(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasText = value.text.trim().isNotEmpty;
        return IgnorePointer(
          ignoring: !hasText,
          child: AnimatedOpacity(
            opacity: hasText ? 1 : 0.35,
            duration: AppMotion.feedback,
            curve: AppMotion.enter,
            child: Semantics(
              button: true,
              enabled: hasText,
              label: freeTextDialogSubmitLabel,
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => _submit(context),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: _checkDiameter,
                  height: _checkDiameter,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 24,
                    color: AppColors.surfaceLight,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: 1.5),
      );
}
