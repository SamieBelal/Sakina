import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/theme/app_typography.dart';

class AnimatedXpBar extends StatefulWidget {
  const AnimatedXpBar({
    super.key,
    required this.progress,
    this.lastGained = 0,
    this.height = 6,
  });

  final double progress;
  final int lastGained;
  final double height;

  @override
  State<AnimatedXpBar> createState() => _AnimatedXpBarState();
}

class _AnimatedXpBarState extends State<AnimatedXpBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _barController;
  late Animation<double> _barAnimation;

  int _floatKey = 0;
  int? _shownGained;
  Timer? _hideFloatTimer;

  @override
  void initState() {
    super.initState();
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _barAnimation = Tween<double>(
      begin: widget.progress,
      end: widget.progress,
    ).animate(CurvedAnimation(parent: _barController, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant AnimatedXpBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.progress != oldWidget.progress) {
      final currentValue = _barAnimation.value;
      _barController.reset();
      _barAnimation = Tween<double>(
        begin: currentValue,
        end: widget.progress,
      ).animate(
          CurvedAnimation(parent: _barController, curve: Curves.easeOut));
      _barController.forward();
    }

    if (widget.lastGained > 0 &&
        widget.lastGained != oldWidget.lastGained) {
      _hideFloatTimer?.cancel();
      setState(() {
        _floatKey++;
        _shownGained = widget.lastGained;
      });
      // Total animation: 200ms fadeIn + 1200ms slide + 200ms delay + 400ms fadeOut = 2000ms.
      // Hide the widget from the tree shortly after.
      _hideFloatTimer = Timer(const Duration(milliseconds: 2050), () {
        if (mounted) {
          setState(() => _shownGained = null);
        }
      });
    }
  }

  @override
  void dispose() {
    _hideFloatTimer?.cancel();
    _barController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _barAnimation,
          builder: (_, __) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(widget.height),
              child: LinearProgressIndicator(
                value: _barAnimation.value,
                minHeight: widget.height,
                backgroundColor: AppColors.borderLight,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            );
          },
        ),
        if (_shownGained != null)
          Positioned(
            top: -22,
            right: 0,
            child: Text(
              '+${_shownGained!} XP',
              key: ValueKey(_floatKey),
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.streakAmber,
                fontWeight: FontWeight.w800,
              ),
            )
                .animate(key: ValueKey('xp-float-$_floatKey'))
                .fadeIn(duration: 200.ms)
                .slideY(begin: 0.4, end: -0.6, duration: 1200.ms)
                .then(delay: 200.ms)
                .fadeOut(duration: 400.ms),
          ),
      ],
    );
  }
}
