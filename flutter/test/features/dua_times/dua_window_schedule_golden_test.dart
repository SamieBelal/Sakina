import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/dua_times/models/dua_window.dart';
import 'package:sakina/features/dua_times/models/dua_window_schedule.dart';
import 'package:sakina/features/dua_times/models/dua_window_type.dart';

/// GOLDEN serialization contract for the payload the engine pushes across the
/// App Group to the Swift widget decoder (spec §7 / §14).
///
/// Instants are epoch-MILLIS (int) so `Date(timeIntervalSince1970: n/1000)`
/// decodes them directly. If this test breaks, the Swift decoder must be
/// updated in lockstep — do NOT silently change the shape.
void main() {
  test('DuaWindowSchedule.toJson pins the exact key shape', () {
    final active = DuaWindow(
      type: DuaWindowType.lastThirdOfNight,
      tier: DuaWindowTier.hero,
      titleKey: 'dua_window.last_third.title',
      sourceRef: 'al-Bukhari 1145',
      startUtc: DateTime.utc(2027, 5, 15, 22, 11),
      endUtc: DateTime.utc(2027, 5, 16, 1, 20),
      isAllDay: false,
      locationDependent: true,
    );
    final next = DuaWindow(
      type: DuaWindowType.arafah,
      tier: DuaWindowTier.hero,
      titleKey: 'dua_window.arafah',
      sourceRef: 'Tirmidhi 3585',
      startUtc: DateTime.utc(2027, 5, 15, 21, 0),
      endUtc: DateTime.utc(2027, 5, 16, 21, 0),
      isAllDay: true,
      locationDependent: false,
    );
    final schedule = DuaWindowSchedule(
      active: active,
      next: next,
      upcoming: [next],
      urgency: UrgencyState.comfortable,
      computedAt: DuaScheduleStamp(
        tz: 'Asia/Riyadh',
        lat: 21.4225,
        lon: 39.8262,
        computedThroughUtc: DateTime.utc(2027, 5, 22, 21, 0),
      ),
    );

    // Round-trip through a real JSON string so nested Freezed objects are fully
    // materialised as plain maps — exactly what crosses the App Group boundary.
    final json = jsonDecode(jsonEncode(schedule.toJson())) as Map<String, dynamic>;

    // ---- Top-level keys ----
    expect(json.keys.toList(),
        ['active', 'next', 'upcoming', 'urgency', 'computed_at']);
    expect(json['urgency'], 'comfortable');

    // ---- Window keys (active) ----
    final activeJson = json['active'] as Map<String, dynamic>;
    expect(activeJson.keys.toList(), [
      'type',
      'tier',
      'title_key',
      'source_ref',
      'start_utc',
      'end_utc',
      'is_all_day',
      'location_dependent',
    ]);
    expect(activeJson['type'], 'last_third_of_night');
    expect(activeJson['tier'], 'hero');
    expect(activeJson['title_key'], 'dua_window.last_third.title');
    expect(activeJson['source_ref'], 'al-Bukhari 1145');
    // Epoch MILLIS (int), UTC.
    expect(activeJson['start_utc'],
        DateTime.utc(2027, 5, 15, 22, 11).millisecondsSinceEpoch);
    expect(activeJson['end_utc'],
        DateTime.utc(2027, 5, 16, 1, 20).millisecondsSinceEpoch);
    expect(activeJson['start_utc'], isA<int>());
    expect(activeJson['is_all_day'], false);
    expect(activeJson['location_dependent'], true);

    // ---- upcoming[] is a list of the same window shape ----
    final upcoming = json['upcoming'] as List<dynamic>;
    expect(upcoming, hasLength(1));
    expect((upcoming.first as Map)['type'], 'arafah');
    expect((upcoming.first as Map)['is_all_day'], true);

    // ---- Stamp keys ----
    final stamp = json['computed_at'] as Map<String, dynamic>;
    expect(stamp.keys.toList(), ['tz', 'lat', 'lon', 'computed_through_utc']);
    expect(stamp['tz'], 'Asia/Riyadh');
    expect(stamp['lat'], 21.4225);
    expect(stamp['lon'], 39.8262);
    expect(stamp['computed_through_utc'],
        DateTime.utc(2027, 5, 22, 21, 0).millisecondsSinceEpoch);
    expect(stamp['computed_through_utc'], isA<int>());
  });

  test('round-trips through fromJson', () {
    final schedule = DuaWindowSchedule(
      active: null,
      next: null,
      upcoming: const [],
      urgency: UrgencyState.upcoming,
      computedAt: DuaScheduleStamp(
        tz: 'local',
        lat: null,
        lon: null,
        computedThroughUtc: DateTime.utc(2027, 1, 1),
      ),
    );
    final restored = DuaWindowSchedule.fromJson(
      jsonDecode(jsonEncode(schedule.toJson())) as Map<String, dynamic>,
    );
    expect(restored, schedule);
    expect(restored.computedAt.computedThroughUtc.isUtc, isTrue);
  });
}
