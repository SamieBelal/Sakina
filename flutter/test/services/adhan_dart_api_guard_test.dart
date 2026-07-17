import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';

/// Compile-guard for the `adhan_dart` symbol surface the duʿā-times feature
/// depends on (design spec §4). The port has historically re-cased/renamed
/// members; pinning the version is not enough — this test references the exact
/// symbols so an upgrade that renames `SunnahTimes.lastThirdOfTheNight` (or
/// moves the `Madhab`/`HighLatitudeRule` enums) fails CI instead of silently
/// breaking the night-third path.
void main() {
  test('SunnahTimes exposes lastThirdOfTheNight (compile-guard)', () {
    final params = CalculationMethodParameters.muslimWorldLeague().copyWith(
      madhab: Madhab.shafi,
      highLatitudeRule: HighLatitudeRule.middleOfTheNight,
    );
    final pt = PrayerTimes(
      coordinates: const Coordinates(21.4225, 39.8262),
      date: DateTime.utc(2024, 1, 1),
      calculationParameters: params,
      precision: true,
    );
    final sunnah = SunnahTimes(pt, precision: true);

    // The load-bearing symbol. If this member is renamed, this line won't
    // compile — which is exactly the CI tripwire we want.
    final DateTime lastThird = sunnah.lastThirdOfTheNight;
    expect(lastThird, isA<DateTime>());

    // `PrayerTimes.fajrAfter` is the night-third END (next-day Fajr) the service
    // reads in `_windowFrom`. Reference it here so a rename fails CI too.
    final DateTime fajrAfter = pt.fajrAfter;
    expect(fajrAfter, isA<DateTime>());

    // Also pin the enum values we rely on.
    expect(Madhab.shafi.shadowLength, 1);
    expect(Madhab.hanafi.shadowLength, 2);
    expect(HighLatitudeRule.values, contains(HighLatitudeRule.seventhOfTheNight));
  });
}
