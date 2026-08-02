import 'dart:math' as math;

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

      // The deck's opening `recognition` beat reads as a key line.
      case BeatKind.keyLine:
      case BeatKind.recognition:
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

      // Deck comfort verses render exactly like catalog verses.
      case BeatKind.verse:
      case BeatKind.comfortVerse:
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
            // scripture-appropriate entrance than the pull-quote sweep. Deck
            // verses may carry translation only; then the block is omitted
            // rather than leaving an empty gap above the translation.
            if (screen.primary.isNotEmpty) ...[
              reduce
                  ? arabic
                  : arabic
                      .animate()
                      .fadeIn(duration: 420.ms)
                      .scaleXY(begin: 0.96, end: 1, duration: 460.ms, curve: Curves.easeOut),
              const SizedBox(height: AppSpacing.lg),
            ],
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
        // Standalone fields (deck path) win over the legacy response; the
        // getters resolve both, so a deck duʿa never renders blank.
        final arabic = screen.duaArabicText;
        final transliteration = screen.duaTransliterationText;
        final translation = screen.duaTranslationText;
        if (arabic.isEmpty && transliteration.isEmpty && translation.isEmpty) {
          return const SizedBox.shrink();
        }
        return DuaTextBlock(
          arabic: arabic,
          transliteration: transliteration,
          translation: translation,
          source: screen.duaSourceText,
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

    // The arch is a CONSTANT vessel: same width for every Name, whatever the
    // meaning line happens to be.
    //
    // This used to be `maxWidth`, a ceiling rather than a width, over a
    // `MainAxisSize.min` column — so the frame shrink-wrapped its content. The
    // meanings run 9 to 51 characters ("The Guide" against "The Trustee — the
    // Guardian you hand your affairs to"), and 12 of the 14 shipped decks are
    // short, so short Names collapsed the arch to roughly the width of their
    // Arabic while the two long ones pushed it to the full 360. Consecutive
    // reveals changed the frame's PROPORTION, which reads as inconsistency
    // rather than as responsiveness — the Name is what should vary, not the
    // vessel around it.
    //
    // Measured against the width this widget is ACTUALLY laid out in, not the
    // window. An earlier version subtracted a margin from `MediaQuery.sizeOf`,
    // which was dead arithmetic: the content already sits inside the screen's
    // 30px horizontal padding, so the incoming maxWidth is window-60 and
    // `SizedBox` clamps to its parent regardless — the subtracted term could
    // never win. Reading the real constraint says what it means and drops the
    // MediaQuery dependency. 360 is the cap on roomy devices; narrower ones
    // simply get their available width, so the arch stays constant per device.
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        width: math.min(360.0, constraints.maxWidth),
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
            // The whole meaning block — gap, reserve and text — is skipped when
            // there is no meaning, which makes the daily arch shorter than the
            // onboarding one. **That is intended (founder, 2026-07-30), not an
            // oversight.** Two reviews have now flagged it as the reserve
            // failing to do its job, so: hoisting the reserve out of this guard
            // would buy a constant height across both surfaces at the cost of a
            // permanent blank two-line band under every daily reveal. A rare
            // difference between surfaces was judged cheaper than a visible gap
            // on the common path. Please do not "fix" it without re-deciding
            // that trade.
            if (meaning.isNotEmpty) ...[
              const SizedBox(height: 6),
              // Within a surface that DOES show a meaning, two lines are
              // reserved whether or not the meaning fills them, so the arch
              // keeps its height as well as its width. Without this the frame
              // grew by a line between "The Guide" and "The Trustee — the
              // Guardian you hand your affairs to". The slack under a short
              // meaning sits above the diamond rule and reads as composure; a
              // frame that changes size between two consecutive reveals does
              // not.
              //
              //
              // Scaled, not a raw constant: the font it reserves for is
              // text-scaled, so an unscaled reserve silently stops reserving
              // anything. At textScaler 2.0 one line is already 45.9 — the whole
              // unscaled two-line budget — so the stabilisation would lapse for
              // exactly the users who most need a predictable layout, in a file
              // whose own contract is that text scale is honoured and never
              // capped.
              _in(
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.textScalerOf(context).scale(_meaningLineHeight) *
                            2,
                  ),
                  child: Text(
                    meaning,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.sacredInk,
                      fontStyle: FontStyle.italic,
                      fontSize: _meaningFontSize,
                      height: _meaningLineHeightFactor,
                    ),
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
      ),
    );
  }
}

/// The Name's meaning line, pinned so the two-line reserve in the arch can be
/// computed rather than eyeballed. Changing either value changes the reserved
/// height with it, which is the point — they must not drift apart.
const double _meaningFontSize = 17;
const double _meaningLineHeightFactor = 1.35;
const double _meaningLineHeight = _meaningFontSize * _meaningLineHeightFactor;

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
