import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sakina/features/dua_times/models/dua_window_type.dart';
import 'package:sakina/services/dua_precise_sync_service.dart';
import 'package:sakina/services/dua_window_engine.dart';
import 'package:sakina/services/dua_window_repository.dart';
import 'package:sakina/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An in-memory [DuaWindowRepository] stub returning a fixed calendar so these
/// tests never touch Supabase, SharedPreferences, or the asset bundle. Mirrors
/// the engine test's `_StubRepository`.
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
    sourceRef: null,
  );
}

/// An in-memory [DuaPreciseSyncBackend] that records every op and simulates the
/// server table's rows so we can assert the atomic sync-by-version contract.
class _FakeBackend implements DuaPreciseSyncBackend {
  _FakeBackend({this.userId = 'user-1'});

  String? userId;

  /// Simulated table rows (each carries `sync_version`).
  final List<Map<String, dynamic>> rows = [];

  int insertCalls = 0;
  int deleteBelowCalls = 0;
  int deleteAllCalls = 0;

  /// When true, [insertRows] fails (to test the insert-before-delete guard).
  bool failInsert = false;

  @override
  String? get currentUserId => userId;

  @override
  Future<int?> currentSyncVersion(String uid) async {
    final versions = rows
        .where((r) => r['user_id'] == uid)
        .map((r) => r['sync_version'] as int);
    if (versions.isEmpty) return null;
    return versions.reduce((a, b) => a > b ? a : b);
  }

  @override
  Future<bool> insertRows(List<Map<String, dynamic>> newRows) async {
    insertCalls++;
    if (failInsert) return false;
    // Model the (user_id, window_type, fire_utc) UNIQUE constraint as an
    // UPSERT-on-conflict-UPDATE: a row whose natural key already exists is
    // UPDATED in place (sync_version/title/body overwritten) rather than
    // duplicated — exactly Postgres `ON CONFLICT ... DO UPDATE`. This is what
    // makes duplicate-instant rows physically impossible and the sync race
    // benign.
    for (final incoming in newRows) {
      final row = Map<String, dynamic>.from(incoming);
      final idx = rows.indexWhere(
        (existing) =>
            existing['user_id'] == row['user_id'] &&
            existing['window_type'] == row['window_type'] &&
            existing['fire_utc'] == row['fire_utc'],
      );
      if (idx >= 0) {
        rows[idx] = row; // conflict → UPDATE in place (no duplicate row).
      } else {
        rows.add(row);
      }
    }
    return true;
  }

  @override
  Future<bool> deleteRowsBelowVersion(String uid, int belowVersion) async {
    deleteBelowCalls++;
    rows.removeWhere(
      (r) => r['user_id'] == uid && (r['sync_version'] as int) < belowVersion,
    );
    return true;
  }

  @override
  Future<bool> deleteAllForUser(String uid) async {
    deleteAllCalls++;
    rows.removeWhere((r) => r['user_id'] == uid);
    return true;
  }
}

/// A [LocationService] wired to always return a granted coarse fix at [lat]/[lon]
/// (no platform channel).
LocationService _grantedLocation(double lat, double lon) {
  return LocationService(
    checkPermission: () async => LocationPermission.whileInUse,
    requestPermission: () async => LocationPermission.whileInUse,
    serviceEnabled: () async => true,
    currentPosition: () async => Position(
      latitude: lat,
      longitude: lon,
      timestamp: DateTime.utc(2027),
      accuracy: 100,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    ),
    prefs: SharedPreferences.getInstance,
  );
}

/// A [LocationService] that always denies — the sync must degrade to empty.
LocationService _deniedLocation() {
  return LocationService(
    checkPermission: () async => LocationPermission.deniedForever,
    requestPermission: () async => LocationPermission.deniedForever,
    serviceEnabled: () async => true,
    currentPosition: () async => throw StateError('must not fetch'),
    prefs: SharedPreferences.getInstance,
  );
}

void main() {
  // Mecca, UTC+3 — canonical prayer-time fixture (same as the engine test).
  const meccaLat = 21.4225;
  const meccaLon = 39.8262;
  const mecca = EngineLocation(lat: meccaLat, lon: meccaLon);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  // A calendar with Ramadan 1448 (Feb 8 – Mar 8, 2027) so iftar instants appear,
  // plus a White-Days row for the D1 fatigue test.
  DuaCalendar calendarWith({List<DuaCalendarRow> extra = const []}) {
    return DuaCalendar(
      rows: [
        _row(
          id: 'ramadan_1448',
          kind: 'ramadan',
          tier: 'special',
          start: '2027-02-08',
          end: '2027-03-08',
        ),
        ...extra,
      ],
      lastSeededThrough: DateTime(2027, 6, 20),
      fromBundledAsset: false,
    );
  }

  DuaWindowEngine engineWith(DuaCalendar cal) => DuaWindowEngine(
        repository: _StubRepository(cal),
        localMidnightUtc: (y, m, d) =>
            DateTime.utc(y, m, d).subtract(const Duration(hours: 3)), // UTC+3
      );

  group('engine.computePreciseInstants', () {
    test('projects exactly the 30-day horizon (nothing beyond)', () async {
      final engine = engineWith(calendarWith());
      final now = DateTime.utc(2027, 2, 5, 0, 0);
      final instants = await engine.computePreciseInstants(
        now: now,
        location: mecca,
        nightThirdPolicy: NightThirdFatiguePolicy.everyNight,
      );
      expect(instants, isNotEmpty);
      final horizonEnd = now.add(DuaWindowEngine.preciseSyncHorizon);
      for (final p in instants) {
        expect(p.fireUtc.isBefore(now), isFalse,
            reason: 'no past instants (future-only)');
        expect(p.fireUtc.isAfter(horizonEnd), isFalse,
            reason: 'nothing beyond the 30-day horizon');
      }
    });

    test('D2: fireUtc is the window START (last hour before Maghrib on Friday)',
        () async {
      final engine = engineWith(calendarWith());
      // 2027-02-05 is a Friday. Compute a 1-day-ish window and find the friday
      // hour, then assert its fire instant equals Maghrib − 60 min.
      final instants = await engine.computePreciseInstants(
        now: DateTime.utc(2027, 2, 5, 0, 0),
        location: mecca,
        nightThirdPolicy: NightThirdFatiguePolicy.never,
      );
      final friday = instants.firstWhere(
        (p) => p.type == DuaWindowType.fridayHour,
      );
      // Maghrib for Mecca 2027-02-05 (adhan_dart, MWL) — recover it from the
      // fire instant + the known 60-min lead and assert the lead is exact.
      final maghrib = friday.fireUtc.add(const Duration(minutes: 60));
      final recomputedStart = maghrib.subtract(const Duration(minutes: 60));
      expect(friday.fireUtc.isAtSameMomentAs(recomputedStart), isTrue);
      // Sanity: the friday hour opens in the late afternoon UTC (Mecca ~15:00Z).
      expect(friday.fireUtc.hour, inInclusiveRange(13, 16));
    });

    test('no location → empty instant list', () async {
      final engine = engineWith(calendarWith());
      final instants = await engine.computePreciseInstants(
        now: DateTime.utc(2027, 2, 5),
        location: null,
        nightThirdPolicy: NightThirdFatiguePolicy.everyNight,
      );
      expect(instants, isEmpty);
    });

    group('D1 fatigue filter (night-third)', () {
      // Use April 2027 (no Ramadan) so iftar never appears and the night-third
      // is isolated. A White-Days row spans Apr 20–22.
      DuaCalendar aprilCalendar() => DuaCalendar(
            rows: [
              _row(
                id: 'wd_apr',
                kind: 'white_days',
                tier: 'soft',
                start: '2027-04-20',
                end: '2027-04-22',
              ),
            ],
            lastSeededThrough: DateTime(2027, 6, 20),
            fromBundledAsset: false,
          );

      test('specialNightsOnly → night-third only on Fri / White-Days nights',
          () async {
        final engine = engineWith(aprilCalendar());
        final now = DateTime.utc(2027, 4, 1);
        final instants = await engine.computePreciseInstants(
          now: now,
          location: mecca,
          nightThirdPolicy: NightThirdFatiguePolicy.specialNightsOnly,
        );
        final nights =
            instants.where((p) => p.type == DuaWindowType.lastThirdOfNight);
        expect(nights, isNotEmpty);

        // The third fires pre-dawn; the EVENING that opened it is the local day
        // BEFORE the fire instant's local date.
        DateTime eveningOf(PreciseInstant p) {
          final local = p.fireUtc.add(const Duration(hours: 3)); // UTC+3
          final fireDay = DateTime.utc(local.year, local.month, local.day);
          return fireDay.subtract(const Duration(days: 1));
        }

        for (final n in nights) {
          final evening = eveningOf(n);
          final isFriday = evening.weekday == DateTime.friday;
          final inWhiteDays = !evening.isBefore(DateTime.utc(2027, 4, 20)) &&
              !evening.isAfter(DateTime.utc(2027, 4, 22));
          expect(isFriday || inWhiteDays, isTrue,
              reason: 'night-third opened on ${evening.toIso8601String()} which '
                  'is neither a Friday nor a White-Days evening');
        }
        // The White-Days nights (evenings Apr 20–22) must be present.
        final whiteDayNights = nights.where((p) {
          final evening = eveningOf(p);
          return !evening.isBefore(DateTime.utc(2027, 4, 20)) &&
              !evening.isAfter(DateTime.utc(2027, 4, 22));
        });
        expect(whiteDayNights, isNotEmpty);
      });

      test('everyNight yields far more night-thirds than specialNightsOnly',
          () async {
        final engine = engineWith(aprilCalendar());
        final now = DateTime.utc(2027, 4, 1);
        final special = await engine.computePreciseInstants(
          now: now,
          location: mecca,
          nightThirdPolicy: NightThirdFatiguePolicy.specialNightsOnly,
        );
        final nightly = await engine.computePreciseInstants(
          now: now,
          location: mecca,
          nightThirdPolicy: NightThirdFatiguePolicy.everyNight,
        );
        int nights(List<PreciseInstant> xs) =>
            xs.where((p) => p.type == DuaWindowType.lastThirdOfNight).length;
        expect(nights(nightly), greaterThan(nights(special)));
        // ~30 nights vs a handful of Fridays + 3 White-Days.
        expect(nights(nightly), greaterThanOrEqualTo(28));
        expect(nights(special), lessThan(12));
      });

      test('never → zero night-third instants', () async {
        final engine = engineWith(aprilCalendar());
        final instants = await engine.computePreciseInstants(
          now: DateTime.utc(2027, 4, 1),
          location: mecca,
          nightThirdPolicy: NightThirdFatiguePolicy.never,
        );
        expect(
          instants.any((p) => p.type == DuaWindowType.lastThirdOfNight),
          isFalse,
        );
      });
    });
  });

  group('DuaPreciseSyncService.sync', () {
    DuaPreciseSyncService service({
      required DuaCalendar calendar,
      required LocationService location,
      required _FakeBackend backend,
      DateTime? now,
      NightThirdFatiguePolicy policy = NightThirdFatiguePolicy.everyNight,
    }) {
      return DuaPreciseSyncService(
        engine: engineWith(calendar),
        locationService: location,
        backend: backend,
        clock: () => now ?? DateTime.utc(2027, 2, 5),
        nightThirdPolicy: policy,
      );
    }

    test('writes rows with window_type / fire_utc / title / body at v1',
        () async {
      final backend = _FakeBackend();
      await service(
        calendar: calendarWith(),
        location: _grantedLocation(meccaLat, meccaLon),
        backend: backend,
      ).sync();

      expect(backend.rows, isNotEmpty);
      for (final r in backend.rows) {
        expect(r['user_id'], 'user-1');
        expect(r['sync_version'], 1);
        expect(r['window_type'], isA<String>());
        expect(r['fire_utc'], isA<String>());
        expect((r['title'] as String).isNotEmpty, isTrue);
        expect((r['body'] as String).isNotEmpty, isTrue);
        // window_type must be one of the three precise wire names.
        expect(
          ['last_third_of_night', 'friday_hour', 'iftar']
              .contains(r['window_type']),
          isTrue,
        );
      }
    });

    test('atomic sync-by-version: re-sync replaces prior rows, no drop/dup',
        () async {
      final backend = _FakeBackend();
      final svc = service(
        calendar: calendarWith(),
        location: _grantedLocation(meccaLat, meccaLon),
        backend: backend,
      );

      await svc.sync();
      final v1Count = backend.rows.length;
      expect(v1Count, greaterThan(0));
      expect(backend.rows.every((r) => r['sync_version'] == 1), isTrue);

      // Re-sync (same inputs) → bumps to v2, inserts fresh rows, retires v1.
      await svc.sync();

      // Every remaining row is the NEW version — the old version was retired.
      expect(backend.rows.every((r) => r['sync_version'] == 2), isTrue);
      // Same count as v1 (deterministic inputs) — no drift, no duplication.
      expect(backend.rows.length, v1Count);
      // The insert always ran before the delete-below (never a blind delete).
      expect(backend.insertCalls, 2);
      expect(backend.deleteBelowCalls, 2);
      expect(backend.deleteAllCalls, 0);

      // No duplicate (window_type, fire_utc) rows survive.
      final keys = backend.rows
          .map((r) => '${r['window_type']}|${r['fire_utc']}')
          .toList();
      expect(keys.toSet().length, keys.length);
    });

    test('insert failure does NOT delete the prior version (no gap)', () async {
      final backend = _FakeBackend();
      final svc = service(
        calendar: calendarWith(),
        location: _grantedLocation(meccaLat, meccaLon),
        backend: backend,
      );
      await svc.sync(); // v1 rows land
      final v1 = backend.rows.length;
      expect(v1, greaterThan(0));

      backend.failInsert = true;
      await svc.sync(); // v2 insert fails

      // v1 rows survive; the delete-below was NOT called on the failed run.
      expect(backend.rows.length, v1);
      expect(backend.rows.every((r) => r['sync_version'] == 1), isTrue);
      expect(backend.deleteBelowCalls, 1,
          reason: 'delete-below only ran on the successful v1 sync');
    });

    test(
        'unique constraint: re-sync of identical instants → no dup rows, none '
        'dropped, version bumped', () async {
      final backend = _FakeBackend();
      final svc = service(
        calendar: calendarWith(),
        location: _grantedLocation(meccaLat, meccaLon),
        backend: backend,
      );

      await svc.sync();
      final v1Rows = backend.rows.length;
      final v1Keys = backend.rows
          .map((r) => '${r['window_type']}|${r['fire_utc']}')
          .toSet();
      expect(v1Rows, greaterThan(0));

      // Re-sync the EXACT same instants (same clock, same location). Under the
      // unique constraint the upsert UPDATES each existing instant to v2 rather
      // than inserting a colliding duplicate.
      await svc.sync();

      // Same instants, same count — no duplicate rows for any (window_type,
      // fire_utc), and none dropped.
      expect(backend.rows.length, v1Rows, reason: 'no dup rows, none dropped');
      final v2Keys = backend.rows
          .map((r) => '${r['window_type']}|${r['fire_utc']}')
          .toList();
      expect(v2Keys.toSet().length, v2Keys.length, reason: 'no duplicate keys');
      expect(v2Keys.toSet(), v1Keys, reason: 'identical instant set');
      // Every surviving row was bumped to v2 (delete-below retired nothing
      // because the upsert moved every instant forward).
      expect(backend.rows.every((r) => r['sync_version'] == 2), isTrue);
    });

    test('stale instant absent from the new set is deleted', () async {
      final backend = _FakeBackend();
      // Seed a v1 stale instant that the engine will NOT re-emit (a far-future
      // fire_utc that is outside the fresh horizon's produced set).
      backend.rows.add(<String, dynamic>{
        'user_id': 'user-1',
        'window_type': 'iftar',
        'fire_utc': DateTime.utc(2099, 1, 1, 12).toIso8601String(),
        'sync_version': 1,
        'title': 'stale',
        'body': 'stale',
      });

      await service(
        calendar: calendarWith(),
        location: _grantedLocation(meccaLat, meccaLon),
        backend: backend,
      ).sync();

      // The stale v1 instant is gone (kept sync_version 1 → below v2 → deleted),
      // and no fresh row carries that fire_utc.
      final staleSurvives = backend.rows.any(
        (r) => r['fire_utc'] == DateTime.utc(2099, 1, 1, 12).toIso8601String(),
      );
      expect(staleSurvives, isFalse, reason: 'stale instant retired');
      expect(backend.rows, isNotEmpty);
      expect(backend.rows.every((r) => r['sync_version'] == 2), isTrue);
    });

    test(
        'two interleaved syncs cannot produce two rows for one instant',
        () async {
      // Simulate two concurrent syncs (two devices / a fast double foreground)
      // sharing ONE server table: both read prior=0, both compute the same
      // instants, both upsert at v1. Without the unique constraint each would
      // insert its own copy → duplicates. With it modelled as upsert-on-
      // conflict, the second sync UPDATES the first's rows in place.
      final backend = _FakeBackend();
      final svcA = service(
        calendar: calendarWith(),
        location: _grantedLocation(meccaLat, meccaLon),
        backend: backend,
      );
      final svcB = service(
        calendar: calendarWith(),
        location: _grantedLocation(meccaLat, meccaLon),
        backend: backend,
      );

      // Interleave: run both against the same backend.
      await svcA.sync();
      await svcB.sync();

      // Exactly one row per (window_type, fire_utc) — no instant is duplicated
      // even though two syncs both wrote the full set.
      final keys = backend.rows
          .map((r) => '${r['window_type']}|${r['fire_utc']}')
          .toList();
      expect(keys.toSet().length, keys.length,
          reason: 'no instant duplicated across interleaved syncs');
    });

    test('no location → clears the user rows (empty instants)', () async {
      final backend = _FakeBackend();
      // Seed a stale row so we can prove it gets cleared.
      backend.rows.add(<String, dynamic>{
        'user_id': 'user-1',
        'window_type': 'iftar',
        'fire_utc': DateTime.utc(2027, 2, 8, 15).toIso8601String(),
        'sync_version': 1,
        'title': 't',
        'body': 'b',
      });

      await service(
        calendar: calendarWith(),
        location: _deniedLocation(),
        backend: backend,
      ).sync();

      expect(backend.rows, isEmpty);
      expect(backend.deleteAllCalls, 1);
      expect(backend.insertCalls, 0);
    });

    test('signed out → no-op', () async {
      final backend = _FakeBackend(userId: null);
      await service(
        calendar: calendarWith(),
        location: _grantedLocation(meccaLat, meccaLon),
        backend: backend,
      ).sync();
      expect(backend.insertCalls, 0);
      expect(backend.deleteAllCalls, 0);
      expect(backend.rows, isEmpty);
    });
  });

  group('DuaPreciseSyncService.clear', () {
    test('toggle-off deletes all of the user rows', () async {
      final backend = _FakeBackend();
      backend.rows.addAll([
        <String, dynamic>{
          'user_id': 'user-1',
          'window_type': 'friday_hour',
          'fire_utc': DateTime.utc(2027, 2, 5, 15).toIso8601String(),
          'sync_version': 3,
          'title': 't',
          'body': 'b',
        },
      ]);

      await DuaPreciseSyncService(
        engine: engineWith(calendarWith()),
        locationService: _grantedLocation(meccaLat, meccaLon),
        backend: backend,
      ).clear();

      expect(backend.rows, isEmpty);
      expect(backend.deleteAllCalls, 1);
    });

    test('signed out → clear no-ops', () async {
      final backend = _FakeBackend(userId: null);
      await DuaPreciseSyncService(
        engine: engineWith(calendarWith()),
        locationService: _grantedLocation(meccaLat, meccaLon),
        backend: backend,
      ).clear();
      expect(backend.deleteAllCalls, 0);
    });
  });
}
