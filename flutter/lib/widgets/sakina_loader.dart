import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sakina/core/constants/app_colors.dart';

/// Variants of the Sakina loader.
///
/// - [breathingStar]: an 8-pointed khatam star that slowly pulses and rotates,
///   evoking a lamp breathing. Use for most loading states.
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
    this.size = 90,
    this.color,
    this.variant = SakinaLoaderVariant.breathingStar,
  });

  /// Creates a full-screen loader wrapped in a themed [Scaffold].
  /// Convenience for the common "screen is booting" pattern.
  static Widget fullScreen({
    Color? color,
    SakinaLoaderVariant variant = SakinaLoaderVariant.breathingStar,
  }) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: SakinaLoader(color: color, variant: variant),
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
  List<AnimationController>? _rippleControllers;

  @override
  void initState() {
    super.initState();

    switch (widget.variant) {
      case SakinaLoaderVariant.breathingStar:
        _breathController = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1400),
        )..repeat(reverse: true);
      case SakinaLoaderVariant.ripple:
        _rippleControllers = List.generate(
          3,
          (_) => AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1600),
          ),
        );
        for (var i = 0; i < _rippleControllers!.length; i++) {
          Future.delayed(Duration(milliseconds: i * 530), () {
            if (mounted) _rippleControllers![i].repeat();
          });
        }
    }
  }

  @override
  void dispose() {
    _breathController?.dispose();
    if (_rippleControllers != null) {
      for (final c in _rippleControllers!) {
        c.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.secondary;
    switch (widget.variant) {
      case SakinaLoaderVariant.breathingStar:
        return _buildBreathingStar(color);
      case SakinaLoaderVariant.ripple:
        return _buildRipple(color);
    }
  }

  Widget _buildBreathingStar(Color color) {
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

  Widget _buildRipple(Color color) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(_rippleControllers!.length, (index) {
          return AnimatedBuilder(
            animation: _rippleControllers![index],
            builder: (context, _) {
              final value = _rippleControllers![index].value;
              final scale = 0.3 + (2.2 - 0.3) * value;
              final opacity = (0.6 - 0.6 * value).clamp(0.0, 1.0);
              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: widget.size * 0.4,
                    height: widget.size * 0.4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
