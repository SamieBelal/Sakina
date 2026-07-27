import 'package:flutter/material.dart';
import 'package:sakina/core/constants/app_colors.dart';

/// The segmented progress bar at the top of the beat reveal flow (one segment
/// per screen, Glorify / IG-story style). Gold fill on the [AppColors.sacredTrack]
/// track. Decorative — excluded from the semantics tree (the per-beat "beat N of
/// M" announcement carries progress for screen-reader users).
class BeatProgressBar extends StatefulWidget {
  final int count;
  final int currentIndex;

  const BeatProgressBar({
    super.key,
    required this.count,
    required this.currentIndex,
  });

  @override
  State<BeatProgressBar> createState() => _BeatProgressBarState();
}

class _BeatProgressBarState extends State<BeatProgressBar>
    with SingleTickerProviderStateMixin {
  /// One-shot: the bar arrives as a gold hairline that widens into the
  /// segmented track. It rides the bar's own first mount rather than the canvas
  /// entrance, because those are different moments on different paths — Reflect
  /// enters the canvas with the bar already present, muḥāsabah enters on the
  /// loading view and has no bar yet. Advancing a beat must not replay it.
  late final AnimationController _entrance;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery isn't available in initState, and reading reduced motion off
    // the platform dispatcher would ignore an inherited override.
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = Row(
      children: List.generate(widget.count, (i) {
        final filled = i <= widget.currentIndex;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == widget.count - 1 ? 0 : 5),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 3,
              decoration: BoxDecoration(
                color: filled ? AppColors.secondary : AppColors.sacredTrack,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }),
    );

    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _entrance,
        builder: (context, child) {
          final t = Curves.easeOutCubic.transform(_entrance.value);
          return Opacity(
            opacity: t,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(t, 1, 1),
              child: child,
            ),
          );
        },
        child: track,
      ),
    );
  }
}
