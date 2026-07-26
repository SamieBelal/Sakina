/// Plain immutable models for the bundled Name-story decks
/// (`assets/content/name_stories.json`).
///
/// Deliberately hand-written rather than Freezed: these are read-only content
/// records parsed once from an asset, never mutated, never serialized back, and
/// never sent over the wire — codegen would add a build step for nothing. The
/// shape mirrors the public-catalog contract so a server refresh path can be
/// added later without reshaping the model.
///
/// **Script separation is structural.** `arabic`, `transliteration` and
/// `translation` stay separate fields end-to-end so no renderer is ever tempted
/// to concatenate Arabic and Latin into one `Text` (RTL bleed — see CLAUDE.md).
library;

/// One deck: the ordered beats that teach a single Name of Allah, plus the
/// provenance record that the ship gate (`test/content/name_stories_ship_gate_test.dart`)
/// enforces before it may render.
class NameStoryDeck {
  /// Stable content id, e.g. `as-salam@1` (name slug + content revision).
  final String deckId;

  /// The Name's id in `assets/content/collectible_names.json`.
  final int nameId;

  /// Latin rendering of the Name, e.g. `As-Salam`. Never mixed with Arabic.
  final String transliteration;

  /// Problem-chip keys this deck answers (`anxiety`, `sign`, …).
  final List<String> chipKeys;

  /// 1 = the Name met during onboarding, 2 = the sealed second Name.
  final int positionInPair;

  final List<NameStoryBeat> beats;

  /// Verification record for every scriptural claim in [beats].
  final List<NameStorySource> sources;

  final String author;
  final String reviewedBy;
  final String reviewedAt;

  /// `good` is the only value that may ship — see [NameStoriesService].
  final String reviewVerdict;

  const NameStoryDeck({
    required this.deckId,
    required this.nameId,
    required this.transliteration,
    required this.chipKeys,
    required this.positionInPair,
    required this.beats,
    required this.sources,
    required this.author,
    required this.reviewedBy,
    required this.reviewedAt,
    required this.reviewVerdict,
  });

  factory NameStoryDeck.fromJson(Map<String, dynamic> json) => NameStoryDeck(
        deckId: (json['deck_id'] ?? '') as String,
        nameId: (json['name_id'] ?? 0) as int,
        transliteration: (json['transliteration'] ?? '') as String,
        chipKeys: ((json['chip_keys'] ?? const []) as List)
            .map((k) => k as String)
            .toList(growable: false),
        positionInPair: (json['position_in_pair'] ?? 0) as int,
        beats: ((json['beats'] ?? const []) as List)
            .map((b) => NameStoryBeat.fromJson(b as Map<String, dynamic>))
            .toList(growable: false),
        sources: ((json['sources'] ?? const []) as List)
            .map((s) => NameStorySource.fromJson(s as Map<String, dynamic>))
            .toList(growable: false),
        author: (json['author'] ?? '') as String,
        reviewedBy: (json['reviewed_by'] ?? '') as String,
        reviewedAt: (json['reviewed_at'] ?? '') as String,
        reviewVerdict: (json['review_verdict'] ?? '') as String,
      );
}

/// One beat = one screen in the reveal flow.
///
/// Field meaning is per-[kind] and NOT uniform — the asset is authored, not
/// generated, so read this table before touching a renderer:
///
/// | kind           | primary                | arabic         | transliteration | source   | label                |
/// |----------------|------------------------|----------------|-----------------|----------|----------------------|
/// | bridge         | the line               | —              | —               | —        | —                    |
/// | recognition    | the line               | —              | —               | —        | —                    |
/// | name_intro     | the Name's meaning     | the Name       | the Name        | —        | provenance note      |
/// | story          | the beat text          | —              | —               | citation | STORY TITLE (shown)  |
/// | verse          | the translation        | optional       | —               | citation | provenance note      |
/// | comfort_verse  | the translation        | optional       | —               | citation | provenance note      |
/// | dua            | the translation        | the duʿa       | the duʿa        | —        | provenance note      |
/// | takeaway       | the line               | —              | —               | —        | provenance note      |
///
/// **[label] is display copy for `story` only.** Everywhere else it holds an
/// editorial/provenance note written for the reviewer ("catalog id 6, verbatim",
/// "pair synergy") and must never reach the screen.
class NameStoryBeat {
  /// Deck-native wire kind (`bridge`, `name_intro`, `story`, `verse`, `dua`,
  /// `takeaway`, `recognition`, `comfort_verse`, `pair_synergy`). Kept as a
  /// String so the asset stays the single source of truth for the kind
  /// vocabulary; `buildBeatScreensFromDeck` maps it to a `BeatKind`.
  final String kind;
  final String label;
  final String primary;
  final String arabic;
  final String transliteration;
  final String translation;
  final String source;

  const NameStoryBeat({
    required this.kind,
    this.label = '',
    this.primary = '',
    this.arabic = '',
    this.transliteration = '',
    this.translation = '',
    this.source = '',
  });

  factory NameStoryBeat.fromJson(Map<String, dynamic> json) => NameStoryBeat(
        kind: (json['kind'] ?? '') as String,
        label: (json['label'] ?? '') as String,
        primary: (json['primary'] ?? '') as String,
        arabic: (json['arabic'] ?? '') as String,
        transliteration: (json['transliteration'] ?? '') as String,
        translation: (json['translation'] ?? '') as String,
        source: (json['source'] ?? '') as String,
      );

  /// The pair-synergy beat — the one closing line on the Name₁ deck that names
  /// Name₂. Authors mark it either by kind or by a `synergy` label, so both are
  /// accepted here exactly as the ship gate accepts them.
  bool get isPairSynergy =>
      kind == 'pair_synergy' || label.toLowerCase().contains('synergy');
}

/// One row of a deck's verification table.
class NameStorySource {
  /// What was checked, in the reviewer's words.
  final String claim;
  final String url;

  /// Reviewer's verification marker (e.g. `✅ verified`).
  final String verified;

  /// Human-readable citation, e.g. `Sahih al-Bukhari 3653 (sahih)`.
  final String sourceLabel;

  const NameStorySource({
    required this.claim,
    required this.url,
    required this.verified,
    required this.sourceLabel,
  });

  factory NameStorySource.fromJson(Map<String, dynamic> json) =>
      NameStorySource(
        claim: (json['claim'] ?? '') as String,
        url: (json['url'] ?? '') as String,
        verified: (json['verified'] ?? '') as String,
        sourceLabel: (json['source_label'] ?? '') as String,
      );
}
