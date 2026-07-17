import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/prayer_time_service.dart';

/// Tolerance for comparing against published prayer-time tables. adhan_dart is a
/// precise astronomical calc; published calendars round to the minute and vary
/// slightly by convention, so we assert within a few minutes.
const Duration _tol = Duration(minutes: 4);

void _closeTo(DateTime? actual, DateTime expected, {Duration tol = _tol}) {
  expect(actual, isNotNull);
  final diff = actual!.toUtc().difference(expected.toUtc()).abs();
  expect(
    diff <= tol,
    isTrue,
    reason: 'expected $expected, got ${actual.toUtc()} (Δ $diff)',
  );
}

void main() {
  const service = PrayerTimeService();

  // Mecca — a canonical fixture whose MWL/Shafiʿī times are widely published.
  const meccaLat = 21.4225;
  const meccaLon = 39.8262;
  final jan1 = DateTime.utc(2024, 1, 1);

  group('PrayerTimeService.prayerTimes — published fixtures', () {
    test('Mecca 2024-01-01 MWL/Shafi matches published times (±4m)', () {
      final t = service.prayerTimes(
        lat: meccaLat,
        lon: meccaLon,
        date: jan1,
      );
      // Mecca is UTC+3; the UTC instants below correspond to local
      // Fajr 05:39, Sunrise 06:58, Dhuhr 12:24, Asr 15:28, Maghrib 17:49.
      _closeTo(t.fajr, DateTime.utc(2024, 1, 1, 2, 39));
      _closeTo(t.sunrise, DateTime.utc(2024, 1, 1, 3, 58));
      _closeTo(t.dhuhr, DateTime.utc(2024, 1, 1, 9, 24));
      _closeTo(t.asr, DateTime.utc(2024, 1, 1, 12, 28));
      _closeTo(t.maghrib, DateTime.utc(2024, 1, 1, 14, 49));
      _closeTo(t.isha, DateTime.utc(2024, 1, 1, 16, 4));
    });

    test('all returned instants are UTC', () {
      final t = service.prayerTimes(lat: meccaLat, lon: meccaLon, date: jan1);
      expect(t.fajr!.isUtc, isTrue);
      expect(t.maghrib!.isUtc, isTrue);
    });
  });

  // (Removed the madhab/ʿAsr test: madhab was dropped from the feature — the
  // Friday window now anchors to Maghrib, not ʿAsr, so nothing is madhab-
  // dependent. See dua_window_catalog.fridayHourLeadBeforeMaghrib.)

  group('lastThirdOfNight correctness', () {
    test('window opens at 2/3 of Maghrib→Fajr and closes at Fajr', () {
      // Daytime on Jan 1 → returns tonight's upcoming third from Jan-1 times.
      final noonUtc = DateTime.utc(2024, 1, 1, 9, 0); // ~noon local Mecca
      final w = service.lastThirdOfNight(
        lat: meccaLat,
        lon: meccaLon,
        now: noonUtc,
        nowLocalDate: DateTime(2024, 1, 1),
      );
      expect(w, isNotNull);
      // From the probe: Jan-1 last third opens 22:42Z, closes (fajrAfter) 02:39Z Jan-2.
      _closeTo(w!.startUtc, DateTime.utc(2024, 1, 1, 22, 42));
      _closeTo(w.endUtc, DateTime.utc(2024, 1, 2, 2, 39));
      // Start is strictly after Maghrib and the window has positive length.
      expect(w.endUtc.isAfter(w.startUtc), isTrue);
    });

    test('high latitude undefined window → null (omitted, not wrong)', () {
      // Extreme polar latitude in deep summer: Fajr/Isha undefined even with the
      // recommended high-lat rule can drive NaN → service must return null.
      final w = service.lastThirdOfNight(
        lat: 78.0, // Svalbard
        lon: 15.0,
        now: DateTime.utc(2024, 6, 21, 0, 0),
        nowLocalDate: DateTime(2024, 6, 21),
      );
      // adhan_dart emits a degenerate span here (Maghrib/Fajr weeks apart under
      // the midnight sun); the service must omit it (null), never a wrong time.
      expect(w, isNull);
    });
  });

  group('night-third off-by-one guard (02:00 local)', () {
    test(
        'at 02:00 local the active third is derived from YESTERDAY\'s Maghrib',
        () {
      // Mecca is UTC+3. 02:00 local on 2024-01-02 == 2024-01-01 23:00 UTC.
      final nowUtc = DateTime.utc(2024, 1, 1, 23, 0);
      final localDate = DateTime(2024, 1, 2); // the local calendar day

      final w = service.lastThirdOfNight(
        lat: meccaLat,
        lon: meccaLon,
        now: nowUtc,
        nowLocalDate: localDate,
      );
      expect(w, isNotNull);

      // CORRECT (yesterday=Jan-1 source): window 22:42Z Jan-1 → 02:39Z Jan-2,
      // which CONTAINS now (23:00Z Jan-1).
      _closeTo(w!.startUtc, DateTime.utc(2024, 1, 1, 22, 42));
      _closeTo(w.endUtc, DateTime.utc(2024, 1, 2, 2, 39));
      expect(
        !nowUtc.isBefore(w.startUtc) && nowUtc.isBefore(w.endUtc),
        isTrue,
        reason: 'now must fall inside the active last-third window',
      );

      // Guard against the naive bug: seeding from TODAY (Jan-2) would yield a
      // window that opens 22:43Z Jan-2 — i.e. does NOT contain now. Prove the
      // returned window is not that (tomorrow-night) window.
      final wrongStart = DateTime.utc(2024, 1, 2, 22, 43);
      expect(
        w.startUtc.difference(wrongStart).abs() > const Duration(hours: 12),
        isTrue,
        reason: 'must NOT be tomorrow-night window from today\'s PrayerTimes',
      );
    });
  });
}
