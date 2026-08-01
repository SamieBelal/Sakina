import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Whether THIS user will actually be granted the introductory offer attached
/// to a product.
///
/// The distinction the old `_planHasTrial` could not make: a product can carry
/// a free introductory offer forever while a given Apple ID has already burned
/// its one-per-subscription-group grant. Apple grants one introductory offer
/// per Apple ID per subscription group, **ever** — so everyone who used the
/// current 3-day trial is ineligible for whatever replaces it, and showing them
/// trial copy means they tap "Start my N days free" and are charged instantly.
enum TrialEligibility {
  /// The store will grant the intro offer to this user.
  eligible,

  /// The product has an intro offer but this user has already used theirs (or
  /// the product has none at all). Render "Subscribe" and non-trial copy.
  ineligible,

  /// Not resolved yet (offerings still loading, or the store could not say).
  ///
  /// **Treated as [ineligible] by every render path.** RevenueCat's own
  /// guidance for an unknown status is to show non-intro pricing rather than
  /// risk a misleading promise, and that is also the direction that cannot
  /// cost a refund: the failure mode is a lost trial start, never a user
  /// charged after being told they would not be.
  unresolved,
}

/// Whether the gate may promise [productId] a free trial to THIS user.
///
/// [statuses] is `null` until [PurchaseService.getIntroEligibility] has
/// answered; anything unresolved is [TrialEligibility.unresolved], which every
/// render path treats as ineligible.
///
/// The one deliberate exception is Android: Play evaluates eligibility itself
/// at purchase time and RevenueCat therefore answers
/// [IntroEligibilityStatus.introEligibilityStatusUnknown] for **every** Android
/// user. Treating that as ineligible would hide trial copy from the entire
/// platform, so Android falls back to the product-level signal — today's
/// behaviour, unchanged. iOS, where the answer is real and where the refund
/// exposure lives, is strict.
TrialEligibility resolveTrialEligibility({
  required String productId,
  required bool productHasFreeTrial,
  required Map<String, IntroEligibilityStatus>? statuses,
  TargetPlatform? platform,
}) {
  if (!productHasFreeTrial) return TrialEligibility.ineligible;
  if (statuses == null) return TrialEligibility.unresolved;

  switch (statuses[productId]) {
    case IntroEligibilityStatus.introEligibilityStatusEligible:
      return TrialEligibility.eligible;
    case IntroEligibilityStatus.introEligibilityStatusIneligible:
    case IntroEligibilityStatus.introEligibilityStatusNoIntroOfferExists:
      return TrialEligibility.ineligible;
    case IntroEligibilityStatus.introEligibilityStatusUnknown:
    case null:
      final target = platform ?? defaultTargetPlatform;
      return target == TargetPlatform.android
          ? TrialEligibility.eligible
          : TrialEligibility.ineligible;
  }
}

/// The free introductory period the STORE will actually grant, read off the
/// product rather than written down in Dart.
///
/// Every duration in paywall copy derives from here (W5 Wave B.4). Before this
/// existed, "3 days" was hardcoded in five separate strings, so a change in App
/// Store Connect silently turned the paywall into a false promise at the moment
/// of payment — the exact failure §3.2 of the plan calls out. Nothing in the
/// paywall may hardcode a trial length again.
class TrialOffer {
  const TrialOffer({required this.units, required this.unit});

  /// `intro.periodNumberOfUnits` — e.g. `3` for `P3D`, `1` for `P1W`.
  final int units;

  /// `intro.periodUnit` — day / week / month / year.
  final PeriodUnit unit;

  /// The trial on [product], or `null` when the product carries no FREE intro
  /// offer (a paid intro price is not a trial and must never be sold as one).
  ///
  /// [IntroductoryPrice.periodUnit] arrives as [PeriodUnit.unknown] when the
  /// store hands back a unit string the SDK does not know, and
  /// `periodNumberOfUnits` has been observed as 0 on some storefronts, so both
  /// fall back to parsing the ISO-8601 `period` (`P3D`, `P1W`, …). If neither
  /// source yields a usable duration we return `null` — the paywall then shows
  /// non-trial copy, which is wrong-but-safe, rather than a duration we guessed.
  static TrialOffer? fromProduct(StoreProduct? product) {
    final intro = product?.introductoryPrice;
    if (intro == null || intro.price != 0) return null;

    final parsed = _parseIso8601Period(intro.period);
    final units =
        intro.periodNumberOfUnits > 0 ? intro.periodNumberOfUnits : parsed?.$1;
    final unit = intro.periodUnit == PeriodUnit.unknown
        ? parsed?.$2
        : intro.periodUnit;

    if (units == null || units <= 0 || unit == null) return null;
    return TrialOffer(units: units, unit: unit);
  }

  /// The trial expressed in whole days, or `null` when the unit does not
  /// convert cleanly (a month is not a fixed number of days, and the timeline
  /// page would rather render nothing than a wrong "Day 30").
  int? get days {
    switch (unit) {
      case PeriodUnit.day:
        return units;
      case PeriodUnit.week:
        return units * 7;
      case PeriodUnit.month:
      case PeriodUnit.year:
      case PeriodUnit.unknown:
        return null;
    }
  }

  /// The user-facing duration: `"3 days"`, `"7 days"`, `"1 month"`.
  ///
  /// A `P1W` trial renders as "7 days", not "1 week" — the approved copy
  /// counts the trial in days on every surface, and the two are the same
  /// promise.
  String get label {
    final d = days;
    if (d != null) return _plural(d, 'day');
    switch (unit) {
      case PeriodUnit.month:
        return _plural(units, 'month');
      case PeriodUnit.year:
        return _plural(units, 'year');
      case PeriodUnit.day:
      case PeriodUnit.week:
      case PeriodUnit.unknown:
        return _plural(units, 'day');
    }
  }

  static String _plural(int n, String noun) => '$n $noun${n == 1 ? '' : 's'}';

  /// `P3D` / `P1W` / `P2M` / `P1Y` → (3, day) / (1, week) / …
  static (int, PeriodUnit)? _parseIso8601Period(String period) {
    final match = RegExp(r'^P(\d+)([DWMY])$').firstMatch(period.toUpperCase());
    if (match == null) return null;
    final n = int.tryParse(match.group(1)!);
    if (n == null || n <= 0) return null;
    final unit = switch (match.group(2)!) {
      'D' => PeriodUnit.day,
      'W' => PeriodUnit.week,
      'M' => PeriodUnit.month,
      'Y' => PeriodUnit.year,
      _ => null,
    };
    if (unit == null) return null;
    return (n, unit);
  }

  @override
  bool operator ==(Object other) =>
      other is TrialOffer && other.units == units && other.unit == unit;

  @override
  int get hashCode => Object.hash(units, unit);

  @override
  String toString() => 'TrialOffer($label)';
}
