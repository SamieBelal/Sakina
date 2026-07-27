/// "How long have you been carrying this?" — the options, and the plan-screen
/// pacing copy they buy (One Ship W2-D1a).
///
/// §G4 is binding: a question with no consumer inside 24h does not ship. This
/// one has two — [carryingPacingLine], rendered on the queue plan screen, and
/// the AI teaching context W3 rides it into. Nothing here is a habit target: the
/// question asks how long the weight has been there, never how often the user
/// intends to show up.
library;

/// One selectable answer. [key] is stable snake_case (persisted to
/// `OnboardingState.carryingDuration` and used as the analytics value); the
/// label is free to be re-written.
class CarryingDuration {
  const CarryingDuration({required this.key, required this.label});

  final String key;
  final String label;
}

const String carryingDurationQuestionLabel =
    'How long have you been carrying this?';

/// Deliberately not "be honest" or "think carefully" — the subline exists to
/// take the weight off answering, not to add any.
const String carryingDurationSublineLabel = 'However long it has been.';

/// Render order is the order below: nearest in time first.
const List<CarryingDuration> carryingDurations = [
  CarryingDuration(key: 'days', label: 'Only these past few days'),
  CarryingDuration(key: 'months', label: 'Months, on and off'),
  CarryingDuration(key: 'years', label: 'Years'),
  CarryingDuration(key: 'always', label: 'As long as I can remember'),
];

/// [carryingDurations] keyed by [CarryingDuration.key].
final Map<String, CarryingDuration> carryingDurationsByKey = {
  for (final d in carryingDurations) d.key: d,
};

/// The queue plan screen's pacing line for [key] — the answer's visible
/// consequence (plan of record §V6.8.A6: months/years answers set the plan's
/// pacing copy).
///
/// Long-carry answers get gentleness, not urgency; a fresh weight gets the same
/// pace described plainly. An unanswered question gets the neutral line rather
/// than a guess.
String carryingPacingLine(String? key) {
  switch (key) {
    case 'days':
      return 'This is still new. One Name a day, in the order they help most.';
    case 'months':
    case 'years':
    case 'always':
      return "You've carried this a long time. We'll go gently — one Name a day.";
    default:
      return 'One Name a day, in the order they help most.';
  }
}
