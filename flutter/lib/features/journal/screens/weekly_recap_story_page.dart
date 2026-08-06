import 'package:flutter/material.dart';

import 'package:sakina/features/journal/journal_resurfacing.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_flow.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_models.dart';

/// The four screens the weekly recap becomes when it is opened.
///
/// **Every beat is skipped when its data is empty**, which is not a nicety:
/// `themes` is empty whenever nobody's words matched a bucket (the model's own
/// doc comment calls that common), `oneLine` is empty for a week that produced
/// no line worth handing back, and `names` is empty for a row set with no Name.
/// A blank screen inside a tap-through flow is worse than a shorter flow — the
/// reader taps into nothing and cannot tell whether it broke.
///
/// **No new [BeatKind].** The four slots already existed:
///   * the opener is a [BeatKind.keyLine] — sweep bar, one pull quote, which is
///     what a key line has always been;
///   * themes and Names are [BeatKind.story] screens, the only kind that renders
///     a small-caps label above its body;
///   * the user's own line is a [BeatKind.entryCover], the kind that renders its
///     body inside curly quotes. It is the archive's "here are your words"
///     screen, and this is the archive.
///
/// The Names screen carries Latin transliterations only. Their Arabic is never
/// concatenated into it (CLAUDE.md) — the recap has no Arabic to render, and the
/// `Text` is pinned LTR so it cannot inherit a direction either.
List<BeatScreen> buildWeeklyRecapScreens(WeeklyRecap recap) {
  final screens = <BeatScreen>[
    BeatScreen(
      kind: BeatKind.keyLine,
      primary: JournalResurfacingCopy.recapOpener(recap.entryCount),
    ),
  ];

  final themes = recap.themes.where((t) => t.trim().isNotEmpty).toList();
  if (themes.isNotEmpty) {
    screens.add(BeatScreen(
      kind: BeatKind.story,
      label: JournalResurfacingCopy.recapThemesLabel,
      primary: themes.join(' · '),
    ));
  }

  final names = recap.names.where((n) => n.trim().isNotEmpty).toList();
  if (names.isNotEmpty) {
    screens.add(BeatScreen(
      kind: BeatKind.story,
      label: JournalResurfacingCopy.recapNamesLabel,
      primary: names.join(', '),
    ));
  }

  final line = recap.oneLine.trim();
  if (line.isNotEmpty) {
    screens.add(BeatScreen(
      kind: BeatKind.entryCover,
      label: JournalResurfacingCopy.recapWordsLabel,
      primary: line,
    ));
  }

  return screens;
}

/// The weekly recap, read as a story on the sacred canvas (2026-08-06).
///
/// Modelled on `ReflectionStoryPage` deliberately and down to the dismissal:
/// same [BeatRevealFlow], same "a reading is not a supplication" pair of props —
/// `showCompletionCeremony: false` and a `Done` label, so there is no "Ameen"
/// pill and no 1.1s bloom between "I have read this" and the archive coming
/// back.
class WeeklyRecapStoryPage extends StatefulWidget {
  const WeeklyRecapStoryPage({
    required this.recap,
    this.completionLabel = 'Done',
    super.key,
  });

  final WeeklyRecap recap;
  final String completionLabel;

  @override
  State<WeeklyRecapStoryPage> createState() => _WeeklyRecapStoryPageState();
}

class _WeeklyRecapStoryPageState extends State<WeeklyRecapStoryPage> {
  /// One dismissal per page — [_dismiss] pops UNCONDITIONALLY, so without this
  /// a double-tap on "Done" inside one frame pops twice: this route and the
  /// Journal underneath it.
  bool _dismissed = false;

  /// Leaves the story.
  ///
  /// **`pop`, never `maybePop`.** [BeatRevealFlow] wraps itself in
  /// `PopScope(canPop: false)` whose handler calls its own `_back()` — that is
  /// how the system back GESTURE steps back one beat instead of abandoning the
  /// flow. `maybePop` is precisely the call `PopScope` intercepts, so a "Done"
  /// routed through it is refused its pop and handed to `_back()` instead: the
  /// reader taps Done on the last beat and is sent back one screen. That was a
  /// real, shipped bug on the re-read page (fixed in `af71431`), and it is the
  /// same trap here.
  ///
  /// An imperative `pop` does not consult `PopScope`, which is the distinction
  /// wanted: the GESTURE still means "back one beat", the BUTTON means "I am
  /// done".
  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BeatRevealFlow(
      status: BeatFlowStatus.ready,
      // No AI response behind a recap — the resolver's output IS the content.
      response: null,
      screens: buildWeeklyRecapScreens(widget.recap),
      completionLabel: widget.completionLabel,
      showCompletionCeremony: false,
      onAmeen: _dismiss,
      // Back on the first beat leaves rather than trapping the reader on the
      // opener.
      onReturnHome: _dismiss,
    );
  }
}
