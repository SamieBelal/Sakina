import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/referral_service.dart';

/// Pins the [MyReferralsState.progressTowardNext] math across the table of
/// (grant count, confirmed count) tuples spelled out in
/// docs/superpowers/plans/2026-05-23-my-referrals-screen.md.
///
/// The formula is: `grants.isEmpty ? confirmedCount.clamp(0,3) :
/// (confirmedCount - grants.length * 3).clamp(0, 3)`. A future "fancier"
/// rewrite that drifts from this will trip these cases.
void main() {
  MyReferralGrant grant(int daysAgo) {
    return MyReferralGrant(
      grantedAt: DateTime.utc(2026, 5, 23).subtract(Duration(days: daysAgo)),
      expiresAt: DateTime.utc(2026, 5, 23)
          .subtract(Duration(days: daysAgo))
          .add(const Duration(days: 30)),
      cardTier: 'gold',
    );
  }

  MyReferralsState state({required int confirmed, required int grantCount}) {
    return MyReferralsState(
      code: 'ABCD2EFG',
      confirmedCount: confirmed,
      grants: List<MyReferralGrant>.generate(
        grantCount,
        (i) => grant((i + 1) * 30),
      ),
    );
  }

  group('MyReferralsState.progressTowardNext', () {
    // (grantCount, confirmedCount, expected)
    const cases = <List<int>>[
      // 0 grants — early-game window. Progress mirrors confirmedCount, capped at 3.
      [0, 0, 0],
      [0, 1, 1],
      [0, 2, 2],
      [0, 3, 3],
      [0, 4, 3], // Capped — server should grant before we hit this state.
      // 1 grant — confirmedCount >= 3 already (3 were consumed by the grant).
      [1, 3, 0],
      [1, 4, 1],
      [1, 5, 2],
      [1, 6, 3],
      [1, 7, 3], // Capped.
      // 2 grants — 6 were consumed.
      [2, 6, 0],
      [2, 7, 1],
      [2, 8, 2],
      [2, 9, 3],
      [2, 10, 3], // Capped.
    ];

    for (final c in cases) {
      final grantCount = c[0];
      final confirmed = c[1];
      final expected = c[2];
      test('grants=$grantCount confirmed=$confirmed → $expected', () {
        final s = state(confirmed: confirmed, grantCount: grantCount);
        expect(s.progressTowardNext, expected);
      });
    }

    test('progressTowardNext never exceeds 3 even with absurd confirmedCount',
        () {
      expect(state(confirmed: 999, grantCount: 0).progressTowardNext, 3);
      expect(state(confirmed: 999, grantCount: 1).progressTowardNext, 3);
    });

    test('progressTowardNext never goes negative if data is inconsistent', () {
      // Defensive — shouldn't happen if server invariants hold (grants only
      // exist after 3 confirms) but clamp keeps the dots renderable.
      expect(state(confirmed: 0, grantCount: 2).progressTowardNext, 0);
    });
  });
}
