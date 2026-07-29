import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_motion.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/adjusted_arabic_display.dart';
import '../../../widgets/beat_reveal/mihrab_arch_frame.dart';
import '../../../widgets/beat_reveal/sacred_canvas_threshold.dart';

/// The app's opening beat — 2:286 on the sacred canvas (Wave H §6).
///
/// **This REPLACES the welcome screen** (`hook_screen.dart`, deleted
/// 2026-07-29). It does not precede it: comfort → welcome → question would be
/// two gates before the most exposing question in the app. The only element
/// carried over from the old screen is the "I already have an account" link.
///
/// Why it exists. Acquisition is two organic reels, and the second one promises
/// **2:286** — *Allah does not burden a soul beyond that it can bear*. The old
/// screen answered that promise with a **different** ayah (94:6), the tagline
/// "Reflect · Build · Discover" (a feature list, delivered to someone in pain),
/// and an arch image **fetched over the network from a `googleusercontent.com`
/// URL on the app's very first screen**. Ad-scent broke in the first second, and
/// the first frame depended on someone else's CDN.
///
/// It also closes a structural gap: we ask the most exposing question in the app
/// before depositing any trust. This is the deposit before the withdrawal.
///
/// **The arch is now code-drawn.** [MihrabArchFrame] — already the house arch,
/// already used for the Name-of-Allah hero — replaces the remote image outright,
/// so there is no asset to bundle and nothing to fetch. Its gold strokes are a
/// sanctioned non-text accent on the canvas (DESIGN.md §6.2); every glyph on the
/// screen is cream `sacredInk`/`Soft`/`Faint`.
///
/// **Arabic and Latin never share a `Text`** (CLAUDE.md). The ayah, its
/// translation and the reference are three widgets; the Arabic one carries an
/// explicit `TextDirection.rtl`.
///
/// **Motion.** This is the first thing the app ever does, so it is unhurried and
/// certain — not a splash, not a loader. Layers overlap rather than queue
/// ([AppMotion.beat] apart) and the last one settles at ~1.12s; a viewer who
/// arrived from a reel will not wait longer. No bounce. Under
/// `MediaQuery.disableAnimations` the travel and the arch draw-on drop out and
/// the fades remain — content is never gated behind an animation.
class ComfortOpeningScreen extends StatefulWidget {
  const ComfortOpeningScreen({
    required this.onNext,
    this.onSignIn,
    this.departureLead = AppMotion.beat,
    super.key,
  });

  // ── Copy ────────────────────────────────────────────────────────────────
  // Short, plain, small words. The verse does the theological work; the English
  // line only opens the door. Nothing here attributes a stance, intent or
  // outcome to Allah, claims a "sign", or implies the reader drifted.

  /// 2:286, verbatim from the app's pre-verified catalog
  /// (`reflection_verse_catalog.dart`) — never re-typed, never generated.
  static const String ayahArabic = 'لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا';

  /// The catalog's translation of the same verse, so the app renders 2:286 one
  /// way everywhere.
  static const String ayahEnglish =
      'Allah does not burden a soul beyond that it can bear.';

  static const String ayahReference = 'Al-Baqarah · 2:286';

  /// The one line the app speaks in its own voice. An open door, not a promise
  /// about what happens next.
  static const String acknowledgement =
      "Whatever you're carrying, you can bring it here.";

  static const String ctaLabel = 'Begin';

  /// Fired after the canvas has begun dissolving. Its future completes when the
  /// pushed flow is popped back here, which is what restores the canvas — see
  /// [_begin].
  final Future<void> Function() onNext;

  final VoidCallback? onSignIn;

  /// How long the departure dissolve runs before [onNext] fires. The push
  /// overlaps the dissolve rather than queueing behind it (the house rule); zero
  /// in tests.
  final Duration departureLead;

  @override
  State<ComfortOpeningScreen> createState() => _ComfortOpeningScreenState();
}

class _ComfortOpeningScreenState extends State<ComfortOpeningScreen> {
  /// Short screens (iPhone SE and friends) get a compacted rhythm — same
  /// threshold as the hook screen it hands over to.
  static const double _compactHeightThreshold = 700;

  /// True from the tap on Begin until the flow is popped back to this screen.
  bool _leaving = false;

  bool get _reduceMotion => MediaQuery.of(context).disableAnimations;

  /// Crossing out of the canvas, then into the (cream) hook screen.
  ///
  /// The emerald dissolves to cream first, so the push lands cream-on-cream and
  /// the user never meets the full-luminance inversion the threshold spec was
  /// written to kill. `_leaving` is restored when [ComfortOpeningScreen.onNext]'s
  /// future completes — i.e. when the flow is popped back to this route — which
  /// is the only moment the canvas is wanted again. Resetting on a timer instead
  /// would re-bloom the canvas underneath the page covering it.
  Future<void> _begin() async {
    if (_leaving) return;
    HapticFeedback.lightImpact();
    setState(() => _leaving = true);
    if (widget.departureLead > Duration.zero) {
      await Future<void>.delayed(widget.departureLead);
      if (!mounted) return;
    }
    await widget.onNext();
    if (!mounted) return;
    setState(() => _leaving = false);
  }

  void _signIn() {
    final onSignIn = widget.onSignIn;
    if (onSignIn == null || _leaving) return;
    HapticFeedback.lightImpact();
    onSignIn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Cream underneath, so the departure dissolve resolves onto the surface
      // the next screen is painted on.
      backgroundColor: AppColors.backgroundLight,
      body: SacredCanvasThreshold(
        onCanvas: !_leaving,
        child: _leaving
            ? const SizedBox.expand()
            : _canvas(context, key: const ValueKey('comfort-opening-canvas')),
      ),
    );
  }

  Widget _canvas(BuildContext context, {Key? key}) {
    final compact = MediaQuery.sizeOf(context).height < _compactHeightThreshold;
    final gap = compact ? AppSpacing.md : AppSpacing.lg;
    return DecoratedBox(
      key: key,
      decoration: const BoxDecoration(gradient: AppColors.sacredCanvasGradient),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            compact ? AppSpacing.md : AppSpacing.lg,
            AppSpacing.pagePadding,
            compact ? AppSpacing.md : AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _layer(
                _wordmark(),
                delay: Duration.zero,
                duration: AppMotion.layer,
                rise: AppMotion.riseMedium,
              ),
              SizedBox(height: gap),
              // The arch takes whatever the fixed rows leave, so the niche is
              // tall on a large phone and merely shorter on an SE — never
              // squashed into a tunnel mouth.
              Expanded(
                child: _layer(
                  _ayahInArch(compact: compact),
                  delay: AppMotion.beat,
                  duration: AppMotion.entrance,
                  rise: AppMotion.riseLarge,
                ),
              ),
              SizedBox(height: gap),
              _layer(
                Text(
                  ComfortOpeningScreen.acknowledgement,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyLarge.copyWith(
                    fontSize: 19,
                    height: 1.45,
                    color: AppColors.sacredInk,
                  ),
                ),
                delay: AppMotion.beat * 3,
                duration: AppMotion.entrance,
                rise: AppMotion.riseMedium,
              ),
              SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
              _layer(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _beginCta(),
                    SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
                    _signInLink(),
                  ],
                ),
                delay: AppMotion.beat * 4,
                duration: AppMotion.layer,
                rise: AppMotion.riseSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// One entrance layer. Travel drops out under reduced motion; the fade — and
  /// so the content — always stays.
  Widget _layer(
    Widget child, {
    required Duration delay,
    required Duration duration,
    required double rise,
  }) {
    return child
        .animate(delay: delay)
        .fadeIn(duration: duration, curve: AppMotion.enter)
        .moveY(
          begin: _reduceMotion ? 0 : rise,
          end: 0,
          duration: duration,
          curve: AppMotion.enter,
        );
  }

  /// Arabic-only, so it needs no direction guard beyond the widget's own —
  /// [AdjustedArabicDisplay] pins `TextDirection.rtl` and corrects Aref Ruqaa's
  /// ascender whitespace (direct Aref Ruqaa text bleeds into the row below).
  Widget _wordmark() => AdjustedArabicDisplay(
        text: AppStrings.sakinaArabic,
        style: AppTypography.nameOfAllahDisplay.copyWith(
          fontSize: 30,
          color: AppColors.sacredInkSoft,
        ),
      );

  /// Scripture inside the niche; the app's own voice stays outside it.
  Widget _ayahInArch({required bool compact}) {
    return MihrabArchFrame(
      // The draw-on is the sanctioned ~1s sacred moment (DESIGN.md §5) and
      // finishes inside the screen's own settle budget.
      animate: !_reduceMotion,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ComfortOpeningScreen.ayahArabic,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: AppTypography.quranArabic.copyWith(
                fontSize: compact ? 24 : 27,
                color: AppColors.sacredInk,
              ),
            ),
            SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
            // Translation and reference arrive a beat after the Arabic they
            // belong to, inside the layer that brought the arch.
            _layer(
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ComfortOpeningScreen.ayahEnglish,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.sacredInkSoft,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    ComfortOpeningScreen.ayahReference,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.sacredInkFaint,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
              delay: AppMotion.beat,
              duration: AppMotion.layer,
              rise: AppMotion.riseSmall,
            ),
          ],
        ),
      ),
    );
  }

  /// The canvas's own CTA shape — gold as a FILL with dark emerald ink on it,
  /// never gold text (DESIGN.md §2.3). Same pill as "Ameen".
  Widget _beginCta() {
    return Semantics(
      button: true,
      label: ComfortOpeningScreen.ctaLabel,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _begin,
        behavior: HitTestBehavior.opaque,
        child: Container(
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
            ComfortOpeningScreen.ctaLabel,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.sacredCanvasTop,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  /// The one element the old welcome screen must keep.
  Widget _signInLink() {
    return TextButton(
      onPressed: widget.onSignIn == null ? null : _signIn,
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        foregroundColor: AppColors.sacredInk,
      ),
      child: Text(
        AppStrings.hookLoginLink,
        textAlign: TextAlign.center,
        style: AppTypography.labelLarge.copyWith(
          // Chrome ink stays >=80% on the canvas (DESIGN.md §6.4).
          color: AppColors.sacredInk.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}
