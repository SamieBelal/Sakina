import 'package:freezed_annotation/freezed_annotation.dart';

import 'dua_window_type.dart';

part 'dua_window.freezed.dart';
part 'dua_window.g.dart';

/// A single *awqāt al-ijābah* (time of accepted duʿā) window with concrete
/// bounds resolved for a given day + location.
///
/// **Timing is always stored as absolute UTC instants** (`startUtc`/`endUtc`),
/// which stays correct across DST. All-day calendar windows (`isAllDay: true`)
/// carry the device-local midnight→midnight span expanded to UTC by the engine
/// (see spec §4 — a fixed UTC instant would open ʿArafah ~13h early/late at the
/// date line).
///
/// `titleKey` and `sourceRef` are copy/source keys carried verbatim from the
/// curated catalog — no scripture is fabricated here (per `CLAUDE.md`).
///
/// The JSON shape is the serialization contract shared with the native widget
/// (spec §7). Field names use snake_case JSON keys.
@freezed
class DuaWindow with _$DuaWindow {
  const factory DuaWindow({
    /// The category of this window (drives priority + icon + copy).
    required DuaWindowType type,

    /// Visual + priority weight (hero / special / soft).
    required DuaWindowTier tier,

    /// i18n copy key for the window title (e.g. `dua_window.last_third.title`).
    @JsonKey(name: 'title_key') required String titleKey,

    /// Optional hadith source reference for the "why" disclosure
    /// (e.g. `al-Bukhari 1145`). Never fabricated — carried from the catalog.
    @JsonKey(name: 'source_ref') String? sourceRef,

    /// Window open instant (absolute UTC).
    @JsonKey(name: 'start_utc') required DateTime startUtc,

    /// Window close instant (absolute UTC).
    @JsonKey(name: 'end_utc') required DateTime endUtc,

    /// True for all-day/all-night calendar windows (ʿArafah, ʿAshura, White
    /// Days, Eids, Friday day, Ramadan). Renders "today only", never a ticking
    /// countdown (spec §9.1 escalation ladder).
    @JsonKey(name: 'is_all_day') required bool isAllDay,

    /// True if this window's bounds were derived from prayer times (needs a
    /// location). When the travel guard trips or location is absent, these are
    /// suppressed and only calendar windows survive (spec §9 / §10).
    @JsonKey(name: 'location_dependent') required bool locationDependent,
  }) = _DuaWindow;

  factory DuaWindow.fromJson(Map<String, dynamic> json) =>
      _$DuaWindowFromJson(json);
}
