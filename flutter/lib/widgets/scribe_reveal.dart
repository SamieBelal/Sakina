import 'package:flutter/material.dart';

/// Reveals [child] along its reading direction, as if a hand were writing it.
///
/// **Why a mask and not a per-character typewriter.** Appending characters one
/// at a time is the usual way to do this, and it does not survive Arabic:
///
/// * Arabic is cursive and its glyphs are *contextually shaped* — a letter
///   renders differently depending on what follows it. Laying out
///   `text.substring(0, n)` re-shapes the trailing letter on every single
///   frame: it appears in its isolated/final form, then visibly morphs to
///   medial when the next character lands. That is a flicker on every letter.
/// * The harakat are separate combining code points. Character-by-character
///   makes a bare consonant appear and its vowel mark pop on a beat later, so
///   the line reads as broken rather than as written.
/// * `String.length` counts UTF-16 code units, so a naive slice can cut a
///   grapheme cluster in half.
///
/// Masking fully laid-out text has none of these problems: the line is shaped
/// once, correctly, and only the ink arrives. It is also the truer idiom — the
/// letters emerge connected, in stroke order, rather than being typed.
class ScribeReveal extends StatelessWidget {
  const ScribeReveal({
    required this.progress,
    required this.direction,
    required this.child,
    this.softness = 0.16,
    super.key,
  });

  /// 0 = nothing written, 1 = fully written.
  final double progress;

  /// The direction the hand travels. [TextDirection.rtl] for Arabic — the
  /// reveal must run right-to-left or it reads as a wipe rather than a stroke.
  final TextDirection direction;

  /// Width of the soft leading edge as a fraction of the box, wide enough that
  /// ink appears to bleed in rather than be uncovered by a hard edge.
  final double softness;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Once the line is written there is nothing to mask, and a ShaderMask costs
    // a saveLayer every frame — so drop out of the tree entirely.
    if (progress >= 1) return child;

    final rtl = direction == TextDirection.rtl;
    // Overrun the far edge by [softness] so the trailing soft edge clears the
    // box: at progress == 1 the line is fully opaque, not faded at one end.
    final head = (progress * (1 + softness)).clamp(0.0, 1.0);
    final tail = (progress * (1 + softness) - softness).clamp(0.0, 1.0);

    return ShaderMask(
      // The shader is the source and the child the destination, so dstIn keeps
      // the child exactly where the gradient is opaque.
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: rtl ? Alignment.centerRight : Alignment.centerLeft,
        end: rtl ? Alignment.centerLeft : Alignment.centerRight,
        colors: const [
          Colors.white,
          Colors.white,
          Colors.transparent,
          Colors.transparent,
        ],
        stops: [0, tail, head, 1],
      ).createShader(bounds),
      child: child,
    );
  }
}
