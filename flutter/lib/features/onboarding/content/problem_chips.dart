/// The hook-screen chip taxonomy (One Ship W2-B1).
///
/// Seven chips — six problem chips plus the sign chip, always last — approved
/// by the founder on 2026-07-25 (plan of record §0.1①②, mock
/// `docs/superpowers/mocks/2026-07-25-hook-screen-mock.html`). The taxonomy cap
/// IS the choice-overload guard: bench chips (family strain, grief, sleep) are
/// deliberately absent from the screen and are reachable only through the
/// free-text keyword map below.
///
/// **Name-pair ids are never hardcoded here.** Each chip's pair is derived at
/// runtime from the approved decks in `assets/content/name_stories.json` via
/// [NameStoriesService] (`position_in_pair` 1 then 2), so an unapproved deck
/// cannot be revealed by a stale constant: the ship gate drops it, the chip
/// resolves short, and [ProblemChipResolver] falls back to the comfort pair.
library;

import 'package:sakina/models/name_story_deck.dart';
import 'package:sakina/services/name_stories_service.dart';

/// What the user's tap promised them — the `contract` key of
/// `user_profiles.acquisition_promise` (the DB check constraint requires it).
abstract final class HookContract {
  static const String problem = 'problem';
  static const String sign = 'sign';
}

/// Which onboarding EXPERIENCE ran — `user_profiles.onboarding_flow`, the tour
/// suppression key, and `OnboardingState.onboardingFlow`.
///
/// The wire values live here rather than in the provider so the validating
/// setter and its callers share one literal;
/// `test/features/onboarding/complete_onboarding_queue_seed_test.dart` pins
/// [reelV1] against `AppSessionNotifier.onboardingFlowReelV1`, which cannot
/// import this file's direction.
abstract final class OnboardingFlow {
  static const String reelV1 = 'reel_v1';
  static const String legacy = 'legacy';

  static const Set<String> values = {reelV1, legacy};
}

/// How the hook was expressed — `hook_type` in `acquisition_promise`.
///
/// The field records ORIGIN, not the last widget touched: [reel] outranks
/// [chip] and [freeText], because a reel arrival who then taps a chip is still
/// a reel arrival. [OnboardingNotifier.applyHookSelection] preserves it.
abstract final class HookType {
  static const String chip = 'chip';
  static const String freeText = 'free_text';

  /// Arrival through a `sakina://reel/<id>` deep link (Wave E stamps it).
  static const String reel = 'reel';
}

/// `problem_category` for free text that matched no chip. The reveal still
/// happens — on the comfort pair — but the category records that the taxonomy
/// did not cover what they typed, which is the signal that grows it.
const String problemCategoryUnmatched = 'unmatched';

/// One selectable card on the hook screen.
class ProblemChip {
  const ProblemChip({
    required this.chipKey,
    required this.label,
    required this.problemCategory,
    required this.contract,
  });

  /// Matches `chip_keys` in `name_stories.json` — the join to the deck pair.
  final String chipKey;

  /// The sentence shown on the card, verbatim from the approved mock.
  final String label;

  /// Analytics/segmentation category (snake_case, stable across copy edits).
  final String problemCategory;

  /// [HookContract.problem] or [HookContract.sign].
  final String contract;

  bool get isSign => contract == HookContract.sign;
}

/// Render order is the approved order: six problem chips, sign chip last.
const List<ProblemChip> problemChips = [
  ProblemChip(
    chipKey: 'anxiety',
    label: "My mind won't stop racing",
    problemCategory: 'anxiety',
    contract: HookContract.problem,
  ),
  ProblemChip(
    chipKey: 'heavy',
    label: 'Everything feels heavy',
    problemCategory: 'heavy',
    contract: HookContract.problem,
  ),
  ProblemChip(
    chipKey: 'guilt',
    label: 'I keep sinning and going back',
    problemCategory: 'guilt',
    contract: HookContract.problem,
  ),
  ProblemChip(
    chipKey: 'far-from-allah',
    label: 'I feel far from Allah',
    problemCategory: 'far_from_allah',
    contract: HookContract.problem,
  ),
  ProblemChip(
    chipKey: 'rizq',
    label: "I'm worried about money / providing",
    problemCategory: 'rizq',
    contract: HookContract.problem,
  ),
  ProblemChip(
    chipKey: 'unseen',
    label: "No one sees what I'm carrying",
    problemCategory: 'unseen',
    contract: HookContract.problem,
  ),
  ProblemChip(
    chipKey: 'sign',
    // Short on purpose. The long form ("…— everything just feels heavy")
    // duplicated the `heavy` chip two rows above, and research on first-question
    // screens (Noom's praised "I haven't decided yet") says the escape hatch
    // reads best as the shortest, least-committal line on the screen.
    label: "I can't put it into words",
    problemCategory: 'unspoken',
    contract: HookContract.sign,
  ),
];

/// Free-text → chip keyword map, in **evaluation order** (first hit wins).
///
/// Order encodes the disambiguation rules, so it is load-bearing:
///   * `guilt` first — "I feel far from Allah because I keep sinning" is a
///     return-cycle problem, and Al-Ghaffar/At-Tawwab answer it more directly.
///   * `rizq` before `heavy` — "lost my job" must not be read as grief.
///   * `unseen` before `anxiety` — marriage/loneliness terms are the
///     being-unseen problem, not a racing mind.
///   * `heavy` last — grief, sadness and family strain land there, which is
///     also the widest net (Al-Jabbar mends, Ash-Shafi heals).
///
/// Bench-chip routing required by the research note (family, marriage, exams,
/// sleep, grief) is pinned by `test/features/onboarding/problem_chips_test.dart`.
///
/// Single words match whole tokens; entries containing a space match as a
/// phrase. Write them apostrophe-free — [normalizeProblemText] strips those.
///
/// Only terms that name the *problem register* belong here. Ambient devotional
/// words ("praying", "faith") and ambient relational ones ("disconnected") were
/// removed on 2026-07-26: they fire on sentences about something else entirely
/// ("I keep praying for a job", "disconnected from my wife").
///
/// Negation is deliberately unhandled — "I am not anxious" still matches
/// `anxiety`. The cost is a wrong `problem_category` on a rare sentence, never a
/// wrong-feeling reveal: every chip's Names are plausible comfort for someone
/// who typed the word at all, and a negation parser would cost far more than
/// the mistake.
const Map<String, List<String>> problemChipKeywords = {
  'guilt': [
    'sin', 'sins', 'sinning', 'sinned', 'guilt', 'guilty', 'shame', 'ashamed',
    'haram', 'relapse', 'relapsed', 'relapsing', 'addiction', 'addicted',
    'porn', 'zina',
    'repent', 'repentance', 'tawbah', 'taubah', 'istighfar', 'astaghfirullah',
    'forgive', 'forgiveness', 'keep going back', 'same mistake',
  ],
  'far-from-allah': [
    'far from allah', 'distant from allah', 'iman', 'imaan',
    'spiritually', 'spiritual', 'salah', 'salat', 'namaz',
    'quran', 'worship', 'dhikr', 'hypocrite', 'munafiq',
    'cant be consistent', 'not consistent', 'empty inside', 'going through the motions',
  ],
  'rizq': [
    'money', 'rizq', 'rizk', 'income', 'salary', 'wage', 'wages', 'rent',
    'debt', 'debts', 'loan', 'loans', 'bills', 'broke', 'poverty', 'afford',
    'provide', 'providing', 'provider', 'job', 'jobs', 'unemployed',
    'unemployment', 'fired', 'redundant', 'laid off', 'lost my job', 'work visa',
  ],
  'unseen': [
    'alone', 'lonely', 'loneliness', 'isolated', 'isolation', 'invisible',
    'unheard', 'unseen', 'misunderstood', 'no one', 'nobody', 'marriage',
    'married', 'marry', 'spouse', 'husband', 'wife', 'divorce', 'divorced',
    'nikah', 'rishta', 'proposal', 'single', 'no friends', 'nobody knows',
  ],
  'anxiety': [
    'anxiety', 'anxious', 'panic', 'panicking', 'worry', 'worried', 'worrying',
    'stress', 'stressed', 'overthinking', 'overthink', 'racing', 'restless',
    'nervous', 'scared', 'afraid', 'fear', 'dread', 'waswas', 'waswasa',
    'sleep', 'asleep',
    'insomnia', 'cant sleep', 'up all night', 'exam', 'exams', 'finals',
    'results', 'deadline', 'interview', 'uni', 'university', 'college',
    'school', 'studies', 'studying',
  ],
  'heavy': [
    'heavy', 'sad', 'sadness', 'depressed', 'depression', 'hopeless',
    'hopelessness', 'despair', 'crying', 'numb', 'tired', 'exhausted', 'drained',
    'burnt out', 'burned out', 'giving up', 'grief', 'grieving', 'mourning',
    'died', 'death', 'passed away', 'funeral', 'janazah', 'miscarriage',
    'heartbreak', 'heartbroken', 'broken', 'family', 'parents', 'mother',
    'father', 'mum', 'mom', 'dad', 'siblings', 'brother', 'sister',
    'in laws', 'at home', 'arguing', 'fighting', 'illness', 'sick',
  ],
};

/// Lowercases, drops apostrophes ("won't" → "wont") and reduces everything
/// else non-alphanumeric to single spaces, leaving a space-padded token string
/// that both the whole-token and phrase matchers can scan.
String normalizeProblemText(String raw) {
  final folded = raw.toLowerCase().replaceAll(RegExp(r"[’'`]"), '');
  final spaced = folded.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  return spaced.isEmpty ? '' : ' $spaced ';
}

/// The chip [text] most nearly names, or `null` when nothing matches.
///
/// Pure — no asset access, no I/O — so the mapping is unit-testable on its own.
String? matchChipKeyForText(String text) {
  final normalized = normalizeProblemText(text);
  if (normalized.isEmpty) return null;
  for (final entry in problemChipKeywords.entries) {
    for (final keyword in entry.value) {
      // Both sides are space-padded, so a single keyword matches a whole token
      // and a multi-word keyword matches a whole phrase — never a substring
      // ("sad" must not fire on "salad").
      if (normalized.contains(' $keyword ')) return entry.key;
    }
  }
  return null;
}

/// [problemChips] keyed by [ProblemChip.chipKey].
final Map<String, ProblemChip> problemChipsByKey = {
  for (final c in problemChips) c.chipKey: c,
};

/// The chip whose pair answers unmatched free text (Ar-Rahman + Al-Lateef).
const String comfortChipKey = NameStoriesService.comfortChipKey;

/// Everything the hook screen commits: what the user said, how they said it,
/// and which Name pair answers it.
class ChipSelection {
  const ChipSelection({
    required this.contract,
    required this.problemCategory,
    required this.hookType,
    required this.pairNameIds,
    this.chipKey,
    this.problemTextRaw,
  });

  final String contract;
  final String problemCategory;

  /// [HookType.chip] or [HookType.freeText].
  final String hookType;

  /// `[name₁, name₂]` — Name₁ is met in onboarding, Name₂ is sealed. Empty
  /// only if even the comfort pair is unapproved (the ship gate prevents it).
  final List<int> pairNameIds;

  /// The chip that answered, or null when free text matched nothing. Null is
  /// deliberate: unmatched text reveals the comfort pair but must NOT be
  /// recorded as the sign chip — the user never claimed that contract.
  final String? chipKey;

  /// Verbatim typed text (`first_problem_text`); null for chip taps.
  final String? problemTextRaw;

  /// The same answer against a different pair — how a `sakina://reel/<id>`
  /// link's `name_ids` override lands (W2-E4).
  ///
  /// Only the Names change. What the user said (`contract`,
  /// `problemCategory`, `chipKey`, the typed text) is theirs and is carried
  /// through untouched; the reel is allowed to choose which Names answer it,
  /// not to rewrite the question.
  ChipSelection withPairNameIds(List<int> pairNameIds) => ChipSelection(
        contract: contract,
        problemCategory: problemCategory,
        hookType: hookType,
        pairNameIds: pairNameIds,
        chipKey: chipKey,
        problemTextRaw: problemTextRaw,
      );
}

/// Resolves a tap or a typed sentence into a [ChipSelection], deriving the
/// Name pair from the approved decks.
class ProblemChipResolver {
  ProblemChipResolver({NameStoriesService? stories})
      : _stories = stories ?? nameStoriesService;

  final NameStoriesService _stories;

  /// The chip the user tapped.
  Future<ChipSelection> forChip(String chipKey) async {
    // Validated before the lookup: an off-taxonomy key is a programming error,
    // not something to spend an asset read on.
    final chip = _requireChip(chipKey);
    return _chipSelection(chip.chipKey, await pairNameIdsForChip(chip.chipKey));
  }

  /// What the user typed instead of tapping.
  Future<ChipSelection> forFreeText(String text) async {
    final matched = matchChipKeyForText(text);
    return _freeTextSelection(
      text,
      matched,
      await pairNameIdsForChip(matched ?? comfortChipKey),
    );
  }

  /// What a tap still commits when the deck lookup itself failed (a missing or
  /// unparseable asset). Everything the tap said, with no pair — the reveal
  /// treats an empty pair as the comfort fallback, so a resolver failure costs
  /// the tailored Names, never the user's way forward.
  ChipSelection unresolvedForChip(String chipKey) =>
      _chipSelection(chipKey, const []);

  /// The same, for typed text: the keyword match is pure, so only the pair is
  /// lost.
  ChipSelection unresolvedForFreeText(String text) =>
      _freeTextSelection(text, matchChipKeyForText(text), const []);

  ProblemChip _requireChip(String chipKey) {
    final chip = problemChipsByKey[chipKey];
    if (chip == null) {
      throw ArgumentError.value(chipKey, 'chipKey', 'not in the taxonomy');
    }
    return chip;
  }

  ChipSelection _chipSelection(String chipKey, List<int> pairNameIds) {
    final chip = _requireChip(chipKey);
    return ChipSelection(
      contract: chip.contract,
      problemCategory: chip.problemCategory,
      hookType: HookType.chip,
      chipKey: chip.chipKey,
      pairNameIds: pairNameIds,
    );
  }

  ChipSelection _freeTextSelection(
    String text,
    String? matchedChipKey,
    List<int> pairNameIds,
  ) {
    final chip =
        matchedChipKey == null ? null : problemChipsByKey[matchedChipKey];
    return ChipSelection(
      // Typed words are always the problem contract — the sign contract is a
      // claim only the user's own tap on the sign card may make.
      contract: HookContract.problem,
      problemCategory: chip?.problemCategory ?? problemCategoryUnmatched,
      hookType: HookType.freeText,
      chipKey: chip?.chipKey,
      problemTextRaw: text.trim(),
      pairNameIds: pairNameIds,
    );
  }

  /// `[name₁, name₂]` for [chipKey], falling back to the comfort pair when the
  /// chip's own pair is not fully approved — never half a pair.
  Future<List<int>> pairNameIdsForChip(String chipKey) async {
    final own = _idsOf(await _stories.decksForChip(chipKey));
    if (own.length == 2) return own;
    if (chipKey == comfortChipKey) return const [];
    final comfort = _idsOf(await _stories.comfortPair());
    return comfort.length == 2 ? comfort : const [];
  }

  List<int> _idsOf(List<NameStoryDeck> decks) {
    if (decks.length != 2) return const [];
    if (decks[0].positionInPair != 1 || decks[1].positionInPair != 2) {
      return const [];
    }
    return [decks[0].nameId, decks[1].nameId];
  }
}
