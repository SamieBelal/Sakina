/// Pure decision core for the referral nudge card.
///
/// Kept dependency-free (no Flutter / Riverpod / Supabase imports) so every
/// branch is unit-testable without RevenueCat or a network — same leaf-module
/// discipline as `onboarding_stage.dart`. The widget gathers the inputs (streak,
/// referral progress, prefs) and calls [resolveReferralNudge]; this function
/// holds the timing + eligibility rules and nothing else.
///
/// ```
///                    resolveReferralNudge
///   currentStreak < consistentStreakDays ──────────► hidden  (not yet earned)
///   hasEarnedGrant || progress >= 3 ───────────────► hidden  (already rewarded)
///   lastShownAt != null
///     && now < lastShownAt + reshowInterval
///     && progress <= lastShownProgress ────────────► hidden  (cooldown, no bump)
///   else ──────────────────────────────────────────► show
/// ```
///
/// ## Why a streak and not a subscription (founder, 2026-07-29)
///
/// This card used to gate on an active RevenueCat entitlement, because it was
/// written to replace the referral entry point the hard paywall removed — so its
/// audience was "people on the welcome side of the wall", which then meant
/// payers. That conflated two different things: *having paid* and *having
/// something to vouch for*.
///
/// Asking someone to recommend Sakina to three friends only works once they have
/// an experience to recommend. A payer on day 1 has bought a promise; a free user
/// on day 7 has kept a habit. The second is the better advocate, and the second
/// is also the growth channel that matters when acquisition is organic reels.
///
/// So the audience gate is now consistency, and the threshold is not invented:
/// [consistentStreakDays] is the app's own first streak milestone, which unlocks
/// the title **"Consistent"** (`streakMilestones` in `streak_service.dart`). The
/// ask therefore lands in the same session the app congratulates them for being
/// consistent, which is the strongest moment it will ever have.
///
/// This also retired the old grace window. It existed so we wouldn't ask for a
/// referral days after someone paid; a 7-day streak needs no such delay, because
/// reaching it *is* the earned moment.
library;

/// The app's first streak milestone — the one that unlocks the title
/// "Consistent" (مُوَاظِب). Mirrored here rather than imported so this module
/// stays dependency-free; `referral_nudge_gate_test.dart` pins the two together
/// so they cannot drift.
const int consistentStreakDays = 7;

enum ReferralNudgeDecision { hidden, show }

/// Decide whether the referral nudge card should render this pass.
///
/// - [currentStreak]: the user's live streak in days. The audience gate — see
///   the library doc for why this replaced an entitlement check.
/// - [now]: current instant (injected for deterministic tests).
/// - [progressTowardNext]: confirmed referees toward the next reward, 0..3.
/// - [hasEarnedGrant]: the user already earned at least one referral grant
///   (`MyReferralsState.grants.isNotEmpty`) — card disappears for good.
/// - [lastShownAt]: when the card was last shown/dismissed (prefs), or null.
/// - [lastShownProgress]: [progressTowardNext] at the last show (prefs); a
///   strictly higher current value bypasses the cooldown so "1 of 3 joined!"
///   surfaces promptly instead of waiting out [reshowInterval].
ReferralNudgeDecision resolveReferralNudge({
  required int currentStreak,
  required DateTime now,
  required int progressTowardNext,
  required bool hasEarnedGrant,
  required DateTime? lastShownAt,
  required int lastShownProgress,
  int minStreakDays = consistentStreakDays,
  Duration reshowInterval = const Duration(days: 7),
}) {
  // 1. Audience: they have to have kept the habit before we ask them to vouch
  //    for it. Deliberately the CURRENT streak, not the longest — someone whose
  //    streak has lapsed is not who we want carrying an invitation.
  if (currentStreak < minStreakDays) return ReferralNudgeDecision.hidden;

  // 2. Already rewarded — card is done for good.
  if (hasEarnedGrant || progressTowardNext >= 3) {
    return ReferralNudgeDecision.hidden;
  }

  // 3. Cooldown — unless a friend joined since we last showed it.
  if (lastShownAt != null) {
    final cooldownOver = !now.isBefore(lastShownAt.add(reshowInterval));
    final progressClimbed = progressTowardNext > lastShownProgress;
    if (!cooldownOver && !progressClimbed) {
      return ReferralNudgeDecision.hidden;
    }
  }

  return ReferralNudgeDecision.show;
}
