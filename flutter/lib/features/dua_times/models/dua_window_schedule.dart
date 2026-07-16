import 'package:freezed_annotation/freezed_annotation.dart';

import 'dua_json_converters.dart';
import 'dua_window.dart';
import 'dua_window_type.dart';

part 'dua_window_schedule.freezed.dart';
part 'dua_window_schedule.g.dart';

/// Provenance stamp for a [DuaWindowSchedule].
///
/// This is the payload the native widget's **travel guard** reads (spec §7/§9,
/// decision D5): the extension compares the stamped [tz] against
/// `TimeZone.current` and, on mismatch, suppresses precise (location-dependent)
/// windows — rendering calendar + soft-night only rather than lying with the
/// old city's prayer times.
///
/// [computedThroughUtc] is the horizon the schedule covers, so a stale payload
/// can be detected. [lat]/[lon] are the coarse coordinates the precise windows
/// were computed from (null when location was unavailable → calendar-only).
@freezed
class DuaScheduleStamp with _$DuaScheduleStamp {
  const factory DuaScheduleStamp({
    /// IANA time-zone identifier the schedule was computed in
    /// (e.g. `America/Los_Angeles`). The travel-guard key.
    required String tz,

    /// Coarse latitude used for precise windows; null if location-only.
    double? lat,

    /// Coarse longitude used for precise windows; null if location-only.
    double? lon,

    /// The UTC instant through which this schedule's windows are populated.
    /// Serialized as epoch millis (int) for the Swift decoder.
    @JsonKey(name: 'computed_through_utc')
    @EpochMillisConverter()
    required DateTime computedThroughUtc,
  }) = _DuaScheduleStamp;

  factory DuaScheduleStamp.fromJson(Map<String, dynamic> json) =>
      _$DuaScheduleStampFromJson(json);
}

/// The resolved duʿā-window schedule pushed to both surfaces (in-app card +
/// native widget). The engine (a later wave) composes prayer + calendar windows
/// into this shape; this foundation slice only defines the contract.
///
/// - [active]: the highest-priority window covering `now` (null if between).
/// - [next]: the next window to open after `now` (null if none upcoming).
/// - [upcoming]: the ordered ~7-day timeline (includes [next]) for the widget.
/// - [urgency]: the escalation state for [active] (spec §9.1). When no window is
///   active this is [UrgencyState.upcoming].
/// - [computedAt]: provenance stamp for the travel guard + staleness checks.
///
/// The JSON shape is the serialization contract shared with the Swift decoder
/// (spec §7 / §14 golden test).
@freezed
class DuaWindowSchedule with _$DuaWindowSchedule {
  const factory DuaWindowSchedule({
    DuaWindow? active,
    DuaWindow? next,
    @Default(<DuaWindow>[]) List<DuaWindow> upcoming,
    @Default(UrgencyState.upcoming) UrgencyState urgency,
    @JsonKey(name: 'computed_at') required DuaScheduleStamp computedAt,
  }) = _DuaWindowSchedule;

  factory DuaWindowSchedule.fromJson(Map<String, dynamic> json) =>
      _$DuaWindowScheduleFromJson(json);
}
