/// What the free tier grants, in the user's words, said once in onboarding
/// (2026-08-07).
///
/// **The gap this closes.** Every other string in the app that describes the
/// free allowance — `WarmupExhaustedSheet`, `DailyCapSheet` — fires *after* a
/// block. Until this line existed, the first time a user learned there was a
/// limit was the moment they hit it, which is the worst possible introduction
/// to a rule that is, on the numbers, generous: 3 lifetime warm-ups of each
/// feature, then 3 shared reflections and duʿās a week, with the day's Name
/// free forever on top.
///
/// **Framed as the grant.** The cap is the same fact read from the other side,
/// and the other side is the one worth saying to someone who has not signed up
/// yet.
///
/// Kept out of the widget for the reason every copy file here is: it is a
/// product decision referenced verbatim by tests, and a rewording of a promise
/// made pre-signup is a bigger change than it looks.
library;

abstract final class FreeTierCopy {
  /// [weeklyPool] is `reel_v1`'s shared Reflect + Build-a-Duʿā allowance —
  /// passed in rather than written out, so a re-dial of `weekly_pool_size`
  /// cannot leave this line quietly lying to new users.
  ///
  /// **Says "a week", not "3 free then paywall".** And it leads with the part
  /// that never runs out: the daily Name consults no gate at all, on any tier,
  /// forever. That is the sentence that makes the second half read as a bonus
  /// rather than as a meter.
  ///
  /// **Does not mention the warm-up.** A new user's first six generations are
  /// free of the weekly pool entirely (3 reflect + 3 duʿā, lifetime), so this
  /// line understates what they actually have for their first week — which is
  /// the correct direction to be wrong in. Naming both grants would need two
  /// sentences and a word like "then", and "then" is what turns a gift into
  /// terms.
  static String freeTierGrant(int weeklyPool) =>
      'Your Name each day is free, always — plus $weeklyPool reflections and '
      'duʿās a week to build on it.';
}
