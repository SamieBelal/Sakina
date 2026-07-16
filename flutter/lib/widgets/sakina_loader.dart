import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:sakina/core/constants/app_colors.dart';

/// Variants of the Sakina loader.
///
/// - [breathingStar]: an 8-pointed khatam star that slowly pulses and rotates,
///   evoking a lamp breathing. Use for most loading states. When no [color] is
///   given it renders the premium two-tone (emerald + gold) Lottie medallion;
///   when an explicit [color] is passed (e.g. on the emerald sacred canvas) it
///   falls back to the monochrome khatam SVG so contrast is preserved.
/// - [ripple]: three concentric circles rippling outward. Use for longer
///   waits (e.g. AI generation) where you want "working, please wait" affordance.
enum SakinaLoaderVariant { breathingStar, ripple }

/// Brand-consistent loading indicator for Sakina.
///
/// Replaces `CircularProgressIndicator` so loading states feel devotional
/// rather than mechanical. Uses warm matte gold by default and respects the
/// "breathing" motion tokens used elsewhere in the app (1400ms ease-in-out).
class SakinaLoader extends StatefulWidget {
  const SakinaLoader({
    super.key,
    this.size = 120,
    this.color,
    this.variant = SakinaLoaderVariant.breathingStar,
  });

  /// Creates a full-screen loader wrapped in a themed [Scaffold].
  /// Convenience for the common "screen is booting" pattern. Uses a larger
  /// size so the mark reads as a centered focal point, not a small spinner.
  static Widget fullScreen({
    Color? color,
    SakinaLoaderVariant variant = SakinaLoaderVariant.breathingStar,
    double size = 180,
  }) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: SakinaLoader(size: size, color: color, variant: variant),
      ),
    );
  }

  final double size;
  final Color? color;
  final SakinaLoaderVariant variant;

  @override
  State<SakinaLoader> createState() => _SakinaLoaderState();
}

class _SakinaLoaderState extends State<SakinaLoader>
    with TickerProviderStateMixin {
  AnimationController? _breathController;

  @override
  void initState() {
    super.initState();

    switch (widget.variant) {
      case SakinaLoaderVariant.breathingStar:
        // Only the monochrome SVG fallback (explicit color) is driven by a
        // controller; the default path uses the self-animating Lottie asset.
        if (widget.color != null) {
          _breathController = AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1400),
          )..repeat(reverse: true);
        }
      case SakinaLoaderVariant.ripple:
        // Self-animating Lottie loop — no controller needed.
        break;
    }
  }

  @override
  void dispose() {
    _breathController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.variant) {
      case SakinaLoaderVariant.breathingStar:
        return _buildBreathingStar(widget.color);
      case SakinaLoaderVariant.ripple:
        return _buildRipple();
    }
  }

  Widget _buildBreathingStar(Color? color) {
    // Default: premium two-tone Lottie medallion (breathe + slow rotation baked
    // into the asset). Sits on cream surfaces across the app.
    if (color == null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Lottie.asset(
          'assets/animations/breathing_star.json',
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          repeat: true,
        ),
      );
    }

    // Explicit tint (e.g. sacredInk on the emerald canvas): monochrome khatam.
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _breathController!,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_breathController!.value);
          final scale = 0.85 + 0.15 * t;
          final opacity = 0.55 + 0.45 * t;
          final angle = _breathController!.value * 0.15;
          return Transform.rotate(
            angle: angle,
            child: Transform.scale(
              scale: scale,
              child: Opacity(opacity: opacity, child: child),
            ),
          );
        },
        child: SvgPicture.asset(
          'assets/icons/loader_star.svg',
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ),
    );
  }

  // The ripple loader is now a fixed-palette Lottie (baked gold + emerald),
  // so tinting is no longer supported — the [color] param is ignored. This
  // mirrors breathingStar, whose default Lottie path also ignores tint and
  // only colors the monochrome SVG fallback.
  // The ripple loader is a fixed-palette Lottie (baked gold + emerald), so the
  // widget's [color] is intentionally not applied here — mirrors breathingStar,
  // whose default Lottie path also ignores tint.
  Widget _buildRipple() {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Lottie.asset(
        'assets/animations/ripple_loader.json',
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        repeat: true,
      ),
    );
  }
}
