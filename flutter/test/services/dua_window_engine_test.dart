import 'package:geolocator/geolocator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/dua_times/models/dua_window.dart';
import 'package:sakina/features/dua_times/models/dua_window_schedule.dart';
import 'package:sakina/features/dua_times/models/dua_window_type.dart';
import 'package:sakina/services/dua_window_engine.dart';
import 'package:sakina/services/dua_window_repository.dart';
import 'package:sakina/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An in-memory [DuaWindowRepository] stub returning a fixed calendar so the
/// engine tests never touch Supabase, SharedPreferences, or the asset bundle.
class _StubRepository extends DuaWindowRepository {
  _StubRepository(this._calendar);
  final DuaCalendar _calendar;

  @override
  Future<DuaCalendar> load() async => _calendar;

  @override
  Future<DuaCalendar> refreshFromRemote() async => _calendar;
}

DuaCalendarRow _row({
  required String id,
  required String kind,
  required String tier,
  required String start,
  required String end,
  String? source,
}) {
  DateTime d(String s) {
    final p = s.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  return DuaCalendarRow(
    id: id,
    kind: kind,
    tier: tier,
    titleKey: 'dua_window.$kind',
    startDate: d(start),
    endDate: d(end),
    sourceRef: source,
  );
}

/// Build a [LocalMidnightResolver] simulating a fixed UTC offset (in hours).
/// Local midnight of date D occurs at UTC = D 00:00 minus the offset.
LocalMidnightResolver _fixedOffset(int offsetHours) {
  return (y, m, day) =>
      DateTime.utc(y, m, day).subtract(Duration(hours: offsetHours));
}

void main() {
  // Mecca, UTC+3 — canonical prayer-time fixture.
  const meccaLat = 21.4225;
  const meccaLon = 39.8262;
  const mecca = EngineLocation(lat: meccaLat, lon: meccaLon);

  // Ramadan 1448 + ʿArafah + Friday calendar rows from the seed.
  final fullCalendar = DuaCalendar(
    rows: [
      _row(
          id: 'ramadan_1448',
          kind: 'ramadan',
          tier: 'special',
          start: '2027-02-08',
          end: '2027-03-08'),
      _row(
          id: 'arafah_1448',
          kind: 'arafah',
          tier: 'hero',
          start: '2027-05-15',
          end: '2027-05-15',
          source: 'Tirmidhi 3585'),
      _row(
          id: 'white_days_dhulhijja_1448',
          kind: 'white_days',
          tier: 'soft',
          start: '2027-05-19',
          end: '2027-05-21',
          source: 'Tirmidhi 761'),
    ],
    lastSeededThrough: DateTime(2027, 6, 20),
    fromBundledAsset: false,
  );

  DuaWindowEngine engine(DuaCalendar cal, {LocalMidnightResolver? resolver}) {
    return DuaWindowEngine(
      repository: _StubRepository(cal),
      localMidnightUtc: resolver ?? (y, m, d) => DateTime(y, m, d).toUtc(),
    );
  }

  group('active / next resolution', () {
    test('night-third active at local 02:00 (UTC-spanning midnight)', () async {
      // Mecca is UTC+3. Local 02:00 on 2027-05-16 = UTC 2027-05-15 23:00.
      // Probed last-third: 22:11 → 01:20 UTC, so now IS inside it.
      final e = engine(fullCalendar, resolver: _fixedOffset(3));
      final s = await e.buildSchedule(
        now: DateTime.utc(2027, 5, 15, 23, 0),
        location: mecca,
        tzName: 'Asia/Riyadh',
      );
      expect(s.active, isNotNull);
      expect(s.active!.type, DuaWindowType.lastThirdOfNight);
      expect(s.urgency, isNot(UrgencyState.upcoming));
    });

    test('between windows → active null, next populated', () async {
      // Midday Mecca (no night-third, not Friday, not Ramadan, no calendar day
      // active on 2027-05-13). UTC 09:00 = local 12:00.
      final e = engine(fullCalendar);
      final s = await e.buildSchedule(
        now: DateTime.utc(2027, 5, 13, 9, 0),
        location: mecca,
      );
      expect(s.active, isNull);
      expect(s.next, isNotNull);
      expect(s.urgency, UrgencyState.upcoming);
    });
  });

  group('overlap priority', () {
    test('ʿArafah (all-day) beats an overlapping White-Days window', () async {
      // Both ʿArafah (2027-05-15) and a synthetic White-Days spanning the same
      // day are active at local noon on 2027-05-15.
      final cal = DuaCalendar(
        rows: [
          _row(
              id: 'arafah',
              kind: 'arafah',
              tier: 'hero',
              start: '2027-05-15',
              end: '2027-05-15'),
          _row(
              id: 'wd',
              kind: 'white_days',
              tier: 'soft',
              start: '2027-05-14',
              end: '2027-05-16'),
        ],
        lastSeededThrough: DateTime(2027, 6, 20),
        fromBundledAsset: false,
      );
      final e = engine(cal, resolver: _fixedOffset(3));
      // Local noon 2027-05-15 = UTC 09:00. No location → calendar only.
      final s = await e.buildSchedule(now: DateTime.utc(2027, 5, 15, 9, 0));
      expect(s.active, isNotNull);
      expect(s.active!.type, DuaWindowType.arafah);
    });

    test('Friday (day) beats White Days when overlapping', () async {
      final cal = DuaCalendar(
        rows: [
          _row(
              id: 'wd',
              kind: 'white_days',
              tier: 'soft',
              start: '2027-05-13',
              end: '2027-05-15'),
        ],
        lastSeededThrough: DateTime(2027, 6, 20),
        fromBundledAsset: false,
      );
      // 2027-05-14 is a Friday. Local noon = UTC 09:00. No location.
      final e = engine(cal, resolver: _fixedOffset(3));
      final s = await e.buildSchedule(now: DateTime.utc(2027, 5, 14, 9, 0));
      expect(s.active, isNotNull);
      expect(s.active!.type, DuaWindowType.fridayDay);
    });

    test('priorityOf ranks ʿArafah > Friday-hour > Friday-day > White-Days',
        () {
      expect(
        DuaWindowEngine.priorityOf(DuaWindowType.arafah) >
            DuaWindowEngine.priorityOf(DuaWindowType.fridayHour),
        isTrue,
      );
      expect(
        DuaWindowEngine.priorityOf(DuaWindowType.fridayHour) >
            DuaWindowEngine.priorityOf(DuaWindowType.fridayDay),
        isTrue,
      );
      expect(
        DuaWindowEngine.priorityOf(DuaWindowType.fridayDay) >
            DuaWindowEngine.priorityOf(DuaWindowType.whiteDays),
        isTrue,
      );
    });
  });

  group('Friday hour', () {
    test('emitted on Friday (last hour before Maghrib), absent other days',
        () async {
      final emptyCal = DuaCalendar(
        rows: const [],
        lastSeededThrough: DateTime(2027, 6, 20),
        fromBundledAsset: false,
      );
      final e = engine(emptyCal);
      // 2027-05-14 is a Friday. Maghrib ~15:51 UTC → the window is the last hour
      // before it (~14:51 → 15:51). Probe at 15:30 (inside).
      final fri = await e.buildSchedule(
        now: DateTime.utc(2027, 5, 14, 15, 30), // inside the last hour
        location: mecca,
      );
      expect(
        fri.active?.type,
        DuaWindowType.fridayHour,
        reason: 'inside the last hour before Maghrib on Friday',
      );

      // 2027-05-13 is a Thursday — no Friday hour anywhere in the schedule.
      final thu = await e.buildSchedule(
        now: DateTime.utc(2027, 5, 13, 13, 0),
        location: mecca,
      );
      final hasFridayHour = [
        ...thu.upcoming,
        if (thu.active != null) thu.active!,
      ].any((w) => w.type == DuaWindowType.fridayHour);
      // A Friday hour for 2027-05-14 IS within the 7-day horizon, so it should
      // appear in upcoming — but never as Thursday's active window.
      expect(thu.active?.type, isNot(DuaWindowType.fridayHour));
      expect(hasFridayHour, isTrue,
          reason: 'next Friday hour is within horizon');
    });
  });

  group('iftar', () {
    test('present in Ramadan, absent outside Ramadan', () async {
      // Ramadan day 1 = 2027-02-08. Probe: Maghrib 15:14 UTC → iftar 14:54.
      final e = engine(fullCalendar);
      final inRamadan = await e.buildSchedule(
        now: DateTime.utc(2027, 2, 8, 15, 0), // inside iftar lead
        location: mecca,
      );
      final hasIftar = [
        ...inRamadan.upcoming,
        if (inRamadan.active != null) inRamadan.active!,
      ].any((w) => w.type == DuaWindowType.iftar);
      expect(hasIftar, isTrue);

      // A non-Ramadan day (2027-05-13) → no iftar window at all.
      final outside = await e.buildSchedule(
        now: DateTime.utc(2027, 5, 13, 9, 0),
        location: mecca,
      );
      final hasIftarOutside = [
        ...outside.upcoming,
        if (outside.active != null) outside.active!,
      ].any((w) => w.type == DuaWindowType.iftar);
      expect(hasIftarOutside, isFalse);
    });

    test(
        'pinned to fasting days — fires on the first & last fast, never on '
        'the eve before Ramadan or on Eid', () async {
      // Ramadan 1448 = Feb 8 → Mar 8 (29 days). Iftar breaks the fast at
      // Maghrib on each of those days: the standard Umm al-Qura convention
      // (start_date = the first fasting day; Eid = the day after end_date, no
      // fast). This pins the ±1 boundary so it can't drift in a refactor.
      final e = engine(fullCalendar, resolver: _fixedOffset(3));

      String utcDate(DuaWindow w) {
        final d = w.startUtc.toUtc();
        return '${d.year.toString().padLeft(4, '0')}-'
            '${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}';
      }

      Set<String> iftarDates(DuaWindowSchedule s) => <DuaWindow>{
            ...s.upcoming,
            if (s.active != null) s.active!,
          }.where((w) => w.type == DuaWindowType.iftar).map(utcDate).toSet();

      // Near the END (horizon Mar 5..12): last fast Mar 8, Eid Mar 9.
      final endDates = iftarDates(
        await e.buildSchedule(
            now: DateTime.utc(2027, 3, 5, 9), location: mecca),
      );
      expect(endDates.contains('2027-03-08'), isTrue,
          reason: 'last fast (29 Ramadan)');
      expect(endDates.any((d) => d.compareTo('2027-03-09') >= 0), isFalse,
          reason: 'no iftar on Eid al-Fitr or after');

      // Near the START (horizon Feb 5..12): first fast Feb 8.
      final startDates = iftarDates(
        await e.buildSchedule(
            now: DateTime.utc(2027, 2, 5, 9), location: mecca),
      );
      expect(startDates.contains('2027-02-08'), isTrue,
          reason: 'first fast (1 Ramadan)');
      expect(startDates.any((d) => d.compareTo('2027-02-08') < 0), isFalse,
          reason: 'no iftar the evenings before Ramadan');
    });
  });

  group('degrade: no location', () {
    test('LocationService denied (null fix) → calendar-only schedule',
        () async {
      SharedPreferences.setMockInitialValues({});
      final deniedLocation = LocationService(
        checkPermission: () async => LocationPermission.deniedForever,
        requestPermission: () async => LocationPermission.deniedForever,
        serviceEnabled: () async => true,
        currentPosition: () async => throw StateError('must not fetch'),
        prefs: SharedPreferences.getInstance,
      );
      final e = DuaWindowEngine(
        repository: _StubRepository(fullCalendar),
        locationService: deniedLocation,
      );
      final s = await e.buildSchedule(now: DateTime.utc(2027, 5, 14, 13, 0));
      final all = [
        ...s.upcoming,
        if (s.active != null) s.active!,
        if (s.next != null) s.next!,
      ];
      expect(all.any((w) => w.locationDependent), isFalse);
      expect(s.computedAt.lat, isNull);
    });

    test('permission-denied → calendar-only + soft night, no precise windows',
        () async {
      final e = engine(fullCalendar);
      final s = await e.buildSchedule(
        now: DateTime.utc(2027, 5, 14, 13, 0), // a Friday
        location: null,
      );
      final all = [
        ...s.upcoming,
        if (s.active != null) s.active!,
        if (s.next != null) s.next!,
      ];
      // No location-dependent (precise) windows may be present.
      expect(all.any((w) => w.locationDependent), isFalse);
      // Calendar Friday-day survives.
      expect(all.any((w) => w.type == DuaWindowType.fridayDay), isTrue);
      // A soft-night marker is present (soft tier, not location-dependent).
      expect(
        all.any((w) => w.tier == DuaWindowTier.soft && !w.locationDependent),
        isTrue,
      );
      // Stamp carries no coordinates.
      expect(s.computedAt.lat, isNull);
      expect(s.computedAt.lon, isNull);
    });
  });

  group('high latitude', () {
    test('undefined night-third window is omitted (no wrong time)', () async {
      // Longyearbyen, Svalbard (78°N) in June → polar day, no valid night.
      final emptyCal = DuaCalendar(
        rows: const [],
        lastSeededThrough: DateTime(2027, 6, 20),
        fromBundledAsset: false,
      );
      final e = engine(emptyCal);
      final s = await e.buildSchedule(
        now: DateTime.utc(2027, 6, 21, 0, 0),
        location: const EngineLocation(lat: 78.22, lon: 15.65),
      );
      final all = [
        ...s.upcoming,
        if (s.active != null) s.active!,
      ];
      expect(
        all.any((w) => w.type == DuaWindowType.lastThirdOfNight),
        isFalse,
        reason: 'polar day → night-third undefined → omitted',
      );
    });
  });

  group('7-day upcoming generation', () {
    test('upcoming ordered by start, all within horizon', () async {
      final e = engine(fullCalendar);
      final now = DateTime.utc(2027, 5, 13, 9, 0);
      final s = await e.buildSchedule(now: now, location: mecca);
      expect(s.upcoming, isNotEmpty);
      // Monotonic non-decreasing start instants.
      for (var i = 1; i < s.upcoming.length; i++) {
        expect(
          s.upcoming[i].startUtc.isBefore(s.upcoming[i - 1].startUtc),
          isFalse,
        );
      }
      // All within the 7-day horizon.
      final horizonEnd = now.add(DuaWindowEngine.horizon);
      for (final w in s.upcoming) {
        expect(w.startUtc.isAfter(horizonEnd), isFalse);
      }
      // Stamp horizon matches.
      expect(s.computedAt.computedThroughUtc, horizonEnd);
    });
  });

  group('all-day date-line rule', () {
    test('ʿArafah opens at device-local midnight in Honolulu and Auckland',
        () async {
      final cal = DuaCalendar(
        rows: [
          _row(
              id: 'arafah',
              kind: 'arafah',
              tier: 'hero',
              start: '2027-05-15',
              end: '2027-05-15'),
        ],
        lastSeededThrough: DateTime(2027, 6, 20),
        fromBundledAsset: false,
      );

      // Honolulu UTC-10 → local midnight 2027-05-15 = UTC 2027-05-15 10:00.
      final hono = engine(cal, resolver: _fixedOffset(-10));
      final sHono = await hono.buildSchedule(
        now: DateTime.utc(2027, 5, 15, 12, 0),
      );
      final arafahHono = _findArafah(sHono);
      expect(arafahHono.startUtc, DateTime.utc(2027, 5, 15, 10, 0));

      // Auckland UTC+13 → local midnight 2027-05-15 = UTC 2027-05-14 11:00.
      final auck = engine(cal, resolver: _fixedOffset(13));
      final sAuck = await auck.buildSchedule(
        now: DateTime.utc(2027, 5, 14, 12, 0),
      );
      final arafahAuck = _findArafah(sAuck);
      expect(arafahAuck.startUtc, DateTime.utc(2027, 5, 14, 11, 0));

      // The two are NOT a shared UTC instant — proves per-device anchoring.
      expect(arafahHono.startUtc == arafahAuck.startUtc, isFalse);
    });
  });
}

dynamic _findArafah(DuaWindowSchedule s) {
  final all = [
    ...s.upcoming,
    if (s.active != null) s.active!,
  ];
  return all.firstWhere((w) => w.type == DuaWindowType.arafah);
}
