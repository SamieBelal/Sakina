import 'package:adhan_dart/adhan_dart.dart';

/// Result of a prayer-time computation for a single day at a single location.
///
/// All instants are **absolute UTC** (adhan_dart computes in UTC). A given
/// field is `null` when the underlying time is undefined at high latitude — the
/// caller must omit that window rather than render a wrong time (spec §10).
class PrayerDayTimes {
  const PrayerDayTimes({
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  /// The civil date (device-local day) these times were computed for.
  final DateTime date;

  final DateTime? fajr;
  final DateTime? sunrise;
  final DateTime? dhuhr;
  final DateTime? asr;
  final DateTime? maghrib;
  final DateTime? isha;
}

/// A resolved last-third-of-the-night window (Maghrib → Fajr, final third),
/// both bounds absolute UTC. `null` fields ⇒ undefined at this latitude/date.
class LastThirdOfNight {
  const LastThirdOfNight({required this.startUtc, required this.endUtc});

  /// When the last third opens (2/3 of the way from Maghrib to next Fajr).
  final DateTime startUtc;

  /// When the last third closes (next Fajr).
  final DateTime endUtc;
}

/// Thin wrapper over `adhan_dart` — the single seam the rest of the feature
/// uses for prayer times + the last-third-of-night window.
///
/// Deliberately dependency-free of Riverpod/Supabase (pure computation), per
/// `CLAUDE.md` service-layer conventions. The `adhan_dart` symbol surface is
/// pinned + compile-guarded (see `test/services/prayer_time_service_test.dart`
/// and spec §4) because the port has historically re-cased members.
class PrayerTimeService {
  const PrayerTimeService();

  /// Build calculation parameters for [method] + [madhab] with a sane
  /// high-latitude rule chosen from [coordinates] (spec §4: `seventhOfTheNight`
  /// above 48°, `middleOfTheNight` otherwise).
  CalculationParameters _params({
    required Coordinates coordinates,
    required CalculationParameters method,
    required Madhab madhab,
  }) {
    return method.copyWith(
      madhab: madhab,
      highLatitudeRule: HighLatitudeRule.recommended(coordinates),
    );
  }

  /// Default calculation method — Muslim World League (spec §5, fixed in v1).
  static CalculationParameters defaultMethod() =>
      CalculationMethodParameters.muslimWorldLeague();

  /// Compute the five daily prayer times (+ sunrise) for [date] at [lat]/[lon].
  ///
  /// [date] is interpreted as a civil day; adhan_dart takes the y/m/d and
  /// computes UTC instants. Undefined (high-latitude NaN) times come back as
  /// `null` so callers can omit the corresponding window.
  PrayerDayTimes prayerTimes({
    required double lat,
    required double lon,
    required DateTime date,
    CalculationParameters? method,
    Madhab madhab = Madhab.shafi,
  }) {
    final coordinates = Coordinates(lat, lon);
    final params = _params(
      coordinates: coordinates,
      method: method ?? defaultMethod(),
      madhab: madhab,
    );
    final pt = PrayerTimes(
      coordinates: coordinates,
      date: date,
      calculationParameters: params,
      precision: true,
    );
    return PrayerDayTimes(
      date: date,
      fajr: _valid(pt.fajr),
      sunrise: _valid(pt.sunrise),
      dhuhr: _valid(pt.dhuhr),
      asr: _valid(pt.asr),
      maghrib: _valid(pt.maghrib),
      isha: _valid(pt.isha),
    );
  }

  /// Resolve the **correct** last-third-of-night window covering [now].
  ///
  /// The night spans local midnight, so which day's `PrayerTimes` we seed
  /// `SunnahTimes` from matters (spec §4, the off-by-one guard):
  ///
  /// - **Before today's Fajr** ⇒ you are still inside the third that opened at
  ///   *yesterday's* Maghrib ⇒ seed from **yesterday's** `PrayerTimes`.
  /// - **At/after today's Maghrib** ⇒ tonight's third has begun ⇒ seed from
  ///   **today's** `PrayerTimes`.
  /// - **Between Fajr and Maghrib** (daytime) ⇒ no third is active; return the
  ///   *upcoming* one from today's `PrayerTimes` so the caller can count down.
  ///
  /// Returns `null` if the required prayer times are undefined at this latitude
  /// (caller omits the window rather than show a wrong time).
  ///
  /// [nowLocalDate] should carry the device-local y/m/d for "today"; [now] is
  /// the absolute instant used to pick which side of the boundary we're on.
  LastThirdOfNight? lastThirdOfNight({
    required double lat,
    required double lon,
    required DateTime now,
    required DateTime nowLocalDate,
    CalculationParameters? method,
    Madhab madhab = Madhab.shafi,
  }) {
    final coordinates = Coordinates(lat, lon);
    final params = _params(
      coordinates: coordinates,
      method: method ?? defaultMethod(),
      madhab: madhab,
    );
    final nowUtc = now.toUtc();

    final today = _dateOnly(nowLocalDate);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayPt = PrayerTimes(
      coordinates: coordinates,
      date: today,
      calculationParameters: params,
      precision: true,
    );
    final todayFajr = _valid(todayPt.fajr);
    final todayMaghrib = _valid(todayPt.maghrib);

    // Before today's Fajr → derive from yesterday's Maghrib → today's Fajr.
    if (todayFajr != null && nowUtc.isBefore(todayFajr)) {
      final yesterdayPt = PrayerTimes(
        coordinates: coordinates,
        date: yesterday,
        calculationParameters: params,
        precision: true,
      );
      return _windowFrom(yesterdayPt);
    }

    // At/after today's Maghrib → derive from today's Maghrib → tomorrow's Fajr.
    if (todayMaghrib != null && !nowUtc.isBefore(todayMaghrib)) {
      return _windowFrom(todayPt);
    }

    // Daytime (between Fajr and Maghrib): no active third. Return tonight's
    // upcoming third so the caller can count down to it.
    return _windowFrom(todayPt);
  }

  /// Build a [LastThirdOfNight] from a `PrayerTimes` via `SunnahTimes`.
  /// `SunnahTimes.lastThirdOfTheNight` is the compile-guarded symbol (spec §4).
  ///
  /// Returns `null` when the window is undefined or *degenerate* — at extreme
  /// high latitudes (midnight sun / polar night) adhan_dart can emit a Maghrib
  /// and Fajr weeks apart, yielding a non-positive or absurdly long span. Per
  /// spec §10 we omit such windows rather than render a wrong time.
  LastThirdOfNight? _windowFrom(PrayerTimes pt) {
    final maghrib = _valid(pt.maghrib);
    final fajrAfter = _valid(pt.fajrAfter);
    if (maghrib == null || fajrAfter == null) return null;

    final sunnah = SunnahTimes(pt, precision: true);
    final start = _valid(sunnah.lastThirdOfTheNight);
    if (start == null) return null;

    final startUtc = start.toUtc();
    final endUtc = fajrAfter.toUtc();

    // Sanity band: a real night is a few hours long. Reject non-positive spans
    // and anything longer than ~a day (polar artifacts).
    final span = endUtc.difference(startUtc);
    if (span <= Duration.zero || span > const Duration(hours: 24)) {
      return null;
    }

    return LastThirdOfNight(startUtc: startUtc, endUtc: endUtc);
  }

  /// Returns the UTC instant if valid, or `null` if adhan_dart produced an
  /// undefined (NaN-backed) DateTime at high latitude.
  static DateTime? _valid(DateTime? t) {
    if (t == null) return null;
    final ms = t.millisecondsSinceEpoch;
    if (ms.isNaN || ms == 0) return null;
    return t.isUtc ? t : t.toUtc();
  }

  /// Strip any time-of-day, keeping y/m/d (used to seed `PrayerTimes`).
  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
