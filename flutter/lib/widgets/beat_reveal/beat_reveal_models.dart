import 'package:sakina/core/utils/beat_splitter.dart';
import 'package:sakina/models/name_story_deck.dart';
import 'package:sakina/services/ai_service.dart';

/// The kind of a single beat screen — drives rendering, the analytics
/// `beat_kind` property, and the screen-reader label prefix.
enum BeatKind {
  name,
  keyLine,
  reframe,
  story,
  verse,
  takeaway,
  dua,
  // ── Deck-native kinds (onboarding reveal) ──
  /// Opens the sign deck: "you didn't find this by accident". Styled as a key
  /// line.
  recognition,

  /// The steadying verse that follows [recognition] before the deck's own
  /// bridge. Styled as a verse.
  comfortVerse,
}

/// The value `beat_kind` carries in analytics.
///
/// New kinds are snake_case. [BeatKind.keyLine] is the one exception: it has
/// been emitting `keyLine` (from `.name`) since the beat flow shipped, so it
/// keeps that value — renaming it would split every existing beat funnel in
/// two. Exhaustive by design: a new kind must decide its wire value here.
extension BeatKindWireName on BeatKind {
  String get wireName {
    switch (this) {
      case BeatKind.name:
        return 'name';
      case BeatKind.keyLine:
        return 'keyLine'; // historical value — do not snake_case (see above)
      case BeatKind.reframe:
        return 'reframe';
      case BeatKind.story:
        return 'story';
      case BeatKind.verse:
        return 'verse';
      case BeatKind.takeaway:
        return 'takeaway';
      case BeatKind.dua:
        return 'dua';
      case BeatKind.recognition:
        return 'recognition';
      case BeatKind.comfortVerse:
        return 'comfort_verse';
    }
  }
}

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

  /// Populated only for [BeatKind.dua] on the AI path — the full dua stack.
  /// Deck-built screens leave this null and carry the four `dua*` fields below
  /// instead; read them through [duaArabicText] and friends, never directly.
  final ReflectResponse? dua;

  /// Standalone duʿa fields for [BeatKind.dua] screens that have no
  /// [ReflectResponse] behind them (the deck path). Kept as four separate
  /// fields so Arabic and Latin never share a widget.
  final String duaArabic;
  final String duaTransliteration;
  final String duaTranslation;
  final String duaSource;

  const BeatScreen({
    required this.kind,
    this.label = '',
    this.primary = '',
    this.source = '',
    this.arabic = '',
    this.dua,
    this.duaArabic = '',
    this.duaTransliteration = '',
    this.duaTranslation = '',
    this.duaSource = '',
  });

  // ── Effective duʿa text ──
  // The standalone field wins; the legacy response is the fallback. Renderers
  // and semantics both go through these so a deck screen can never fall into
  // the `dua == null` branch and render blank.
  String get duaArabicText =>
      duaArabic.isNotEmpty ? duaArabic : (dua?.duaArabic ?? '');
  String get duaTransliterationText => duaTransliteration.isNotEmpty
      ? duaTransliteration
      : (dua?.duaTransliteration ?? '');
  String get duaTranslationText =>
      duaTranslation.isNotEmpty ? duaTranslation : (dua?.duaTranslation ?? '');
  String get duaSourceText =>
      duaSource.isNotEmpty ? duaSource : (dua?.duaSource ?? '');

  /// The full text a screen reader announces for this beat.
  String get semanticText {
    switch (kind) {
      case BeatKind.dua:
        final parts = [
          if (duaTransliterationText.isNotEmpty) duaTransliterationText,
          if (duaTranslationText.isNotEmpty) duaTranslationText,
          if (duaSourceText.isNotEmpty) duaSourceText,
        ];
        if (parts.isEmpty) return 'Duʿa';
        return parts.join('. ');
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

/// Builds the screen list for a bundled Name-story deck (the onboarding
/// reveal). The deck's beat order IS the screen order — decks are authored and
/// founder-reviewed as a sequence, so nothing is reordered, merged or dropped
/// here beyond the optional pair-synergy beat.
///
/// [includePairSynergy] false drops the Name₁ closing beat that names Name₂ —
/// for surfaces that reveal a deck outside its pair.
///
/// Field mapping is per-kind because the asset's fields are per-kind (see the
/// table on [NameStoryBeat]). Two consequences worth stating out loud:
///  * `label` reaches the screen ONLY for story beats. Every other kind uses it
///    for an editorial note ("catalog id 6, verbatim", "pair synergy") that must
///    never be rendered.
///  * verse/comfort_verse/dua beats hold their ENGLISH translation in `primary`
///    (Arabic, when present, is in `arabic`) — the inverse of the
///    [BeatKind.verse] screen convention, where `primary` is the Arabic.
/// [meaningAlreadyShown] is the meaning string a surface UPSTREAM of this deck
/// has already displayed. The `name_intro` hero drops its meaning line only when
/// the two match exactly; otherwise it keeps it.
///
/// It compares rather than assumes because the assumption was wrong. This
/// started as a bool on the premise that the card and the deck always carry the
/// same meaning — true for 13 of the 14 shipped decks, and false for the one
/// that matters most: `al-wakeel@1` is position 2, the sealed D1 Name, and its
/// card says "The Trustee" while its deck says "The Trustee — the Guardian you
/// hand your affairs to". A bool deleted those 39 authored characters on the
/// single most important reveal in the funnel. Comparing is also self-correcting
/// — if the catalog and the deck drift apart later, the meaning survives instead
/// of vanishing silently.
///
/// Set it when something upstream has ALREADY named the Name. The decks were
/// authored for the onboarding order — deck first, card after "Ameen" — so
/// `name_intro` is genuinely the introduction there. The daily loop inverts it:
/// `CardRevealOverlay` shows the tier badge, then `card.transliteration`, then
/// `card.english`, and the deck opens two taps later. Left whole, the arch
/// restates the transliteration AND the meaning within about five seconds of the
/// card doing it (and on D1 it is the third showing, after the D0 sealed tease
/// displayed the same three fields).
///
/// The calligraphy is the one thing the card cannot give — it renders Arabic
/// small — so it stays, and the transliteration stays with it so a reader who
/// cannot read Arabic still knows which Name this is. What goes is the meaning
/// line alone, which is the sentence the card had just finished delivering.
List<BeatScreen> buildBeatScreensFromDeck(
  NameStoryDeck deck, {
  bool includePairSynergy = true,
  String? meaningAlreadyShown,
}) {
  final screens = <BeatScreen>[];

  for (final beat in deck.beats) {
    if (!includePairSynergy && beat.isPairSynergy) continue;

    switch (beat.kind) {
      case 'bridge':
        screens.add(BeatScreen(kind: BeatKind.keyLine, primary: beat.primary));
      case 'recognition':
        screens.add(
          BeatScreen(kind: BeatKind.recognition, primary: beat.primary),
        );
      case 'name_intro':
        // Mihrab hero: Arabic name, transliteration on `label`, meaning on
        // `source` — the same slots the AI path fills.
        screens.add(BeatScreen(
          kind: BeatKind.name,
          arabic: beat.arabic,
          // The transliteration STAYS either way: it is the only thing telling a
          // reader who cannot read Arabic which Name they are looking at, and a
          // hero that cannot be identified is decoration. Only the meaning goes,
          // because that is the line the card repeated.
          label: beat.transliteration,
          source: beat.primary.trim() == (meaningAlreadyShown ?? '').trim()
              ? ''
              : beat.primary,
        ));
      case 'story':
        screens.add(BeatScreen(
          kind: BeatKind.story,
          label: beat.label, // the story title — the one displayed label
          primary: beat.primary,
          source: beat.source,
        ));
      case 'verse':
      case 'comfort_verse':
        screens.add(BeatScreen(
          kind: beat.kind == 'verse' ? BeatKind.verse : BeatKind.comfortVerse,
          primary: beat.arabic, // may be empty — the view then shows only the
          label: beat.primary, // translation + citation
          source: beat.source,
        ));
      case 'dua':
        screens.add(BeatScreen(
          kind: BeatKind.dua,
          duaArabic: beat.arabic,
          duaTransliteration: beat.transliteration,
          duaTranslation: beat.primary,
          duaSource: beat.source,
        ));
      case 'takeaway':
        // Includes the pair-synergy beat: it is a takeaway carrying a `synergy`
        // label, not a kind of its own.
        screens.add(BeatScreen(kind: BeatKind.takeaway, primary: beat.primary));
      default:
        // Unknown kind: the ship gate rejects these at build time, so reaching
        // here means a hand-edited asset. Skip the beat rather than crash the
        // reveal.
        continue;
    }
  }

  return screens;
}

/// The 0-based index of the duʿa screen — where "Skip to duʿa" lands.
int duaScreenIndex(List<BeatScreen> screens) =>
    screens.lastIndexWhere((s) => s.kind == BeatKind.dua).clamp(0, screens.length - 1);
