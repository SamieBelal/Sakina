import 'package:flutter/material.dart';

/// Renders large Arabic display text with ascender metric correction.
///
/// Aref Ruqaa and similar calligraphic Arabic fonts have large built-in
/// ascender whitespace (~32% of font size) above the visible glyphs.
/// This widget applies a [Transform.translate] to visually shift the text
/// upward by that amount, without affecting layout or clipping glyphs.
class AdjustedArabicDisplay extends StatelessWidget {
  const AdjustedArabicDisplay({
    required this.text,
    required this.style,
    this.textAlign = TextAlign.center,
    super.key,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final fontSize = style.fontSize ?? 48.0;
    return Transform.translate(
      offset: Offset(0, -(fontSize * 0.05)),
      child: Text(
        text,
        style: style,
        textDirection: TextDirection.rtl,
        textAlign: textAlign,
      ),
    );
  }
}
