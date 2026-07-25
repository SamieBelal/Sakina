import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/widgets/adjusted_arabic_display.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_models.dart';
import 'package:sakina/widgets/beat_reveal/mihrab_arch_frame.dart';
import 'package:sakina/widgets/dua_text_block.dart';

/// Renders the CONTENT of a single [BeatScreen] on the sacred canvas — the
/// chrome (progress bar, skip, hint, Ameen pill, share icon) is overlaid by the
/// parent [BeatRevealFlow]. Applies the "center-until-overflow" rule: content
/// is vertically centered when it fits and top-aligned + scrollable when it
/// doesn't (accessibility text sizes / long beats never clip).
class BeatScreenView extends StatelessWidget {
  final BeatScreen screen;

  /// When true, the Name hero plays its one-time draw-on entrance (arch draws,
  /// crest + name stagger in). The host gates this to the first reveal so
  /// back-navigating to beat 0 doesn't replay it.
  final bool playNameEntrance;

  const BeatScreenView({
    super.key,
    required this.screen,
    this.playNameEntrance = false,
  });

  // Pull-quote style for the key line + takeaway. Uses the app's body font
  // (Outfit) — same family as the story beats — at a larger size + weight so it
  // still reads as a pull quote without switching to a serif.
  static TextStyle _pullQuote(double size) => AppTypography.bodyLarge.copyWith(
        fontSize: size,
        height: 1.35,
        fontWeight: FontWeight.w600,
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

  // Gold bar that sweeps in from the left (key line / takeaway accent).
  Widget _sweepBar(bool reduce) {
    final bar = _goldBar();
    if (reduce) return bar;
    return bar
        .animate()
        .scaleX(
          begin: 0,
          end: 1,
          alignment: Alignment.centerLeft,
          duration: 280.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(duration: 160.ms);
  }

  // Pull-quote text that fades up just after the bar sweeps.
  Widget _quoteText(String text, double size, bool reduce) {
    final t = Text(text, style: _pullQuote(size));
    if (reduce) return t;
    return t
        .animate()
        .fadeIn(delay: 150.ms, duration: 320.ms)
        .moveY(begin: 10, end: 0, delay: 150.ms, duration: 340.ms, curve: Curves.easeOutCubic);
  }

  Widget _content(bool reduce) {
    switch (screen.kind) {
      case BeatKind.name:
        return _NameHero(
          arabic: screen.arabic,
          transliteration: screen.label,
          meaning: screen.source,
          animate: playNameEntrance && !reduce,
        );

      case BeatKind.keyLine:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _sweepBar(reduce),
            const SizedBox(height: 18),
            _quoteText(screen.primary, 27, reduce),
          ],
        );

      case BeatKind.reframe:
        return Text(
          screen.primary,
          style: AppTypography.bodyLarge
              .copyWith(color: AppColors.sacredInk, height: 1.55, fontSize: 22),
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
                height: 1.6,
                fontSize: 22,
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
        final arabic = SizedBox(
          width: double.infinity,
          child: Text(
            screen.primary, // Arabic
            style:
                AppTypography.quranArabic.copyWith(color: AppColors.sacredInk),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The Arabic soft-settles in (fade + gentle scale) — a calmer,
            // scripture-appropriate entrance than the pull-quote sweep.
            reduce
                ? arabic
                : arabic
                    .animate()
                    .fadeIn(duration: 420.ms)
                    .scaleXY(begin: 0.96, end: 1, duration: 460.ms, curve: Curves.easeOut),
            const SizedBox(height: AppSpacing.lg),
            Text(
              screen.label, // translation
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.sacredInk,
                height: 1.55,
                fontSize: 20,
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
            _sweepBar(reduce),
            const SizedBox(height: 18),
            _quoteText(screen.primary, 23, reduce),
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
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
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
              child: Center(child: _content(reduce)),
            ),
          ),
        );
      },
    );
  }
}

/// The Name-of-Allah hero: the Arabic name, its transliteration and meaning,
/// framed by the gold mihrab arch on the sacred canvas.
class _NameHero extends StatelessWidget {
  const _NameHero({
    required this.arabic,
    required this.transliteration,
    required this.meaning,
    this.animate = false,
  });

  final String arabic;
  final String transliteration;
  final String meaning;

  /// One-time draw-on entrance: the arch strokes in, then the crest, name and
  /// meaning stagger up behind it. False → everything static (replays / RM).
  final bool animate;

  // Fade + rise a child in, delayed [ms] behind the arch draw (only when
  // [animate]). Static passthrough otherwise.
  Widget _in(Widget child, int ms) {
    if (!animate) return child;
    return child
        .animate()
        .fadeIn(delay: ms.ms, duration: 380.ms)
        .moveY(begin: 12, end: 0, delay: ms.ms, duration: 420.ms, curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final crest = animate
        ? const MihrabCrestOrnament(size: 26)
            .animate()
            .fadeIn(delay: 480.ms, duration: 360.ms)
            .scaleXY(begin: 0.6, end: 1, delay: 480.ms, duration: 460.ms, curve: Curves.easeOutBack)
        : const MihrabCrestOrnament(size: 26);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: MihrabArchFrame(
        animate: animate,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            crest,
            // Ascender-corrected Arabic (raw Aref Ruqaa bleeds — see widget doc).
            // Above/below padding scaled from the doc's 48px reference to 62px.
            const SizedBox(height: 40),
            _in(
              AdjustedArabicDisplay(
                text: arabic,
                style: AppTypography.nameOfAllahDisplay.copyWith(
                  fontSize: 62,
                  color: AppColors.sacredInk,
                ),
              ),
              620,
            ),
            const SizedBox(height: 26),
            if (transliteration.isNotEmpty)
              _in(
                Text(
                  transliteration,
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                760,
              ),
            if (meaning.isNotEmpty) ...[
              const SizedBox(height: 6),
              _in(
                Text(
                  meaning,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.sacredInk,
                    fontStyle: FontStyle.italic,
                    fontSize: 17,
                  ),
                ),
                860,
              ),
            ],
            const SizedBox(height: 20),
            _in(_DividerDiamond(), 960),
          ],
        ),
      ),
    );
  }
}

/// Small centered gold diamond flanked by hairlines — the reference mockup's
/// mid-card separator.
class _DividerDiamond extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget line() => Container(
          width: 34,
          height: 1,
          color: AppColors.secondary.withValues(alpha: 0.5),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        line(),
        const SizedBox(width: 8),
        Transform.rotate(
          angle: 0.785398, // 45°
          child: Container(
            width: 5,
            height: 5,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 8),
        line(),
      ],
    );
  }
}
