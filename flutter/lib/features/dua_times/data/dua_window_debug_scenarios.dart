import '../models/dua_window.dart';
import '../models/dua_window_schedule.dart';
import '../models/dua_window_type.dart';

/// Dev/QA-only synthetic schedules so reviewers can SEE each card + widget state
/// on demand, without waiting for the real clock (e.g. an actual Friday, or
/// ʿArafah). Window instants are relative to `now`, so the live countdown (the
/// card's Dart `Timer` and the widget's `Text(timerInterval:)`) actually ticks.
///
/// NOT used in production — driven only from Dev Tools, which is release-stripped
/// (`!kReleaseMode`). See `DuaWindowNotifier.debugPreview`.
class DuaWindowDebugScenarios {
  const DuaWindowDebugScenarios._();

  static DuaScheduleStamp _preciseStamp(DateTime now) => DuaScheduleStamp(
        tz: 'local',
        lat: 21.4225,
        lon: 39.8262,
        computedThroughUtc: now.toUtc().add(const Duration(days: 7)),
      );

  static DuaWindow _fridayHour(DateTime now, Duration endsIn) => DuaWindow(
        type: DuaWindowType.fridayHour,
        tier: DuaWindowTier.hero,
        titleKey: 'dua_window.friday_hour.title',
        sourceRef: 'al-Bukhari 935, Muslim 852',
        startUtc: now.toUtc().subtract(const Duration(minutes: 30)),
        endUtc: now.toUtc().add(endsIn),
        isAllDay: false,
        locationDependent: true,
      );

  static DuaWindow _nightThird(DateTime now, Duration endsIn) => DuaWindow(
        type: DuaWindowType.lastThirdOfNight,
        tier: DuaWindowTier.hero,
        titleKey: 'dua_window.last_third.title',
        sourceRef: 'al-Bukhari 1145',
        startUtc: now.toUtc().subtract(const Duration(hours: 1)),
        endUtc: now.toUtc().add(endsIn),
        isAllDay: false,
        locationDependent: true,
      );

  static DuaWindowSchedule _active(DateTime now, DuaWindow w, UrgencyState u) =>
      DuaWindowSchedule(
        active: w,
        upcoming: [w],
        urgency: u,
        computedAt: _preciseStamp(now),
      );

  /// Friday hour, comfortable (>1h left) — static deadline, emerald.
  static DuaWindowSchedule fridayComfortable(DateTime now) => _active(now,
      _fridayHour(now, const Duration(minutes: 55)), UrgencyState.comfortable);

  /// Friday hour, closing (<1h) — live countdown.
  static DuaWindowSchedule fridayClosing(DateTime now) => _active(
      now, _fridayHour(now, const Duration(minutes: 42)), UrgencyState.closing);

  /// Friday hour, last call (<15m) — AMBER + sharper verb.
  static DuaWindowSchedule fridayLastCall(DateTime now) => _active(
      now, _fridayHour(now, const Duration(minutes: 9)), UrgencyState.lastCall);

  /// Last third of the night, closing — live countdown.
  static DuaWindowSchedule nightClosing(DateTime now) => _active(
      now, _nightThird(now, const Duration(minutes: 48)), UrgencyState.closing);

  /// ʿArafah — all-day ("today only", never ticks).
  static DuaWindowSchedule arafahToday(DateTime now) {
    final w = DuaWindow(
      type: DuaWindowType.arafah,
      tier: DuaWindowTier.hero,
      titleKey: 'dua_window.arafah',
      sourceRef: 'Tirmidhi 3585',
      startUtc: DateTime(now.year, now.month, now.day).toUtc(),
      endUtc: DateTime(now.year, now.month, now.day + 1).toUtc(),
      isAllDay: true,
      locationDependent: false,
    );
    return _active(now, w, UrgencyState.allDay);
  }

  /// Between windows — the next window (Friday hour) opens tomorrow.
  static DuaWindowSchedule between(DateTime now) {
    final next = _fridayHour(now, Duration.zero).copyWith(
      startUtc: now.toUtc().add(const Duration(hours: 20)),
      endUtc: now.toUtc().add(const Duration(hours: 21)),
    );
    return DuaWindowSchedule(
      next: next,
      upcoming: [next],
      urgency: UrgencyState.upcoming,
      computedAt: _preciseStamp(now),
    );
  }
}
