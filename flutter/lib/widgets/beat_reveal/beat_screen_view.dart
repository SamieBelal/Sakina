import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_models.dart';
import 'package:sakina/widgets/dua_text_block.dart';

/// Renders the CONTENT of a single [BeatScreen] on the sacred canvas — the
/// chrome (progress bar, skip, hint, Ameen pill, share icon) is overlaid by the
/// parent [BeatRevealFlow]. Applies the "center-until-overflow" rule: content
/// is vertically centered when it fits and top-aligned + scrollable when it
/// doesn't (accessibility text sizes / long beats never clip).
class BeatScreenView extends StatelessWidget {
  final BeatScreen screen;

  const BeatScreenView({super.key, required this.screen});

  static TextStyle _serif(double size) => GoogleFonts.dmSerifDisplay(
        fontSize: size,
        height: 1.32,
        color: AppColors.sacredInk,
      );

  Widget _goldBar() => Container(
        width: 26,
        height: 3,
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _content() {
    switch (screen.kind) {
      case BeatKind.keyLine:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _goldBar(),
            const SizedBox(height: 18),
            Text(screen.primary, style: _serif(27)),
          ],
        );

      case BeatKind.reframe:
        return Text(
          screen.primary,
          style: AppTypography.bodyLarge
              .copyWith(color: AppColors.sacredInk, height: 1.6, fontSize: 18),
        );

      case BeatKind.story:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (screen.label.isNotEmpty) ...[
              Text(
                screen.label.toUpperCase(),
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.secondary,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 14),
            ],
            Text(
              screen.primary,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.sacredInk,
                height: 1.65,
                fontSize: 18,
              ),
            ),
            if (screen.source.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                screen.source,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.sacredInkSoft,
                  fontStyle: FontStyle.italic,
                ),
                textDirection: TextDirection.ltr,
              ),
            ],
          ],
        );

      case BeatKind.verse:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: Text(
                screen.primary, // Arabic
                style: AppTypography.quranArabic
                    .copyWith(color: AppColors.sacredInk),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              screen.label, // translation
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.sacredInk,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
            ),
            if (screen.source.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                screen.source, // reference
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.sacredInkSoft,
                  fontStyle: FontStyle.italic,
                ),
                textDirection: TextDirection.ltr,
              ),
            ],
          ],
        );

      case BeatKind.takeaway:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _goldBar(),
            const SizedBox(height: 18),
            Text(screen.primary, style: _serif(23)),
          ],
        );

      case BeatKind.dua:
        final d = screen.dua;
        if (d == null) return const SizedBox.shrink();
        return DuaTextBlock(
          arabic: d.duaArabic,
          transliteration: d.duaTransliteration,
          translation: d.duaTranslation,
          source: d.duaSource,
          onSacredCanvas: true,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Center-until-overflow: a scroll view whose child is forced to at least the
    // viewport height, with the content vertically centered inside. Short
    // content centers; tall content (large text scale / long beats) scrolls
    // instead of clipping. textScaleFactor is honored fully — never capped.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 30,
                vertical: 24,
              ),
              child: Center(child: _content()),
            ),
          ),
        );
      },
    );
  }
}
