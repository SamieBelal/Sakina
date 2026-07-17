import 'package:freezed_annotation/freezed_annotation.dart';

/// The category of an *awqāt al-ijābah* (time of accepted duʿā) window.
///
/// Recurring windows are location-dependent (derived from prayer times);
/// calendar windows are location-independent (device weekday / seeded
/// `dua_windows` rows). See the design spec §3 for the full table + sources.
///
/// The JSON values are the serialization contract shared with the native
/// widget's Swift decoder — do NOT rename them without updating the widget
/// extension (see §7 / §14 serialization-contract test).
enum DuaWindowType {
  /// Maghrib → Fajr, final third of the night. Location-dependent.
  @JsonValue('last_third_of_night')
  lastThirdOfNight,

  /// ʿAsr → Maghrib on Friday. Friday itself is calendar; the *hour* is
  /// location-dependent.
  @JsonValue('friday_hour')
  fridayHour,

  /// ~20 min before Maghrib during Ramadan. Location-dependent.
  @JsonValue('iftar')
  iftar,

  /// Day of ʿArafah — 9 Dhul-Ḥijjah. Calendar (seeded).
  @JsonValue('arafah')
  arafah,

  /// First 10 days of Dhul-Ḥijjah. Calendar (seeded).
  @JsonValue('dhul_hijjah_10')
  dhulHijjah10,

  /// Last 10 nights / Laylat al-Qadr (odd emphasis). Calendar (seeded).
  @JsonValue('laylat_al_qadr')
  laylatAlQadr,

  /// All of Ramadan. Calendar (seeded).
  @JsonValue('ramadan')
  ramadan,

  /// ʿAshura (+ the 9th). Calendar (seeded).
  @JsonValue('ashura')
  ashura,

  /// White Days — 13–15 of each Hijri month. Calendar (seeded).
  @JsonValue('white_days')
  whiteDays,

  /// The two Eids — 1 Shawwal, 10 Dhul-Ḥijjah. Calendar (seeded).
  @JsonValue('eid')
  eid,

  /// Friday (Jumuʿah) as a whole day. Calendar (device weekday).
  @JsonValue('friday_day')
  fridayDay,
}

/// The stable snake_case wire string for a [DuaWindowType].
///
/// This MUST match the `@JsonValue(...)` labels above (the serialization
/// contract shared with the native widget's Swift decoder AND the server's
/// `dua_precise_notifications.window_type` column). Centralised here so the
/// notification scheduler, the precise-sync service, and the copy map all speak
/// the same vocabulary instead of each re-deriving it (per `CLAUDE.md`).
extension DuaWindowTypeWire on DuaWindowType {
  String get wireName {
    switch (this) {
      case DuaWindowType.lastThirdOfNight:
        return 'last_third_of_night';
      case DuaWindowType.fridayHour:
        return 'friday_hour';
      case DuaWindowType.iftar:
        return 'iftar';
      case DuaWindowType.arafah:
        return 'arafah';
      case DuaWindowType.dhulHijjah10:
        return 'dhul_hijjah_10';
      case DuaWindowType.laylatAlQadr:
        return 'laylat_al_qadr';
      case DuaWindowType.ramadan:
        return 'ramadan';
      case DuaWindowType.ashura:
        return 'ashura';
      case DuaWindowType.whiteDays:
        return 'white_days';
      case DuaWindowType.eid:
        return 'eid';
      case DuaWindowType.fridayDay:
        return 'friday_day';
    }
  }
}

/// Visual + priority weight of a window on the surfaces.
///
/// `hero` wins the primary line (see overlap priority in spec §4);
/// `soft` is the humble location-absent "depths of the night" framing.
enum DuaWindowTier {
  @JsonValue('hero')
  hero,

  @JsonValue('special')
  special,

  @JsonValue('soft')
  soft,
}

/// Runtime urgency state used to drive the copy + escalation ladder (spec §9.1).
///
/// Computed by the engine from `now` vs the active window bounds and carried in
/// the schedule payload so the Swift widget can mirror the escalation ladder
/// without re-deriving it. JSON values are the serialization contract — do NOT
/// rename without updating the widget decoder.
enum UrgencyState {
  /// Active window, > 1h remaining — calm static deadline.
  @JsonValue('comfortable')
  comfortable,

  /// Active window, < 1h remaining — live ticking countdown.
  @JsonValue('closing')
  closing,

  /// Active window, < 15m remaining — amber last-call treatment.
  @JsonValue('last_call')
  lastCall,

  /// Active all-day window (ʿArafah, ʿAshura, White Days) — "today only",
  /// never a ticking countdown.
  @JsonValue('all_day')
  allDay,

  /// No active window — counting down to the next one.
  @JsonValue('upcoming')
  upcoming,
}
