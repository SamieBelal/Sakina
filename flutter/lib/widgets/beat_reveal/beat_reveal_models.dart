import 'package:sakina/core/utils/beat_splitter.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
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

  // ── Archive kinds (Wave D) ──
  /// The cover card that opens a RE-READ of a saved entry: the night's date and
  /// the words the user wrote that night. It exists so a re-read is visibly a
  /// re-read — the live reveal has no cover, and dropping a reader straight into
  /// a reframe they last saw eight months ago reads as new content.
  entryCover,
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
      case BeatKind.entryCover:
        return 'entry_cover';
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
///
/// [selection] is the swap seam: **deck beat kind → already-resolved variant
/// id**, e.g. `{'bridge': 'anxiety', 'reflection': 'guilt'}`. A named beat
/// renders that variant's text in place of its `primary`; everything else — an
/// unnamed beat, an id the beat does not carry, a beat with no variants at all —
/// renders `primary`. `variants.isEmpty → primary` is the main path, not an edge
/// case.
///
/// **`selection: null` is byte-identical to the pre-personalisation output for
/// every shipped deck**, pinned across all 99 in
/// `test/widgets/beat_reveal_deck_test.dart`. The three live call sites pass
/// nothing and are unaffected.
///
/// Three things about the shape, each load-bearing:
///
///  * **Per beat kind, not one id per deck.** Whether the bridge and the
///    reflection get the SAME id is an open founder decision (plan §7, "paired
///    vs independent"). A single deck-wide id would hard-code *paired* into the
///    signature and make *independent* a breaking change; a map expresses both,
///    and the seam does not have to know which one won.
///  * **Resolved ids only.** This function looks a given id up on a given beat
///    and does nothing else — no chip mapping, no rotation, no seen set, no
///    fallback ladder. That policy lives in the selector service, because the
///    docstring above promises nothing is reordered, merged or dropped here and
///    the same promise has to cover *which words*, not just which beats.
///  * **Read only inside the two personalisable cases.** A selection naming
///    `verse` or `dua` cannot swap anything even on a hand-edited asset: the
///    other branches never consult it. The gate keeps `variants` off those
///    kinds; this keeps the builder from caring if it ever failed to.
List<BeatScreen> buildBeatScreensFromDeck(
  NameStoryDeck deck, {
  bool includePairSynergy = true,
  String? meaningAlreadyShown,
  Map<String, String>? selection,
}) {
  final screens = <BeatScreen>[];

  for (final beat in deck.beats) {
    if (!includePairSynergy && beat.isPairSynergy) continue;

    switch (beat.kind) {
      case 'bridge':
        screens.add(BeatScreen(
          kind: BeatKind.keyLine,
          primary: beat.textForVariant(selection?[beat.kind]),
        ));
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
      case 'reflection':
        // Drawn with the takeaway template on purpose: it is a closing prose
        // screen, and giving it its own `BeatKind` is a design decision about
        // how a reflective question should look, not a plumbing one. Mapping it
        // here keeps the beat visible today; a dedicated template can replace
        // this line without touching the asset or the gate.
        screens.add(BeatScreen(
          kind: BeatKind.takeaway,
          primary: beat.textForVariant(selection?[beat.kind]),
        ));
      default:
        // Unknown kind: the ship gate rejects these at build time, so reaching
        // here means a hand-edited asset. Skip the beat rather than crash the
        // reveal.
        continue;
    }
  }

  return screens;
}

/// The 0-based index of the duʿa screen, or **-1 when the list has none**.
///
/// The `-1` is the contract, and it replaced a `.clamp(0, length - 1)` that was
/// a real bug rather than a defensive nicety. `lastIndexWhere` returns -1 for
/// "not found", and clamping turned that into **0** — so on any screen list with
/// no duʿa beat, "Skip to duʿa" jumped the reader BACKWARDS to the first beat
/// and emitted a `reflect_flow_skipped` for a skip that never happened. Nothing
/// on the live AI or deck paths could reach it (both always end on or contain a
/// duʿa); a re-read built from an archived entry that saved no duʿā can, which
/// is why Wave D is where it surfaced.
///
/// Callers must treat -1 as *"there is nowhere to skip to"* and hide the
/// affordance, not as an index.
int duaScreenIndex(List<BeatScreen> screens) =>
    screens.lastIndexWhere((s) => s.kind == BeatKind.dua);

/// Builds the screen list for RE-READING a saved journal entry (Wave D, D2).
///
/// The archive's counterpart to [buildBeatScreens]: same slots, same order, same
/// content-driven segment count — a saved entry carries the identical beat
/// fields, because [buildSavedReflection] wrote them from the same
/// [ReflectResponse] the live flow rendered.
///
/// Three deliberate differences from the live path:
///  * it opens on a [BeatKind.entryCover] carrying the night's date and the
///    user's own words. A re-read that opens on the reframe is indistinguishable
///    from a fresh reflection.
///  * verses are included by default. `includeVerses: false` exists on the live
///    muḥāsabah path because the night is a single sitting; an archive re-read
///    is the one place the whole entry should be available.
///  * the duʿā screen is **conditional**. The live path always appends one
///    because a response always has one; a legacy row, a deck-path night, or an
///    entry whose duʿā fields were never populated has nothing to render, and
///    appending an empty screen produces a blank final beat holding the
///    completion CTA. This is the case [duaScreenIndex] now returns -1 for.
///
/// Legacy rows (`beat_data` NULL — everything saved before 2026-07-14) carry no
/// structured beats, and fall back to [splitIntoBeats] over the joined
/// `reframe` / `story` prose exactly as [buildBeatScreens] does. That fallback
/// is the reason the archive can render an entry from before the beat flow
/// existed at all.
List<BeatScreen> buildBeatScreensFromReflection(
  SavedReflection r, {
  bool includeVerses = true,
  bool includeCover = true,
  String? coverLabel,
}) {
  final screens = <BeatScreen>[];

  // ── Cover ── the night, and what the user said that night.
  if (includeCover) {
    screens.add(BeatScreen(
      kind: BeatKind.entryCover,
      label: coverLabel ?? '',
      primary: r.userText.trim(),
      arabic: r.nameArabic,
      source: r.name,
    ));
  }

  // ── Name of Allah hero ── the mihrab arch, same slots as the live path.
  if (r.nameArabic.isNotEmpty) {
    screens.add(BeatScreen(
      kind: BeatKind.name,
      arabic: r.nameArabic,
      label: r.name,
      // A saved row has no `meaning` column — the Name and its Arabic are all
      // that were ever persisted. An empty source renders the hero without the
      // meaning line rather than with a blank one.
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

  // ── Takeaway ──
  if (r.takeaway.isNotEmpty) {
    screens.add(BeatScreen(kind: BeatKind.takeaway, primary: r.takeaway));
  }

  // ── Verses ── one per screen.
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

  // ── Duʿā ── only when the entry actually saved one.
  if (r.duaArabic.trim().isNotEmpty ||
      r.duaTransliteration.trim().isNotEmpty ||
      r.duaTranslation.trim().isNotEmpty) {
    screens.add(BeatScreen(
      kind: BeatKind.dua,
      duaArabic: r.duaArabic,
      duaTransliteration: r.duaTransliteration,
      duaTranslation: r.duaTranslation,
      duaSource: r.duaSource,
    ));
  }

  return screens;
}
