import 'package:sakina/features/streaks/models/companion_state.dart';
import 'package:sakina/services/streak_service.dart';

/// The at-risk cutoff (local hour). Before this the un-lit lamp reads
/// `pendingUnlit` ("waiting to be lit"); at/after it, `atRiskUnlit` ("still
/// time" — gentle, never panic). This local-time split ONLY chooses between two
/// same-brightness states; the lit level itself is derived from the streak
/// (UTC day boundary in `streak_service`), never from local time (plan §1 clock
/// note).
const int companionAtRiskHour = 20;

/// Pure resolver: `(StreakState, freezeOwned, now) → CompanionState`.
///
/// Conditions are evaluated in the exact order of the plan §1 table. `protected`
/// is orthogonal — the freeze shield is composited over whatever brightness
/// resolves.
///
/// The three inputs must come from a single consistent snapshot (see
/// `companionInputsProvider`) so `protected` never renders against a stale
/// freeze while the streak is already post-consume.
CompanionState resolveCompanionState({
  required StreakState streak,
  required bool freezeOwned,
  required DateTime now,
}) {
  return CompanionState(
    brightness: _resolveBrightness(streak, now),
    protected: freezeOwned,
  );
}

CompanionBrightness _resolveBrightness(StreakState streak, DateTime now) {
  // Never acted → endowed (lit, faint) — never a cold Day 0.
  if (streak.lastActive == null && streak.longestStreak == 0) {
    return CompanionBrightness.endowedDim;
  }

  // Has history but the streak is at zero → resting, not lost.
  if (streak.currentStreak == 0) {
    return CompanionBrightness.dormant;
  }

  // Streak ≥ 1. If today's reflection is done, the lamp is lit — bucket by depth.
  if (streak.todayActive) {
    if (streak.currentStreak <= 3) return CompanionBrightness.dim;
    if (streak.currentStreak <= 29) return CompanionBrightness.glowing;
    return CompanionBrightness.fullyLit;
  }

  // Streak ≥ 1 but today not yet done — waiting to be lit. Local-hour split
  // only (same brightness, different copy/breath cue).
  return now.hour < companionAtRiskHour
      ? CompanionBrightness.pendingUnlit
      : CompanionBrightness.atRiskUnlit;
}
