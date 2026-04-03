import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class TypingTextWidget extends StatefulWidget {
  const TypingTextWidget({
    required this.text,
    this.charDuration = const Duration(milliseconds: 80),
    this.startDelay = Duration.zero,
    this.onComplete,
    this.style,
    super.key,
  });

  final String text;
  final Duration charDuration;
  final Duration startDelay;
  final VoidCallback? onComplete;
  final TextStyle? style;

  @override
  State<TypingTextWidget> createState() => _TypingTextWidgetState();
}

class _TypingTextWidgetState extends State<TypingTextWidget> {
  int _charCount = 0;
  Timer? _typingTimer;
  Timer? _cursorTimer;
  bool _showCursor = true;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _cursorTimer = Timer.periodic(
      const Duration(milliseconds: 530),
      (_) {
        if (mounted) setState(() => _showCursor = !_showCursor);
      },
    );

    if (widget.startDelay == Duration.zero) {
      _startTyping();
    } else {
      Future.delayed(widget.startDelay, () {
        if (mounted) _startTyping();
      });
    }
  }

  void _startTyping() {
    _started = true;
    _typingTimer = Timer.periodic(widget.charDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_charCount < widget.text.length) {
        setState(() => _charCount++);
      } else {
        timer.cancel();
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ??
        AppTypography.bodyLarge.copyWith(color: AppColors.textPrimaryLight);
    final cursorStyle = style.copyWith(
      color: _showCursor ? AppColors.primary : Colors.transparent,
    );

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: _started ? widget.text.substring(0, _charCount) : '',
            style: style,
          ),
          TextSpan(text: '|', style: cursorStyle),
        ],
      ),
    );
  }
}
