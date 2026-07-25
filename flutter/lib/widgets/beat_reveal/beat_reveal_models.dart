import 'package:sakina/core/utils/beat_splitter.dart';
import 'package:sakina/services/ai_service.dart';

/// The kind of a single beat screen — drives rendering, the analytics
/// `beat_kind` property, and the screen-reader label prefix.
enum BeatKind { name, keyLine, reframe, story, verse, takeaway, dua }

/// One screen in the tap-through reflection flow. Built by [buildBeatScreens]
/// from a [ReflectResponse]; the widget renders per [kind].
class BeatScreen {
  final BeatKind kind;

  /// Small-caps label above the body (story title, or '' for none).
  final String label;

  /// The primary body / pull-quote / beat text ('' for the dua screen).
  final String primary;

  /// Attribution line (story source, verse reference); '' when none.
  final String source;

  /// Arabic display text — populated only for [BeatKind.name] (the Name of
  /// Allah in Arabic script, rendered in the mihrab arch hero).
  final String arabic;

  /// Populated only for [BeatKind.dua] — the full dua stack + Ameen.
  final ReflectResponse? dua;

  const BeatScreen({
    required this.kind,
    this.label = '',
    this.primary = '',
    this.source = '',
    this.arabic = '',
    this.dua,
  });

  /// The full text a screen reader announces for this beat.
  String get semanticText {
    switch (kind) {
      case BeatKind.dua:
        final d = dua;
        if (d == null) return 'Duʿa';
        return [
          if (d.duaTransliteration.isNotEmpty) d.duaTransliteration,
          if (d.duaTranslation.isNotEmpty) d.duaTranslation,
          if (d.duaSource.isNotEmpty) d.duaSource,
        ].join('. ');
      default:
        return [
          if (label.isNotEmpty) label,
          if (primary.isNotEmpty) primary,
          if (source.isNotEmpty) source,
        ].join('. ');
    }
  }
}

/// Builds the ordered screen list for a response. Empty pieces are omitted, so
/// the segment count is content-driven. When the response carries no structured
/// beats (legacy / demo / re-hydrated old entry), it falls back to
/// [splitIntoBeats] over the joined prose so old content still animates.
///
/// [includeVerses] adds one screen per complete catalog verse between the
/// takeaway and the duʿa (Reflect surfaces only; muḥāsabah passes false).
///
/// [includeName] prepends the Name-of-Allah mihrab hero. Reflect passes true
/// (the hero opens the flow); muḥāsabah passes false because the gacha card
/// reveal already showed the Name moments earlier — see the "skip step 0"
/// decision in `daily_loop_provider.dart`.
List<BeatScreen> buildBeatScreens(
  ReflectResponse r, {
  bool includeVerses = false,
  bool includeName = true,
}) {
  final screens = <BeatScreen>[];

  // ── Name of Allah hero ── (mihrab arch; opens the flow). The transliteration
  // rides on `label`, the meaning on `source`; screen readers announce both.
  if (includeName && r.nameArabic.isNotEmpty) {
    screens.add(BeatScreen(
      kind: BeatKind.name,
      arabic: r.nameArabic,
      label: r.name,
      source: r.meaning,
    ));
  }

  // ── Reframe ──
  if (r.reframeKey.isNotEmpty) {
    screens.add(BeatScreen(kind: BeatKind.keyLine, primary: r.reframeKey));
  }
  if (r.hasBeats) {
    if (r.reframeBody.isNotEmpty) {
      screens.add(BeatScreen(kind: BeatKind.reframe, primary: r.reframeBody));
    }
  } else {
    for (final beat in splitIntoBeats(r.reframe)) {
      screens.add(BeatScreen(kind: BeatKind.reframe, primary: beat));
    }
  }

  // ── Story ── one beat per screen; title on the first, source on the last.
  final storyBeats =
      r.storyBeats.isNotEmpty ? r.storyBeats : splitIntoBeats(r.story);
  for (var i = 0; i < storyBeats.length; i++) {
    screens.add(BeatScreen(
      kind: BeatKind.story,
      label: i == 0 ? r.storyTitle : '',
      primary: storyBeats[i],
      source: i == storyBeats.length - 1 ? r.storySource : '',
    ));
  }

  // ── Takeaway ── (carries the share affordance in the widget)
  if (r.takeaway.isNotEmpty) {
    screens.add(BeatScreen(kind: BeatKind.takeaway, primary: r.takeaway));
  }

  // ── Verses (Reflect only) ── one per screen.
  if (includeVerses) {
    for (final v in r.verses.where((v) => v.isComplete)) {
      screens.add(BeatScreen(
        kind: BeatKind.verse,
        primary: v.arabic,
        label: v.translation,
        source: v.reference,
      ));
    }
  }

  // ── Duʿa ── always last; carries the Ameen CTA.
  screens.add(BeatScreen(kind: BeatKind.dua, dua: r));

  return screens;
}

/// The 0-based index of the duʿa screen — where "Skip to duʿa" lands.
int duaScreenIndex(List<BeatScreen> screens) =>
    screens.lastIndexWhere((s) => s.kind == BeatKind.dua).clamp(0, screens.length - 1);
