/// The one place in the app that tells a user about the free tier BEFORE they
/// hit it (2026-08-07).
///
/// Every other string on the subject — `WarmupExhaustedSheet`,
/// `DailyCapSheet` — fires after a block. This line is the only pre-emptive
/// one, and it sits on `QueuePlanScreen`, the screen whose own source comment
/// calls it *"the payoff: everything above earns this screen; everything below
/// is an ask"*.
///
/// The placement is the product decision and is asserted here as such: on the
/// payoff, not on the paywall two screens later. Explaining what someone
/// already gets for free at the moment you ask them to pay is handing them a
/// reason to decline.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:sakina/features/onboarding/content/free_tier_copy.dart';
import 'package:sakina/services/gating_service.dart';

void main() {
  group('the grant line', () {
    test('leads with what never runs out', () {
      final line = FreeTierCopy.freeTierGrant(3);
      // The daily Name consults no gate at all, on any tier, forever. Saying it
      // first is what makes the metered half read as a bonus rather than a
      // meter.
      expect(line.indexOf('day'), lessThan(line.indexOf('reflections')));
      expect(line.toLowerCase(), contains('free, always'));
    });

    test('takes the pool size as an argument rather than writing "three"', () {
      // A hardcoded number becomes a lie the day `weekly_pool_size` is
      // re-dialled — and this is a promise made to someone who has not signed
      // up yet, which is the worst kind to break.
      expect(FreeTierCopy.freeTierGrant(3), contains('3 reflections'));
      expect(FreeTierCopy.freeTierGrant(5), contains('5 reflections'));
      expect(FreeTierCopy.freeTierGrant(5), isNot(contains('3')));
    });

    test('names duʿās too, because the pool is SHARED', () {
      // `reel_v1`'s pool is one budget across Reflect and Build-a-Duʿā. Copy
      // that named only one of them would surprise a user who spent theirs on
      // the other.
      expect(FreeTierCopy.freeTierGrant(3), contains('duʿās'));
    });

    test('is framed as a grant — no "then", no "only", no "limit"', () {
      final line = FreeTierCopy.freeTierGrant(3).toLowerCase();
      for (final word in ['limit', 'only', 'then', 'run out', 'upgrade']) {
        expect(line, isNot(contains(word)),
            reason: 'the cap read from the giving side is the whole point of '
                'putting this before the paywall rather than on it: "$line"');
      }
    });

    test('the default it is called with matches what the client enforces', () {
      // `QueuePlanScreen` passes `weeklyPoolSizeFallback`, which is also the
      // seeded dial and the RPC's own `coalesce(..., 3)`. If those three ever
      // disagree, the promise and the gate disagree.
      expect(GatingService.weeklyPoolSizeFallback, 3);
    });
  });
}
