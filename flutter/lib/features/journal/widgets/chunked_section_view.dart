import 'package:flutter/material.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/core/utils/beat_splitter.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/widgets/dua_text_block.dart';

/// Renderer B (spec §4) — the cardless, typographic "chunked" layout for
/// re-reading surfaces (journal detail, Ameen/share summary).
///
/// Structured beats (`hasBeats == true`) render as:
///   1. `reframeKey` — a FREESTANDING typographic pull quote: a short gold bar
///      ABOVE the line, then serif emerald ink. Explicitly NOT a card, NOT a
///      side/border-left accent, no fill (AI-slop pattern we avoid).
///   2. `reframeBody` — a plain paragraph.
///   3. `storyTitle` — a serif title line (if present).
///   4. each `storyBeats` entry — its own paragraph, separated by whitespace.
///   5. `storySource` — a small italic/tertiary attribution line.
///   6. `takeaway` — a highlighted closing line (serif, gold accent bar).
///   7. dua — via [DuaTextBlock] (light theme, `onSacredCanvas: false`).
///
/// Legacy entries (`hasBeats == false`) fall back to
/// [splitIntoBeats] over `reframe` / `story` prose and render those as plain
/// paragraph chunks — with NO pull quote (a mid-sentence fragment promoted to a
/// pull quote reads worse than none).
///
/// Content sections are plain paragraphs separated by [AppSpacing] whitespace —
/// there are no card containers here (the old `_sectionCard` is dropped).
class ChunkedSectionView extends StatelessWidget {
  const ChunkedSectionView({required this.reflection, super.key});

  final SavedReflection reflection;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (reflection.hasBeats) {
      _buildStructured(children);
    } else {
      _buildLegacy(children);
    }

    // Dua block — unchanged structurally, on the light cream theme.
    if (reflection.duaArabic.isNotEmpty ||
        reflection.duaTranslation.isNotEmpty) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: AppSpacing.xl));
      }
      children.add(
        DuaTextBlock(
          arabic: reflection.duaArabic,
          transliteration: reflection.duaTransliteration,
          translation: reflection.duaTranslation,
          source: reflection.duaSource,
          onSacredCanvas: false,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  // ── Structured beats path ──────────────────────────────────────────────
  void _buildStructured(List<Widget> children) {
    if (reflection.reframeKey.isNotEmpty) {
      children.add(_pullQuote(reflection.reframeKey));
    }

    if (reflection.reframeBody.isNotEmpty) {
      _addGap(children);
      children.add(_paragraph(reflection.reframeBody));
    }

    if (reflection.storyTitle.isNotEmpty) {
      _addGap(children, large: true);
      children.add(_storyTitle(reflection.storyTitle));
    }

    for (final beat in reflection.storyBeats) {
      if (beat.trim().isEmpty) continue;
      _addGap(children);
      children.add(_paragraph(beat));
    }

    if (reflection.storySource.isNotEmpty) {
      _addGap(children);
      children.add(_attribution(reflection.storySource));
    }

    if (reflection.takeaway.isNotEmpty) {
      _addGap(children, large: true);
      children.add(_takeaway(reflection.takeaway));
    }
  }

  // ── Legacy fallback path ───────────────────────────────────────────────
  void _buildLegacy(List<Widget> children) {
    final reframeBeats = splitIntoBeats(reflection.reframe);
    final storyBeats = splitIntoBeats(reflection.story);

    // No pull quote for legacy entries — a mid-sentence fragment as a pull
    // quote looks worse than none. Just chunked paragraphs.
    for (final beat in reframeBeats) {
      if (children.isNotEmpty) _addGap(children);
      children.add(_paragraph(beat));
    }

    if (storyBeats.isNotEmpty) {
      if (children.isNotEmpty) _addGap(children, large: true);
      for (var i = 0; i < storyBeats.length; i++) {
        if (i > 0) _addGap(children);
        children.add(_paragraph(storyBeats[i]));
      }
    }

    // If there was no reframe/story at all, fall back to the preview.
    if (children.isEmpty && reflection.reframePreview.isNotEmpty) {
      for (final beat in splitIntoBeats(reflection.reframePreview)) {
        if (children.isNotEmpty) _addGap(children);
        children.add(_paragraph(beat));
      }
    }
  }

  void _addGap(List<Widget> children, {bool large = false}) {
    children.add(SizedBox(height: large ? AppSpacing.lg : AppSpacing.sm));
  }

  // ── Typographic pieces ─────────────────────────────────────────────────

  /// Freestanding pull quote: a short ~26px gold bar ABOVE the line, then a
  /// serif emerald line. No card, no fill, no side accent.
  Widget _pullQuote(String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          text,
          style: AppTypography.displaySmall.copyWith(
            fontSize: 22,
            height: 1.3,
            color: AppColors.primary,
          ),
          textDirection: TextDirection.ltr,
        ),
      ],
    );
  }

  Widget _paragraph(String text) {
    return Text(
      text,
      style: AppTypography.bodyLarge.copyWith(
        color: AppColors.textPrimaryLight,
        height: 1.6,
      ),
      textDirection: TextDirection.ltr,
    );
  }

  Widget _storyTitle(String text) {
    return Text(
      text,
      style: AppTypography.headlineMedium.copyWith(
        color: AppColors.textPrimaryLight,
      ),
      textDirection: TextDirection.ltr,
    );
  }

  Widget _attribution(String text) {
    return Text(
      text,
      style: AppTypography.bodySmall.copyWith(
        fontStyle: FontStyle.italic,
        color: AppColors.textTertiaryLight,
      ),
      textDirection: TextDirection.ltr,
    );
  }

  /// Highlighted closing line: serif, gold accent bar above.
  Widget _takeaway(String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          text,
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.secondary,
            height: 1.4,
          ),
          textDirection: TextDirection.ltr,
        ),
      ],
    );
  }
}
