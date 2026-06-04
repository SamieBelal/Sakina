import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/referrals/referral_nudge_gate.dart';

/// Pure-logic coverage for the referral nudge gate. No RevenueCat, no Supabase,
/// no Flutter — every timing/eligibility branch is exercised here. The widget
/// test (referral_nudge_card_test.dart) covers wiring; this covers the rules.
void main() {
  final now = DateTime.utc(2026, 6, 10, 12);

  // Defaults to a clearly-eligible caller; each test overrides the one axis
  // under scrutiny so a failure points at exactly one rule.
  ReferralNudgeDecision decide({
    DateTime? premiumStartedAt,
    int progressTowardNext = 1,
    bool hasEarnedGrant = false,
    DateTime? lastShownAt,
    int lastShownProgress = 0,
  }) {
    return resolveReferralNudge(
      premiumStartedAt:
          premiumStartedAt ?? now.subtract(const Duration(days: 5)),
      now: now,
      progressTowardNext: progressTowardNext,
      hasEarnedGrant: hasEarnedGrant,
      lastShownAt: lastShownAt,
      lastShownProgress: lastShownProgress,
    );
  }

  test('hidden when not an RC subscriber (premiumStartedAt null)', () {
    expect(
      resolveReferralNudge(
        premiumStartedAt: null,
        now: now,
        progressTowardNext: 1,
        hasEarnedGrant: false,
        lastShownAt: null,
        lastShownProgress: 0,
      ),
      ReferralNudgeDecision.hidden,
    );
  });

  test('show for a paid subscriber past grace (audience is trial OR paid)', () {
    // A long-time payer: premium began 200 days ago, well past grace.
    expect(
      decide(premiumStartedAt: now.subtract(const Duration(days: 200))),
      ReferralNudgeDecision.show,
    );
  });

  test('hidden once a referral grant has been earned', () {
    expect(decide(hasEarnedGrant: true), ReferralNudgeDecision.hidden);
  });

  test('hidden when progress already at 3/3', () {
    expect(decide(progressTowardNext: 3), ReferralNudgeDecision.hidden);
  });

  test('hidden inside the grace window, shown just after', () {
    // 1 day in — still inside the 2-day grace.
    expect(
      decide(premiumStartedAt: now.subtract(const Duration(days: 1))),
      ReferralNudgeDecision.hidden,
    );
    // 3 days in — past grace.
    expect(
      decide(premiumStartedAt: now.subtract(const Duration(days: 3))),
      ReferralNudgeDecision.show,
    );
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

  test('happy path: premium, past grace, 1/3, never shown → show', () {
    expect(decide(lastShownAt: null), ReferralNudgeDecision.show);
  });
}
