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
class ReflectionStoryPage extends StatefulWidget {
  const ReflectionStoryPage({
    required this.reflection,
    this.completionLabel = 'Done',
    super.key,
  });

  final SavedReflection reflection;
  final String completionLabel;

  @override
  State<ReflectionStoryPage> createState() => _ReflectionStoryPageState();

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
}

class _ReflectionStoryPageState extends State<ReflectionStoryPage> {
  /// One dismissal per page.
  ///
  /// [_dismiss] pops UNCONDITIONALLY (see below), so without this a double-tap
  /// on "Done" inside one frame would pop twice — this route and the Journal
  /// underneath it. The live flow is protected from that by its ceremony latch
  /// (`_completing`), which a re-read deliberately does not set: it has no
  /// ceremony to latch during.
  bool _dismissed = false;

  /// Leaves the story.
  ///
  /// **`pop`, never `maybePop` — this is the fix for a real bug.**
  /// [BeatRevealFlow] wraps itself in `PopScope(canPop: false)` whose handler
  /// calls its own `_back()`, which is how the system back GESTURE steps back
  /// one beat instead of abandoning the night. `maybePop` is precisely the call
  /// that `PopScope` intercepts, so the "Done" pill — which ran through
  /// `maybePop` — was refused the pop and handed to `_back()` instead. The
  /// reader tapped Done on the last beat and got sent back one screen: on a
  /// saved entry the beats end `… → verse → duʿā`, so that landed on the ayah,
  /// with no way out but the system gesture.
  ///
  /// An imperative `pop` does not consult `PopScope`, which is exactly the
  /// distinction wanted here: the GESTURE still means "back one beat", and the
  /// BUTTON means "I am done".
  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final screens = buildBeatScreensFromReflection(
      widget.reflection,
      coverLabel: ReflectionStoryPage.coverLabel(widget.reflection),
    );
    return BeatRevealFlow(
      status: BeatFlowStatus.ready,
      // No AI response behind a re-read — the saved row IS the content, exactly
      // as a deck's beats are on the reveal path.
      response: null,
      screens: screens,
      completionLabel: widget.completionLabel,
      showCompletionCeremony: false,
      onAmeen: _dismiss,
      // Back on the first beat leaves the canvas, matching the live flow's
      // gesture rather than trapping the reader on the cover.
      onReturnHome: _dismiss,
    );
  }
}
