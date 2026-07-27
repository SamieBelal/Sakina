/// **APPROVED (founder verdict: good, 2026-07-27 — stems, labels, and all five sequences as drafted).** The aspiration question's options and,
/// more importantly, the five-Name ORDERINGS each one seeds into the queue
/// (One Ship W2-C2a). Author: Claude; reviewer: founder — same review contract
/// as the decks (plan open item 2). Nothing here is new content: every id
/// already exists in `assets/content/collectible_names.json` with an approved
/// anchor in `assets/content/name_anchors.json`. What needs eyes is the
/// *sequence* — which Name a user meets on day 3, 4, 5, 6, 7 after the pair the
/// hook gave them.
///
/// Register (spec, plan D1): depth, not productivity. The options name what a
/// heart is reaching for, never a habit target, a streak, or a completion goal.
/// The `sign` contract gets its own phrasing of the same options — a user who
/// tapped "I can't put it into words" is not asked to declare a project.
library;

import 'package:sakina/features/onboarding/content/problem_chips.dart';

/// One selectable answer to the aspiration question.
class Aspiration {
  const Aspiration({
    required this.key,
    required this.label,
    required this.signLabel,
    required this.queueNameIds,
  });

  /// Stable snake_case key — persisted to `OnboardingState.aspiration` and used
  /// as the analytics value. Copy may change; this may not.
  final String key;

  /// The option as shown after a problem chip.
  final String label;

  /// The option as shown after the **sign** chip. Same aspiration, softer
  /// claim: the sign user described a state, not a goal.
  final String signLabel;

  /// Queue positions 3-7, in the order the user will meet them.
  ///
  /// Invariants pinned by `test/features/onboarding/aspirations_test.dart`:
  ///   * exactly 5 ids, internally unique;
  ///   * disjoint from EVERY chip pair (and therefore from the comfort pair) —
  ///     `seed_name_queue` raises on a duplicate id anywhere in the 7, and the
  ///     first two positions always come from a pair;
  ///   * every id exists in the collectible catalog and carries a Name anchor.
  final List<int> queueNameIds;
}

/// The question stem. Two registers, one question — see [Aspiration.signLabel].
const String aspirationQuestionLabel = 'What are you reaching for?';
const String aspirationQuestionSignLabel = 'What would help most right now?';

/// Render order is the order below.
const List<Aspiration> aspirations = [
  Aspiration(
    key: 'closeness',
    label: 'To feel close to Allah again',
    signLabel: 'To feel Him near',
    // Al-Mujeeb (answers) → Al-Waliyy (befriends) → Al-Batin (nearer than the
    // near) → An-Nur (light in the chest) → Ar-Raheem (the mercy kept for you).
    queueNameIds: [37, 64, 82, 17, 3],
  ),
  Aspiration(
    key: 'consistency',
    label: 'To keep turning back, even when I slip',
    signLabel: 'To stop drifting',
    // As-Sabur (patient with you) → Al-Qayyum (holds what you cannot) →
    // Al-Haleem (does not rush to punish) → Al-Muqeet (feeds the returning) →
    // Al-Hafeez (keeps what you entrust).
    queueNameIds: [32, 16, 29, 54, 39],
  ),
  Aspiration(
    key: 'peace',
    label: 'To carry less noise inside',
    signLabel: 'To be still',
    // Al-Mumin (grants safety) → Al-Muhaymin (watches over) → Al-Quddus (free
    // of every flaw) → Al-Wasi (room enough for all of it) → Al-Haqq (what is
    // actually real).
    queueNameIds: [7, 18, 5, 57, 61],
  ),
  Aspiration(
    key: 'gratitude',
    label: 'To notice what He has already given',
    signLabel: 'To see the good again',
    // Ash-Shakur (rewards the small) → Al-Wahhab (gives unasked) → Al-Kareem
    // (gives without accounting) → Al-Barr (the source of the kindness) →
    // An-Nafi (what benefits comes from Him).
    queueNameIds: [28, 12, 30, 85, 96],
  ),
  Aspiration(
    key: 'guidance',
    label: 'To know what He wants from me',
    signLabel: 'To be shown the way',
    // Ar-Rasheed (directs to the right end) → Al-Hakeem (wisdom in the decree)
    // → Al-Aleem (knows what you do not) → Al-Khabeer (knows the inside of it)
    // → Al-Hakam (settles what you cannot).
    queueNameIds: [99, 26, 14, 49, 47],
  ),
];

/// [aspirations] keyed by [Aspiration.key].
final Map<String, Aspiration> aspirationsByKey = {
  for (final a in aspirations) a.key: a,
};

/// The option list for a hook [contract] — [HookContract.sign] gets the softer
/// register, everything else the problem register.
String aspirationLabelFor(Aspiration aspiration, String? contract) =>
    contract == HookContract.sign ? aspiration.signLabel : aspiration.label;

/// The question stem for a hook [contract].
String aspirationQuestionFor(String? contract) => contract == HookContract.sign
    ? aspirationQuestionSignLabel
    : aspirationQuestionLabel;

/// Queue positions 3-7 for [aspirationKey], or empty when the user has not
/// answered (or answered with a key the taxonomy no longer has).
///
/// Empty is a legitimate seed: `seed_name_queue` accepts 2-7 ids, so a user who
/// skipped the question gets a two-row queue (the pair) rather than an invented
/// ordering. Never guess a default — the sequences are founder-reviewed content.
List<int> aspirationQueueNameIds(String? aspirationKey) =>
    aspirationsByKey[aspirationKey]?.queueNameIds ?? const [];
