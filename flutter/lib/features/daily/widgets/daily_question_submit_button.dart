import 'package:flutter/material.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_motion.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';

/// The daily question's commit affordance.
///
/// Gold fill with canvas-dark text — the established primary on the sacred
/// canvas (`BeatRevealFlow._MessageView`), and the one way gold is allowed near
/// text on this surface: as a fill behind dark glyphs, never as the ink.
///
/// **Faded, never removed, while the field is empty.** A button that appears on
/// the first keystroke shifts the field under the user's thumb mid-sentence.
class DailyQuestionSubmitButton extends StatelessWidget {
  const DailyQuestionSubmitButton({
    required this.controller,
    required this.label,
    required this.onTap,
    super.key,
  });

  /// Watched rather than mirrored into parent state so a keystroke repaints
  /// this button alone, not the whole surface.
  final TextEditingController controller;

  final String label;
  final VoidCallback onTap;

  /// Comfortably past Apple's 44pt floor; a `minHeight` so Dynamic Type grows
  /// the pill instead of clipping the label.
  static const double minHeight = 56;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final ready = value.text.trim().isNotEmpty;
        return Semantics(
          button: true,
          enabled: ready,
          label: label,
          excludeSemantics: true,
          child: IgnorePointer(
            ignoring: !ready,
            child: AnimatedOpacity(
              opacity: ready ? 1 : 0.4,
              duration: AppMotion.feedback,
              curve: AppMotion.enter,
              child: GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  constraints: const BoxConstraints(minHeight: minHeight),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm + 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTypography.labelLarge
                        .copyWith(color: AppColors.sacredCanvasTop),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
