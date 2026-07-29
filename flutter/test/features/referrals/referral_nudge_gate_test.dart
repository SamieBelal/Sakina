import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/referrals/referral_nudge_gate.dart';
import 'package:sakina/services/streak_service.dart';

/// Pure-logic coverage for the referral nudge gate. No RevenueCat, no Supabase,
/// no Flutter — every timing/eligibility branch is exercised here. The widget
/// test (referral_nudge_card_test.dart) covers wiring; this covers the rules.
///
/// The audience rule changed on 2026-07-29: it was "active RC subscriber past a
/// 2-day grace", it is now "has held a streak to the app's first milestone".
/// See the gate's library doc for the reasoning.
void main() {
  final now = DateTime.utc(2026, 6, 10, 12);

  // Defaults to a clearly-eligible caller; each test overrides the one axis
  // under scrutiny so a failure points at exactly one rule.
  ReferralNudgeDecision decide({
    int currentStreak = consistentStreakDays,
    int progressTowardNext = 1,
    bool hasEarnedGrant = false,
    DateTime? lastShownAt,
    int lastShownProgress = 0,
  }) {
    return resolveReferralNudge(
      currentStreak: currentStreak,
      now: now,
      progressTowardNext: progressTowardNext,
      hasEarnedGrant: hasEarnedGrant,
      lastShownAt: lastShownAt,
      lastShownProgress: lastShownProgress,
    );
  }

  test('the threshold is the app\'s own first streak milestone', () {
    // The gate mirrors the constant rather than importing it (it is a
    // dependency-free leaf module), so this is the pin that stops the two
    // drifting. If the milestone ladder changes, this fails and someone has to
    // decide deliberately whether the referral ask moves with it.
    expect(consistentStreakDays, streakMilestones.first.days);
    expect(
      streakMilestones.first.titleUnlock,
      'Consistent',
      reason: 'the ask is timed to the moment the app calls the user consistent '
          '— if that title moves to another milestone, revisit the gate',
    );
  });

  test('hidden below the milestone, shown exactly at it', () {
    expect(
      decide(currentStreak: consistentStreakDays - 1),
      ReferralNudgeDecision.hidden,
    );
    // Boundary pinned explicitly: a `<` ↔ `<=` slip would delay the ask by a
    // full day and miss the celebration session it is timed to.
    expect(decide(currentStreak: consistentStreakDays),
        ReferralNudgeDecision.show);
  });

  test('hidden for a brand-new user, however much they have paid', () {
    // The old gate would have shown this card to a day-1 subscriber. Payment is
    // no longer the audience: someone who has bought a promise has nothing to
    // vouch for yet.
    expect(decide(currentStreak: 0), ReferralNudgeDecision.hidden);
    expect(decide(currentStreak: 1), ReferralNudgeDecision.hidden);
  });

  test('shown to a free user who kept the habit', () {
    // The point of the change — no entitlement is consulted at all.
    expect(decide(currentStreak: 40), ReferralNudgeDecision.show);
  });

  test('hidden once a referral grant has been earned', () {
    expect(decide(hasEarnedGrant: true), ReferralNudgeDecision.hidden);
  });

  test('hidden when progress already at 3/3', () {
    expect(decide(progressTowardNext: 3), ReferralNudgeDecision.hidden);
  });

  test('hidden inside the 7-day cooldown, shown after it expires', () {
    // Shown 1 day ago, no progress change → still cooling down.
    expect(
      decide(
        lastShownAt: now.subtract(const Duration(days: 1)),
        progressTowardNext: 1,
        lastShownProgress: 1,
      ),
      ReferralNudgeDecision.hidden,
    );
    // Shown 8 days ago → cooldown expired.
    expect(
      decide(
        lastShownAt: now.subtract(const Duration(days: 8)),
        progressTowardNext: 1,
        lastShownProgress: 1,
      ),
      ReferralNudgeDecision.show,
    );
  });

  test('progress climbing bypasses the cooldown', () {
    // In cooldown (1 day ago) BUT a friend joined since last show (2 > 1).
    expect(
      decide(
        lastShownAt: now.subtract(const Duration(days: 1)),
        progressTowardNext: 2,
        lastShownProgress: 1,
      ),
      ReferralNudgeDecision.show,
    );
    // In cooldown, progress unchanged → stays hidden.
    expect(
      decide(
        lastShownAt: now.subtract(const Duration(days: 1)),
        progressTowardNext: 1,
        lastShownProgress: 1,
      ),
      ReferralNudgeDecision.hidden,
    );
  });

  test('happy path: at the milestone, 1/3, never shown → show', () {
    expect(decide(lastShownAt: null), ReferralNudgeDecision.show);
  });

  test('exactly at the cooldown boundary (now == lastShownAt + 7d) → show', () {
    expect(
      decide(
        lastShownAt: now.subtract(const Duration(days: 7)),
        progressTowardNext: 1,
        lastShownProgress: 1,
      ),
      ReferralNudgeDecision.show,
    );
  });

  test('progress regressed below last-shown (in cooldown) stays hidden', () {
    // e.g. a grant consumed confirmations and progress reset 2 → 0, or stale
    // prefs. progressClimbed must be FALSE, so the cooldown still suppresses.
    expect(
      decide(
        lastShownAt: now.subtract(const Duration(days: 1)),
        progressTowardNext: 0,
        lastShownProgress: 2,
      ),
      ReferralNudgeDecision.hidden,
    );
  });

  test('a lapsed streak withdraws the ask', () {
    // Current, not longest, on purpose: someone whose streak just broke is not
    // who we want carrying an invitation, even if they were consistent for
    // months. The cooldown prefs survive, so the ask returns when they do.
    expect(decide(currentStreak: 0), ReferralNudgeDecision.hidden);
  });
}
