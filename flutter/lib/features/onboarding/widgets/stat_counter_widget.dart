import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class StatCounterWidget extends StatefulWidget {
  const StatCounterWidget({
    required this.targetValue,
    this.duration = const Duration(milliseconds: 1500),
    this.prefix,
    this.suffix,
    super.key,
  });

  final int targetValue;
  final Duration duration;
  final String? prefix;
  final String? suffix;

  @override
  State<StatCounterWidget> createState() => _StatCounterWidgetState();
}

class _StatCounterWidgetState extends State<StatCounterWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  final _formatter = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.targetValue.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _formatter.format(_animation.value.toInt());
        final text = '${widget.prefix ?? ''}$value${widget.suffix ?? ''}';
        return Text(
          text,
          style: AppTypography.displaySmall.copyWith(
            color: AppColors.textPrimaryLight,
          ),
        );
      },
    );
  }
}
