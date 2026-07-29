/// **DRAFT — the seven orderings below need the founder's eye (spec §11 item 1,
/// same review protocol as the original five aspiration sequences).** H5 —
/// "What would help most right now?" — the multi-select chip cloud that replaces
/// the single-select aspiration question, and the five-Name orderings each chip
/// seeds into the queue (One Ship W2-H, §5).
///
/// Nothing here is new content: every id already exists in
/// `assets/content/collectible_names.json` with an approved anchor in
/// `assets/content/name_anchors.json`. What needs eyes is the *sequence* — which
/// Name a user meets on day 3, 4, 5, 6, 7 after the pair the hook gave them —
/// and the blend that fires when they choose more than one.
///
/// **Why chips and not rows.** Seven full-width multi-select rows would
/// reintroduce exactly the "seven stacked rectangles" failure the hook screen
/// was redesigned on 2026-07-27 to escape. Three sourced mitigations: constrain
/// the count (Daylio caps activity selection at five; Chernev's meta-analysis
/// finds the levers are categorisation and constraint, not fewer options), chips
/// rather than rows (Material 3 and the multi-select literature both favour them
/// at this scale — every selection visible at a glance, and they do not read as
/// a form), and Headspace's "What brings you to Headspace?" as the closest comp.
///
/// **The inconsistency with the hook screen is deliberate — do not "fix" it.**
/// The hook is single-select, full-width, tap-to-commit: one exposing question
/// where the tap *is* the commitment, so it earns full-width weight and an
/// instant advance. H5 is lower-stakes, later, and reversible, so it should feel
/// physically lighter under the thumb. Different interaction weight signalling
/// different stakes is the point.
///
/// Register (spec §8): the options name what a heart is reaching for, never a
/// habit target, a streak or a completion goal, and never presuppose a lapse.
/// *"To understand what Allah is teaching me in this"* was rejected outright —
/// it attributes intent to Allah. "Making sense of it" does the same job
/// cleanly.
library;

/// One chip in the H5 cloud.
class HelpChip {
  const HelpChip({
    required this.key,
    required this.label,
    required this.queueNameIds,
  });

  /// Stable snake_case key — persisted to `OnboardingState.helpWith` (ordered)
  /// and used as the analytics value. Copy may change; this may not.
  final String key;

  /// The chip as shown. Short by design: a chip cloud is read at a glance, and
  /// a sentence-length chip wraps into a block that is a row again.
  final String label;

  /// This chip's own five, in the order the user would meet them if it were
  /// their only selection.
  ///
  /// Invariants pinned by `test/features/onboarding/help_chips_test.dart`,
  /// mirroring `aspirations_test.dart` because they are the same server
  /// constraints (`seed_name_queue` raises `check_violation` on a duplicate id
  /// anywhere in the 7, and every id is FK'd to `collectible_names`):
  ///   * exactly 5 ids, internally unique;
  ///   * disjoint from EVERY chip pair (and therefore from the comfort pair) —
  ///     the first two queue positions always come from a pair;
  ///   * every id exists in the collectible catalog and carries a Name anchor.
  final List<int> queueNameIds;
}

/// The question stem. One register for everyone: unlike the aspiration question
/// it replaces, this phrasing already asks what would *help* rather than what
/// the user is reaching for, which is the softer claim the sign contract needed
/// its own wording for.
const String helpChipsQuestionLabel = 'What would help most right now?';

/// **Load-bearing copy, not filler (spec §5).** This ICP's fear ranking puts
/// *failing at another thing* near the top; stating that the choice is
/// reversible removes the pressure to get it right, which is most of what makes
/// a seven-option screen feel light. It also solves the one documented risk with
/// chips — that users may not realise multi-selection is possible — with
/// microcopy rather than checkbox glyphs.
const String helpChipsSublineLabel =
    'Choose up to three. You can change this later.';

/// How many chips a user may hold at once. The cap IS the design.
const int helpChipsMaxSelections = 3;

/// Queue positions 3-7 — five, the same length the single-select aspiration
/// answer seeded.
const int helpChipsQueueLength = 5;

/// Render order is the order below.
const List<HelpChip> helpChips = [
  HelpChip(
    key: 'words',
    label: 'Words to turn to',
    // As-Sami (hears the silent prayer) → Al-Mujeeb (answers the one who
    // calls) → Al-Kareem (gives without accounting, so asking is no
    // imposition) → Al-Ghafur (what to say when you do not know what to say)
    // → Al-Afuw (erases completely).
    queueNameIds: [45, 37, 30, 51, 86],
  ),
  HelpChip(
    key: 'sense',
    label: 'Making sense of it',
    // Al-Hakeem (wisdom in the decree) → Al-Aleem (knows what you do not) →
    // Al-Khabeer (knows the inside of it) → Al-Hakam (settles what you cannot)
    // → Ar-Rasheed (directs affairs to their right end).
    queueNameIds: [26, 14, 49, 47, 99],
  ),
  HelpChip(
    key: 'daily',
    label: 'Something small each day',
    // Ash-Shakur (rewards the smallest) → Al-Muqeet (nourishes, portion by
    // portion) → Al-Qayyum (holds what you cannot) → Al-Haleem (does not rush)
    // → Al-Hafeez (keeps what you entrust).
    queueNameIds: [28, 54, 16, 29, 39],
  ),
  HelpChip(
    key: 'less_alone',
    label: 'Feeling less alone',
    // Al-Waliyy (the protecting friend) → Ash-Shaheed (witnesses all of it) →
    // Ar-Raqeeb (sees the thought as well as the act) → Ar-Rauf (tenderness,
    // not just attention) → Al-Batin (hidden, yet closer than the near).
    queueNameIds: [64, 60, 40, 87, 82],
  ),
  HelpChip(
    key: 'closer',
    label: 'Feeling closer to Allah',
    // An-Nur (light in the chest) → Ar-Raheem (the mercy kept for the
    // believers) → Al-Barr (the source of the kindness already felt) →
    // Al-Hameed (worth praising in every situation) → Al-Haqq (what is
    // actually real).
    queueNameIds: [17, 3, 85, 65, 61],
  ),
  HelpChip(
    key: 'names',
    // Reel 2's literal promise and the founder's stated second product aspect.
    // Nothing in the current intake captures the learning motive at all.
    label: 'Learning His Names',
    // The classical opening run after Ar-Rahman and Ar-Raheem — Al-Malik →
    // Al-Quddus → Al-Azeez → Al-Khaliq → Al-Hayy. Deliberately the sequence a
    // person learning the 99 would meet in order, because that is what this
    // chip asked for.
    queueNameIds: [4, 5, 8, 10, 15],
  ),
  HelpChip(
    key: 'strength',
    // The sabr/endurance motive the old four aspirations missed entirely, and
    // plausibly the most common thing a practising Muslim in hardship wants.
    label: 'Strength to keep going',
    // Al-Qawiyy (strength that never weakens) → Al-Mateen (unshakeable, not
    // merely strong) → As-Sabur (patient with His creation) → Al-Qadir (power
    // without effort) → Ar-Rafi (raises those He wills in rank).
    queueNameIds: [62, 63, 32, 75, 42],
  ),
];

/// [helpChips] keyed by [HelpChip.key].
final Map<String, HelpChip> helpChipsByKey = {
  for (final c in helpChips) c.key: c,
};

/// Queue positions 3-7 for an ORDERED [keys] selection (spec §5 blend rule:
/// *weight by selection order, interleave, dedupe against the revealed pair, cap
/// at five*).
///
/// The interleave is a plain round-robin over the selected chips' own sequences,
/// which is what "weight by selection order" buys: with three selections the
/// first chip contributes two of the five and the third contributes one, without
/// any weighting table to keep in sync. One selection therefore degenerates to
/// exactly that chip's five — the single-select behaviour, unchanged.
///
/// Deterministic and order-stable: the same ordered [keys] always produce the
/// same five ids, so a user who backs up and re-enters the plan screen never
/// sees their queue reshuffle.
///
/// [exclude] is normally unnecessary — every sequence above is disjoint from all
/// 14 deck pair ids by construction, and that is test-pinned. It exists for the
/// one case construction cannot cover: a `sakina://reel/<id>?name_ids=a,b`
/// override may name any two catalog Names, and a collision there would make
/// `seed_name_queue` raise for exactly those users.
///
/// Returns empty — never an invented default — when nothing was selected, or
/// when every key is off-taxonomy. Empty is a legitimate seed: `seed_name_queue`
/// accepts 2-7 ids, so the user gets a two-row queue (the pair) rather than an
/// ordering nobody approved.
List<int> helpChipsQueueNameIds(
  List<String> keys, {
  Set<int> exclude = const {},
}) {
  final sequences = <List<int>>[];
  final seenKeys = <String>{};
  for (final key in keys) {
    // A repeated key would double that chip's weight in the interleave, which
    // no selection UI can produce but a restored prefs blob could.
    if (!seenKeys.add(key)) continue;
    final chip = helpChipsByKey[key];
    if (chip != null) sequences.add(chip.queueNameIds);
  }
  if (sequences.isEmpty) return const [];

  final picked = <int>[];
  final seenIds = <int>{};
  final longest =
      sequences.map((s) => s.length).reduce((a, b) => a > b ? a : b);
  for (var round = 0; round < longest; round++) {
    for (final sequence in sequences) {
      if (picked.length == helpChipsQueueLength) {
        return List<int>.unmodifiable(picked);
      }
      if (round >= sequence.length) continue;
      final id = sequence[round];
      if (exclude.contains(id) || !seenIds.add(id)) continue;
      picked.add(id);
    }
  }
  return List<int>.unmodifiable(picked);
}
