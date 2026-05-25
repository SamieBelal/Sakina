import 'package:flutter/material.dart';

/// Renders large Arabic display text with ascender metric correction.
///
/// Aref Ruqaa and similar calligraphic Arabic fonts have large built-in
/// ascender whitespace (~32% of font size) above the visible glyphs. The
/// usual escape hatches — `height`, `StrutStyle(forceStrutHeight: true)`,
/// `FittedBox`, `OverflowBox`, `ClipRect`, negative padding — either clip
/// glyphs or fail to shift the glyph position within its line box across
/// navigation rebuilds. DO NOT try them; use this widget instead.
///
/// This widget applies a [Transform.translate] to visually shift the text
/// upward without affecting layout or clipping glyphs. Compensate for the
/// removed ascender with explicit `SizedBox` padding around the widget:
///
/// - **Above the Arabic:** `SizedBox(height: 44)` for `fontSize: 48`. Scale
///   proportionally for other sizes (e.g. `height: 33` for `fontSize: 36`).
/// - **Below the Arabic:** `SizedBox(height: 20)`.
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
