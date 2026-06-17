import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/paywall/paywall_experiment.dart';
import 'package:sakina/features/tour/models/onboarding_tour_step.dart';

void main() {
  group('assignPaywallArm', () {
    test('is deterministic — same id always maps to the same arm', () {
      for (final id in ['u1', 'user-abcdef', '00000000-0000-0000', 'z']) {
        final first = assignPaywallArm(id);
        for (var i = 0; i < 5; i++) {
          expect(assignPaywallArm(id), first, reason: 'unstable for $id');
        }
      }
    });

    test('hashes userId + ":paywall" (NOT the raw id) — salted bucket', () {
      // The salted bucket is tourBucket(userId + ':paywall'); arm follows the
      // same <50 / >=50 split as the tour variant. Pin the exact derivation so
      // the salt can never silently drift back to the raw id.
      for (final id in ['user-1', 'qwerty', 'a-very-long-user-id-12345']) {
        final saltedBucket = tourBucket('$id:paywall');
        final expected = saltedBucket < 50
            ? PaywallArm.controlNoTrial
            : PaywallArm.treatmentReverseTrial;
        expect(assignPaywallArm(id), expected, reason: 'salt mismatch for $id');
      }
    });

    test('splits a population roughly 50/50', () {
      var control = 0;
      var treatment = 0;
      for (var i = 0; i < 4000; i++) {
        final id = 'user-$i-${i * 7}';
        switch (assignPaywallArm(id)) {
          case PaywallArm.controlNoTrial:
            control++;
          case PaywallArm.treatmentReverseTrial:
            treatment++;
        }
      }
      final total = control + treatment;
      expect(total, 4000);
      // Each arm within 40–60% — generous band for a 4k sample.
      expect(control / total, greaterThan(0.40));
      expect(control / total, lessThan(0.60));
    });

    // G2 de-correlation regression: the paywall arm must NOT be perfectly
    // correlated with the tour variant, or the two experiments could never run
    // concurrently without confounding. Salting userId with ':paywall' breaks
    // the correlation. If the salt were dropped, the two would be identical for
    // EVERY id and this test would fail.
    test('G2: is de-correlated from assignTourVariant across a population', () {
      var sameSide = 0;
      const n = 4000;
      for (var i = 0; i < n; i++) {
        final id = 'user-$i-${i * 13}';
        final paywallTreatment =
            assignPaywallArm(id) == PaywallArm.treatmentReverseTrial;
        final tourFull = assignTourVariant(id) == TourVariant.full;
        // "Same side" = both upper-half or both lower-half of their bucket space.
        if (paywallTreatment == tourFull) sameSide++;
      }
      final agreement = sameSide / n;
      // If salted correctly, agreement is ~50% (independent). A raw-id (unsalted)
      // implementation would land near 100%. Assert well below total correlation.
      expect(agreement, lessThan(0.70),
          reason: 'paywall arm appears correlated with tour variant — is the '
              'userId salted with ":paywall"?');
      expect(agreement, greaterThan(0.30));
    });

    test('empty id is handled deterministically (anon)', () {
      expect(assignPaywallArm(''), assignPaywallArm(''));
    });
  });
}
