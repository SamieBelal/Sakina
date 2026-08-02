import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/constants/app_strings.dart';
import 'package:sakina/services/gating_service.dart';

/// The value-depth bullets name the free tier's actual numbers ("three a
/// week"). That is the strongest version of the argument and the most
/// fragile: the number lives in `app_config.weekly_pool_size`, which is a
/// runtime dial, so tuning it turns a shipped purchase surface into a false
/// claim with no code change and no review.
///
/// The copy firewall cannot catch this — "three a week" is a legitimate
/// sentence, and it is TRUE today. Only the relationship between the string
/// and the dial is checkable.
///
/// **What this test can and cannot do.** It pins the copy against
/// [GatingService.weeklyPoolSizeFallback], the client-side constant that
/// mirrors the seeded dial. So it catches a developer changing the fallback
/// without the copy, or the copy without the fallback. It CANNOT see
/// production: someone updating `app_config.weekly_pool_size` in the
/// dashboard breaks the promise and every test here still passes. That is a
/// runbook item, not a testable one — recorded here so the gap is known
/// rather than assumed covered.
const _valueDepthBullets = <String>[
  AppStrings.paywallValueDepthBullet1,
  AppStrings.paywallValueDepthBullet1Sign,
  AppStrings.paywallValueDepthBullet2,
  AppStrings.paywallValueDepthBullet2Sign,
  AppStrings.paywallValueDepthBullet3,
];

void main() {
  test('no bullet states a free-tier allowance', () {
    // Two reasons, and the second is the one a future editor will miss.
    //
    //  1. Product: the ceremony is first exposure, before any cap has been
    //     hit. Naming the free allowance here advertises the free tier at the
    //     moment the screen asks for money. The contrast belongs on
    //     DailyCapSheet, where the user has actually felt the limit.
    //  2. Correctness: any such number is `app_config.weekly_pool_size` — a
    //     RUNTIME dial. A shipped string quoting it becomes false the moment
    //     the dial is tuned, with no code change, no review, and nothing the
    //     copy firewall can detect, because the sentence is legitimate today.
    const pool = GatingService.weeklyPoolSizeFallback;
    const numberWords = <int, String>{
      1: 'one', 2: 'two', 3: 'three', 4: 'four',
      5: 'five', 6: 'six', 7: 'seven',
    };

    for (final bullet in _valueDepthBullets) {
      final lower = bullet.toLowerCase();
      for (final quantity in <String>['$pool', numberWords[pool] ?? '—']) {
        expect(lower, isNot(contains('$quantity a week')),
            reason: 'this bullet quotes the weekly pool. Say what premium '
                'GIVES, not what free withholds — and never hardcode a dial '
                'into a purchase surface.');
      }
      expect(lower, isNot(contains('free gives')),
          reason: 'premium-only framing: describe the gain, not the ceiling');
    }
  });

  test('no value-depth bullet promises the journal, which is free', () {
    // `lib/features/journal/` has no gating of any kind: no GatingService,
    // no premium check, no row cap. A bullet claiming the journal as a
    // premium gain is not differentiating anything.
    for (final bullet in _valueDepthBullets) {
      expect(bullet.toLowerCase(), isNot(contains('journal')),
          reason: 'the journal is unlimited for free users — selling it as a '
              'premium gain is a claim the product does not back');
    }
  });
}
