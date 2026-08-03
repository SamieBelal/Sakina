import 'package:flutter/material.dart';

import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_flow.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_models.dart';

/// Re-reads a saved journal entry in the tap-through story format (Wave D, D2).
///
/// The archive's whole complaint was that an entry rendered as two lines of grey
/// text while the night it came from rendered as a full-screen sequence on the
/// sacred canvas. This is the same [BeatRevealFlow] the night used, fed by
/// [buildBeatScreensFromReflection] instead of a live AI response.
///
/// **A re-read is not a supplication.** It completes on [completionLabel]
/// ("Done") with no ceremony — see the two props on [BeatRevealFlow] for why
/// the live path's "Ameen" pill and 1.1s bloom are wrong here.
///
/// Renders nothing when the entry has no beats at all (an empty row, or one
/// whose only content was the user's own words): [canRenderAsStory] is the
/// caller's check, and the Journal only offers the affordance when it passes.
class ReflectionStoryPage extends StatelessWidget {
  const ReflectionStoryPage({
    required this.reflection,
    this.completionLabel = 'Done',
    super.key,
  });

  final SavedReflection reflection;
  final String completionLabel;

  /// Whether [reflection] has enough content for the story format to be worth
  /// offering. False for an entry that is only the user's own words — the flow
  /// would be a cover card and nothing else.
  static bool canRenderAsStory(SavedReflection r) =>
      buildBeatScreensFromReflection(r, includeCover: false).isNotEmpty;

  /// The cover card's small-caps date line, from the entry's own day.
  ///
  /// Prefers `entryLocalDay` — the night the entry belongs to — over `saved_at`,
  /// for the same reason every other surface does: near midnight the timestamp
  /// and the day disagree, and the day is the one the user lived.
  static String coverLabel(SavedReflection r) {
    final day = r.entryLocalDay;
    final parsed = day != null && day.isNotEmpty
        ? parseLocalDayString(day)
        : DateTime.tryParse(r.date);
    if (parsed == null) return '';
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
  }

  @override
  Widget build(BuildContext context) {
    final screens = buildBeatScreensFromReflection(
      reflection,
      coverLabel: coverLabel(reflection),
    );
    return BeatRevealFlow(
      status: BeatFlowStatus.ready,
      // No AI response behind a re-read — the saved row IS the content, exactly
      // as a deck's beats are on the reveal path.
      response: null,
      screens: screens,
      completionLabel: completionLabel,
      showCompletionCeremony: false,
      onAmeen: () => Navigator.of(context).maybePop(),
      // Back on the first beat leaves the canvas, matching the live flow's
      // gesture rather than trapping the reader on the cover.
      onReturnHome: () => Navigator.of(context).maybePop(),
    );
  }
}
